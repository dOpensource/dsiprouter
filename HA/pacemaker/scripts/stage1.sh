#!/bin/bash

# import runtime environment
if ! [[ -f "$1" ]] || ! source "$1"; then
   echo "Could not import runtime environment"
   exit 1
fi

if (( ${DEBUG:-0} == 1 )); then
    set -x
fi

addDefRoute() {
    local IP="$1"

    local VIP_CIDR="${IP}/${CIDR_NETMASK:-32}"
    local ROUTE_INFO=$(ip route get 8.8.8.8 | head -1)
    local DEF_IF=$(printf '%s' "${ROUTE_INFO}" | grep -oP 'dev \K\w+')
    local VIP_ROUTE_INFO=$(printf '%s' "${ROUTE_INFO}" | sed -r "s|8.8.8.8|0.0.0.0/1|; s|dev [\w\d]+|dev ${DEF_IF}|; s|src [\w\d]+|src ${IP}|")

    runas ip address add $VIP_CIDR dev $DEF_IF
    runas ip route add $VIP_ROUTE_INFO
}

removeDefRoute() {
    local IP="$1"

    local ROUTE_INFO=$(ip route get 8.8.8.8 | head -1)
    local DEF_IF=$(printf '%s' "${ROUTE_INFO}" | grep -oP 'dev \K\w+')

    runas ip address del $VIP_CIDR dev $DEF_IF
    runas ip route del 0.0.0.0/1
}

printdbg 'installing requirements'
if cmdExists 'apt-get'; then
    runas apt-get -o DPkg::Lock::Timeout=$PKG_MGR_TIMEOUT install -y corosync pacemaker pcs firewalld jq perl dnsutils sed unzip
elif cmdExists 'dnf'; then
    runas dnf install -y corosync pacemaker pcs firewalld jq perl bind-utils sed unzip
elif cmdExists 'yum'; then
    runas yum install -y corosync pacemaker pcs firewalld jq perl bind-utils sed unzip
else
    printerr "OS on remote node [${HOST_LIST[$i]}] is currently not supported"
    exit 1
fi

if (( $? != 0 )); then
    printerr "Failed to install requirements on remote node ${HOST_LIST[$i]}"
    exit 1
fi

printdbg 'configuring server for cluster deployment'

printdbg 'updating firewall rules'
for PORT in ${PACEMAKER_TCP_PORTS[@]}; do
    runas firewall-cmd --zone=public --add-port=${PORT}/tcp --permanent
done
for PORT in ${PACEMAKER_UDP_PORTS[@]}; do
    runas firewall-cmd --zone=public --add-port=${PORT}/udp --permanent
done
runas firewall-cmd --reload

printdbg 'setting up cluster password'
echo "${CLUSTER_PASS}" | runas passwd -q --stdin hacluster 2>/dev/null ||
    echo "hacluster:${CLUSTER_PASS}" | runas chpasswd 2>/dev/null ||
    { printerr "could not change hacluster user password"; exit 1; }

printdbg 'setting up cluster hostname resolution'

# for each node remove the loopback hostname if present
# this will cause issues when adding nodes to the cluster
# ref: https://serverfault.com/questions/363095/why-does-my-hostname-appear-with-the-address-127-0-1-1-rather-than-127-0-0-1-in
grep -v -E '^127\.0\.1\.1' /etc/hosts >/tmp/hosts &&
    runas mv -f /tmp/hosts /etc/hosts

