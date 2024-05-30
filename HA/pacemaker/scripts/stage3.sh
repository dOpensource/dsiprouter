#!/bin/bash

# import runtime environment
if ! [[ -f "$1" ]] || ! source "$1"; then
   echo "Could not import runtime environment"
   exit 1
fi

if (( ${DEBUG:-0} == 1 )); then
    set -x
fi

# $1 == resource name
# returns: 0 == success, else == failure
# notes: prints node name where resource is found
findResource() {
    local RESOURCE_FIND_TIMEOUT=5
    local NODE

    timeout "$RESOURCE_FIND_TIMEOUT" bash <<EOF 2>/dev/null
while true; do
    NODE=\$(
        runas -u hacluster pcs status resources |
        awk '\$2=="'$1'" && \$4=="Started" {print \$5}'
    )
    if [[ -n "\$NODE" ]]; then
        echo "\$NODE"
        break
    fi
    sleep 1
done
EOF
    return $?
}

# output: prints numbers of pacemaker resources that are down
getNumResourcesDown() {
    runas -u hacluster pcs status resources |
    grep -v -F 'Resource Group' |
    awk '$4!="Started" {print $2}' |
    wc -l
}

# $1 == timeout
# returns: 0 == resources up within timeout, else == resources not up within timeout
# notes: block while waiting for resources to come online until timeout
waitResources() {
    timeout "$1" bash <<'EOF' 2>/dev/null
RESOURCES_DOWN=$(getNumResourcesDown)
while (( $RESOURCES_DOWN > 0 )); do
    sleep 1
    RESOURCES_DOWN=$(getNumResourcesDown)
done
EOF
    return $?
}

# notes: prints out detailed info about cluster
showClusterStatus() {
    runas -u hacluster corosync-cfgtool -s
    runas -u hacluster pcs status --full
}

## Pacemaker / Corosync cluster
if (( $i == 0 )); then
    printdbg 'configuring pacemaker cluster'

    # disabling stonith/quorum for now because it has caused issues in the past (on first node)
    runas pcs property set stonith-enabled=false
    runas pcs property set no-quorum-policy=ignore

    printdbg 'Setting up the virtual ip address resource'
    # create resource for services and virtual ip and default route (on first node)
    case "$CLOUD_PLATFORM" in
        DO)
            runas pcs resource create cluster_vip ocf:digitalocean:floatip \
                do_token=${DO_TOKEN} floating_ip=${KAM_VIP} \
                op monitor interval=15s timeout=15s \
                op start interval=0 timeout=30s \
                meta resource-stickiness=100 \
                --group vip_group
            ;;
        AWS)
            runas pcs resource create cluster_vip ocf:aws:floatip \
                elastic_ip=${KAM_VIP} \
                op monitor interval=15s timeout=15s \
                op start interval=0 timeout=30s \
                meta resource-stickiness=100 \
                --group vip_group
            ;;
        *)
            runas pcs resource create cluster_vip ocf:heartbeat:IPaddr2 \
                ip=${KAM_VIP} cidr_netmask=${CIDR_NETMASK} \
                op monitor interval=15s timeout=15s \
                op start interval=0 timeout=30s \
                meta resource-stickiness=100 \
                --group vip_group
            runas pcs resource create cluster_srcaddr ocf:heartbeat:IPsrcaddr \
                ipaddress=${KAM_VIP} cidr_netmask=${CIDR_NETMASK} \
                op monitor interval=15s timeout=15s \
                op start interval=0 timeout=30s \
                meta resource-stickiness=100 \
                --group vip_group
            ;;
    esac

    printdbg 'Setting up resources for dsiprouter services'
    if grep -q 'rtpengine_service' 2>/dev/null <<<"${CLUSTER_RESOURCES[@]}"; then
        runas pcs resource create rtpengine_service systemd:rtpengine \
            op monitor interval=30s timeout=15s \
            op start interval=0 timeout=30s on-fail=restart \
            op stop interval=0 timeout=30s \
            meta resource-stickiness=100 \
            --group dsip_group
    fi
    if grep -q 'kamailio_service' 2>/dev/null <<<"${CLUSTER_RESOURCES[@]}"; then
        runas pcs resource create kamailio_service systemd:kamailio \
            op monitor interval=30s timeout=15s \
            op start interval=0 timeout=30s on-fail=restart \
            op stop interval=0 timeout=30s \
            meta resource-stickiness=100 \
            --group dsip_group
    fi
    if grep -q 'dsiprouter_service' 2>/dev/null <<<"${CLUSTER_RESOURCES[@]}"; then
        runas pcs resource create dsiprouter_service systemd:dsiprouter \
            op monitor interval=60s timeout=15s \
            op start interval=0 timeout=30s on-fail=restart \
            op stop interval=0 timeout=30s \
            meta resource-stickiness=100 \
            --group dsip_group
    fi

    printdbg 'colocating resources on the same node'
    runas pcs constraint colocation set vip_group dsip_group \
        sequential=true \
        setoptions score=INFINITY
    runas pcs constraint order set vip_group dsip_group \
        action=start sequential=true require-all=true \
        setoptions symmetrical=false kind=Mandatory
