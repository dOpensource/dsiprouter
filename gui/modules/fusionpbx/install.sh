#!/usr/bin/env bash

# Debug this script if in debug mode
(( $DEBUG == 1 )) && set -x

# ENABLED=1 --> install, ENABLED=0 --> do nothing, ENABLED=-1 uninstall
ENABLED=1

# Import dsip_lib utility / shared functions if not already
if [[ "$DSIP_LIB_IMPORTED" != "1" ]]; then
    . ${DSIP_PROJECT_DIR}/dsiprouter/dsip_lib.sh
fi

# TODO: replace docker workflow here by simply adding to default dsiprouter nginx configs
function install {
    local FUSIONPBX_DIR="${DSIP_PROJECT_DIR}/gui/modules/fusionpbx"

    case "$DISTRO" in
        debian|ubuntu)
            apt-get install -y apt-transport-https ca-certificates software-properties-common gnupg lsb-release

            local DEB_ARCH=$(dpkg --print-architecture)
            local DISTRO_CODENAME=$(lsb_release -cs)

            mkdir -p /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/${DISTRO}/gpg | gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
            mkdir -p /etc/apt/sources.list.d
            (cat <<EOF
deb [arch=${DEB_ARCH} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${DISTRO} ${DISTRO_CODENAME} stable
#deb-src [arch=${DEB_ARCH} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${DISTRO} ${DISTRO_CODENAME} stable
EOF
            ) >/etc/apt/sources.list.d/docker.list
            mkdir -p /etc/apt/preferences.d
            (cat <<'EOF'
Package: *
Pin: origin download.docker.com
Pin-Priority: 1000
EOF
            ) >/etc/apt/preferences.d/docker.pref

            apt-get update -y
            apt-get install -y docker-ce

            if (( $? != 0 )); then
                printerr "Failed installing Docker"
                return 1
            fi
            ;;
        amzn)
            yum install -y ca-certificates yum-utils device-mapper-persistent-data lvm2
            amazon-linux-extras enable -y docker >/dev/null
            yum clean -y metadata
            yum install -y docker

            if (( $? != 0 )); then
                printerr "Failed installing Docker"
                return 1
            fi
            ;;
        rhel|almalinux|rocky)
            dnf install -y dnf-utils device-mapper-persistent-data lvm2 ca-certificates
    #        CA_CERT_DIR=$(dirname $(find / -name '*ca-bundle.crt'))
    #        cp -f ${CA_CERT_DIR}/ca-bundle.crt ${CA_CERT_DIR}/ca-bundle.bak
    #        curl http://curl.haxx.se/ca/cacert.pem -o ${CA_CERT_DIR}/ca-bundle.crt
    #        update-ca-trust force-enable
    #        update-ca-trust extract

            dnf remove -y docker\*
            # docker.io does not provide support for x86_64 on rhel/alma/rocky
            # instead we use the centos repo docker.io provides (binary compatible)
            dnf config-manager -y --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            dnf config-manager -y --enable docker-ce-stable
            dnf install -y docker-ce

            if (( $? != 0 )); then
                printerr "Failed installing Docker"
                return 1
            fi
            ;;
        *)
            printerr "Failed installing Docker, OS Distro not supported"
            return 1
            ;;
    esac

    systemctl enable docker.service
    systemctl start docker

    firewall-cmd --permanent --zone=public --add-port=80/tcp
    firewall-cmd --permanent --zone=public --add-port=443/tcp
    firewall-cmd --reload

    # Install Nginx container
    docker create nginx
    #docker run --name docker-nginx -p 80:80  -v ${FUSIONPBX_DIR}/dsiprouter.nginx:/etc/nginx/conf.d/default.conf  -d nginx

    # Install a default self signed certificate for spinning up NGINX
    openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 -subj "/C=US/ST=MI/L=Detroit/O=dopensource.com/CN=dSIPRouter" -keyout ${FUSIONPBX_DIR}/certs/cert.key -out ${FUSIONPBX_DIR}/certs/cert_combined.crt

    cronAppend "*/1 * * * * ${DSIP_PROJECT_DIR}/gui/dsiprouter_cron.py fusionpbx sync"

    printdbg "FusionPBX module installed"
    return 0
}

function uninstall {
	# Forcefully stop all docker containers and remove them
	docker ps -a -q > /dev/null
	if [ $? == 1 ]; then
		docker rm -f $(docker ps -a -q) > /dev/null
		printdbg "Stopped and removed all docker containers"
	else
		printwarn "No docker containers to remove"
	fi

    case "$DISTRO" in
        debian|ubuntu)
            # Can't remove packages because it removes python3-pip package
            #apt-get remove -y \
            #apt-transport-https \
            #ca-certificates
            #software-properties-common

            # Remove Docker Engine
            apt-get remove -y docker-ce

            # remove the docker repo
            rm -f /etc/apt/keyrings/docker.gpg /etc/apt/sources.list.d/docker.list /etc/apt/preferences.d/docker.pref
            apt-get update -y
            ;;
        amzn)
            yum remove -y docker
            amazon-linux-extras disable -y docker >/dev/null
            yum clean -y metadata
            ;;
        rhel|almalinux|rocky)
            #yum remove -y ca-certificates
            #yum remove -y device-mapper-persistent-data lvm2
            yum remove -y docker-ce

            # Remove the repos
            rm -f /etc/yum.repos.d/docker-ce*
            yum clean all
            ;;
    esac

    firewall-cmd --permanent --zone=public --remove-port=80/tcp
    firewall-cmd --permanent --zone=public --remove-port=443/tcp
    firewall-cmd --reload

    rm -f ${FUSIONPBX_DIR}/certs/*{.key/.crt}
    cronRemove 'dsiprouter_cron.py fusionpbx sync'

    printdbg "FusionPBX module uninstalled"
    return 0
}

function main {
    if (( ${ENABLED} == 1 )); then
        install && exit 0 || exit 1
    elif (( ${ENABLED} == -1 )); then
        uninstall && exit 0 || exit 1
    else
        exit 0
    fi
}

main
