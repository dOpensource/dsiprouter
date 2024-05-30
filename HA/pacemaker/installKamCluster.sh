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

#======================================================================================
# process and validate the CLI args
#======================================================================================

# process args before doing anything else
printUsage() {
    echo "Usage: $0 [OPTIONAL OPTIONS] <REQUIRED OPTIONS> <REQUIRED ARGUMENTS>"
    echo "OPTIONAL OPTIONS:"
    echo "    -h|--help"
    echo "    -debug"
    echo "    -i <ssh key file>"
    echo "    --do-token=<your token>"
    echo "    --aws-access-key=<your key>"
    echo "    --aws-secret-key=<your key>"
    echo "REQUIRED OPTIONS (one of):"
    echo "    -vip <virtual ip>"
    echo "    -net <subnet cidr>"
    echo "REQUIRED ARGUMENTS:"
    echo " <[sshuser1[:sshpass1]@]node1[:sshport1]> <[sshuser2[:sshpass2]@]node2[:sshport2]> ..."
}

# loop through args and evaluate any options
IN_NODES=()
while (( $# > 0 )); do
    ARG="$1"
    case $ARG in
        -h|--help)
            printUsage
            exit 0
            ;;
        -debug)
            IN_DEBUG=1
            shift
            ;;
        -vip)
            shift
            IN_KAM_VIP="$1"
            shift
            ;;
        -net)
            shift
            IN_CIDR_FULL="$1"
            IN_CIDR_NETMASK=$(cut -s -d '/' -f 2 <<<"$1")
            shift
            ;;
        -i)
            shift
            IN_SSH_KEY_FILE="$1"
            shift
            ;;
        --do-token=*)
            IN_DO_TOKEN=$(cut -s -d '=' -f 2 <<<"$1")
            shift
            ;;
        --aws-access-key=*)
            IN_AWS_ACCESS_KEY=$(cut -s -d '=' -f 2 <<<"$1")
            shift
            ;;
        --aws-secret-key=*)
            IN_AWS_SECRET_TOKEN=$(cut -s -d '=' -f 2 <<<"$1")
            shift
            ;;
        *)  # add to list of args
            IN_NODES+=( "$ARG" )
            shift
            ;;
    esac
done

# make sure required args are fulfilled
if [[ -z "$IN_KAM_VIP" ]] && [[ -z "$IN_CIDR_NETMASK" ]]; then
    echo 'Kamailio virtual IP or CIDR network is required'
    echo "For usage information run: $0 --help"
    exit 1
fi

