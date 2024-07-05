#!/bin/sh

mkdir -p /run/network/
rm -f /run/network/ifupdown.conf 2>/dev/null

# check whether nmcli reports that network manager is managing the interface
# ref: https://gitlab.freedesktop.org/NetworkManager/NetworkManager/-/blob/main/src/libnmc-base/nm-client-utils.c?ref_type=heads#L288
NM_IFACES=$(nmcli -t -m tabular device status | awk -F ':' '$3 !~ /unmanaged|[^ ]+ \(externally\)/ {print $1}')
# check whether networkctl reports that systemd-networkd is manaing the interface
# ref: https://github.com/systemd/systemd/blob/e603a438a7918a2fcc35d7683fd755d3837b7024/src/network/networkd-link.c#L2918
SN_IFACES=$(networkctl list --json=short | jq -r -e '.Interfaces[] | select(.AdministrativeState!="unmanaged").Name')
# blacklist those managed interfaces from being managed by ifupdown
EXCLUSIONS=''
for IFACE in $NM_IFACES $SN_IFACES; do
    EXCLUSIONS="$EXCLUSIONS $IFACE ${IFACE}:*"
done

[ -n "$EXCLUSIONS" ] && echo "EXCLUDE_INTERFACES='$EXCLUSIONS'" >/run/network/ifupdown.conf

exit 0