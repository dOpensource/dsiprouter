#!/usr/bin/env bash
#
# Summary:      consul service mesh
# Supported OS: debian, ubuntu, linuxmint, redhat, centos, amazon linux
# Notes:        you must be able to ssh to every node in the cluster from where script is run
#               supported ssh authentication methods: password, pubkey
#               by default the consul agent type is set to client
#               atleast one consul agent must be a server or installation will hault
# Usage:        ./installConsulCluster.sh [-h|--help|-cloud] <[user1[:pass1]@]node1[:port1][?server]> <[user2[:pass2]@]node2[:port2][?server]> ...
#

# set project root, if in a git repo resolve top level dir
PROJECT_ROOT=${PROJECT_ROOT:-$(dirname $(dirname $(dirname $(readlink -f "$0"))))}
# import shared library functions
. ${PROJECT_ROOT}/HA/shared_lib.sh


# node configuration settings
export CLUSTER_NAME="consulcluster"
CLOUD_AUTO_JOIN=0
DSIP_SYSTEM_CONFIG_DIR="/etc/dsiprouter"
PATH_UPDATE_FILE="/etc/profile.d/dsip_paths.sh"
CONSUL_PRIV_KEY="${DSIP_SYSTEM_CONFIG_DIR}/consulkey"
export KEY_CIPHER_TEXT_B64=$(dd if=/dev/urandom bs=32 count=1 2>/dev/null | base64)
SERVICES_TO_TRACK=("dsiprouter" "kamailio" "haproxy" "asterisk" "freeswitch" "rtpengine" "rtpproxy" "mysql" "mariadb" "postgresql" "redis")
SSH_DEFAULT_OPTS="-o StrictHostKeyChecking=no -o CheckHostIp=no -o ServerAliveInterval=5 -o ServerAliveCountMax=2"
CONSUL_TCP_PORTS=(8300 8301 8302 8500 8501 8600)
CONSUL_UDP_PORTS=(8301 8302 8600)
CONSUL_URL="https://releases.hashicorp.com/consul/"


printUsage() {
    pprint "$0 [-h|--help|-cloud] <[user1[:pass1]@]node1[:port1][?server]> <[user2[:pass2]@]node2[:port2][?server]> ..."
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
        -cloud)
            # TODO: support cloud auto join
            # https://www.consul.io/docs/agent/cloud-auto-join.html
            printerr "Cloud auto join is not supported at this time" && exit 1
            WITH_CLOUD_AUTO_JOIN=1
            shift
            ;;
        *)  # add to list of args
            ARGS+=( "$ARG" )
            shift
            ;;
    esac
done

# make sure required args are fulfilled
if (( ${#ARGS[@]} < 1 )); then
    printerr "No nodes provided to setup consul cluster" && printUsage && exit 1
elif ! echo "${ARGS[*]}" | grep -q '?server'; then
    printerr "At least 1 server node is required to setup a consul cluster" && printUsage && exit 1
fi

# install local requirements for script
setOSInfo
case "$DISTRO" in
    debian|ubuntu|linuxmint)
        apt-get install -y sshpass gawk perl
        ;;
    centos|redhat|amazon)
        yum install -y epel-release
        yum install -y sshpass gawk perl
        ;;
    *)
        printerr "Your OS Distro is currently not supported"
        exit 1
        ;;
esac

# prints number of nodes in cluster
getClusterSize() {
    consul members 2>/dev/null | tail -n +2 | wc -l
}

isNodeInCluster() {
    local NODE_NAME="$1"
    if consul catalog nodes 2>/dev/null | tail -n +2 | awk '{print $1}' | grep -q "$NODE_NAME"; then
        return 0
    else
        return 1
    fi
}

# $1 == ipv4 persistent rules file
# $2 == ipv6 persistent rules file
setFirewallRules() {
    local IP4RESTORE_FILE="$1"
    local IP6RESTORE_FILE="$2"

    # use firewalld if installed
    if cmdExists "firewall-cmd"; then
        for PORT in ${CONSUL_TCP_PORTS[@]}; do
            firewall-cmd --zone=public --add-port=${PORT}/tcp --permanent
        done
        for PORT in ${CONSUL_UDP_PORTS[@]}; do
            firewall-cmd --zone=public --add-port=${PORT}/udp --permanent
        done
        firewall-cmd --reload
    else
        # set ipv4 firewall rules (on each node)
        for PORT in ${CONSUL_TCP_PORTS[@]}; do
            iptables -I INPUT 1 -p tcp --dport ${PORT} -j ACCEPT
        done
        for PORT in ${CONSUL_UDP_PORTS[@]}; do
            iptables -I INPUT 1 -p udp --dport ${PORT} -j ACCEPT
        done

        # set ipv6 firewall rules (on each node)
        for PORT in ${CONSUL_TCP_PORTS[@]}; do
            ip6tables -I INPUT 1 -p tcp --dport ${PORT} -j ACCEPT
        done
        for PORT in ${CONSUL_UDP_PORTS[@]}; do
            ip6tables -I INPUT 1 -p udp --dport ${PORT} -j ACCEPT
        done
    fi

    # Remove duplicates and save
    mkdir -p $(dirname ${IP4RESTORE_FILE})
    iptables-save | awk '!x[$0]++' > ${IP4RESTORE_FILE}
    mkdir -p $(dirname ${IP6RESTORE_FILE})
    ip6tables-save | awk '!x[$0]++' > ${IP6RESTORE_FILE}
}

