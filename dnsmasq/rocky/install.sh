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

    # Configure dnsmasq systemd service
    mkdir -p /etc/systemd/system/dnsmasq.service.d/
    cp -f ${DSIP_PROJECT_DIR}/dnsmasq/systemd/dnsmasq-v2.service /etc/systemd/system/dnsmasq.service.d/override.conf
    chmod 755 /etc/systemd/system/dnsmasq.service.d/
    chmod 644 /etc/systemd/system/dnsmasq.service.d/override.conf
    systemctl daemon-reload
    systemctl enable dnsmasq

    return 0
}

function uninstall {
    # Stop and disable services
    systemctl disable dnsmasq
    systemctl stop dnsmasq

    # Uninstall packages
    yum remove -y dnsmasq

    # remove systemd service configs
    rm -rf /etc/systemd/system/dnsmasq.service.d/

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
