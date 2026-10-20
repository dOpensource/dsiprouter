#!/usr/bin/env bash
#
# Summary:  collect debugging info from the root volume of a failed (unreachable) dsiprouter image build
#           run this on a working instance that has the bad root volume attached
# Usage:    ./chroot-diag.sh [-d <device>] [-o <output file>] [-h] <root volume mount point>
# Example:  ./chroot-diag.sh -d /dev/nvme1n1 -o /tmp/diag.txt /mnt/bad     (script mounts and unmounts the disk)
#           mount /dev/nvme1n1p1 /mnt/bad && ./chroot-diag.sh /mnt/bad     (volume already mounted)
# Notes:    - with -d the device can be a whole disk (largest non-vfat partition is the root, EFI partition is mounted too) or a partition
#           - without -d the root volume must already be mounted, and the script leaves it mounted
#           - live-state commands (ip, networkctl, nmcli) are not useful offline, config files and journals are read instead
#           - review the output for sensitive data before sharing it
#

set -Eeuo pipefail

ROOT=''
MOUNTED_ROOT=0
MOUNTED_EFI=0
MOUNTED_BINDS=0
TMP_MNT=0
EFI_PART_GUID='c12a7328-f81f-11d2-ba4b-00a0c93ec93b'

function usage() {
    echo "Usage: $0 [-d <device>] [-o <output file>] [-h] <root volume mount point>"
}

function log() {
    echo "[$(date -u +%FT%TZ)] $*" >&2
}

function cleanup() {
    local MNT
    set +e
    if (( MOUNTED_BINDS )); then
        for MNT in sys proc dev; do
            umount -R -l "${ROOT}/${MNT}"
        done
    fi
    (( MOUNTED_EFI )) && umount "${ROOT}/boot/efi"
    if (( MOUNTED_ROOT )); then
        sync
        umount "$ROOT" && log "unmounted $ROOT"
    fi
    # only remove the mount point we created with mktemp, never a user supplied one
    (( TMP_MNT )) && ! mountpoint -q "$ROOT" && rmdir "$ROOT"
    return 0
}

# prints the root partition for a device (the device itself if it is a partition)
function findRootPart() {
    local DEV="$1" TYPE

    TYPE="$(lsblk -dnro TYPE "$DEV")"
    if [[ "$TYPE" == 'disk' ]]; then
        lsblk -nrbpo NAME,SIZE,TYPE,FSTYPE "$DEV" |
            awk '$3 == "part" && $4 != "" && $4 != "vfat" && $4 != "swap" {print $2, $1}' |
            sort -rn | head -n 1 | cut -d ' ' -f 2
    else
        echo "$DEV"
    fi
}

# prints the EFI system partition for a disk (if any)
function findEfiPart() {
    local DEV="$1"

    lsblk -nrpo NAME,TYPE,PARTTYPE "$DEV" |
        awk -v g="$EFI_PART_GUID" '$2 == "part" && tolower($3) == g {print $1; exit}'
}

function mountDisk() {
    local DEV="$1" MNTPT="$2" PART FSTYPE EFI
    local -a OPTS=()

    [[ -b "$DEV" ]] || { log "$DEV is not a block device"; exit 1; }
    if mountpoint -q "$MNTPT" 2>/dev/null; then
        log "$MNTPT is already mounted, unmount it or run without -d"
        exit 1
    fi

    PART="$(findRootPart "$DEV")"
    [[ -n "$PART" ]] || { log "no root partition found on $DEV"; exit 1; }
    if findmnt -rn -S "$PART" >/dev/null; then
        log "$PART is already mounted elsewhere"
        exit 1
    fi

    # cloned images share filesystem UUIDs, xfs refuses to mount a duplicate without nouuid
    FSTYPE="$(lsblk -dnro FSTYPE "$PART")"
    [[ "$FSTYPE" == 'xfs' ]] && OPTS=(-o nouuid)

    mkdir -p "$MNTPT"
    mount "${OPTS[@]}" "$PART" "$MNTPT"
    MOUNTED_ROOT=1
    log "mounted $PART ($FSTYPE) on $MNTPT"

    if [[ "$PART" != "$DEV" ]]; then
        EFI="$(findEfiPart "$DEV")"
        if [[ -n "$EFI" && -d "$MNTPT/boot/efi" ]]; then
            mount "$EFI" "$MNTPT/boot/efi"
            MOUNTED_EFI=1
            log "mounted $EFI on $MNTPT/boot/efi"
        fi
    fi
}

