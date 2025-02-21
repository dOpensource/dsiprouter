#!/usr/bin/env bash
#
# dSIPRouter DNS Resolution - How it Works
#
# Many of the cluster features require a multiple IP addresses to be associated with a local hostname.
# To make these checks performant and not rely on external DNS, a local stub resolver supporting
# multiple IPs per host is required (dnsmasq). This is equivalent to having multiple A / AAAA records
# on an external DNS server. The difference here is that the entries are read locally from /etc/hosts.
# A hostname is first checked locally, and before trying to resolve via the external DNS servers.
#
# By default DNS resolution via other applications is bypassed. DNSMasq is therefore the primary DNS
# resolver for the entire system (even for glibc).
# Upstream DNS resolvers (external, other stub resolvers, etc..) are attempted only after the DNSMasq
# stub resolver checks local records from /etc/hosts.
#
# References:
# dnsmasq(8)        https://manpages.debian.org/stable/dnsmasq-base/dnsmasq.8.en.html
# resolv.conf(5)    https://man7.org/linux/man-pages/man5/resolv.conf.5.html
# hosts(5)          https://man7.org/linux/man-pages/man5/hosts.5.html
#
# dSIPRouter Network Configuration - How it Works
#
# To support a variety of deployment environments the network stack is strictly configured on install.
# The goal is to make builds as reproducible as possible in any environment, without concern for the
# OS provider's (downstream, VM image, etc..) chosen network stack.
# Therefore, to customize your network configuration, make sure your network configurations operate on
# the supported network applications outlined here.
#
# Here is a summary of how the installed network stack works on debian-based OS:
# 1. ignore cloud-init network configurations
# 2. try configuring the network via network-manager
# 3. try configuring the network via systemd-networkd
# 4. try configuring the network via ifupdown
#
# By default network-manager / systemd-networkd will try to assign IPs based on DHCP.
# By default ifupdown is left unaltered.
#
# References:
# cloud-init(1)             https://manpages.debian.org/stable/cloud-init/cloud-init.1.en.html
# systemd-networkd(8)       https://man7.org/linux/man-pages/man8/systemd-networkd.service.8.html
# networkd-dispatcher(8)    https://manpages.debian.org/stable/networkd-dispatcher/networkd-dispatcher.8.en.html
# interfaces(5)             https://manpages.debian.org/stable/ifupdown/interfaces.5.en.html
#
# TODO: Currently this is implemented with systemd service drop-ins but this is very hacky and does not allow
#       fine grain control over timing and service status / network availability checks throughout the startup
#       ordering chain.
#       The preferred method we will implement in the future, will be using network-manager to load the rest of
#       the possible network management services.
#       I.E. instead of trying network-manager then waiting for it to timeout and trying systemd-networkd, the
#       network manager would try each plugin (plugins=keyfile,networkd,ifupdown) in order, until one is successful.
#       The network manager project currently only supports keyfile.ifupdown above. networkd support needs implemented.
#       Other plugins can be used as an example for the new implementation:
#       https://github.com/NetworkManager/NetworkManager/tree/main/src/core/settings/plugins
#

# Debug this script if in debug mode
(( $DEBUG == 1 )) && set -x

# Import dsip_lib utility / shared functions if not already
if [[ "$DSIP_LIB_IMPORTED" != "1" ]]; then
    . ${DSIP_PROJECT_DIR}/dsiprouter/dsip_lib.sh
fi

