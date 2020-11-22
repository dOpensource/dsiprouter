#!/usr/bin/env bash
#
# corosync / pacemaker kamailio cluster config
# Notes:    more than 2 nodes may require fencing settings
#           you must be able to ssh to every node in the cluster from where script is run
#           supported ssh authentication methods: password, pubkey
# Usage:    ./installKamCluster.sh [-h|--help] -vip <virtual ip>|-net <subnet cidr> <[user1[:pass1]@]node1[:port1]> <[user2[:pass2]@]node2[:port2]> ...
#
### log file locations:
# /var/log/pcsd/pcsd.log
# /var/log/cluster/corosync.log
# /var/log/pcsd/pacemaker.log
# /var/log/nodeutil.log

# set project root, if in a git repo resolve top level dir
PROJECT_ROOT=${PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null)}
PROJECT_ROOT=${PROJECT_ROOT:-$(dirname $(dirname $(dirname $(readlink -f "$0"))))}
# import shared library functions
. ${PROJECT_ROOT}/HA/shared_lib.sh


# node configuration settings
PACEMAKER_TCP_PORTS=(2224 3121 5403 21064)
PACEMAKER_UDP_PORTS=(5404 5405)
CLUSTER_NAME="kamcluster"
CLUSTER_PASS="$(createPass)"
CLUSTER_RESOURCE_TIMEOUT=45
KAM_VIP=""
CIDR_NETMASK="24"
DSIP_PROJECT_DIR="/opt/dsiprouter"
DSIP_SCRIPT="${DSIP_PROJECT_DIR}/dsiprouter.sh"
SSH_DEFAULT_OPTS="-o StrictHostKeyChecking=no -o CheckHostIp=no -o ServerAliveInterval=5 -o ServerAliveCountMax=2"


printUsage() {
    pprint "Usage: $0 [-h|--help] -vip <virtual ip>|-net <subnet cidr> <[user1[:pass1]@]node1[:port1]> <[user2[:pass2]@]node2[:port2]> ..."
}

if ! isRoot; then
    printerr "Must be run with root privileges" && exit 1
fi

if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    printUsage && exit 1
fi

# loop through args and evaluate any options
ARGS=()
while (( $# > 0 )); do
    ARG="$1"
    case $ARG in
        -vip)
            shift
            KAM_VIP="$1"
            shift
            ;;
        -net)
            shift
            KAM_VIP=$(findAvailableIP "$1")
            CIDR_NETMASK=$(echo "$1" | cut -d '/' -f 2)
            shift
            ;;
        *)  # add to list of args
            ARGS+=( "$ARG" )
            shift
            ;;
    esac
done

if [[ -z "${KAM_VIP}" ]] || [[ -z "${CIDR_NETMASK}" ]]; then
    printerr 'Kamailio virtual IP or CIDR netmask is required' && printUsage && exit 1
fi

# make sure required args are fulfilled
if (( ${#ARGS[@]} < 2 )); then
    printerr "At least 2 nodes are required to setup kam cluster" && printUsage && exit 1
fi

# install local requirements for script
setOSInfo
case "$DISTRO" in
    debian|ubuntu|linuxmint)
        apt-get install -y sshpass nmap sed gawk
        ;;
    centos|redhat|amazon)
        yum install -y epel-release
        yum install -y sshpass nmap sed gawk
        ;;
    *)
        printerr "Your OS Distro is currently not supported"
        exit 1
        ;;
esac

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
    (pcs status resources | grep "$1" | awk '{print $NF}'
        exit ${PIPESTATUS[0]}; ) 2>/dev/null; return $?
}

