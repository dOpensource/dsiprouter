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

    apt-get install -y dnsmasq

    if (( $? != 0 )); then
        printerr 'Failed installing new dns stack'
        return 1
    fi

    # make sure we unmask before configuring the service ourselves
    systemctl unmask dnsmasq.service

    # configure dnsmasq systemd service
    cp -f ${DSIP_PROJECT_DIR}/dnsmasq/systemd/dnsmasq-v1.service /lib/systemd/system/dnsmasq.service
    chmod 644 /lib/systemd/system/dnsmasq.service
    systemctl daemon-reload
    systemctl enable dnsmasq

    # backup the original resolv.conf
    [[ ! -e "${BACKUPS_DIR}/etc/resolv.conf" ]] && {
        mkdir -p ${BACKUPS_DIR}/etc/
        cp -df /etc/resolv.conf ${BACKUPS_DIR}/etc/resolv.conf
    }

    # make dnsmasq the DNS provider
    rm -f /etc/resolv.conf
    cp -f ${DSIP_PROJECT_DIR}/dnsmasq/configs/resolv.conf /etc/resolv.conf

    # we only need the dhcp dynamic dns servers feature of systemd-resolved, everything else is turned off
    mkdir -p /etc/systemd/resolved.conf.d/
    cp -f ${DSIP_PROJECT_DIR}/dnsmasq/configs/systemdresolved.conf /etc/systemd/resolved.conf.d/99-dsiprouter.conf

    # for some reason the defaults on systemd-networkd are not followed after changing the above
    # so we give the interfaces explicit rules to make sure DNS servers are resolved via DHCP on the ifaces
    # see systemd.network and systemd.networkd for more information
    mkdir -p /etc/systemd/network/
    cp -f ${DSIP_PROJECT_DIR}/dnsmasq/configs/systemd.network /etc/systemd/network/99-dsiprouter.network

    # restart systemd network services
    systemctl restart systemd-networkd &&
    systemctl restart systemd-resolved || {
        printerr 'failed loading new systemd network configurations..'
        printwarn 'reverting network changes and aborting dnsmasq install'
        cp -df ${BACKUPS_DIR}/etc/resolv.conf /etc/resolv.conf
        rm -f /etc/systemd/resolved.conf.d/99-dsiprouter.conf
        rm -f /etc/systemd/network/99-dsiprouter.network
        systemctl restart systemd-networkd
        systemctl restart systemd-resolved
        return 1
    }

    # tell dnsmasq to grab dns servers from systemd-resolved
    export DNSMASQ_RESOLV_FILE="/run/systemd/resolve/resolv.conf"
    envsubst <${DSIP_PROJECT_DIR}/dnsmasq/configs/dnsmasq_sh.conf >/etc/dnsmasq.conf

    return 0
}

function uninstall() {
    # stop and disable services
    systemctl disable dnsmasq
    systemctl stop dnsmasq

    # uninstall packages
    apt-get remove -y --purge dnsmasq

    # remove our systemd-resolved configurations
    rm -f /etc/systemd/resolved.conf.d/99-dsiprouter.conf

    # remove the systemd.network rules
    rm -f /etc/systemd/network/99-dsiprouter.network

    # restore original resolv.conf
    cp -df ${BACKUPS_DIR}/etc/resolv.conf /etc/resolv.conf

    # restart systemd.networkd with the original rules
    systemctl restart systemd-networkd

    # update resolv.conf / restart systemd-resolved with new configs
    systemctl restart systemd-resolved

    # cleanup backup files
    rm -f ${BACKUPS_DIR}/etc/resolv.conf

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
