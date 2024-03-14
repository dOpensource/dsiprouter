#!/usr/bin/env bash
#
# Summary:  corosync / pacemaker kamailio cluster config
#
# Notes:    more than 2 nodes may require fencing settings
#           you must be able to ssh to every node in the cluster from where script is run
#           supported ssh authentication methods: password, pubkey
#           supported DB configurations: central, active/active
#           a secondary private IP address on a dedicated subnet is the preferred method
#           for communication between the pacemaker nodes
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
RETRY_SSH_CONNECT=3 # TODO: implement this
PKG_MGR_TIMEOUT=300

# global variables used throughout script
SSH_KEY_FILE=""
NODE_NAMES=()
HOST_LIST=()
USERHOST_LIST=()
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
    pprint "    --aws-access-key=<your key>"
    pprint "    --aws-secret-key=<your key>"
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
        --aws-access-key=*)
            AWS_ACCESS_KEY=$(cut -s -d '=' -f 2 <<<"$1")
            shift
            ;;
        --aws-secret-key=*)
            AWS_SECRET_TOKEN=$(cut -s -d '=' -f 2 <<<"$1")
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
    local NET_TAKEN_LIST=$(sudo nmap -n -sP -T 5 "$1" -oG - | awk '/Up$/{print $2}')
    local NET_ADDR_LIST=$(sudo nmap -n -sL "$1" | grep "Nmap scan report" | awk '{print $NF}' | tail -n +3 | sed '$ d')
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
    NODE=\$(sudo -u hacluster -n pcs status resources | awk '\$2=="'$1'" && \$4=="Started" {print \$5}')
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
RESOURCES_DOWN=$(sudo -u hacluster -n pcs status resources | grep -v -F 'Resource Group' | awk '$4!="Started" {print $2}' | wc -l)
while (( $RESOURCES_DOWN > 0 )); do
    sleep 1
    RESOURCES_DOWN=$(sudo -u hacluster -n pcs status resources | grep -v -F 'Resource Group' | awk '$4!="Started" {print $2}' | wc -l)
done
EOF
    return $?
}

# notes: prints out detailed info about cluster
showClusterStatus() {
    sudo -u hacluster -n corosync-cfgtool -s
    sudo -u hacluster -n pcs status --full
}

setFirewallRules() {
    for PORT in ${PACEMAKER_TCP_PORTS[@]}; do
        sudo -n firewall-cmd --zone=public --add-port=${PORT}/tcp --permanent
    done
    for PORT in ${PACEMAKER_UDP_PORTS[@]}; do
        sudo -n firewall-cmd --zone=public --add-port=${PORT}/udp --permanent
    done
    sudo -n firewall-cmd --reload
}

addDefRoute() {
    local IP="$1"

    local VIP_CIDR="${IP}/${CIDR_NETMASK:-32}"
    local ROUTE_INFO=$(ip route get 8.8.8.8 | head -1)
    local DEF_IF=$(printf '%s' "${ROUTE_INFO}" | grep -oP 'dev \K\w+')
    local VIP_ROUTE_INFO=$(printf '%s' "${ROUTE_INFO}" | sed -r "s|8.8.8.8|0.0.0.0/1|; s|dev [\w\d]+|dev ${DEF_IF}|; s|src [\w\d]+|src ${IP}|")

    sudo -n ip address add $VIP_CIDR dev $DEF_IF
    sudo -n ip route add $VIP_ROUTE_INFO
}

removeDefRoute() {
    local IP="$1"

    local ROUTE_INFO=$(ip route get 8.8.8.8 | head -1)
    local DEF_IF=$(printf '%s' "${ROUTE_INFO}" | grep -oP 'dev \K\w+')

    sudo -n ip address del $VIP_CIDR dev $DEF_IF
    sudo -n ip route del 0.0.0.0/1
}