# $1 == timeout
# returns: 0 == resources up within timeout, else == resources not up within timeout
# notes: block while waiting for resources to come online until timeout
waitResources() {
    timeout "$1" bash <<'EOF' 2> /dev/null
RESOURCES_DOWN=0
while (( $RESOURCES_DOWN == 0 )); do
    RESOURCES_DOWN=$(pcs status resources 2>/dev/null | grep -q 'Stopped'; echo $?)
    sleep 1
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
    local IP4RESTORE_FILE="$1"
    local IP6RESTORE_FILE="$2"

    # use firewalld if installed
    if cmdExists "firewall-cmd"; then
        for PORT in ${PACEMAKER_TCP_PORTS[@]}; do
            firewall-cmd --zone=public --add-port=${PORT}/tcp --permanent
        done
        for PORT in ${PACEMAKER_UDP_PORTS[@]}; do
            firewall-cmd --zone=public --add-port=${PORT}/udp --permanent
        done
        firewall-cmd --reload
    else
        # set ipv4 firewall rules (on each node)
        for PORT in ${PACEMAKER_TCP_PORTS[@]}; do
            iptables -I INPUT 1 -p tcp --dport ${PORT} -j ACCEPT
        done
        for PORT in ${PACEMAKER_UDP_PORTS[@]}; do
            iptables -I INPUT 1 -p udp --dport ${PORT} -j ACCEPT
        done

        # set ipv6 firewall rules (on each node)
        for PORT in ${PACEMAKER_TCP_PORTS[@]}; do
            ip6tables -I INPUT 1 -p tcp --dport ${PORT} -j ACCEPT
        done
        for PORT in ${PACEMAKER_UDP_PORTS[@]}; do
            ip6tables -I INPUT 1 -p udp --dport ${PORT} -j ACCEPT
        done
    fi

    # Remove duplicates and save
    mkdir -p $(dirname ${IP4RESTORE_FILE})
    iptables-save | awk '!x[$0]++' > ${IP4RESTORE_FILE}
    mkdir -p $(dirname ${IP6RESTORE_FILE})
    ip6tables-save | awk '!x[$0]++' > ${IP6RESTORE_FILE}
}

# loop through args and grab hosts
HOST_LIST=()
NODE_NAMES=()
i=0
for NODE in ${ARGS[@]}; do
    NODE_NAME="${CLUSTER_NAME}-node$((i+1))"
    HOST_LIST+=( $(printf '%s' "$NODE" | cut -d '@' -f 2- | cut -d ':' -f -1) )
    NODE_NAMES+=( "$NODE_NAME" )
    i=$((i+1))
done

## 1st loop installs requirements and enables services
printdbg 'configuring servers for cluster deployment'
i=0
for NODE in ${ARGS[@]}; do
    USER=$(printf '%s' "$NODE" | cut -s -d '@' -f -1 | cut -d ':' -f -1)
    PASS=$(printf '%s' "$NODE" | cut -s -d '@' -f -1 | cut -s -d ':' -f 2-)
    HOST=$(printf '%s' "$NODE" | cut -d '@' -f 2- | cut -d ':' -f -1)
    PORT=$(printf '%s' "$NODE" | cut -d '@' -f 2- | cut -s -d ':' -f 2-)

    # default user is root for ssh
    USER=${USER:-root}
    # default port is 22 for ssh
    PORT=${PORT:-22}

    # validate host connection
    if ! checkConn ${HOST} ${PORT}; then
        printerr "Could not establish connection to host [${HOST}] on port [${PORT}]" && exit 1
    fi

    SSH_CMD="ssh"
    if [ -z "$HOST" ]; then
        printerr "Node [${NODE}] does not contain a host" && printUsage && exit 1
    else
        SSH_REMOTE_HOST="${HOST}"
    fi
    SSH_REMOTE_HOST="${USER}@${SSH_REMOTE_HOST}"
    if [ -n "$PASS" ]; then
        #SSH_CMD="sshpass -f <(printf '${PASS}\n') ssh"
        #SSH_CMD="sshpass -p '${PASS}' ssh"
        export SSHPASS="${PASS}"
        SSH_CMD="sshpass -e ssh"
    fi
    SSH_OPTS="${SSH_DEFAULT_OPTS} -p ${PORT}"
    SSH_CMD="${SSH_CMD} ${SSH_REMOTE_HOST} ${SSH_OPTS}"

    # validate unattended ssh connection
    if ! checkSSH ${SSH_CMD}; then
        printerr "Could not establish unattended ssh connection to [${SSH_REMOTE_HOST}] on port [${PORT}]" && exit 1
    fi

    # remote server will be using bash as interpreter
    SSH_CMD="${SSH_CMD} bash"
    # DEBUG:
    printdbg "SSH_CMD: ${SSH_CMD}"

    # run commands through ssh
