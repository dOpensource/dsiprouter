#!/usr/bin/env bash
#
# Summary: Utility functions for managing cluster nodes
# Summary: Program should be run locally on desired node
# TODO:    panic() and kill() and startup() need ssh cmds w/ key setup
#          to execute on remote node, only work locally now

LOG_FILE="/var/log/nodeutil.log"

# defaults to current node
NODE_NAME=$(sudo -u hacluster crm_node -n)

standby() {
    sudo -u hacluster pcs cluster standby ${1:-$NODE_NAME}
    log_status "standby()"
}

unstandby() {
    sudo -u hacluster pcs cluster unstandby ${1:-$NODE_NAME}
    log_status "unstandby()"
}

stop() {
    sudo -u hacluster pcs cluster stop ${1:-$NODE_NAME}
    log_status "stop()"
}

start() {
    sudo -u hacluster pcs cluster start ${1:-$NODE_NAME}
    log_status "start()"
}

restart() {
    sudo -u hacluster pcs cluster stop ${1:-$NODE_NAME}
    sleep 2
    sudo -u hacluster pcs cluster start ${1:-$NODE_NAME}
    log_status "restart()"
}

startup() {
    sudo systemctl start pacemaker
    sudo systemctl start corosync
    log_status "startup()"
}

panic() {
    echo c | sudo tee /proc/sysrq-trigger
    sudo systemctl stop pacemaker
    sudo systemctl stop corosync
    log_status "panic()"
}

kill() {
    sudo pkill -9 pacemaker
    sudo pkill -9 corosync
    sudo shutdown -h now
    log_status "kill()"
}

start_cluster() {
    sudo -u hacluster pcs cluster start --all
    log_status "start_cluster()"
}

restart_cluster() {
    sudo -u hacluster pcs cluster stop --all
    sleep 5
    sudo -u hacluster pcs cluster start --all
    sleep 2
    log_status "restart_cluster()"
}

stop_cluster() {
    sudo -u hacluster pcs cluster stop --all
    log_status "stop_cluster()"
}

# $1 == resource name
# returns: 0 == success, else == failure
find_resource() {
    (
        sudo -u hacluster pcs status resources | grep "$1" | awk '{print $NF}'
        exit ${PIPESTATUS[0]}
    ) 2>/dev/null
    return $?
}

# $1 == name of command to log
log_status() {
    printf '#===== log_status entry: %s =====#\n' "$(date)" >> ${LOG_FILE}
    printf 'current executing function: %s\n' "$1" >> ${LOG_FILE}
    {
        sudo -u hacluster pcs status
        printf '--------------------\n'
        sudo -u hacluster corosync-cfgtool -s
    } 2>&1 >> ${LOG_FILE}
    printf '#===== end of log entry =====#\n\n' >> ${LOG_FILE}
}

show_status() {
    sudo -u hacluster corosync-cfgtool -s
    sudo -u hacluster pcs status --full
}

### arg parsing ###
cmd=""  # Default none

HELP() {
    echo "Usage: "
    echo "nodeutil -h                    Display this help message."
    echo "nodeutil -t|--target <target>  Specify a specific node as target."
    echo "nodeutil -c|--cmd <cmd>        Specify <cmd> from list of cmds to run."
    echo "Available <cmd> options:"
    echo "standby, unstandby, stop, start, panic, start_cluster, restart_cluster, stop_cluster"
}

#Check the number of arguments. If none are passed, print help and exit
options=$(getopt -o hc:t: -l cmd:,target: -n nodeutil -- "$@")
if [ $? -ne 0 ]; then
	HELP
	exit 1
fi

### parse options ###
eval set -- "$options"
while true; do
    OPT="$1"
    case "$OPT" in
        -h)                 # Show help option menu
            shift
            HELP
            exit 1
            ;;
        -t|--target)        # Grab the target node name
            shift
            NODE_NAME="$1"
            shift
            ;;
        -c|--cmd)           # Grab the cmd to execute
            shift
            cmd="$1"
            shift

            case $cmd in
                standby|unstandby|stop|start|restart|startup|panic|start_cluster|restart_cluster|stop_cluster|find_resource|show_status)
                    $cmd "$@"
                    ;;
                *)
                    HELP && exit 1
                    ;;
            esac
            ;;
        --)
            shift
            break
            ;;
	  esac
done

exit 0
