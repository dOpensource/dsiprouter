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
    cp -f ${DSIP_PROJECT_DIR}/dnsmasq/systemd/dnsmasq-v2.service /lib/systemd/system/dnsmasq.service
    chmod 644 /lib/systemd/system/dnsmasq.service
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