#    (cat <<- EOSSH
    (${SSH_CMD} <<- EOSSH
    set -x

    # re-declare functions and vars we pass to remote server
    # note that variables in function definitions (from calling environement)
    # lose scope unless local to function, they must be passed to remote
    $(typeset -f printdbg)
    $(typeset -f printerr)
    $(typeset -f cmdExists)
    $(typeset -f join)
    $(typeset -f setOSInfo)
    $(typeset -f setFirewallRules)
    HOST_LIST=( ${HOST_LIST[@]} )
    NODE_NAMES=( ${NODE_NAMES[@]} )
    ESC_SEQ="\033["
    ANSI_NONE="\${ESC_SEQ}39;49;00m" # Reset colors
    ANSI_RED="\${ESC_SEQ}1;31m"
    ANSI_GREEN="\${ESC_SEQ}1;32m"


    setOSInfo
    printdbg 'installing requirements'
    case "\$DISTRO" in
        debian|ubuntu|linuxmint)
            # debian-based configs
            IP4RESTORE_FILE="/etc/iptables/rules.v4"
            IP6RESTORE_FILE="/etc/iptables/rules.v6"
            export DEBIAN_FRONTEND=noninteractive

            apt-get install -y corosync pacemaker pcs gawk iptables-persistent netfilter-persistent
            ;;
        centos|redhat|amazon)
            # redhat-based specific configs
            IP4RESTORE_FILE="/etc/sysconfig/iptables"
            IP6RESTORE_FILE="/etc/sysconfig/ip6tables"

            yum install -y corosync pacemaker pcs gawk
            ;;
        *)
            printerr "Your OS Distro is currently not supported"
            exit 1
            ;;
    esac

    if ! cmdExists 'pcs'; then
        printerr 'Failed to install requirements' && exit 1
    fi


    printdbg 'configuring server for cluster deployment'

    # set firewall rules
    setFirewallRules "\$IP4RESTORE_FILE" "\$IP6RESTORE_FILE"

    # start the services (on each node)
    systemctl enable pcsd
    systemctl enable corosync
    systemctl enable pacemaker
    systemctl start pcsd
    echo "${CLUSTER_PASS}" | passwd -q --stdin hacluster 2>/dev/null ||
        echo "hacluster:${CLUSTER_PASS}" | chpasswd 2>/dev/null ||
        { printerr "could not change hacluster user password"; exit 1; }

    # hostnames are required even if not DNS resolvable (on each node)
    if ! grep -q -E \$(join '|' \${HOST_LIST[@]}) /etc/hosts 2>/dev/null; then
        i=0
        while (( \$i < \${#HOST_LIST[@]} )); do
            printf '%s\n' "\${HOST_LIST[\$i]}    \${NODE_NAMES[\$i]}" >> /etc/hosts
            i=\$((i+1))
        done
    fi
    printf '%s\n' "\${NODE_NAMES[$i]}" > /etc/hostname
    hostname \${NODE_NAMES[$i]}

    # enable binding to floating ip (on each node)
    echo '1' > /proc/sys/net/ipv4/ip_nonlocal_bind
    echo 'net.ipv4.ip_nonlocal_bind = 1' > /etc/sysctl.d/99-non-local-bind.conf

    # change kamcfg and rtpenginecfg to use floating ip (on each node)
    if [ -e "${DSIP_SCRIPT}" ]; then
        printdbg 'updating kamailio and rtpengine settings'

        # manually add default route to vip before updating settings
        VIP_CIDR="${KAM_VIP}/${CIDR_NETMASK}"
        ROUTE_INFO=\$(ip route get 8.8.8.8 | head -1)
        DEF_IF=\$(printf '%s' "\${ROUTE_INFO}" | grep -oP 'dev \K\w+')
        VIP_ROUTE_INFO=\$(printf '%s' "\${ROUTE_INFO}" | sed -r "s|8.8.8.8|0.0.0.0/1|; s|dev [\w\d]+|dev \${DEF_IF}|; s|src [\w\d]+|src ${KAM_VIP}|")
        ip address add \$VIP_CIDR dev \$DEF_IF
        ip route add \$VIP_ROUTE_INFO

        ${DSIP_SCRIPT} updatekamconfig
        ${DSIP_SCRIPT} updatertpconfig

        ip address del \$VIP_CIDR dev \$DEF_IF
        ip route del 0.0.0.0/1

        # TODO: enable kamailio to listen to both ip's (maybe??)
    fi

    exit 0
EOSSH
    ) 2>&1

    if (( $? != 0 )); then
        printerr "server configuration failed on ${HOST}" && exit 1
    fi

    i=$((i+1))
done


## 2nd loop creates and configures the cluster
printdbg 'deploying cluster configurations on servers'
i=0
for NODE in ${ARGS[@]}; do
    USER=$(printf '%s' "$NODE" | cut -s -d '@' -f -1 | cut -d ':' -f -1)
    PASS=$(printf '%s' "$NODE" | cut -s -d '@' -f -1 | cut -s -d ':' -f 2-)
    HOST=$(printf '%s' "$NODE" | cut -d '@' -f 2- | cut -d ':' -f -1)
    PORT=$(printf '%s' "$NODE" | cut -d '@' -f 2- | cut -s -d ':' -f 2-)

    # default user is root for ssh
    USER=${USER:-root}
    # default port is 22 for ssh
    PORT=${PORT:-22}

    # validate host connection
    if ! checkConn ${HOST} ${PORT}; then
        printerr "Could not establish connection to host [${HOST}] on port [${PORT}]" && exit 1
    fi

    SSH_CMD="ssh"
    if [ -z "$HOST" ]; then
        printerr "Node [${NODE}] does not contain a host" && printUsage && exit 1
    else
        SSH_REMOTE_HOST="${HOST}"
    fi
    SSH_REMOTE_HOST="${USER}@${SSH_REMOTE_HOST}"
    if [ -n "$PASS" ]; then
        #SSH_CMD="sshpass -f <(printf '${PASS}\n') ssh"
        #SSH_CMD="sshpass -p '${PASS}' ssh"
        export SSHPASS="${PASS}"
        SSH_CMD="sshpass -e ssh"
    fi
    SSH_OPTS="${SSH_DEFAULT_OPTS} -p ${PORT}"
    SSH_CMD="${SSH_CMD} ${SSH_REMOTE_HOST} ${SSH_OPTS}"

    # validate unattended ssh connection
    if ! checkSSH ${SSH_CMD}; then
        printerr "Could not establish unattended ssh connection to [${SSH_REMOTE_HOST}] on port [${PORT}]" && exit 1
    fi

    # remote server will be using bash as interpreter
    SSH_CMD="${SSH_CMD} bash"
    # DEBUG:
    printdbg "SSH_CMD: ${SSH_CMD}"

    # run commands through ssh
#    (cat <<- EOSSH
    (${SSH_CMD} <<- EOSSH
    set -x

    # re-declare functions and vars we pass to remote server
    # note that variables in function definitions (from calling environement)
    # lose scope unless local to function, they must be passed to remote
    $(typeset -f printdbg)
    $(typeset -f printerr)
    $(typeset -f findResource)
    $(typeset -f showClusterStatus)
    $(typeset -f waitResources)
    NODE_NAMES=( ${NODE_NAMES[@]} )
    ESC_SEQ="\033["
    ANSI_NONE="\${ESC_SEQ}39;49;00m" # Reset colors
    ANSI_RED="\${ESC_SEQ}1;31m"
    ANSI_GREEN="\${ESC_SEQ}1;32m"


    ## Pacemaker / Corosync cluster
    if (( $i == 0 )); then
        printdbg 'creating cluster'

        # Now setup the cluster (on first node)
        FLAT_NAMES=\${NODE_NAMES[@]}
        pcs cluster auth --force -u hacluster -p ${CLUSTER_PASS} \$FLAT_NAMES
        (( \$? != 0 )) && { printerr "Cluster auth failed" && exit 1; }
        pcs cluster setup --force --enable --name ${CLUSTER_NAME} \$FLAT_NAMES
        (( \$? != 0 )) && { printerr "Cluster creation failed" && exit 1; }
        # Start the cluster (on first node)
        pcs cluster start --all

        ## Stonith and qourum

        # We can disable this for now for testing (on first node)
        pcs property set stonith-enabled=false
        pcs property set no-quorum-policy=ignore

        ## Setting up the virtual ip address with pacemaker

        # create resource for kamailio and virtual ip and default route (on first node)
        pcs resource create kamailio_vip ocf:heartbeat:IPaddr2 ip=${KAM_VIP} cidr_netmask=${CIDR_NETMASK} op monitor interval=10s
        pcs resource create kamailio_srcaddr ocf:heartbeat:IPsrcaddr ipaddress=${KAM_VIP} cidr_netmask=24 op monitor interval=15s
        pcs resource create kamailio_service systemd:kamailio op monitor interval=20s op start interval=0 timeout=45s op stop interval=0 timeout=45s

        # set the stickiness on each resource before colocating (on first node)
        pcs resource meta kamailio_service resource-stickiness=100
        pcs resource meta kamailio_vip resource-stickiness=100
        pcs resource meta kamailio_srcaddr resource-stickiness=100

        # Then link these two services together (on first node)
        pcs constraint colocation set kamailio_vip kamailio_srcaddr kamailio_service sequential=true setoptions score=INFINITY
        pcs constraint order set kamailio_vip kamailio_srcaddr kamailio_service sequential=true action=start require-all=true setoptions symmetrical=true
    fi

    if (( $i == ${#ARGS[@]} - 1 )); then
        printdbg 'testing cluster'

        RESOURCES=(kamailio_vip kamailio_srcaddr kamailio_service)
        CURRENT_RESOURCE_LOCATIONS=()
        PREVIOUS_RESOURCE_LOCATIONS=()

        # wait on resources to come online (last node)
        waitResources ${CLUSTER_RESOURCE_TIMEOUT} || { printerr "Cluster resource failed to start within ${CLUSTER_RESOURCE_TIMEOUT} sec" && exit 1; }

        # grab operation data for tests (last node)
        for RESOURCE in \${RESOURCES[@]}; do
            PREVIOUS_RESOURCE_LOCATIONS+=( \$(findResource \${RESOURCE}) )
        done

        pcs cluster standby \${PREVIOUS_RESOURCE_LOCATIONS[0]}
        sleep 10 # wait for transfer to start
        waitResources ${CLUSTER_RESOURCE_TIMEOUT} || { printerr "Cluster resource failed to start within ${CLUSTER_RESOURCE_TIMEOUT} sec" && exit 1; }

        for RESOURCE in \${RESOURCES[@]}; do
            CURRENT_RESOURCE_LOCATIONS+=( \$(findResource \${RESOURCE}) )
        done

        pcs cluster unstandby \${PREVIOUS_RESOURCE_LOCATIONS[0]}

        printdbg "PREVIOUS_RESOURCE_LOCATIONS: \${PREVIOUS_RESOURCE_LOCATIONS[@]}"
        printdbg "CURRENT_RESOURCE_LOCATIONS: \${CURRENT_RESOURCE_LOCATIONS[@]}"

        # run tests to make sure operations worked (last node)
        i=0
        while (( \$i < \${#RESOURCES[@]} )); do
            if [[ \${PREVIOUS_RESOURCE_LOCATIONS[\$i]} != \${PREVIOUS_RESOURCE_LOCATIONS[\$((i+1))]:-\${PREVIOUS_RESOURCE_LOCATIONS[0]}} ]]; then
                printerr "Cluster resource colocation tests failed (before migration)" && exit 1
            fi

            if [[ \${CURRENT_RESOURCE_LOCATIONS[\$i]} != \${CURRENT_RESOURCE_LOCATIONS[\$((i+1))]:-\${CURRENT_RESOURCE_LOCATIONS[0]}} ]]; then
                printerr "Cluster resource colocation tests failed (after migration)" && exit 1
            fi

            if [[ \${PREVIOUS_RESOURCE_LOCATIONS[\$i]} == \${CURRENT_RESOURCE_LOCATIONS[\$i]} ]] || [[ \${CURRENT_RESOURCE_LOCATIONS[\$i]} == "Stopped" ]]; then
                printerr "Cluster resource \${RESOURCE} failover tests failed" && exit 1
            fi

            i=\$((i+1))
        done

        # show status to user (last node)
        showClusterStatus
    fi

    exit 0
EOSSH
    ) 2>&1

    if (( $? != 0 )); then
        printerr "kamailio cluster configuration failed on ${HOST}" && exit 1
    fi

    i=$((i+1))
done

exit 0