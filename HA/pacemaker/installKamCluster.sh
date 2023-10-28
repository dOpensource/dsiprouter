#!/usr/bin/env bash
#
# Summary:  corosync / pacemaker kamailio cluster config
#
# Notes:    more than 2 nodes may require fencing settings
#           you must be able to ssh to every node in the cluster from where script is run
#           supported ssh authentication methods: password, pubkey
#           supported DB configurations: central, active/active
##
# TODO:     support active/passive galera replication
#           https://mariadb.com/kb/en/changing-a-replica-to-become-the-primary/
#           better output to user when not in debug mode
#
### log file locations:
# /var/log/pcsd/pcsd.log
# /var/log/cluster/corosync.log
# /var/log/pcsd/pacemaker.log
# /var/log/nodeutil.log

# set project root, if in a git repo resolve top level dir
PROJECT_ROOT=${PROJECT_ROOT:-$(dirname $(dirname $(dirname $(readlink -f "$0"))))}
# import shared library functions
. ${PROJECT_ROOT}/HA/shared_lib.sh


# node configuration settings
PACEMAKER_TCP_PORTS=(2224 3121 5403 21064)
PACEMAKER_UDP_PORTS=(5404 5405)
CLUSTER_NAME="kamcluster"
CLUSTER_PASS="$(createPass)"
RESOURCE_STARTUP_TIMEOUT=30
CLUSTER_OPTIONS=(transport udpu link bindnetaddr=0.0.0.0 broadcast=1)
KAM_VIP=""
CIDR_NETMASK="32"
DSIP_PROJECT_DIR="/opt/dsiprouter"
DSIP_SYSTEM_CONFIG_DIR="/etc/dsiprouter"
STATIC_NETWORKING_MODE=1
RETRY_CLUSTER_START=3
RETRY_SHH_CONNECT=3 # TODO: implement this

# global variables used throughout script
SSH_KEY_FILE=""
NODE_NAMES=()
HOST_LIST=()
USERHOST_LIST=()
INT_IP_LIST=()
CLUSTER_NODE_ADDRS=()
declare -A CLOUD_DICT
CLOUD_PLATFORM=""
CLUSTER_RESOURCES=()
SSH_CMD_LIST=()
RSYNC_CMD_LIST=()
DEBUG=0


printUsage() {
    pprint "Usage: $0 [OPTIONAL OPTIONS] <REQUIRED OPTIONS> <REQUIRED ARGUMENTS>"
    pprint "OPTIONAL OPTIONS:"
    pprint "    -h|--help"
    pprint "    -debug"
    pprint "    -i <ssh key file>"
    pprint "    --do-token=<your token>"
    pprint "REQUIRED OPTIONS (one of):"
    pprint "    -vip <virtual ip>"
    pprint "    -net <subnet cidr>"
    pprint "REQUIRED ARGUMENTS:"
    pprint " <[sshuser1[:sshpass1]@]node1[:sshport1]> <[sshuser2[:sshpass2]@]node2[:sshport2]> ..."
}

# loop through args and evaluate any options
NODES=()
while (( $# > 0 )); do
    ARG="$1"
    case $ARG in
        -h|--help)
            printUsage
            exit 0
            ;;
        -debug)
            DEBUG=1
            shift
            ;;
        -vip)
            shift
            KAM_VIP="$1"
            shift
            ;;
        -net)
            shift
            KAM_VIP=$(findAvailableIP "$1")
            CIDR_NETMASK=$(cut -s -d '/' -f 2 <<<"$1")
            shift
            ;;
        -i)
            shift
            SSH_KEY_FILE="$1"
            shift
            ;;
        --do-token=*)
            DO_TOKEN=$(cut -s -d '=' -f 2 <<<"$1")
            shift
            ;;
        *)  # add to list of args
            NODES+=( "$ARG" )
            shift
            ;;
    esac
done

if (( $DEBUG == 1 )); then
    set -x
fi

# make sure required args are fulfilled
if [[ -z "${KAM_VIP}" ]] || [[ -z "${CIDR_NETMASK}" ]]; then
    printerr 'Kamailio virtual IP or CIDR netmask is required'
    printUsage
    exit 1
fi

