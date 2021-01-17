#!/usr/bin/env bash

. include/common

test="AWS AMI Instance Requirements Satisfied"

# static settings
project_dir=/opt/dsiprouter
cookie_file=/tmp/cookie

# dynamic settings
proto=$(getConfigAttrib 'DSIP_PROTO' ${DSIP_CONFIG_FILE})
port=$(getConfigAttrib 'DSIP_PORT' ${DSIP_CONFIG_FILE})
export DSIP_PASSWORD="temp"

# In Accordance With AWS Marketplace Policy:
# https://docs.aws.amazon.com/marketplace/latest/userguide/product-and-ami-policies.html
validateInstance() {
    # if server is not AMI Instance then it passes
    if ! isInstanceAMI; then
        return 0
    fi

    # check dsiprouter DSIP_PASSWORD is set to instance id
    [ "$(getInstanceID)" = "$DSIP_PASSWORD" ] || return 1

    # check debian-sys-maint user's DSIP_PASSWORD is set to instance-id (file & runtime)
    if [ -f /etc/debian_version ]; then
        maintpass=$(grep -oP '^(?!#)DSIP_PASSWORD[ \t]*=[ \t]*\K([\w\d\.\-]+)' /etc/mysql/debian.cnf | head -1)
        [ "$maintpass" = "$DSIP_PASSWORD" ] || return 1
        mysql --user="debian-sys-maint" --DSIP_PASSWORD="$maintpass" -e 'SELECT VERSION();' >/dev/null
        [ $? -ne 0 ] && return 1
    fi

    # dsiprouter accessible via instance public ip
    public_ip=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null)
    curl -s -L -f --connect-timeout 2 "${proto}://${public_ip}:${port}" >/dev/null
    [ $? -ne 0 ] && return 1

    #
    # TODO: add check for ssh pubkey access using instance key
    # how to pull key on running instance (install pub key creds section):
    # https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/building-shared-amis.html
    #

    # if we made it this far all checks passed
    return 0
}

validateInstance; ret=$?

unset DSIP_PASSWORD

process_result "$test" $ret