fi

if (( $i == ${#NODES[@]} - 1 )); then
    printdbg 'testing cluster'

    PCS_MAJMIN_VER=$(pcs --version | cut -d '.' -f -2 | tr -d '.')

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
    for RESOURCE in ${RESOURCES[@]}; do
        PREVIOUS_RESOURCE_LOCATIONS+=( $(findResource ${RESOURCE}) )
    done

    printdbg "current resource locations: ${PREVIOUS_RESOURCE_LOCATIONS[@]}"
    printdbg "setting ${PREVIOUS_RESOURCE_LOCATIONS[0]} to standby"

    if (( $((10#$PCS_MAJMIN_VER)) >= 10 )); then
        runas -u hacluster pcs node standby ${PREVIOUS_RESOURCE_LOCATIONS[0]}
    else
        runas -u hacluster pcs cluster standby ${PREVIOUS_RESOURCE_LOCATIONS[0]}
    fi

    # wait for transfer to finish (to another node)
    waitResources ${RESOURCE_STARTUP_TIMEOUT} || {
        printerr "Cluster resources failed to start within ${RESOURCE_STARTUP_TIMEOUT} seconds"
        exit 1
    }

    for RESOURCE in ${RESOURCES[@]}; do
        CURRENT_RESOURCE_LOCATIONS+=( $(findResource ${RESOURCE}) )
    done

    printdbg "current resource locations: ${CURRENT_RESOURCE_LOCATIONS[@]}"
    printdbg "resetting ${PREVIOUS_RESOURCE_LOCATIONS[0]}"

    if (( $(pcs --version | cut -d '.' -f 2- | tr -d '.') >= 100 )); then
        runas -u hacluster pcs node unstandby ${PREVIOUS_RESOURCE_LOCATIONS[0]}
    else
        runas -u hacluster pcs cluster unstandby ${PREVIOUS_RESOURCE_LOCATIONS[0]}
    fi

    # wait for transfer to finish (to another node, could be original)
    waitResources ${RESOURCE_STARTUP_TIMEOUT} || {
        printerr "Cluster resources failed to start within ${RESOURCE_STARTUP_TIMEOUT} seconds"
        exit 1
    }

    # run tests to make sure operations worked
    i=0
    while (( $i < ${#RESOURCES[@]} )); do
        if [[ ${PREVIOUS_RESOURCE_LOCATIONS[$i]} != ${PREVIOUS_RESOURCE_LOCATIONS[$((i+1))]:-${PREVIOUS_RESOURCE_LOCATIONS[0]}} ]]; then
            printerr "Cluster resource colocation tests failed (before migration)"
            exit 1
        fi

        if [[ ${CURRENT_RESOURCE_LOCATIONS[$i]} != ${CURRENT_RESOURCE_LOCATIONS[$((i+1))]:-${CURRENT_RESOURCE_LOCATIONS[0]}} ]]; then
            printerr "Cluster resource colocation tests failed (after migration)"
            exit 1
        fi

        if [[ ${PREVIOUS_RESOURCE_LOCATIONS[$i]} == ${CURRENT_RESOURCE_LOCATIONS[$i]} ]]; then
            printerr "Cluster resource ${RESOURCE} failover tests failed"
            exit 1
        fi

        i=$((i+1))
    done

    printdbg 'Any non-critical resource errors are shown below:'
    runas -u hacluster pcs resource failcount show
    printdbg 'Clearing any non-critical resource errors'
    runas -u hacluster -n pcs resource cleanup

    # show status to user
    printdbg 'cluster info:'
    showClusterStatus
fi

exit 0