# find the first private IP address (reverse order) on a physical interface
# this is typically the secondary interface or secondary IP on the primary interface
# sourced here to allow easier declaration on remote node
source <(
    cat <<EOF
    getPacemakerInternalIP() {
        $(declare -f getPhysicalIfaces)
        $(declare -f ipv4TestRFC1918)
EOF
    cat <<'EOF'
        for IP in $(
            for IFACE in $(getPhysicalIfaces | sort -r); do
                ip -4 -o addr show $IFACE | awk '{split($4,a,"/"); print a[1];}'
            done
        ); do
            if ipv4TestRFC1918 "$IP"; then
                echo "$IP"
                return 0
            fi
        done
        return 1
    }
EOF
)

# get the current region via the metadata api
awsGetCurrentRegion() {
    RET=$(curl -s -o /dev/null -w '%{http_code}' http://169.254.169.254/latest/meta-data/ami-id 2>/dev/null)
    if (( $RET == 200 )); then
        curl -s -f http://169.254.169.254/latest/meta-data/placement/region 2>/dev/null
    elif (( $RET == 401 )); then
        TOKEN=$(curl -s -X PUT --connect-timeout 2 -H 'X-aws-ec2-metadata-token-ttl-seconds: 60' http://169.254.169.254/latest/api/token 2>/dev/null)
        curl -s -f --connect-timeout 2 -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/region 2>/dev/null
    else
        return 1
    fi
    return 0
}

# loop through args and gather variables
i=0
for NODE in ${NODES[@]}; do
    SSH_OPTS=(-o StrictHostKeyChecking=no -o CheckHostIp=no -o UserKnownHostsFile=/dev/null -o ServerAliveInterval=5 -o ServerAliveCountMax=2 -x -T)
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
    if ! checkSsh ${SSH_CMD} ${SSH_OPTS[@]} ${USERHOST_LIST[$i]}; then
        printerr "Could not establish unattended ssh connection to [${USERHOST_LIST[$i]}] on port [${PORT}]"
        exit 1
    fi
    if ! checkSshSudo ${SSH_CMD} ${SSH_OPTS[@]} ${USERHOST_LIST[$i]}; then
        printerr "User [${USERHOST_LIST[$i]}] does not have sufficient privileges (add them to sudoers)"
        exit 1
    fi

    # wrap up some args / options
    SSH_CMD_LIST+=( "${SSH_CMD} ${SSH_OPTS[*]}" )
    RSYNC_CMD_LIST+=( "${RSYNC_CMD} ${RSYNC_OPTS[*]}" )

    # install requirements for the next commands
    ${SSH_CMD_LIST[$i]} ${USERHOST_LIST[$i]} bash -l <<- EOSSH
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
            sudo -n apt-get -o DPkg::Lock::Timeout=$PKG_MGR_TIMEOUT install -y gawk curl rsync
        elif cmdExists 'dnf'; then
            sudo -n dnf install -y gawk curl rsync
        elif cmdExists 'yum'; then
            sudo -n yum install -y gawk curl rsync
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
        GCE|AZURE|VULTR|OCE)
            printwarn 'support for virtual IP assignment on this cloud platform has not been tested'
            printwarn 'attempting install anyways'
            ;;
    esac

    # find the internal IP that the cluster will communicate over
    # this secondary interface is where the node will attach the floating IP
    CLUSTER_NODE_ADDRS+=( $(${SSH_CMD_LIST[$i]} -q ${USERHOST_LIST[$i]} "$(typeset -f getPacemakerInternalIP); getPacemakerInternalIP;") )

    # find which resources we will be configuring
    if (( $i == 0 )); then
        case "$CLOUD_PLATFORM" in
            DO|AWS)
                CLUSTER_RESOURCES+=(cluster_vip)
                ;;
            *)
                CLUSTER_RESOURCES+=(cluster_vip cluster_srcaddr)
                ;;
        esac

        CLUSTER_RESOURCES+=($(${SSH_CMD_LIST[$i]} ${USERHOST_LIST[$i]} bash -l <<- EOSSH
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
elif [[ "$CLOUD_PLATFORM" == "AWS" ]] && [[ -z "$AWS_ACCESS_KEY" || -z "$AWS_SECRET_TOKEN" ]]; then
    printerr '--aws-access-key and --aws-secret-key are required when deploying on amazon web services'
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
    (${SSH_CMD_LIST[$i]} ${USERHOST_LIST[$i]} bash -l <<- EOSSH
        if (( $DEBUG == 1 )); then
            set -x
        fi

        # re-declare functions and vars we pass to remote server
        # note that variables in function definitions (from calling environment)
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
            sudo -n apt-get  -o DPkg::Lock::Timeout=$PKG_MGR_TIMEOUT install -y corosync pacemaker pcs firewalld jq perl dnsutils sed unzip
        elif cmdExists 'dnf'; then
            sudo -n dnf install -y corosync pacemaker pcs firewalld jq perl bind-utils sed unzip
        elif cmdExists 'yum'; then
            sudo -n yum install -y corosync pacemaker pcs firewalld jq perl bind-utils sed unzip
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
        echo "${CLUSTER_PASS}" | sudo -n passwd -q --stdin hacluster 2>/dev/null ||
            echo "hacluster:${CLUSTER_PASS}" | sudo -n chpasswd 2>/dev/null ||
            { printerr "could not change hacluster user password"; exit 1; }

        printdbg 'setting up cluster hostname resolution'

        # for each node remove the loopback hostname if present
        # this will cause issues when adding nodes to the cluster
        # ref: https://serverfault.com/questions/363095/why-does-my-hostname-appear-with-the-address-127-0-1-1-rather-than-127-0-0-1-in
        grep -v -E '^127\.0\.1\.1' /etc/hosts >/tmp/hosts &&
            sudo -n mv -f /tmp/hosts /etc/hosts

        # add section for the pacemaker hostnames
        if ! grep -q 'PACEMAKER_CONFIG_START' /etc/hosts 2>/dev/null; then
            sudo -n bash -c "(
                echo ''
                echo '#####PACEMAKER_CONFIG_START'
            )>>/etc/hosts"
            j=0
            while (( \$j < \${#CLUSTER_NODE_ADDRS[@]} )); do
                sudo -n bash -c "echo '\${CLUSTER_NODE_ADDRS[\$j]} \${NODE_NAMES[\$j]}' >>/etc/hosts"
                j=\$((j+1))
            done
            sudo -n bash -c "echo '#####PACEMAKER_CONFIG_END' >>/etc/hosts"
        else
            j=0; tmp='';
            while (( \$j < \${#CLUSTER_NODE_ADDRS[@]} )); do
                tmp+="\${CLUSTER_NODE_ADDRS[\$j]} \${NODE_NAMES[\$j]}\\n"
                j=\$((j+1))
            done
            sudo -n perl -0777 -i -pe "s|(#+PACEMAKER_CONFIG_START).*?(#+PACEMAKER_CONFIG_END)|\\1\\n\${tmp}\\2|gms" /etc/hosts
        fi

        printdbg 'configuring floating IP support on server'

        # enable binding to floating ip (on each node)
        sudo -n bash -c "echo '1' >/proc/sys/net/ipv4/ip_nonlocal_bind"
        sudo -n bash -c "echo 'net.ipv4.ip_nonlocal_bind = 1' >/etc/sysctl.d/99-non-local-bind.conf"

        # change kamcfg and rtpenginecfg to use floating ip (on each node)
        if [[ -e "${DSIP_SYSTEM_CONFIG_DIR}" ]]; then
            printdbg 'updating dsiprouter services'

            DSIP_INIT_PATH=\$(systemctl show -P FragmentPath dsip-init)

            if [[ -n "$CLOUD_PLATFORM" ]]; then
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

                setConfigAttrib 'INTERNAL_IP_ADDR' '${CLUSTER_NODE_ADDRS[$i]}' ${DSIP_SYSTEM_CONFIG_DIR}/gui/settings.py
                setConfigAttrib 'EXTERNAL_IP_ADDR' '$KAM_VIP' ${DSIP_SYSTEM_CONFIG_DIR}/gui/settings.py
                NEW_EXT_FQDN=$(dig +short -x $KAM_VIP)
                if [[ -n "\$NEW_EXT_FQDN" ]]; then
                    setConfigAttrib 'EXTERNAL_FQDN' '\$NEW_EXT_FQDN' ${DSIP_SYSTEM_CONFIG_DIR}/gui/settings.py
                fi
                setConfigAttrib 'UAC_REG_ADDR' '$KAM_VIP' ${DSIP_SYSTEM_CONFIG_DIR}/gui/settings.py

                # update the settings in the various services
                if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.dsiprouterinstalled" ]]; then
                    sudo -n dsiprouter updatedsipconfig
                fi
                if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.kamailioinstalled" ]]; then
                    sudo -n dsiprouter updatekamconfig
                fi
                if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.rtpengineinstalled" ]]; then
                    sudo -n dsiprouter updatertpconfig
                fi
            else
                # manually add default route to vip before updating settings
                addDefRoute "${KAM_VIP}"

                # TODO: enable kamailio to listen to both ip's (maybe??)
                if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.dsiprouterinstalled" ]]; then
                    sudo -n dsiprouter updatedsipconfig
                fi
                if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.kamailioinstalled" ]]; then
                    sudo -n dsiprouter updatekamconfig
                fi
                if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.rtpengineinstalled" ]]; then
                    sudo -n dsiprouter updatertpconfig
                fi

                removeDefRoute "${KAM_VIP}"
            fi

            # systemd services will be managed by corosync/pacemaker instead of dsip-init
            if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.dsiprouterinstalled" ]]; then
                removeDependsOnService "dsiprouter.service" \${DSIP_INIT_PATH}
                sudo -n systemctl stop dsiprouter
                sudo -n systemctl disable dsiprouter
            fi
            if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.kamailioinstalled" ]]; then
                removeDependsOnService "kamailio.service" \${DSIP_INIT_PATH}
                sudo -n systemctl stop kamailio
                sudo -n systemctl disable kamailio
            fi
            if [[ -f "${DSIP_SYSTEM_CONFIG_DIR}/.rtpengineinstalled" ]]; then
                removeDependsOnService "rtpengine.service" \${DSIP_INIT_PATH}
                sudo -n systemctl stop rtpengine
                sudo -n systemctl disable rtpengine
            fi

            addDependsOnService "corosync.service" \${DSIP_INIT_PATH}
            addDependsOnService "pacemaker.service" \${DSIP_INIT_PATH}
        fi

        printdbg 'configuring systemd services for pacemaker cluster'
        sudo -n systemctl enable pcsd
        sudo -n systemctl enable corosync
        sudo -n systemctl enable pacemaker
        sudo -n systemctl start pcsd

        printdbg 'removing any previous corosync configurations'
        PCS_MAJMIN_VER=\$(pcs --version | cut -d '.' -f -2 | tr -d '.')

        if (( \$((10#\$PCS_MAJMIN_VER)) >= 10 )); then
            sudo -n pcs host deauth 2>/dev/null
            sudo -n pcs cluster destroy 2>/dev/null
        else
            sudo -n pcs pcsd clear-auth 2>/dev/null
            sudo -n pcs cluster destroy 2>/dev/null
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
    (${SSH_CMD_LIST[$i]} ${USERHOST_LIST[$i]} bash -l <<- EOSSH
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
        $(typeset -f awsGetCurrentRegion)

        PCS_MAJMIN_VER=\$(pcs --version | cut -d '.' -f -2 | tr -d '.')

        printdbg 'authenticating hacluster user to pcsd'
        sudo -u hacluster -n pcs client local-auth -u hacluster -p ${CLUSTER_PASS}

        if (( \$((10#\$PCS_MAJMIN_VER)) >= 10 )); then
            printdbg 'authenticating nodes to pcsd'
            sudo -n pcs host auth -u hacluster -p ${CLUSTER_PASS} ${NODE_NAMES[@]} || {
                printerr "Cluster auth failed"
                exit 1
            }

            if (( $i == ${#NODES[@]} - 1 )); then
                printdbg 'creating the cluster'
                sudo -n pcs cluster setup --force --enable ${CLUSTER_NAME} ${NODE_NAMES[@]} ${CLUSTER_OPTIONS[@]} || {
                    printerr "Cluster creation failed"
                    exit 1
                }
            fi
        else
            printdbg 'authenticating nodes to pcsd'
            sudo -n pcs cluster auth --force -u hacluster -p ${CLUSTER_PASS} ${NODE_NAMES[@]} || {
                printerr "Cluster auth failed"
                exit 1
            }

            if (( $i == ${#NODES[@]} - 1 )); then
                printdbg 'creating the cluster'
                sudo -n pcs cluster setup --force --enable --name ${CLUSTER_NAME} ${NODE_NAMES[@]} ${CLUSTER_OPTIONS[@]} || {
                    printerr "Cluster creation failed"
                    exit 1
                }
            fi
        fi

        # start cluster on the last node after all auth is completed
        if (( $i == ${#NODES[@]} - 1 )); then
            j=0
            while (( \$j < $RETRY_CLUSTER_START )); do
                sudo -n pcs cluster start --all --request-timeout=15 --wait=15 &&
                    break
                j=\$((j+1))
            done
            # if we attempted all retries and finished the above loop we failed
            if (( \$j == $RETRY_CLUSTER_START )); then
                printerr "Starting cluster failed"
                exit 1
            fi
        fi

        # setup any cloud provider specific configurations
        case "$CLOUD_PLATFORM" in
            DO)
                sudo -n cp -f /tmp/cloud/assign-ip /usr/local/bin/assign-ip
                sudo -n chmod +x /usr/local/bin/assign-ip
                sudo -n mkdir -p /usr/lib/ocf/resource.d/digitalocean
                sudo -n cp -f /tmp/cloud/ocf-floatip /usr/lib/ocf/resource.d/digitalocean/floatip
                sudo -n chmod +x /usr/lib/ocf/resource.d/digitalocean/floatip
                ;;
            AWS)
                if ! cmdExists 'aws'; then
                    cd /tmp &&
                    curl 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' -o awscli.zip &&
                    unzip -qo awscli.zip &&
                    rm -f awscli.zip &&
                    sudo -n ./aws/install -b /usr/bin
                fi

                AWS_REGION=\$(awsGetCurrentRegion) || {
                    printerr "Could not determine current AWS region"
                    exit 1
                }
                sudo -n aws configure set aws_access_key_id $AWS_ACCESS_KEY
                sudo -n aws configure set aws_secret_access_key $AWS_SECRET_TOKEN
                sudo -n aws configure set region \$AWS_REGION

                sudo -n mkdir -p /usr/lib/ocf/resource.d/aws
                sudo -n cp -f /tmp/cloud/ocf-floatip /usr/lib/ocf/resource.d/aws/floatip
                sudo -n chmod +x /usr/lib/ocf/resource.d/aws/floatip
                ;;
        esac

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
    (${SSH_CMD_LIST[$i]} ${USERHOST_LIST[$i]} bash -l <<- EOSSH
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
            sudo -n pcs property set stonith-enabled=false
            sudo -n pcs property set no-quorum-policy=ignore

            printdbg 'Setting up the virtual ip address resource'
            # create resource for services and virtual ip and default route (on first node)
            case "$CLOUD_PLATFORM" in
                DO)
                    sudo -n pcs resource create cluster_vip ocf:digitalocean:floatip \\
                        do_token=${DO_TOKEN} floating_ip=${KAM_VIP} \\
                        op monitor interval=15s timeout=15s \\
                        op start interval=0 timeout=30s \\
                        meta resource-stickiness=100 \\
                        --group vip_group
                    ;;
                AWS)
                    sudo -n pcs resource create cluster_vip ocf:aws:floatip \\
                        elastic_ip=${KAM_VIP} \\
                        op monitor interval=15s timeout=15s \\
                        op start interval=0 timeout=30s \\
                        meta resource-stickiness=100 \\
                        --group vip_group
                    ;;
                *)
                    sudo -n pcs resource create cluster_vip ocf:heartbeat:IPaddr2 \\
                        ip=${KAM_VIP} cidr_netmask=${CIDR_NETMASK} \\
                        op monitor interval=15s timeout=15s \\
                        op start interval=0 timeout=30s \\
                        meta resource-stickiness=100 \\
                        --group vip_group
                    sudo -n pcs resource create cluster_srcaddr ocf:heartbeat:IPsrcaddr \\
                        ipaddress=${KAM_VIP} cidr_netmask=${CIDR_NETMASK} \\
                        op monitor interval=15s timeout=15s \\
                        op start interval=0 timeout=30s \\
                        meta resource-stickiness=100 \\
                        --group vip_group
                    ;;
            esac

            printdbg 'Setting up resources for dsiprouter services'
            if grep -q 'rtpengine_service' 2>/dev/null <<<"${CLUSTER_RESOURCES[@]}"; then
                sudo -n pcs resource create rtpengine_service systemd:rtpengine \\
                    op monitor interval=30s timeout=15s \\
                    op start interval=0 timeout=30s on-fail=restart \\
                    op stop interval=0 timeout=30s \\
                    meta resource-stickiness=100 \\
                    --group dsip_group
            fi
            if grep -q 'kamailio_service' 2>/dev/null <<<"${CLUSTER_RESOURCES[@]}"; then
                sudo -n pcs resource create kamailio_service systemd:kamailio \\
                    op monitor interval=30s timeout=15s \\
                    op start interval=0 timeout=30s on-fail=restart \\
                    op stop interval=0 timeout=30s \\
                    meta resource-stickiness=100 \\
                    --group dsip_group
            fi
            if grep -q 'dsiprouter_service' 2>/dev/null <<<"${CLUSTER_RESOURCES[@]}"; then
                sudo -n pcs resource create dsiprouter_service systemd:dsiprouter \\
                    op monitor interval=60s timeout=15s \\
                    op start interval=0 timeout=30s on-fail=restart \\
                    op stop interval=0 timeout=30s \\
                    meta resource-stickiness=100 \\
                    --group dsip_group
            fi

            printdbg 'colocating resources on the same node'
            sudo -n pcs constraint colocation set vip_group dsip_group \\
                sequential=true \\
                setoptions score=INFINITY
            sudo -n pcs constraint order set vip_group dsip_group \\
                action=start sequential=true require-all=true \\
                setoptions symmetrical=false kind=Mandatory
        fi

        if (( $i == ${#NODES[@]} - 1 )); then
            printdbg 'testing cluster'

            PCS_MAJMIN_VER=\$(pcs --version | cut -d '.' -f -2 | tr -d '.')

            RESOURCES=(${CLUSTER_RESOURCES[@]})
            CURRENT_RESOURCE_LOCATIONS=()
            PREVIOUS_RESOURCE_LOCATIONS=()

            # wait on resources to come online
            waitResources ${RESOURCE_STARTUP_TIMEOUT} || {
                printerr "Cluster resources failed to start within ${RESOURCE_STARTUP_TIMEOUT} seconds"
                exit 1
            }

            # grab operation data for tests
            # TODO: error checking for resources not yet started
            for RESOURCE in \${RESOURCES[@]}; do
                PREVIOUS_RESOURCE_LOCATIONS+=( \$(findResource \${RESOURCE}) )
            done

            printdbg "current resource locations: \${PREVIOUS_RESOURCE_LOCATIONS[@]}"
            printdbg "setting \${PREVIOUS_RESOURCE_LOCATIONS[0]} to standby"

            if (( \$((10#\$PCS_MAJMIN_VER)) >= 10 )); then
                sudo -u hacluster -n pcs node standby \${PREVIOUS_RESOURCE_LOCATIONS[0]}
            else
                sudo -u hacluster -n pcs cluster standby \${PREVIOUS_RESOURCE_LOCATIONS[0]}
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
                sudo -u hacluster -n pcs node unstandby \${PREVIOUS_RESOURCE_LOCATIONS[0]}
            else
                sudo -u hacluster -n pcs cluster unstandby \${PREVIOUS_RESOURCE_LOCATIONS[0]}
            fi

            # wait for transfer to finish (to another node, could be original)
            waitResources ${RESOURCE_STARTUP_TIMEOUT} || {
                printerr "Cluster resources failed to start within ${RESOURCE_STARTUP_TIMEOUT} seconds"
                exit 1
            }

            # run tests to make sure operations worked
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
            sudo -u hacluster -n pcs resource failcount show
            printdbg 'Clearing any non-critical resource errors'
            sudo -u hacluster -n pcs resource cleanup

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