# add section for the pacemaker hostnames
if ! grep -q 'PACEMAKER_CONFIG_START' /etc/hosts 2>/dev/null; then
    runas bash -c "(
        echo ''
        echo '#####PACEMAKER_CONFIG_START'
    )>>/etc/hosts"
    j=0
    while (( $j < ${#CLUSTER_NODE_ADDRS[@]} )); do
        runas bash -c "echo '${CLUSTER_NODE_ADDRS[$j]} ${NODE_NAMES[$j]}' >>/etc/hosts"
        j=$((j+1))
    done
    runas bash -c "echo '#####PACEMAKER_CONFIG_END' >>/etc/hosts"
else
    j=0; tmp='';
    while (( $j < ${#CLUSTER_NODE_ADDRS[@]} )); do
        tmp+="${CLUSTER_NODE_ADDRS[$j]} ${NODE_NAMES[$j]}\n"
        j=$((j+1))
    done
    runas perl -0777 -i -pe "s|(#+PACEMAKER_CONFIG_START).*?(#+PACEMAKER_CONFIG_END)|\1\n${tmp}\2|gms" /etc/hosts
fi

printdbg 'configuring floating IP support on server'

# enable binding to floating ip (on each node)
runas bash -c "echo '1' >/proc/sys/net/ipv4/ip_nonlocal_bind"
runas bash -c "echo 'net.ipv4.ip_nonlocal_bind = 1' >/etc/sysctl.d/99-non-local-bind.conf"

# change kamcfg and rtpenginecfg to use floating ip (on each node)
if [[ -e "${DSIP_SYSTEM_CONFIG_DIR}" ]]; then
    printdbg 'updating dsiprouter services'

    DSIP_INIT_PATH=$(systemctl show -P FragmentPath dsip-init)

    if [[ -n "$CLOUD_PLATFORM" ]]; then
        DSIP_VERSION=$(getConfigAttrib 'VERSION' ${DSIP_SYSTEM_CONFIG_DIR}/gui/settings.py)
        DSIP_MAJ_VER=$(perl -pe 's%([0-9]+)\..*%\1%' <<<"$DSIP_VERSION")
        DSIP_MIN_VER=$(perl -pe 's%[0-9]+\.([0-9]).*%\1%' <<<"$DSIP_VERSION")
        DSIP_PATCH_VER=$(perl -pe 's%[0-9]+\.[0-9]([0-9]).*%\1%' <<<"$DSIP_VERSION")

        # v0.72 and above have static networking supported
        if (( $DSIP_MAJ_VER > 0 )) || (( $DSIP_MAJ_VER == 0 && $DSIP_MIN_VER >= 7 )); then
            setConfigAttrib 'NETWORK_MODE' "$STATIC_NETWORKING_MODE" ${DSIP_SYSTEM_CONFIG_DIR}/gui/settings.py
        else
            removeExecStartCmd 'dsiprouter updatertpconfig' ${DSIP_INIT_PATH}
            removeExecStartCmd 'dsiprouter updatekamconfig' ${DSIP_INIT_PATH}
            removeExecStartCmd 'dsiprouter updatedsipconfig' ${DSIP_INIT_PATH}
        fi

        setConfigAttrib 'INTERNAL_IP_ADDR' '${CLUSTER_NODE_ADDRS[$i]}' ${DSIP_SYSTEM_CONFIG_DIR}/gui/settings.py
        setConfigAttrib 'EXTERNAL_IP_ADDR' '$KAM_VIP' ${DSIP_SYSTEM_CONFIG_DIR}/gui/settings.py
        NEW_EXT_FQDN=$(dig +short -x $KAM_VIP)
        if [[ -n "$NEW_EXT_FQDN" ]]; then
            setConfigAttrib 'EXTERNAL_FQDN' '$NEW_EXT_FQDN' ${DSIP_SYSTEM_CONFIG_DIR}/gui/settings.py
        fi
        setConfigAttrib 'UAC_REG_ADDR' '$KAM_VIP' ${DSIP_SYSTEM_CONFIG_DIR}/gui/settings.py

        # update the settings in the various services
        if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.dsiprouterinstalled" ]]; then
            runas dsiprouter updatedsipconfig
        fi
        if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.kamailioinstalled" ]]; then
            runas dsiprouter updatekamconfig
        fi
        if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.rtpengineinstalled" ]]; then
            runas dsiprouter updatertpconfig
        fi
    else
        # manually add default route to vip before updating settings
        addDefRoute "${KAM_VIP}"

        # TODO: enable kamailio to listen to both ip's (maybe??)
        if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.dsiprouterinstalled" ]]; then
            runas dsiprouter updatedsipconfig
        fi
        if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.kamailioinstalled" ]]; then
            runas dsiprouter updatekamconfig
        fi
        if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.rtpengineinstalled" ]]; then
            runas dsiprouter updatertpconfig
        fi

        removeDefRoute "${KAM_VIP}"
    fi

    # systemd services will be managed by corosync/pacemaker instead of dsip-init
    if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.dsiprouterinstalled" ]]; then
        removeDependsOnService "dsiprouter.service" ${DSIP_INIT_PATH}
        runas systemctl stop dsiprouter
        runas systemctl disable dsiprouter
    fi
    if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.kamailioinstalled" ]]; then
        removeDependsOnService "kamailio.service" ${DSIP_INIT_PATH}
        runas systemctl stop kamailio
        runas systemctl disable kamailio
    fi
    if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.rtpengineinstalled" ]]; then
        removeDependsOnService "rtpengine.service" ${DSIP_INIT_PATH}
        runas systemctl stop rtpengine
        runas systemctl disable rtpengine
    fi

    addDependsOnService "corosync.service" ${DSIP_INIT_PATH}
    addDependsOnService "pacemaker.service" ${DSIP_INIT_PATH}
fi

printdbg 'configuring systemd services for pacemaker cluster'
runas systemctl enable pcsd
runas systemctl enable corosync
runas systemctl enable pacemaker
runas systemctl start pcsd

printdbg 'removing any previous corosync configurations'
PCS_MAJMIN_VER=$(pcs --version | cut -d '.' -f -2 | tr -d '.')

if (( $((10#$PCS_MAJMIN_VER)) >= 10 )); then
    runas pcs host deauth 2>/dev/null
    runas pcs cluster destroy --force 2>/dev/null
else
    runas pcs pcsd clear-auth 2>/dev/null
    runas pcs cluster destroy --force 2>/dev/null
fi

exit 0