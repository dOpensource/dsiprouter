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

    if (( ${DISTRO_VER} >= 8 )); then
        dnf install -y dnsmasq
    else
        yum install -y dnsmasq
    fi

    if (( $? != 0 )); then
        printerr 'Failed installing required packages'
        return 1
    fi

    # make sure we unmask before configuring the service ourselves
    systemctl unmask dnsmasq.service

    # configure dnsmasq systemd service
    if (( ${DISTRO_VER} > 7 )); then
        cp -f ${DSIP_PROJECT_DIR}/dnsmasq/systemd/dnsmasq-v2.service /lib/systemd/system/dnsmasq.service
    else
        cp -f ${DSIP_PROJECT_DIR}/dnsmasq/systemd/dnsmasq-v3.service /lib/systemd/system/dnsmasq.service
    fi
    chmod 644 /lib/systemd/system/dnsmasq.service
    systemctl daemon-reload
    systemctl enable dnsmasq

    # backup the original resolv.conf
    [[ ! -e "${BACKUPS_DIR}/etc/resolv.conf" ]] && {
        mkdir -p ${BACKUPS_DIR}/etc/
        cp -df /etc/resolv.conf ${BACKUPS_DIR}/etc/resolv.conf
    }

    # make dnsmasq the DNS provider
    # centos uses a static resolv.conf by default, which dnsmasq will use for its upstream DNS servers
    [[ ! -e /etc/dnsmasq_resolv.conf ]] && {
        cp -df /etc/resolv.conf /etc/dnsmasq_resolv.conf
    }
    rm -f /etc/resolv.conf
    cp -f ${DSIP_PROJECT_DIR}/dnsmasq/configs/resolv.conf /etc/resolv.conf

    # tell NetworkManager we will manage the DNS servers
    mkdir -p /etc/NetworkManager/conf.d/
    cp -f ${DSIP_PROJECT_DIR}/dnsmasq/configs/networkmanager/dsiprouter.conf /etc/NetworkManager/conf.d/99-dsiprouter.conf

    # make sure the NetworkManager resolv.conf is recreated with the new configuration options
    systemctl restart NetworkManager

    # tell dnsmasq to grab dynamic DNS servers from dhclient
    export DNSMASQ_RESOLV_FILE="/etc/dnsmasq_resolv.conf"
    envsubst <${DSIP_PROJECT_DIR}/dnsmasq/configs/dnsmasq_sh.conf >/etc/dnsmasq.conf

    return 0
}

function uninstall {
    # stop and disable services
    systemctl disable dnsmasq
    systemctl stop dnsmasq

    # uninstall packages
    if (( ${DISTRO_VER} >= 8 )); then
        dnf remove -y dnsmasq
    else
        yum remove -y dnsmasq
    fi

    # remove our NetworkManager configurations
    rm -f /etc/NetworkManager/conf.d/99-dsiprouter.conf

    # restore original resolv.conf
    cp -df ${BACKUPS_DIR}/etc/resolv.conf /etc/resolv.conf

    # update resolv.conf / restart NetworkManager with new configs
    systemctl restart NetworkManager

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