createConsulTrackedService() {
    local NAME="$1"
    local SYSTEMCTL_CMD=$(type -p systemctl)

    (cat << EOF
{
  "service": {
    "name": "${NAME}",
    "tags": ["${NAME}"],
    "check": {
      "id": "${NAME}",
      "service_id": "${NAME}",
      "args": ["${SYSTEMCTL_CMD}", "is-active", "--quiet", "${NAME}"],
      "interval": "10s"
    }
  }
}
EOF
    ) > /etc/consul.d/${NAME}.json
}

# loop through args and grab hosts
export NUM_NODES=0
HOST_LIST=()
for NODE in ${ARGS[@]}; do
    HOST_LIST+=( $(printf '%s' "$NODE" | cut -d '@' -f 2- | cut -d ':' -f -1) )
    NUM_NODES=$((NUM_NODES+1))
done

# set the auto join list for nodes
export RETRY_JOIN="[$(join ',' $(printf '"%s" ' "${HOST_LIST[@]}"))]"

# set config files as variables for transport
CONSUL_SYSTEM_SERVICE=$(cat ${PROJECT_ROOT}/HA/consul/consul.service)
CONSUL_SYSLOG_CONFIG=$(cat ${PROJECT_ROOT}/resources/syslog/consul.conf)
CONSUL_LOGROTATE_CONFIG=$(cat ${PROJECT_ROOT}/resources/logrotate/consul)
CONSUL_SELINUX_MODULE=$(cat ${PROJECT_ROOT}/HA/consul/consul.te)
CONSUL_SELINUX_CONTEXT=$(cat ${PROJECT_ROOT}/HA/consul/consul.fc)

# prevent quote expansion in client and server config
# we will just scp it over because bash expands quote on assignment
mkdir -p /tmp/consul
envsubst < ${PROJECT_ROOT}/HA/consul/consul.hcl > /tmp/consul/consul.hcl
envsubst < ${PROJECT_ROOT}/HA/consul/server.hcl > /tmp/consul/server.hcl

# TODO: in an example config these dns settings were used, do we need them?
# - https://github.com/sboily/asterisk-consul-module/blob/master/contribs/kamailio/config/kamailio/kamailio.cfg
#
# /etc/kamailio/kamailio.cfg
#
#dns_cache_init=no
#use_dns_cache=no
#