if (( ${#NODES[@]} < 2 )); then
    printerr "At least 2 nodes are required to setup kam cluster"
    printUsage
    exit 1
fi

# install local requirements for script
# TODO: validate sudo exists, if not and user=root then install, otherwise fail
if ! cmdExists 'ssh' || ! cmdExists 'sshpass' || ! cmdExists 'nmap' || ! cmdExists 'sed' || ! cmdExists 'awk'; then
    printdbg 'Installing local requirements for cluster install'

    if cmdExists 'apt-get'; then
        sudo apt-get install -y openssh-client sshpass nmap sed gawk rsync
    elif cmdExists 'dnf'; then
        sudo dnf install -y openssh-clients sshpass nmap sed gawk rsync
    elif cmdExists 'yum'; then
        sudo yum install --enablerepo=epel -y openssh-clients sshpass nmap sed gawk rsync
    else
        printerr "Your local OS is not currently not supported"
        exit 1
    fi
fi

# sanity check
if (( $? != 0 )); then
    printerr 'Could not install requirements for cluster install'
    exit 1
fi

# $1 == cidr subnet
# returns: 0 == success, 1 == failure
# notes: prints first available ip in subnet
# notes: assumes .1 is used as default gw in net
findAvailableIP() {
    local NET_TAKEN_LIST=$(nmap -n -sP -T 5 "$1" -oG - | awk '/Up$/{print $2}')
    local NET_ADDR_LIST=$(nmap -n -sL "$1" | grep "Nmap scan report" | awk '{print $NF}' | tail -n +3 | sed '$ d')
    for IP in ${NET_ADDR_LIST[@]}; do
        for ip in ${NET_TAKEN_LIST[@]}; do
            if [[ "$IP" != "$ip" ]]; then
                printf '%s' "$IP"
                return 0
            fi
        done
    done
    return 1
}

# $1 == resource name
# returns: 0 == success, else == failure
# notes: prints node name where resource is found
findResource() {
    local RESOURCE_FIND_TIMEOUT=5
    local NODE

    timeout "$RESOURCE_FIND_TIMEOUT" bash <<EOF 2>/dev/null
while true; do
    NODE=\$(pcs status resources | awk '\$2=="'$1'" && \$4=="Started" {print \$5}')
    if [[ -n "\$NODE" ]]; then
        echo "\$NODE"
        break
    fi
    sleep 1
done
EOF
    return $?
}

# $1 == timeout
# returns: 0 == resources up within timeout, else == resources not up within timeout
# notes: block while waiting for resources to come online until timeout
waitResources() {
    timeout "$1" bash <<'EOF' 2>/dev/null
RESOURCES_DOWN=$(pcs status resources | grep -v -F 'Resource Group' | awk '$4!="Started" {print $2}' | wc -l)
while (( $RESOURCES_DOWN > 0 )); do
    sleep 1
    RESOURCES_DOWN=$(pcs status resources | grep -v -F 'Resource Group' | awk '$4!="Started" {print $2}' | wc -l)
done
EOF
    return $?
}

# notes: prints out detailed info about cluster
showClusterStatus() {
    corosync-cfgtool -s
    pcs status --full
}

setFirewallRules() {
    for PORT in ${PACEMAKER_TCP_PORTS[@]}; do
        firewall-cmd --zone=public --add-port=${PORT}/tcp --permanent
    done
    for PORT in ${PACEMAKER_UDP_PORTS[@]}; do
        firewall-cmd --zone=public --add-port=${PORT}/udp --permanent
    done
    firewall-cmd --reload
}

addDefRoute() {
    local IP="$1"

    local VIP_CIDR="${IP}/${CIDR_NETMASK:-32}"
    local ROUTE_INFO=$(ip route get 8.8.8.8 | head -1)
    local DEF_IF=$(printf '%s' "${ROUTE_INFO}" | grep -oP 'dev \K\w+')
    local VIP_ROUTE_INFO=$(printf '%s' "${ROUTE_INFO}" | sed -r "s|8.8.8.8|0.0.0.0/1|; s|dev [\w\d]+|dev ${DEF_IF}|; s|src [\w\d]+|src ${IP}|")

    ip address add $VIP_CIDR dev $DEF_IF
    ip route add $VIP_ROUTE_INFO
}

removeDefRoute() {
    local IP="$1"

    local ROUTE_INFO=$(ip route get 8.8.8.8 | head -1)
    local DEF_IF=$(printf '%s' "${ROUTE_INFO}" | grep -oP 'dev \K\w+')

    ip address del $VIP_CIDR dev $DEF_IF
    ip route del 0.0.0.0/1
}

# loop through args and gather variables
i=0
for NODE in ${NODES[@]}; do
    SSH_OPTS=(-o StrictHostKeyChecking=no -o CheckHostIp=no -o UserKnownHostsFile=/dev/null -o ServerAliveInterval=5 -o ServerAliveCountMax=2 -x)
    RSYNC_OPTS=()

    NODE_NAME="${CLUSTER_NAME}-node$((i+1))"
    NODE_NAMES+=( "$NODE_NAME" )

    USER=$(printf '%s' "$NODE" | cut -s -d '@' -f -1 | cut -d ':' -f -1)
    PASS=$(printf '%s' "$NODE" | cut -s -d '@' -f -1 | cut -s -d ':' -f 2-)
    HOST=$(printf '%s' "$NODE" | cut -d '@' -f 2- | cut -d ':' -f -1)
    PORT=$(printf '%s' "$NODE" | cut -d '@' -f 2- | cut -s -d ':' -f 2-)

    HOST_LIST+=( "$HOST" )

    # default user is root for ssh
    USER=${USER:-root}
    # default port is 22 for ssh
    PORT=${PORT:-22}

    # validate host connection
    if ! checkConn ${HOST} ${PORT}; then
        printerr "Could not establish connection to host [${HOST}] on port [${PORT}]"
        exit 1
    fi

    if [[ -z "$HOST" ]]; then
        printerr "Node [${NODE}] does not contain a host"
        printUsage
        exit 1
    fi
    USERHOST_LIST+=( "${USER}@${HOST}" )

    if [[ -n "$PASS" ]]; then
        export SSHPASS="${PASS}"
        SSH_CMD="sshpass -e ssh"
        RSYNC_CMD="sshpass -e rsync"
        SSH_OPTS+=(-o PreferredAuthentications=password)
    else
        SSH_CMD="ssh"
        RSYNC_CMD="rsync"
        if [[ -n "$SSH_KEY_FILE" ]]; then
            SSH_OPTS+=(-o PreferredAuthentications=publickey -i $SSH_KEY_FILE)
        else
            SSH_OPTS+=(-o PreferredAuthentications=publickey)
        fi
    fi

    RSYNC_OPTS+=(--port=${PORT} -z --exclude=".*")
    SSH_OPTS+=(-p ${PORT})

    printdbg 'validating unattended ssh connection'
    if ! checkSSH ${SSH_CMD} ${SSH_OPTS[@]} ${USERHOST_LIST[$i]}; then
        printerr "Could not establish unattended ssh connection to [${USERHOST_LIST[$i]}] on port [${PORT}]"
        exit 1
    fi

    # wrap up some args / options
    SSH_CMD_LIST+=( "${SSH_CMD} ${SSH_OPTS[*]}" )
    RSYNC_CMD_LIST+=( "${RSYNC_CMD} ${RSYNC_OPTS[*]}" )

    # install requirements for the next commands
    ${SSH_CMD_LIST[$i]} ${USERHOST_LIST[$i]} bash <<- EOSSH
        if (( $DEBUG == 1 )); then
            set -x
        fi

        # re-declare functions and vars we pass to remote server
        # note that variables in function definitions (from calling environement)
        # lose scope unless local to function, they must be passed to remote
        ESC_SEQ="\033["
        ANSI_NONE="\${ESC_SEQ}39;49;00m" # Reset colors
        ANSI_RED="\${ESC_SEQ}1;31m"
        ANSI_GREEN="\${ESC_SEQ}1;32m"
        $(typeset -f printdbg)
        $(typeset -f printerr)
        $(typeset -f cmdExists)

        printdbg 'installing requirements'
        # awk is required for getInternalIP()
        # curl is required for getCloudPlatform()
        # rsync is required to for the main script
        if cmdExists 'apt-get'; then
            export DEBIAN_FRONTEND=noninteractive
            apt-get install -y gawk curl rsync
        elif cmdExists 'dnf'; then
            dnf install -y gawk curl rsync
        elif cmdExists 'yum'; then
            yum install -y gawk curl rsync
        else
            printerr "OS on remote node [${HOST_LIST[$i]}] is currently not supported"
            exit 1
        fi

        if (( \$? != 0 )); then
            printerr "Failed to install requirements on remote node ${HOST_LIST[$i]}"
            exit 1
        fi
EOSSH

    # find the cloud platform the node is deployed on
    CLOUD_PLATFORM=$(${SSH_CMD_LIST[$i]} -q ${USERHOST_LIST[$i]} "$(typeset -f getCloudPlatform); getCloudPlatform;")
    CLOUD_DICT[$CLOUD_PLATFORM]=1

    # warn the user if we don't have an integration setup for this provider yet
    case "${CLOUD_LIST[$i]}" in
        AWS|GCE|AZURE|VULTR|OCE)
            printwarn 'support for virtual IP assignment on this cloud platform has not been tested'
            printwarn 'attempting install anyways'
            ;;
    esac

    # find the internal IP that the cluster will communicate over
    INT_IP_LIST+=($(${SSH_CMD_LIST[$i]} -q ${USERHOST_LIST[$i]} "$(typeset -f getInternalIP); getInternalIP;"))

    if [[ "$CLOUD_PLATFORM" == "DO" ]]; then
        CLUSTER_NODE_ADDRS+=($(${SSH_CMD_LIST[$i]} -q ${USERHOST_LIST[$i]} "curl -s http://169.254.169.254/metadata/v1/interfaces/private/0/ipv4/address;"))
    else
        CLUSTER_NODE_ADDRS+=( "${INT_IP_LIST[$i]}" )
    fi

    # find which resources we will be configuring
    if (( $i == 0 )); then
        if [[ "$CLOUD_PLATFORM" == "DO" ]]; then
            CLUSTER_RESOURCES+=(cluster_vip)
        else
            CLUSTER_RESOURCES+=(cluster_vip cluster_srcaddr)
        fi

        CLUSTER_RESOURCES+=($(${SSH_CMD_LIST[$i]} ${USERHOST_LIST[$i]} bash <<- EOSSH
            if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.rtpengineinstalled" ]]; then
                echo 'rtpengine_service'
            fi
            if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.kamailioinstalled" ]]; then
                echo 'kamailio_service'
            fi
            if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.dsiprouterinstalled" ]]; then
                echo 'dsiprouter_service'
            fi
EOSSH
        ))
    fi

    i=$((i+1))
done

# make sure user does not try to install on 2 different cloud platforms
if (( ${#CLOUD_DICT[@]} > 1 )); then
    printerr 'nodes are deployed on different cloud platforms'
    printerr 'installation on differing cloud platforms is not supported'
    exit 1
fi

# make sure the credentials for the cloud provider was provided by the user
if [[ "$CLOUD_PLATFORM" == "DO" ]] && [[ -z "$DO_TOKEN" ]]; then
    printerr '--do-token is required when deploying on digital ocean'
    exit 1
fi

# installs requirements and enables services
printdbg 'configuring servers for cluster deployment'
i=0
while (( $i < ${#NODES[@]} )); do
    # copy over any files needed for the install
    if [[ -n "$CLOUD_PLATFORM" ]]; then
        printdbg "Copying cloud configuration files to ${HOST_LIST[$i]}"
        ${RSYNC_CMD_LIST[$i]} --rsh="ssh ${SSH_OPTS[*]} -o IPQoS=throughput" -a ${PROJECT_ROOT}/HA/pacemaker/${CLOUD_PLATFORM}/ ${USERHOST_LIST[$i]}:/tmp/cloud/ 2>&1
        if (( $? != 0 )); then
            printerr "Copying files to ${HOST_LIST[$i]} failed"
            exit 1
        fi
    fi

    # run commands through ssh
    (${SSH_CMD_LIST[$i]} ${USERHOST_LIST[$i]} bash <<- EOSSH
        if (( $DEBUG == 1 )); then
            set -x
        fi

        # re-declare functions and vars we pass to remote server
        # note that variables in function definitions (from calling environement)
        # lose scope unless local to function, they must be passed to remote
        ESC_SEQ="\033["
        ANSI_NONE="\${ESC_SEQ}39;49;00m" # Reset colors
        ANSI_RED="\${ESC_SEQ}1;31m"
        ANSI_GREEN="\${ESC_SEQ}1;32m"
        PACEMAKER_TCP_PORTS=( ${PACEMAKER_TCP_PORTS[@]} )
        PACEMAKER_UDP_PORTS=( ${PACEMAKER_UDP_PORTS[@]} )
        NODE_NAMES=( ${NODE_NAMES[@]} )
        CLUSTER_NODE_ADDRS=( ${CLUSTER_NODE_ADDRS[@]} )
        $(typeset -f printdbg)
        $(typeset -f printerr)
        $(typeset -f cmdExists)
        $(typeset -f setFirewallRules)
        $(typeset -f addDefRoute)
        $(typeset -f removeDefRoute)
        $(typeset -f getConfigAttrib)
        $(typeset -f setConfigAttrib)
        $(typeset -f removeExecStartCmd)
        $(typeset -f addDependsOnService)
        $(typeset -f removeDependsOnService)

        printdbg 'installing requirements'
        if cmdExists 'apt-get'; then
            export DEBIAN_FRONTEND=noninteractive
            apt-get install -y corosync pacemaker pcs firewalld jq perl dnsutils sed
        elif cmdExists 'dnf'; then
            dnf install -y corosync pacemaker pcs firewalld jq perl bind-utils sed
        elif cmdExists 'yum'; then
            yum install -y corosync pacemaker pcs firewalld jq perl bind-utils sed
        else
            printerr "OS on remote node [${HOST_LIST[$i]}] is currently not supported"
            exit 1
        fi

        if (( \$? != 0 )); then
            printerr "Failed to install requirements on remote node ${HOST_LIST[$i]}"
            exit 1
        fi

        printdbg 'configuring server for cluster deployment'

        printdbg 'updating firewall rules'
        setFirewallRules

        printdbg 'setting up cluster password'
        echo "${CLUSTER_PASS}" | passwd -q --stdin hacluster 2>/dev/null ||
            echo "hacluster:${CLUSTER_PASS}" | chpasswd 2>/dev/null ||
            { printerr "could not change hacluster user password"; exit 1; }

        printdbg 'setting up cluster hostname resolution'

        # for each node remove the loopback hostname if present
        # this will cause issues when adding nodes to the cluster
        # ref: https://serverfault.com/questions/363095/why-does-my-hostname-appear-with-the-address-127-0-1-1-rather-than-127-0-0-1-in
        grep -v -E '^127\.0\.1\.1' /etc/hosts >/tmp/hosts &&
            mv -f /tmp/hosts /etc/hosts

        # hostnames are required even if not DNS resolvable (on each node)
        j=0
        while (( \$j < \${#CLUSTER_NODE_ADDRS[@]} )); do
            if ! grep -q -F "\${NODE_NAMES[\$j]}" /etc/hosts 2>/dev/null; then
                echo "\${CLUSTER_NODE_ADDRS[\$j]} \${NODE_NAMES[\$j]}" >>/etc/hosts
            fi
            j=\$((j+1))
        done

        printdbg 'configuring floating IP support on server'

        # enable binding to floating ip (on each node)
        echo '1' > /proc/sys/net/ipv4/ip_nonlocal_bind
        echo 'net.ipv4.ip_nonlocal_bind = 1' > /etc/sysctl.d/99-non-local-bind.conf

        # change kamcfg and rtpenginecfg to use floating ip (on each node)
        if [[ -e "${DSIP_SYSTEM_CONFIG_DIR}" ]]; then
            printdbg 'updating dsiprouter services'

            DSIP_INIT_PATH=\$(systemctl show -P FragmentPath dsip-init)

            if [[ "$CLOUD_PLATFORM" == "DO" ]]; then
                DSIP_VERSION=\$(getConfigAttrib 'VERSION' ${DSIP_SYSTEM_CONFIG_DIR}/gui/settings.py)
                DSIP_MAJ_VER=\$(perl -pe 's%([0-9]+)\..*%\1%' <<<"\$DSIP_VERSION")
                DSIP_MIN_VER=\$(perl -pe 's%[0-9]+\.([0-9]).*%\1%' <<<"\$DSIP_VERSION")
                DSIP_PATCH_VER=\$(perl -pe 's%[0-9]+\.[0-9]([0-9]).*%\1%' <<<"\$DSIP_VERSION")

                # v0.72 and above have static networking supported
                if (( \$DSIP_MAJ_VER > 0 )) || (( \$DSIP_MAJ_VER == 0 && \$DSIP_MIN_VER >= 7 )); then
                    setConfigAttrib 'NETWORK_MODE' "$STATIC_NETWORKING_MODE" ${DSIP_SYSTEM_CONFIG_DIR}/gui/settings.py
                else
                    removeExecStartCmd 'dsiprouter.sh updatertpconfig' \${DSIP_INIT_PATH}
                    removeExecStartCmd 'dsiprouter.sh updatekamconfig' \${DSIP_INIT_PATH}
                    removeExecStartCmd 'dsiprouter.sh updatedsipconfig' \${DSIP_INIT_PATH}
                fi

                setConfigAttrib 'EXTERNAL_IP_ADDR' '$KAM_VIP' ${DSIP_SYSTEM_CONFIG_DIR}/gui/settings.py
                NEW_EXT_FQDN=$(dig +short -x $KAM_VIP)
                if [[ -n "\$NEW_EXT_FQDN" ]]; then
                    setConfigAttrib 'EXTERNAL_FQDN' '\$NEW_EXT_FQDN' ${DSIP_SYSTEM_CONFIG_DIR}/gui/settings.py
                fi
                setConfigAttrib 'UAC_REG_ADDR' '$KAM_VIP' ${DSIP_SYSTEM_CONFIG_DIR}/gui/settings.py

                # update the settings in the various services
                if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.dsiprouterinstalled" ]]; then
                    dsiprouter updatedsipconfig
                fi
                if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.kamailioinstalled" ]]; then
                    dsiprouter updatekamconfig
                fi
                if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.rtpengineinstalled" ]]; then
                    dsiprouter updatertpconfig
                fi
            else
                # manually add default route to vip before updating settings
                addDefRoute "${KAM_VIP}"

                # TODO: enable kamailio to listen to both ip's (maybe??)
                if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.dsiprouterinstalled" ]]; then
                    dsiprouter updatedsipconfig
                fi
                if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.kamailioinstalled" ]]; then
                    dsiprouter updatekamconfig
                fi
                if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.rtpengineinstalled" ]]; then
                    dsiprouter updatertpconfig
                fi

                removeDefRoute "${KAM_VIP}"
            fi

            # systemd services will be managed by corosync/pacemaker instead of dsip-init
            if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.dsiprouterinstalled" ]]; then
                removeDependsOnService "dsiprouter.service" \${DSIP_INIT_PATH}
                systemctl stop dsiprouter
                systemctl disable dsiprouter
            fi
            if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.kamailioinstalled" ]]; then
                removeDependsOnService "kamailio.service" \${DSIP_INIT_PATH}
                systemctl stop kamailio
                systemctl disable kamailio
            fi
            if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.rtpengineinstalled" ]]; then
                removeDependsOnService "rtpengine.service" \${DSIP_INIT_PATH}
                systemctl stop rtpengine
                systemctl disable rtpengine
            fi

            addDependsOnService "corosync.service" \${DSIP_INIT_PATH}
            addDependsOnService "pacemaker.service" \${DSIP_INIT_PATH}
        fi

        printdbg 'configuring systemd services for pacemaker cluster'
        systemctl enable pcsd
        systemctl enable corosync
        systemctl enable pacemaker
        systemctl start pcsd

        printdbg 'removing any previous corosync configurations'
        PCS_MAJMIN_VER=\$(pcs --version | cut -d '.' -f -2 | tr -d '.')

        if (( \$((10#\$PCS_MAJMIN_VER)) >= 10 )); then
            pcs host deauth 2>/dev/null
            pcs cluster destroy 2>/dev/null
        else
            pcs pcsd clear-auth 2>/dev/null
            pcs cluster destroy 2>/dev/null
        fi

        exit 0
EOSSH
    ) 2>&1

    if (( $? != 0 )); then
        printerr "server configuration failed on ${HOST_LIST[$i]}" && exit 1
    fi

    i=$((i+1))
done

printdbg 'initializing pacemaker cluster'
i=0
while (( $i < ${#NODES[@]} )); do
    # run commands through ssh
    (${SSH_CMD_LIST[$i]} ${USERHOST_LIST[$i]} bash <<- EOSSH
        if (( $DEBUG == 1 )); then
            set -x
        fi

        # re-declare functions and vars we pass to remote server
        # note that variables in function definitions (from calling environement)
        # lose scope unless local to function, they must be passed to remote
        ESC_SEQ="\033["
        ANSI_NONE="\${ESC_SEQ}39;49;00m" # Reset colors
        ANSI_RED="\${ESC_SEQ}1;31m"
        ANSI_GREEN="\${ESC_SEQ}1;32m"
        $(typeset -f printdbg)
        $(typeset -f printerr)

        PCS_MAJMIN_VER=\$(pcs --version | cut -d '.' -f -2 | tr -d '.')

        if (( \$((10#\$PCS_MAJMIN_VER)) >= 10 )); then
            printdbg 'authenticating nodes to pcsd'
            pcs host auth -u hacluster -p ${CLUSTER_PASS} ${NODE_NAMES[@]} || {
                printerr "Cluster auth failed"
                exit 1
            }

            if (( $i == ${#NODES[@]} - 1 )); then
                printdbg 'creating the cluster'
                pcs cluster setup --force --enable ${CLUSTER_NAME} ${NODE_NAMES[@]} ${CLUSTER_OPTIONS[@]} || {
                    printerr "Cluster creation failed"
                    exit 1
                }
            fi
        else
            printdbg 'authenticating nodes to pcsd'
            pcs cluster auth --force -u hacluster -p ${CLUSTER_PASS} ${NODE_NAMES[@]} || {
                printerr "Cluster auth failed"
                exit 1
            }

            if (( $i == ${#NODES[@]} - 1 )); then
                printdbg 'creating the cluster'
                pcs cluster setup --force --enable --name ${CLUSTER_NAME} ${NODE_NAMES[@]} ${CLUSTER_OPTIONS[@]} || {
                    printerr "Cluster creation failed"
                    exit 1
                }
            fi
        fi

        # start cluster on the last node after all auth is completed
        if (( $i == ${#NODES[@]} - 1 )); then
            j=0
            while (( \$j < $RETRY_CLUSTER_START )); do
                pcs cluster start --all --request-timeout=15 --wait=15 &&
                    break
                j=\$((j+1))
            done
            # if we attempted all retries and finished the above loop we failed
            if (( \$j == $RETRY_CLUSTER_START )); then
                printerr "Starting cluster failed"
                exit 1
            fi
        fi

        # setup any cloud provider specific configuration files
        if [[ "$CLOUD_PLATFORM" == "DO" ]]; then
            cp -f /tmp/cloud/assign-ip /usr/local/bin/assign-ip
            chmod +x /usr/local/bin/assign-ip
            mkdir -p /usr/lib/ocf/resource.d/digitalocean
            cp -f /tmp/cloud/ocf-floatip /usr/lib/ocf/resource.d/digitalocean/floatip
            chmod +x /usr/lib/ocf/resource.d/digitalocean/floatip
        fi

        exit 0
EOSSH
    ) 2>&1

    if (( $? != 0 )); then
        printerr "initializing pacemaker cluster failed on ${HOST_LIST[$i]}" && exit 1
    fi

    i=$((i+1))
done

# creates and configures the cluster
# TODO: add support for updating virtual IP from various cloud providers
printdbg 'configuring pacemaker cluster'
i=0
while (( $i < ${#NODES[@]} )); do
    # run commands through ssh
    (${SSH_CMD_LIST[$i]} ${USERHOST_LIST[$i]} bash <<- EOSSH
        if (( $DEBUG == 1 )); then
            set -x
        fi

        # re-declare functions and vars we pass to remote server
        # note that variables in function definitions (from calling environement)
        # lose scope unless local to function, they must be passed to remote
        ESC_SEQ="\033["
        ANSI_NONE="\${ESC_SEQ}39;49;00m" # Reset colors
        ANSI_RED="\${ESC_SEQ}1;31m"
        ANSI_GREEN="\${ESC_SEQ}1;32m"
        $(typeset -f printdbg)
        $(typeset -f printerr)
        $(typeset -f findResource)
        $(typeset -f showClusterStatus)
        $(typeset -f waitResources)

        ## Pacemaker / Corosync cluster
        if (( $i == 0 )); then
            printdbg 'configuring pacemaker cluster'

            # disabling stonith/quorum for now because it has caused issues in the past (on first node)
            pcs property set stonith-enabled=false
            pcs property set no-quorum-policy=ignore

            printdbg 'Setting up the virtual ip address resource'
            # create resource for services and virtual ip and default route (on first node)
            if [[ "$CLOUD_PLATFORM" == "DO" ]]; then
                pcs resource create cluster_vip ocf:digitalocean:floatip \\
                    do_token=${DO_TOKEN} floating_ip=${KAM_VIP} \\
                    op monitor interval=15s timeout=15s \\
                    op start interval=0 timeout=30s \\
                    meta resource-stickiness=100 \\
                    --group vip_group
            else
                pcs resource create cluster_vip ocf:heartbeat:IPaddr2 \\
                    ip=${KAM_VIP} cidr_netmask=${CIDR_NETMASK} \\
                    op monitor interval=15s timeout=15s \\
                    op start interval=0 timeout=30s \\
                    meta resource-stickiness=100 \\
                    --group vip_group
                pcs resource create cluster_srcaddr ocf:heartbeat:IPsrcaddr \\
                    ipaddress=${KAM_VIP} cidr_netmask=${CIDR_NETMASK} \\
                    op monitor interval=15s timeout=15s \\
                    op start interval=0 timeout=30s \\
                    meta resource-stickiness=100 \\
                    --group vip_group
            fi

            printdbg 'Setting up resources for dsiprouter services'
            if grep -q 'rtpengine_service' 2>/dev/null <<<"${CLUSTER_RESOURCES[@]}"; then
                pcs resource create rtpengine_service systemd:rtpengine \\
                    op monitor interval=30s timeout=15s \\
                    op start interval=0 timeout=30s on-fail=restart \\
                    op stop interval=0 timeout=30s \\
                    meta resource-stickiness=100 \\
                    --group dsip_group
            fi
            if grep -q 'kamailio_service' 2>/dev/null <<<"${CLUSTER_RESOURCES[@]}"; then
                pcs resource create kamailio_service systemd:kamailio \\
                    op monitor interval=30s timeout=15s \\
                    op start interval=0 timeout=30s on-fail=restart \\
                    op stop interval=0 timeout=30s \\
                    meta resource-stickiness=100 \\
                    --group dsip_group
            fi
            if grep -q 'dsiprouter_service' 2>/dev/null <<<"${CLUSTER_RESOURCES[@]}"; then
                pcs resource create dsiprouter_service systemd:dsiprouter \\
                    op monitor interval=60s timeout=15s \\
                    op start interval=0 timeout=30s on-fail=restart \\
                    op stop interval=0 timeout=30s \\
                    meta resource-stickiness=100 \\
                    --group dsip_group
            fi

            printdbg 'colocating resources on the same node'
            pcs constraint colocation set vip_group dsip_group \\
                sequential=true \\
                setoptions score=INFINITY
            pcs constraint order set vip_group dsip_group \\
                action=start sequential=true require-all=true \\
                setoptions symmetrical=false kind=Mandatory
        fi

        if (( $i == ${#NODES[@]} - 1 )); then
            printdbg 'testing cluster'

            PCS_MAJMIN_VER=\$(pcs --version | cut -d '.' -f -2 | tr -d '.')

            RESOURCES=(${CLUSTER_RESOURCES[@]})
            CURRENT_RESOURCE_LOCATIONS=()
            PREVIOUS_RESOURCE_LOCATIONS=()

            # wait on resources to come online (original node)
            waitResources ${RESOURCE_STARTUP_TIMEOUT} || {
                printerr "Cluster resources failed to start within ${RESOURCE_STARTUP_TIMEOUT} seconds"
                exit 1
            }

            # grab operation data for tests (last node)
            # TODO: error checking for resources not yet started
            for RESOURCE in \${RESOURCES[@]}; do
                PREVIOUS_RESOURCE_LOCATIONS+=( \$(findResource \${RESOURCE}) )
            done

            printdbg "current resource locations: \${PREVIOUS_RESOURCE_LOCATIONS[@]}"
            printdbg "setting \${PREVIOUS_RESOURCE_LOCATIONS[0]} to standby"

            if (( \$((10#\$PCS_MAJMIN_VER)) >= 10 )); then
                pcs node standby \${PREVIOUS_RESOURCE_LOCATIONS[0]}
            else
                pcs cluster standby \${PREVIOUS_RESOURCE_LOCATIONS[0]}
            fi

            # wait for transfer to finish (to another node)
            waitResources ${RESOURCE_STARTUP_TIMEOUT} || {
                printerr "Cluster resources failed to start within ${RESOURCE_STARTUP_TIMEOUT} seconds"
                exit 1
            }

            for RESOURCE in \${RESOURCES[@]}; do
                CURRENT_RESOURCE_LOCATIONS+=( \$(findResource \${RESOURCE}) )
            done

            printdbg "current resource locations: \${CURRENT_RESOURCE_LOCATIONS[@]}"
            printdbg "resetting \${PREVIOUS_RESOURCE_LOCATIONS[0]}"

            if (( \$(pcs --version | cut -d '.' -f 2- | tr -d '.') >= 100 )); then
                pcs node unstandby \${PREVIOUS_RESOURCE_LOCATIONS[0]}
            else
                pcs cluster unstandby \${PREVIOUS_RESOURCE_LOCATIONS[0]}
            fi

            # wait for transfer to finish (to another node, could be original)
            waitResources ${RESOURCE_STARTUP_TIMEOUT} || {
                printerr "Cluster resources failed to start within ${RESOURCE_STARTUP_TIMEOUT} seconds"
                exit 1
            }

            # run tests to make sure operations worked (last node)
            i=0
            while (( \$i < \${#RESOURCES[@]} )); do
                if [[ \${PREVIOUS_RESOURCE_LOCATIONS[\$i]} != \${PREVIOUS_RESOURCE_LOCATIONS[\$((i+1))]:-\${PREVIOUS_RESOURCE_LOCATIONS[0]}} ]]; then
                    printerr "Cluster resource colocation tests failed (before migration)"
                    exit 1
                fi

                if [[ \${CURRENT_RESOURCE_LOCATIONS[\$i]} != \${CURRENT_RESOURCE_LOCATIONS[\$((i+1))]:-\${CURRENT_RESOURCE_LOCATIONS[0]}} ]]; then
                    printerr "Cluster resource colocation tests failed (after migration)"
                    exit 1
                fi

                if [[ \${PREVIOUS_RESOURCE_LOCATIONS[\$i]} == \${CURRENT_RESOURCE_LOCATIONS[\$i]} ]]; then
                    printerr "Cluster resource \${RESOURCE} failover tests failed"
                    exit 1
                fi

                i=\$((i+1))
            done

            printdbg 'Any non-critical resource errors are shown below:'
            pcs resource failcount show
            printdbg 'Clearing any non-critical resource errors'
            pcs resource cleanup vip_group
            pcs resource cleanup dsip_group

            # show status to user
            printdbg 'cluster info:'
            showClusterStatus
        fi

        exit 0
EOSSH
    ) 2>&1

    if (( $? != 0 )); then
        printerr "pacemaker cluster configuration failed on ${HOST_LIST[$i]}" && exit 1
    fi

    i=$((i+1))
done

printdbg 'Successfully configured pacemaker cluster'
exit 0