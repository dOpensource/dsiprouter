#!/usr/bin/env bash

# Debug this script if in debug mode
(( $DEBUG == 1 )) && set -x

# Import dsip_lib utility / shared functions if not already
if [[ "$DSIP_LIB_IMPORTED" != "1" ]]; then
    . ${DSIP_PROJECT_DIR}/dsiprouter/dsip_lib.sh
fi

function install() {
    # mask the service before running package manager to avoid faulty startup errors
    systemctl mask dnsmasq.service

    yum install -y dnsmasq

    if (( $? != 0 )); then
        printerr 'Failed installing required packages'
        return 1
    fi

    # make sure we unmask before configuring the service ourselves
    systemctl unmask dnsmasq.service

    # configure dnsmasq systemd service
    cp -f ${DSIP_PROJECT_DIR}/dnsmasq/systemd/dnsmasq-v3.service /lib/systemd/system/dnsmasq.service
    chmod 644 /lib/systemd/system/dnsmasq.service
    systemctl daemon-reload
    systemctl enable dnsmasq

    # backup the original resolv.conf and dhclient scripts
    [[ ! -e "${BACKUPS_DIR}/etc/resolv.conf" ]] && {
        mkdir -p ${BACKUPS_DIR}/{etc/sysconfig/network-scripts/,usr/sbin/}
        cp -df /etc/resolv.conf ${BACKUPS_DIR}/etc/resolv.conf
        cp -dfr /etc/sysconfig/network-scripts/. ${BACKUPS_DIR}/etc/sysconfig/network-scripts/
        cp -f /usr/sbin/dhclient-script ${BACKUPS_DIR}/usr/sbin/
    }

    # make dnsmasq the DNS provider
    rm -f /etc/resolv.conf
    cp -f ${DSIP_PROJECT_DIR}/dnsmasq/configs/resolv.conf /etc/resolv.conf

    # make all the dhclient scripts use a different resolv.conf location
    sed -i 's%/etc/resolv\.conf%/var/lib/dhclient/resolv.conf%g' /usr/sbin/dhclient-script
    find /etc/sysconfig/network-scripts/ -type f -exec sed -i 's%/etc/resolv\.conf%/var/lib/dhclient/resolv.conf%g' {} +

    # make sure the dhclient resolv.conf is recreated in the new location
    dhclient -r && dhclient

    # tell dnsmasq to grab dynamic DNS servers from dhclient
    export DNSMASQ_RESOLV_FILE="/var/lib/dhclient/resolv.conf"
    envsubst <${DSIP_PROJECT_DIR}/dnsmasq/configs/dnsmasq_sh.conf >/etc/dnsmasq.conf

    return 0
}

function uninstall {
    # stop and disable services
    systemctl disable dnsmasq
    systemctl stop dnsmasq

    # uninstall packages
    yum remove -y dnsmasq

    # restore dhclient scripts
    cp -dfr ${BACKUPS_DIR}/etc/sysconfig/network-scripts/. /etc/sysconfig/network-scripts/
    cp -f ${BACKUPS_DIR}/usr/sbin/dhclient-script /usr/sbin/dhclient-script

    # restore original resolv.conf
    cp -df ${BACKUPS_DIR}/etc/resolv.conf /etc/resolv.conf

    # update resolv.conf if needed
    dhclient -r && dhclient

    # cleanup backup files
    rm -rf ${BACKUPS_DIR}/etc/sysconfig/network-scripts/
    rm -f ${BACKUPS_DIR}/{etc/resolv.conf,usr/sbin/dhclient-script}

    return 0
}

case "$1" in
    install)
        install && exit 0 || exit 1
        ;;
    uninstall)
        uninstall && exit 0 || exit 1
        ;;
    *)
        printerr "Usage: $0 [install | uninstall]"
        exit 1
        ;;
esac