# loop through args and run setup commands
i=0
for NODE in ${ARGS[@]}; do
    USER=$(printf '%s' "$NODE" | cut -s -d '@' -f -1 | cut -d ':' -f -1)
    PASS=$(printf '%s' "$NODE" | cut -s -d '@' -f -1 | cut -s -d ':' -f 2-)
    HOST=$(printf '%s' "$NODE" | cut -d '@' -f 2- | cut -d ':' -f -1)
    PORT=$(printf '%s' "$NODE" | cut -d '@' -f 2- | cut -s -d ':' -f 2- | cut -d '?' -f -1)
    TYPE=$(printf '%s' "$NODE" | cut -s -d '?' -f 2-)

    # default user is root for ssh
    USER=${USER:-root}
    # default port is 22 for ssh
    PORT=${PORT:-22}
    # default type is client
    [[ "$TYPE" != "server" ]] && TYPE="client"

    # validate host connection
    if ! checkConn ${HOST} ${PORT}; then
        printerr "Could not establish connection to host [${HOST}] on port [${PORT}]" && exit 1
    fi

    SSH_CMD="ssh"
    SCP_CMD="scp"
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
        SCP_CMD="sshpass -e scp"
    fi
    SSH_OPTS="${SSH_DEFAULT_OPTS} -p ${PORT}"
    SCP_OPTS="-q ${SSH_DEFAULT_OPTS} -P ${PORT}"
    SSH_CMD="${SSH_CMD} ${SSH_REMOTE_HOST} ${SSH_OPTS}"
    SCP_CMD="${SCP_CMD} ${SCP_OPTS}"

    # validate unattended ssh connection
    if ! checkSSH ${SSH_CMD}; then
        printerr "Could not establish unattended ssh connection to [${SSH_REMOTE_HOST}] on port [${PORT}]" && exit 1
    fi

    NODE_NAME="node$((i+1))"
    # remote server will be using bash as interpreter
    SSH_CMD="${SSH_CMD} bash"
    # DEBUG:
    printdbg "SSH_CMD: ${SSH_CMD}"
    printdbg "SCP_CMD: ${SCP_CMD}"

    # transfer some files before we connect
    ${SCP_CMD} -r /tmp/consul ${SSH_REMOTE_HOST}:/tmp/
    rm -rf /tmp/consul

    # run commands through ssh
    (${SSH_CMD} <<- EOSSH
    set -x

    # re-declare functions and vars we pass to remote server
    # note that variables in function definitions (from calling environement)
    # lose scope unless local to function, they must be passed to remote
    $(typeset -f printdbg)
    $(typeset -f printerr)
    $(typeset -f cmdExists)
    $(typeset -f setOSInfo)
    $(typeset -f join)
    $(typeset -f pathCheck)
    $(typeset -f getClusterSize)
    $(typeset -f setFirewallRules)
    $(typeset -f detectServiceMan)
    $(typeset -f createConsulTrackedService)
    $(typeset -f isNodeInCluster)
    $(typeset -f ipv4Test)
    $(typeset -f ipv6Test)
    $(typeset -f getExternalIP)
    $(typeset -f getInternalIP)
    ESC_SEQ="\033["
    ANSI_NONE="\${ESC_SEQ}39;49;00m" # Reset colors
    ANSI_RED="\${ESC_SEQ}1;31m"
    ANSI_GREEN="\${ESC_SEQ}1;32m"
    TYPE="$TYPE"


    # systemd is a hard requirement
    detectServiceMan
    if [[ "\$SERVICE_MANAGER" != "systemd" ]]; then
        printerr "Systemd is required and not installed on ${NODE_NAME}" && exit 1
    fi

    setOSInfo
    printdbg 'installing requirements'
    case "\$DISTRO" in
        debian|ubuntu|linuxmint)
            # debian-based distro specific settings
            IP4RESTORE_FILE="/etc/iptables/rules.v4"
            IP6RESTORE_FILE="/etc/iptables/rules.v6"
            export DEBIAN_FRONTEND=noninteractive

            apt-get install -y curl wget sed gawk dirmngr iptables-persistent netfilter-persistent
            ;;

        centos|redhat|amazon)
            # rhel-based distro specific settings
            IP4RESTORE_FILE="/etc/sysconfig/iptables"
            IP6RESTORE_FILE="/etc/sysconfig/ip6tables"

            yum install -y curl wget sed gawk

            # rhel/centos SELINUX
            # from: https://lists.fedoraproject.org/archives/list/selinux@lists.fedoraproject.org/thread/IOKQ26N53CT7WMZZWBW2RTSD2YT7TWNQ/
            if sestatus | head -1 | grep -qi 'enabled'; then
                yum install -y policycoreutils-python setools-console selinux-policy-devel

                semanage permissive -a consul_t

                setsebool -P httpd_can_network_connect 1

                mkdir -p /tmp/selinux

                printf '%s' "\$CONSUL_SELINUX_MODULE" > /tmp/selinux/consul.te
                printf '%s' "\$CONSUL_SELINUX_CONTEXT" > /tmp/selinux/consul.fc

                checkmodule -M -m /tmp/selinux/consul.te -o /tmp/selinux/consul.mod
                semodule_package -m /tmp/selinux/galera.mod -f /tmp/selinux/consul.fc -o /tmp/selinux/consul.pp
                semodule -i /tmp/selinux/consul.pp
            fi
            ;;

        *)
            printerr "OS Distro is currently not supported" && exit 1
            ;;
    esac


    # set firewall rules
    setFirewallRules "\$IP4RESTORE_FILE" "\$IP6RESTORE_FILE"

    # fix PATH if needed
    # we are using the default install paths but these may change in the future
    mkdir -p \$(dirname ${PATH_UPDATE_FILE})
    if [[ ! -e "$PATH_UPDATE_FILE" ]]; then
        (cat << 'EOF'
#export PATH="/usr/local/bin\${PATH:+:\$PATH}"
#export PATH="\${PATH:+\$PATH:}/usr/sbin"
#export PATH="\${PATH:+\$PATH:}/sbin"
EOF
        ) > ${PATH_UPDATE_FILE}
    fi

    # minimalistic approach avoids growing duplicates
    # enable (uncomment) and import only what we need
    PATH_UPDATED=0

    # - consul
    if ! pathCheck /usr/local/bin; then
        sed -i -r 's|^#(export PATH="/usr/local/bin\\$\{PATH:\+:\\$PATH\}")\$|\1|' ${PATH_UPDATE_FILE}
        PATH_UPDATED=1
    fi

    # import new path definition if it was updated
    (( \${PATH_UPDATED} == 1 )) &&  . \${PATH_UPDATE_FILE}

    # install consul and configure cluster settings
    if ! cmdExists "consul"; then
        printdbg "Installing consul"
        CONSUL_VER=\$(curl -s "$CONSUL_URL" 2>/dev/null | grep -oP '<a href="/consul/\K[\d\.]+(?=/"\>)' | head -1)
        ARCH=\$(uname -m)

        # normalize architecture to download correct ver (default to x86_64)
        case "\$ARCH" in
            x86_64)
                ARCH="amd64"
                ;;
            i386|i686)
                ARCH="386"
                ;;
            aarch64*|armv[8-9]*)
                ARCH="arm64"
                ;;
            arm|armv[0-7]*)
                ARCH="arm"
                ;;
            *)
                ARCH="amd64"
                ;;
        esac

        wget -q -O /tmp/consul.zip "${CONSUL_URL}\${CONSUL_VER}/consul_\${CONSUL_VER}_linux_\${ARCH}.zip"
        unzip -f /tmp/consul.zip consul -d /usr/local/bin/ &&
        rm -f /tmp/consul.zip &&
        chmod +x /usr/local/bin/consul

        if ! cmdExists "consul"; then
            printerr "Consul install failed on ${NODE_NAME}" && exit 1
        fi
    else
        printdbg "consul is already installed"
    fi

    consul -autocomplete-install
    complete -C /usr/local/bin/consul consul

    useradd --system --user-group --home /etc/consul.d --shell /bin/false --comment "Consul Service Mesh" consul
    mkdir -p /opt/consul
    mkdir -p /etc/consul.d
    mkdir -p /var/run/consul
    chown -R consul:consul /opt/consul
    chown -R consul:consul /var/run/consul

    # create consul agent client configs
    sed "s|EXTERNAL_IP_ADDR|\$(getExternalIP)|; s|NODE_NAME|${NODE_NAME}|" /tmp/consul/consul.hcl > /etc/consul.d/consul.hcl

    # create consul agent server configs
    if [[ "$TYPE" == "server" ]]; then
        cp -f /tmp/consul/server.hcl /etc/consul.d/server.hcl
    fi

    # setup consul syslog configs
    printf '%s' "$CONSUL_SYSLOG_CONFIG" >  /etc/rsyslog.d/consul.conf
    touch /var/log/dsiprouter.log
    systemctl restart rsyslog

    # setup consul logrotate configs
    printf '%s' "$CONSUL_LOGROTATE_CONFIG" > /etc/logrotate.d/consul

    # create consul system service
    printf '%s' "$CONSUL_SYSTEM_SERVICE" > /etc/systemd/system/consul.service
    chmod 0644 /etc/systemd/system/consul.service

    # create consul agents for services
    SERVICES=\$(systemctl list-units | awk '{print $1}' | grep -oP "\$(join '|' ${SERVICES_TO_TRACK[@]})")
    for SERVICE in \${SERVICES[@]}; do
        createConsulTrackedService "\$SERVICE"
    done

    # set permissions for consul configs and cleanup tmp
    chmod -R 0740 /etc/consul.d
    chown -R consul:consul /etc/consul.d
    rm -rf /tmp/consul

    systemctl enable consul
    systemctl restart consul
    if systemctl is-active --quiet consul; then
        printdbg "Consul was successfully configured on [${NODE_NAME}]"
    else
        printerr "Consul configuration failed on [${NODE_NAME}]" && exit 1
    fi

    # check if node connected to cluster
    sleep 5
    if (( \$? == 0 )) && (( \$(getClusterSize) > 0 )) && isNodeInCluster "${NODE_NAME}"; then
        printdbg "Adding Node to cluster success"
    else
        printerr "Adding Node to cluster failed [${NODE_NAME}]" && exit 1
    fi

    exit 0
EOSSH
    ) 2>&1

    if (( $? != 0 )); then
        printerr "consul configuration failed on ${HOST}" && exit 1
    fi

    i=$((i+1))
done

unset CLUSTER_NAME KEY_CIPHER_TEXT_B64 NUM_NODES RETRY_JOIN
exit 0