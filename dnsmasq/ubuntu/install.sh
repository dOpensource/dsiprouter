#!/usr/bin/env bash

# Debug this script if in debug mode
(( $DEBUG == 1 )) && set -x

# Import dsip_lib utility / shared functions if not already
if [[ "$DSIP_LIB_IMPORTED" != "1" ]]; then
    . ${DSIP_PROJECT_DIR}/dsiprouter/dsip_lib.sh
fi

function install() {
    # remove previous dns stack
    apt-get remove -y libnss-resolve systemd-resolved

    if (( $? != 0 )); then
        printerr 'Failed removing old dns stack'
        return 1
    fi

    # mask the service before running package manager to avoid faulty startup errors
    systemctl mask dnsmasq.service

    apt-get install -y dnsmasq resolvconf

    if (( $? != 0 )); then
        printerr 'Failed installing new dns stack'
        return 1
    fi

    # make sure we unmask before configuring the service ourselves
    systemctl unmask dnsmasq.service

    # configure dnsmasq systemd service
    mkdir -p /etc/systemd/system/dnsmasq.service.d/
    cp -f ${DSIP_PROJECT_DIR}/dnsmasq/systemd/dnsmasq-v1.service /etc/systemd/system/dnsmasq.service.d/override.conf
    chmod 755 /etc/systemd/system/dnsmasq.service.d/
    chmod 644 /etc/systemd/system/dnsmasq.service.d/override.conf
    systemctl daemon-reload
    systemctl enable dnsmasq

    # tell network manager to use dnsmasq instead
    cp -f ${DSIP_PROJECT_DIR}/dnsmasq/configs/networkmanager/dsiprouter.conf /etc/NetworkManager/conf.d/99-dsiprouter.conf

    return 0
}

function uninstall() {
    # remove network manager config
    rm -f /etc/NetworkManager/conf.d/99-dsiprouter.conf

    # swap old resolvers in as static file so DNS still works while uninstalling
    mv -f /run/dnsmasq/resolv.conf /etc/resolv.conf

    # uninstall new dns stack
    apt-get remove -y --purge dnsmasq resolvconf

    # remove systemd service configs
    rm -rf /etc/systemd/system/dnsmasq.service.d/

    # reinstall old dns stack
    apt-get install -y libnss-resolve systemd-resolved

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