function main() {
    local OUT='' DEVICE=''
    local OPT

    while getopts ':d:o:h' OPT; do
        case "$OPT" in
            d) DEVICE="$OPTARG" ;;
            o) OUT="$OPTARG" ;;
            h) usage; exit 0 ;;
            *) usage >&2; exit 1 ;;
        esac
    done
    shift $((OPTIND - 1))

    if (( $# != 1 )); then
        usage >&2
        exit 1
    fi
    if (( EUID != 0 )); then
        log 'must be run as root'
        exit 1
    fi

    if [[ -b "$1" ]]; then
        if [[ -n "$DEVICE" ]]; then
            log "$1 is a block device, the positional arg must be a mount point directory (e.g. -d $DEVICE /mnt/bad)"
            exit 1
        fi
        # a device was given instead of a mount point: mount it on a temp dir
        DEVICE="$1"
        set -- "$(mktemp -d /mnt/chroot-diag.XXXXXX)"
        TMP_MNT=1
        log "device given, using mount point $1"
    fi
    ROOT="$(realpath -m "$1")"
    trap cleanup EXIT
    if [[ -n "$DEVICE" ]]; then
        mountDisk "$DEVICE" "$ROOT"
    fi
    if [[ ! -d "$ROOT" ]] || ! mountpoint -q "$ROOT"; then
        log "$ROOT is not a mounted directory"
        exit 1
    fi
    if [[ ! -f "$ROOT/etc/os-release" ]]; then
        log "$ROOT does not look like a root filesystem (missing etc/os-release)"
        exit 1
    fi
    if [[ ! -x "$ROOT/bin/bash" ]]; then
        log "$ROOT/bin/bash not found, cannot chroot"
        exit 1
    fi

    OUT="${OUT:-/tmp/diag-$(date -u +%Y%m%dT%H%M%SZ).txt}"
    : >"$OUT"

    local MNT
    MOUNTED_BINDS=1
    for MNT in dev proc sys; do
        mount --rbind "/$MNT" "${ROOT}/${MNT}"
        mount --make-rslave "${ROOT}/${MNT}"
    done

    log "collecting diagnostics from $ROOT into $OUT"
    chroot "$ROOT" /bin/bash -s >"$OUT" 2>&1 <<'CHROOT_EOF' || true
sec() { printf '\n\n########## %s ##########\n' "$*"; }
run() { printf '\n$ %s\n' "$*"; bash -c "$*" 2>&1; echo "[rc=$?]"; }
J='journalctl --directory=/var/log/journal --no-pager'

sec 'IMAGE STATE (was pre-snapshot.sh run? expect: no ssh host keys, no authorized_keys, empty machine-id, empty /var/lib/cloud/instances)'
run 'date -u; cat /etc/os-release | head -5'
run 'ls -la /etc/ssh/ | grep -i key'
run 'ls -la /root/.ssh /home/*/.ssh'
run 'wc -c /etc/machine-id; cat /etc/machine-id'
run 'ls -la /var/lib/cloud /var/lib/cloud/instances /var/lib/cloud/data'
run 'ls -la /opt/dsiprouter | head -20'

sec 'PACKAGES (cloud-init must be "ii", not "rc")'
run "dpkg -l 2>/dev/null | grep -Ei 'cloud-init|openssh-server|network-manager|ifupdown|netplan|systemd |dnsmasq|resolvconf'"
run 'grep -iE "cloud-init|netplan|network-manager|ifupdown" /var/log/apt/history.log /var/log/dpkg.log | tail -60'
run 'apt-mark showhold; dpkg-query -W -f "cloud-init conflicts: \${Conflicts}\n" cloud-init'
run 'ls -la /lib/systemd/system/cloud-init* /usr/lib/systemd/system/cloud-* 2>&1'

sec 'ENABLED UNITS'
run 'systemctl --root=/ is-enabled NetworkManager systemd-networkd systemd-networkd-wait-online networking systemd-resolved dnsmasq dsip-init ssh ssh.socket cloud-init-local cloud-init-main cloud-init-network cloud-config cloud-final cloud-init'
run "systemctl --root=/ list-unit-files --no-pager | grep -Ei 'network|ssh|cloud|dsip|dnsmasq|resolv|wait-online'"
run 'ls -la /etc/systemd/system/*.wants/ | grep -Ei "network|ssh|cloud|dsip|dnsmasq|resolv"'
run 'for u in networking systemd-networkd NetworkManager; do echo "=== $u.service.d"; cat /etc/systemd/system/$u.service.d/* /etc/systemd/system/$u.service 2>&1; done'
run 'cat /etc/systemd/system/dsip-init.service'

sec 'NETWORK CONFIG ON DISK'
run 'ls -laR /etc/systemd/network /etc/network /etc/netplan /etc/NetworkManager /run/systemd/network /run/network'
run 'for f in /etc/systemd/network/* /etc/network/interfaces /etc/network/interfaces.d/* /etc/netplan/* /etc/default/networking; do echo "=== $f"; cat "$f"; done'
run 'cat /etc/NetworkManager/NetworkManager.conf /etc/NetworkManager/conf.d/*.conf'
run 'ls -la /etc/NetworkManager/system-connections'
run 'ls -la /opt/dsiprouter/dnsmasq/configs/*'
run 'ls -la /etc/resolv.conf; cat /etc/resolv.conf'
run 'cat /etc/hosts /etc/hostname'

sec 'CLOUD-INIT CONFIG'
run 'cat /etc/cloud/cloud.cfg.d/*.cfg'
run 'grep -nEi "ssh|users|default_user|disable_root|network" /etc/cloud/cloud.cfg'
run 'cat /var/lib/cloud/data/result.json /var/lib/cloud/data/status.json'

sec 'SSHD'
run 'ls -la /etc/ssh/ /etc/ssh/sshd_config.d/'
run 'cat /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*'
run 'mkdir -p /run/sshd; sshd -t'
run 'grep -v nologin /etc/passwd'

sec 'JOURNAL BOOT LIST (boot 0 = last boot, the failed one)'
run "ls -la /var/log/journal /var/log/journal/*"
run "$J --list-boots"

sec 'JOURNAL BOOT 0: ssh'
run "$J -b 0 -u ssh -u ssh.socket | tail -100"
sec 'JOURNAL BOOT 0: cloud-init'
run "$J -b 0 -u cloud-init-local -u cloud-init-main -u cloud-init-network -u cloud-config -u cloud-final -u cloud-init | tail -200"
sec 'JOURNAL BOOT 0: network'
run "$J -b 0 -u NetworkManager -u systemd-networkd -u systemd-networkd-wait-online -u systemd-resolved -u networking -u dnsmasq -u dsip-init | tail -200"
sec 'JOURNAL BOOT 0: warnings and above'
run "$J -b 0 -p warning | tail -200"
sec 'JOURNAL BOOT 0: failed units / dependency problems'
run "$J -b 0 | grep -Ei 'failed|dependency|ordering cycle|timed out|unreachable' | tail -100"

sec 'JOURNAL PREVIOUS BOOT (-1): ssh and network'
run "$J -b -1 -u ssh -u systemd-networkd -u NetworkManager -u networking -u cloud-init-local -u cloud-config -u cloud-final | tail -150"

sec 'CLOUD-INIT LOGS'
run 'tail -300 /var/log/cloud-init.log'
run 'tail -100 /var/log/cloud-init-output.log'
CHROOT_EOF

    log "done: $OUT ($(wc -l <"$OUT") lines)"
}

main "$@"