function install() {
    # backup the configuration files we will replace
    [[ ! -e "${BACKUPS_DIR}/network/" ]] && {
        mkdir -p ${BACKUPS_DIR}/network/
        cp -df /etc/resolv.conf ${BACKUPS_DIR}/network/resolv.conf
        cp -df /etc/default/networking ${BACKUPS_DIR}/network/networking
    }

    # make sure the dns stack is installed (minimal images do not include these packages)
    # debian used resolvconf up to debian12 when they switch to systemd-resolved
    if (( $DISTRO_VER < 12 )); then
        apt-get purge -y systemd-resolved libnss-resolve
        apt-get install -y resolvconf ifupdown network-manager

        resolvconf -u
    else
        apt-get purge -y resolvconf
        apt-get install -y systemd-resolved libnss-resolve ifupdown network-manager

        # we only need the dhcp dynamic dns servers feature of systemd-resolved, everything else is turned off
        mkdir -p /etc/systemd/resolved.conf.d/
        cp -f ${DSIP_PROJECT_DIR}/dnsmasq/configs/systemdresolved/dsiprouter.conf /etc/systemd/resolved.conf.d/99-dsiprouter.conf

        systemctl restart systemd-resolved
    fi

    # we give the interfaces explicit rules to make sure DNS servers are resolved via DHCP on the interfaces
    # docker interfaces are managed by docker services so we also make sure systemd-networkd does not manage those
    # see systemd.network and systemd.networkd for more information
    mkdir -p /etc/systemd/network/
    cp -f ${DSIP_PROJECT_DIR}/dnsmasq/configs/systemdnetworkd/docker.network /etc/systemd/network/98-docker.network
    cp -f ${DSIP_PROJECT_DIR}/dnsmasq/configs/systemdnetworkd/dsiprouter.network /etc/systemd/network/99-dsiprouter.network

    # configure NetworkManager
    mkdir -p /etc/NetworkManager/conf.d/
    cp -f ${DSIP_PROJECT_DIR}/dnsmasq/configs/networkmanager/dsiprouter.conf /etc/NetworkManager/conf.d/99-dsiprouter.conf

    # systemd-networkd and networking service customizations
    mkdir -p /etc/systemd/system/systemd-networkd.service.d/
    cp -f ${DSIP_PROJECT_DIR}/dnsmasq/configs/systemdnetworkd/override.conf /etc/systemd/system/systemd-networkd.service.d/00-dsiprouter.conf
    cp -f ${DSIP_PROJECT_DIR}/dnsmasq/configs/systemdnetworkd/networkd-pre.sh /usr/lib/systemd/networkd-pre
    chmod +x /usr/lib/systemd/networkd-pre
    mkdir -p /etc/systemd/system/networking.service.d/
    cp -f ${DSIP_PROJECT_DIR}/dnsmasq/configs/ifupdown/override.conf /etc/systemd/system/networking.service.d/00-dsiprouter.conf
    cp -f ${DSIP_PROJECT_DIR}/dnsmasq/configs/ifupdown/networking-pre.sh /usr/lib/ifupdown/networking-pre
    chmod +x /usr/lib/ifupdown/networking-pre

    # adjusting the service timeouts "online"
    mkdir -p /etc/systemd/system/systemd-networkd-wait-online.service.d/
    cp -f ${DSIP_PROJECT_DIR}/dnsmasq/configs/systemdnetworkd/wait-override.conf /etc/systemd/system/systemd-networkd-wait-online.service.d/00-dsiprouter.conf
    mkdir -p /etc/systemd/system/NetworkManager-wait-online.service.d/
    cp -f ${DSIP_PROJECT_DIR}/dnsmasq/configs/networkmanager/wait-override.conf /etc/systemd/system/NetworkManager-wait-online.service.d/00-dsiprouter.conf
    cp -f ${DSIP_PROJECT_DIR}/dnsmasq/configs/ifupdown/default.conf /etc/default/networking

    systemctl daemon-reload
    systemctl enable NetworkManager
    systemctl enable systemd-networkd
    systemctl enable networking

    # restart network services. if we fail, revert and exit.
    # TODO: we can not ensure the network stack is properly reverted without tracking the original set of packages and reverting them as well
    systemctl restart NetworkManager &&
    systemctl restart systemd-networkd &&
    systemctl restart networking || {
        printerr 'failed loading updated network configurations..'
        printwarn 'reverting network changes and aborting dnsmasq install'
        cp -df ${BACKUPS_DIR}/etc/resolv.conf /etc/resolv.conf
        cp -df ${BACKUPS_DIR}/network/networking /etc/default/networking
        rm -f /etc/systemd/resolved.conf.d/99-dsiprouter.conf
        rm -f /etc/systemd/network/98-docker.network
        rm -f /etc/systemd/network/99-dsiprouter.network
        rm -f /etc/NetworkManager/conf.d/99-dsiprouter.conf
        rm -f /etc/systemd/system/systemd-networkd.service.d/00-dsiprouter.conf
        rm -f /etc/systemd/system/networking.service.d/00-dsiprouter.conf
        rm -f /etc/systemd/system/NetworkManager-wait-online.service.d/00-dsiprouter.conf
        rm -f /usr/lib/systemd/networkd-pre
        rm -f /usr/lib/ifupdown/networking-pre
        systemctl daemon-reload
        systemctl revert NetworkManager
        systemctl revert systemd-networkd
        systemctl revert networking
        systemctl restart NetworkManager || systemctl restart systemd-networkd || systemctl restart networking
        return 1
    }

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

    # make dnsmasq the DNS provider
    rm -f /etc/resolv.conf
    cp -f ${DSIP_PROJECT_DIR}/dnsmasq/configs/resolv.conf /etc/resolv.conf

    # update the dnsmasq settings
    if (( $DISTRO_VER < 12 )); then
        export DNSMASQ_RESOLV_FILE="/run/dnsmasq/resolv.conf"

        # setup resolvconf to work with dnsmasq
        cp -f ${DSIP_PROJECT_DIR}/dnsmasq/configs/resolvconf_def /etc/default/resolvconf &&
        rm -f /etc/resolvconf/update.d/dnsmasq &&
        cp -f ${DSIP_PROJECT_DIR}/dnsmasq/configs/resolvconf_upd /etc/resolvconf/update.d/dnsmasq &&
        chmod +x /etc/resolvconf/update.d/dnsmasq &&
        resolvconf -u || {
            printerr 'failed loading new resolvconf network configurations..'
        }
    else
        export DNSMASQ_RESOLV_FILE="/run/systemd/resolve/resolv.conf"
    fi

    # tell dnsmasq to grab dns servers found via dhcp
    envsubst <${DSIP_PROJECT_DIR}/dnsmasq/configs/dnsmasq_sh.conf >/etc/dnsmasq.conf

    return 0
}

function uninstall() {
    # stop and disable services
    systemctl disable dnsmasq
    systemctl stop dnsmasq

    # uninstall packages
    apt-get remove -y --purge dnsmasq

    # remove network manager config
    rm -f /etc/NetworkManager/conf.d/99-dsiprouter.conf

    # remove our systemd-resolved configurations
    rm -f /etc/systemd/resolved.conf.d/99-dsiprouter.conf

    # remove the systemd.network rules
    rm -f /etc/systemd/network/99-dsiprouter.network

    # restore original resolv.conf
    cp -df ${BACKUPS_DIR}/etc/resolv.conf /etc/resolv.conf

    # restart related services
    if (( $DISTRO_VER < 12 )); then
        resolvconf -u
    else
        systemctl restart systemd-networkd
        systemctl restart systemd-resolved
    fi
    if systemctl is-active -q NetworkManager &>/dev/null; then
        systemctl restart NetworkManager
    fi

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