if (( ${#IN_NODES[@]} < 2 )); then
    echo "At least 2 nodes are required to setup kam cluster"
    echo "For usage information run: $0 --help"
    exit 1
fi

# start debugging if requested
if (( ${IN_DEBUG:-0} == 1 )); then
    set -x
fi

#======================================================================================
# setup the environment we will use on remote nodes
#======================================================================================

# export current environment (will be used later)
INITIAL_ENV_FILE=$(mktemp)
DIRTY_ENV_FILE=$(mktemp)
CLEAN_ENV_FILE=$(mktemp)
declare -p >"$INITIAL_ENV_FILE"

# trap exit signals to remove environment files no matter how the script exits
cleanupHandler() {
    printdbg 'cleaning up temp files onn all hosts prior to exit'
    # local files
    rm -f "$INITIAL_ENV_FILE" "$DIRTY_ENV_FILE" "$CLEAN_ENV_FILE" 2>/dev/null
    # remote files
    if (( ${#SSH_CMD_LIST[@]} > 0 )); then
        for i in $(seq 0 $((${#NODES[@]}-1))); do
            ${SSH_CMD_LIST[$i]} ${USERHOST_LIST[$i]} "rm -f $CLEAN_ENV_FILE"
        done
    fi
    # reset signals
    trap - EXIT SIGHUP SIGINT SIGQUIT SIGTERM
}
trap 'cleanupHandler $?' EXIT SIGHUP SIGINT SIGQUIT SIGTERM

# set project root, if in a git repo resolve top level dir
PROJECT_ROOT=${PROJECT_ROOT:-$(dirname $(dirname $(dirname $(readlink -f "$0"))))}
# import shared library functions
source ${PROJECT_ROOT}/HA/shared_lib.sh

# node configuration settings
PACEMAKER_TCP_PORTS=(2224 3121 5403 21064)
PACEMAKER_UDP_PORTS=(5404 5405)
CLUSTER_NAME="kamcluster"
CLUSTER_PASS="$(createPass)"
RESOURCE_STARTUP_TIMEOUT=30
CLUSTER_OPTIONS=(transport udpu link bindnetaddr=0.0.0.0 broadcast=1)
KAM_VIP="$IN_KAM_VIP"
CIDR_NETMASK=${IN_CIDR_NETMASK:-32}
DSIP_SYSTEM_CONFIG_DIR="/etc/dsiprouter"
STATIC_NETWORKING_MODE=1
RETRY_CLUSTER_START=3
RETRY_SSH_CONNECT=3 # TODO: implement this
PKG_MGR_TIMEOUT=300

# global variables used throughout script
NODES=( ${IN_NODES[@]} )
DEBUG=${IN_DEBUG:-0}
SSH_KEY_FILE="$IN_SSH_KEY_FILE"
DO_TOKEN="$IN_DO_TOKEN"
AWS_ACCESS_KEY="$IN_AWS_ACCESS_KEY"
AWS_SECRET_TOKEN="$IN_AWS_SECRET_TOKEN"
NODE_NAMES=()
HOST_LIST=()
USERHOST_LIST=()
CLUSTER_NODE_ADDRS=()
declare -A CLOUD_DICT
CLOUD_PLATFORM=""
CLUSTER_RESOURCES=()
SSH_CMD_LIST=()
RSYNC_CMD_LIST=()

# install local requirements for script
if ! cmdExists 'ssh' || ! cmdExists 'sshpass' || ! cmdExists 'nmap' || ! cmdExists 'sed' || ! cmdExists 'awk' || ! cmdExists 'comm'; then
    printdbg 'Installing local requirements for cluster install'

    if cmdExists 'apt-get'; then
        runas apt-get install -y openssh-client sshpass nmap sed gawk rsync coreutils
    elif cmdExists 'dnf'; then
        runas dnf install -y openssh-clients sshpass nmap sed gawk rsync coreutils
    elif cmdExists 'yum'; then
        runas yum install --enablerepo=epel -y openssh-clients sshpass nmap sed gawk rsync coreutils
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

# go back and find VIP if subnet given (nmap required)
if [[ -z "$KAM_VIP" ]] && [[ -n "$IN_CIDR_FULL" ]]; then
    KAM_VIP=$(findAvailableIP "$IN_CIDR_FULL")
    if [[ -z "$KAM_VIP" ]]; then
        printerr "Could not available IP to use as the VIP in subnet '$CIDR_NETMASK'"
        exit 1
    fi
fi

# find the first private IP address (reverse order) on a physical interface
# this is typically the secondary interface or secondary IP on the primary interface
# if no RFC1918 address is found use the IP associated with the default route
# NOTE: sourced here to allow easier declaration on remote node
source <(
    cat <<EOF
    getPacemakerInternalIP() {
        $(declare -f getPhysicalIfaces)
        $(declare -f ipv4TestRFC1918)
        $(declare -f getInternalIP)
EOF
    cat <<'EOF'
        for IP in $(
            for IFACE in $(getPhysicalIfaces | sort -r); do
                ip -4 -o addr show $IFACE | awk '{split($4,a,"/"); print a[1];}'
            done
        ); do
            if ipv4TestRFC1918 "$IP"; then
                echo -n "$IP"
                return 0
            fi
        done
        IP="$(getInternalIP)"
        [[ -n "$IP" ]] && {
            echo -n "$IP"
            return 0
        }
        return 1
    }
EOF
)

#======================================================================================
# validate connections / prepare commands for main logic
#======================================================================================

i=0
for NODE in ${NODES[@]}; do
    SSH_OPTS=( ${DEFAULT_SSH_OPTS[@]} )
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
    if ! checkSshRunas ${SSH_CMD} ${SSH_OPTS[@]} ${USERHOST_LIST[$i]}; then
        printerr "User [${USERHOST_LIST[$i]}] does not have sufficient privileges"
        printwarn 'Ensure the user can escalate to root via sudo or su'
        exit 1
    fi

    # wrap up some args / options
    SSH_CMD_LIST+=( "${SSH_CMD} ${SSH_OPTS[*]}" )
    RSYNC_CMD_LIST+=( "${RSYNC_CMD} ${RSYNC_OPTS[*]}" )

    # install requirements for the following commands (can not be copied as a script to remote node)
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
        $(typeset -f runas)

        printdbg 'installing requirements'
        # awk is required for getInternalIP()
        # curl is required for getCloudPlatform()
        # rsync is required to for the main script
        if cmdExists 'apt-get'; then
            runas apt-get -o DPkg::Lock::Timeout=$PKG_MGR_TIMEOUT install -y gawk curl rsync
        elif cmdExists 'dnf'; then
            runas dnf install -y gawk curl rsync
        elif cmdExists 'yum'; then
            runas yum install -y gawk curl rsync
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
    [[ -n "$CLOUD_PLATFORM" ]] && CLOUD_DICT[$CLOUD_PLATFORM]=1

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
elif [[ "$CLOUD_PLATFORM" == "AWS" ]] && [[ -z "$AWS_ACCESS_KEY" || -z "$AWS_SECRET_TOKEN" ]]; then
    printerr '--aws-access-key and --aws-secret-key are required when deploying on amazon web services'
    exit 1
fi

#======================================================================================
# stage1: install requirements and start configuring individual nodes
#======================================================================================

printdbg 'configuring servers for cluster deployment'
i=0
while (( $i < ${#NODES[@]} )); do
    # copy over any files needed for the install
    printdbg "Copying configuration files to ${HOST_LIST[$i]}"
    if [[ -n "$CLOUD_PLATFORM" ]]; then
        ${RSYNC_CMD_LIST[$i]} --rsh="ssh ${SSH_OPTS[*]} -o IPQoS=throughput" -a ${PROJECT_ROOT}/HA/pacemaker/${CLOUD_PLATFORM}/ ${USERHOST_LIST[$i]}:/tmp/cloud/ 2>&1 &&
        ${RSYNC_CMD_LIST[$i]} --rsh="ssh ${SSH_OPTS[*]} -o IPQoS=throughput" -a ${PROJECT_ROOT}/HA/pacemaker/scripts/ ${USERHOST_LIST[$i]}:/tmp/scripts/ 2>&1
        if (( $? != 0 )); then
            printerr "Copying configuration files to ${HOST_LIST[$i]} failed"
            exit 1
        fi
    fi
    # the runtime environment we will use on the remote node needs cleaned and copied over
    declare -p >"$DIRTY_ENV_FILE"
    (
        comm -3 <(sort "$INITIAL_ENV_FILE") <(sort "$DIRTY_ENV_FILE")
        declare -f
    ) >"$CLEAN_ENV_FILE"
    ${RSYNC_CMD_LIST[$i]} --rsh="ssh ${SSH_OPTS[*]} -o IPQoS=throughput" "$CLEAN_ENV_FILE" "${USERHOST_LIST[$i]}:${CLEAN_ENV_FILE}" 2>&1
    if (( $? != 0 )); then
        printerr "Copying runtime environment file to ${HOST_LIST[$i]} failed"
        exit 1
    fi

    # run commands through ssh
    ${SSH_CMD_LIST[$i]} ${USERHOST_LIST[$i]} "bash /tmp/scripts/stage1.sh ${CLEAN_ENV_FILE}" 2>&1

    if (( $? != 0 )); then
        printerr "server configuration failed on ${HOST_LIST[$i]}"
        exit 1
    fi

    i=$((i+1))
done

#======================================================================================
# stage2: configure pacemaker settings on each node
#======================================================================================

printdbg 'initializing pacemaker cluster'
i=0
while (( $i < ${#NODES[@]} )); do
    # run commands through ssh
    ${SSH_CMD_LIST[$i]} ${USERHOST_LIST[$i]} "bash /tmp/scripts/stage2.sh ${CLEAN_ENV_FILE}" 2>&1

    if (( $? != 0 )); then
        printerr "initializing pacemaker cluster failed on ${HOST_LIST[$i]}"
        exit 1
    fi

    i=$((i+1))
done

#======================================================================================
# stage3: configure the pacemaker cluster and resources
#======================================================================================

# creates and configures the cluster
# TODO: add support for updating virtual IP from various cloud providers
printdbg 'configuring pacemaker cluster'
i=0
while (( $i < ${#NODES[@]} )); do
    # run commands through ssh
    ${SSH_CMD_LIST[$i]} ${USERHOST_LIST[$i]} "bash /tmp/scripts/stage3.sh ${CLEAN_ENV_FILE}" 2>&1

    if (( $? != 0 )); then
        printerr "pacemaker cluster configuration failed on ${HOST_LIST[$i]}"
        exit 1
    fi

    i=$((i+1))
done

printdbg 'Successfully configured pacemaker cluster'
exit 0
