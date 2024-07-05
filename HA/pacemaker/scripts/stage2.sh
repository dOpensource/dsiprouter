#!/bin/bash

# import runtime environment
if ! [[ -f "$1" ]] || ! source "$1"; then
   echo "Could not import runtime environment"
   exit 1
fi

if (( ${DEBUG:-0} == 1 )); then
    set -x
fi

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

PCS_MAJMIN_VER=$(pcs --version | cut -d '.' -f -2 | tr -d '.')

printdbg 'authenticating hacluster user to pcsd'
runas -u hacluster pcs client local-auth -u hacluster -p ${CLUSTER_PASS}

if (( $((10#$PCS_MAJMIN_VER)) >= 10 )); then
    printdbg 'authenticating nodes to pcsd'
    runas pcs host auth -u hacluster -p ${CLUSTER_PASS} ${NODE_NAMES[@]} || {
        printerr "Cluster auth failed"
        exit 1
    }

    if (( $i == ${#NODES[@]} - 1 )); then
        printdbg 'creating the cluster'
        runas pcs cluster setup --force --enable ${CLUSTER_NAME} ${NODE_NAMES[@]} ${CLUSTER_OPTIONS[@]} || {
            printerr "Cluster creation failed"
            exit 1
        }
    fi
else
    printdbg 'authenticating nodes to pcsd'
    runas pcs cluster auth --force -u hacluster -p ${CLUSTER_PASS} ${NODE_NAMES[@]} || {
        printerr "Cluster auth failed"
        exit 1
    }

    if (( $i == ${#NODES[@]} - 1 )); then
        printdbg 'creating the cluster'
        runas pcs cluster setup --force --enable --name ${CLUSTER_NAME} ${NODE_NAMES[@]} ${CLUSTER_OPTIONS[@]} || {
            printerr "Cluster creation failed"
            exit 1
        }
    fi
fi

# start cluster on the last node after all auth is completed
if (( $i == ${#NODES[@]} - 1 )); then
    j=0
    while (( $j < $RETRY_CLUSTER_START )); do
        runas pcs cluster start --all --request-timeout=15 --wait=15 &&
            break
        j=$((j+1))
    done
    # if we attempted all retries and finished the above loop we failed
    if (( $j == $RETRY_CLUSTER_START )); then
        printerr "Starting cluster failed"
        exit 1
    fi
fi

# setup any cloud provider specific configurations
case "$CLOUD_PLATFORM" in
    DO)
        runas cp -f /tmp/cloud/assign-ip /usr/local/bin/assign-ip
        runas chmod +x /usr/local/bin/assign-ip
        runas mkdir -p /usr/lib/ocf/resource.d/digitalocean
        runas cp -f /tmp/cloud/ocf-floatip /usr/lib/ocf/resource.d/digitalocean/floatip
        runas chmod +x /usr/lib/ocf/resource.d/digitalocean/floatip
        ;;
    AWS)
        if ! cmdExists 'aws'; then
            cd /tmp &&
            curl 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' -o awscli.zip &&
            unzip -qo awscli.zip &&
            rm -f awscli.zip &&
            runas ./aws/install -b /usr/bin
        fi

        AWS_REGION=$(awsGetCurrentRegion) || {
            printerr "Could not determine current AWS region"
            exit 1
        }
        runas aws configure set aws_access_key_id $AWS_ACCESS_KEY
        runas aws configure set aws_secret_access_key $AWS_SECRET_TOKEN
        runas aws configure set region $AWS_REGION

        runas mkdir -p /usr/lib/ocf/resource.d/aws
        runas cp -f /tmp/cloud/ocf-floatip /usr/lib/ocf/resource.d/aws/floatip
        runas chmod +x /usr/lib/ocf/resource.d/aws/floatip
        ;;
esac

exit 0