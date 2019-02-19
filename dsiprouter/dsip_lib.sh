#!/usr/bin/env bash
#set -x

# NOTES:
# contains utility functions and shared variables
# should be sourced by an external script

# returns: 0 == success, 1 == failure
install_mysql_community() {
    mkdir -p /usr/src/mysql
    cd /usr/src/mysql

    # centos 7
    if [[ "$DISTRO" == "centos" ]]; then
        # download mysql community v8
        wget https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-community-common-8.0.12-1.el7.x86_64.rpm &&
        wget https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-community-client-8.0.12-1.el7.x86_64.rpm &&
        wget https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-community-devel-8.0.12-1.el7.x86_64.rpm &&
        wget https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-community-libs-8.0.12-1.el7.x86_64.rpm &&
        wget https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-community-libs-compat-8.0.12-1.el7.x86_64.rpm &&
        wget https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-community-server-8.0.12-1.el7.x86_64.rpm

        # install mysql community v8
        rpm -ivh mysql*common*.rpm &&
        rpm -ivh mysql*client*.rpm &&
        rpm -ivh mysql*devel*.rpm &&
        rpm -ivh mysql*libs*.rpm &&
        rpm -ivh mysql*libs-compat*.rpm &&
        rpm -ivh mysql*server*.rpm

    # debian 9
    elif [[ "$DISTRO" == "debian" ]]; then
        # download mysql community v8

        wget https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-common_8.0.12-1debian9_amd64.deb &&
        wget https://dev.mysql.com/get/Downloads/MySQL-8.0/libmysqlclient21_8.0.12-1debian9_amd64.deb &&
        wget https://dev.mysql.com/get/Downloads/MySQL-8.0/libmysqlclient-dev_8.0.12-1debian9_amd64.deb &&
        wget https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-community-client-core_8.0.12-1debian9_amd64.deb &&
        wget https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-community-client_8.0.12-1debian9_amd64.deb &&
        wget https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-community-server-core_8.0.12-1debian9_amd64.deb &&
        wget https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-community-server_8.0.12-1debian9_amd64.deb

        # install mysql community v8
        dpkg -i mysql*common*.deb &&
        dpkg -i mysql*libmysqlclient*.deb &&
        dpkg -i mysql*client*.deb &&
        dpkg -i mysql*server*.deb

    else
        return 1
    fi

    # start mysql without password checking
    systemctl stop mysqld 2>/dev/null
    systemctl set-environment MYSQLD_OPTS="--skip-grant-tables" &&
    systemctl start mysqld

    # set default password to nothing
    mysql --user='root' mysql -e \
        "FLUSH PRIVILEGES; " \
        "UNINSTALL COMPONENT 'file://component_validate_password'; " \
        "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY ''; " \
        "FLUSH PRIVILEGES; " \
        "INSTALL COMPONENT 'file://component_validate_password'; "

    # restart mysql normally
    systemctl restart mysqld

    return 0
}

# $1 == attribute name
# $2 == attribute value
# $3 == python config file
# $4 == whether to 'quote' value (use for strings)
setConfigAttrib() {
    local NAME="$1"
    local VALUE="$2"
    local CONFIG_FILE="$3"

    if (( $# >= 4 )); then
        VALUE="'${VALUE}'"
    fi
    sed -i -r -e "s|($NAME[[:space:]]?=[[:space:]]?.*)|$NAME = $VALUE|g" ${CONFIG_FILE}
}

# $1 == attribute name
# $2 == python config file
# returns: attribute value
getConfigAttrib() {
    local NAME="$1"
    local CONFIG_FILE="$2"

    local VALUE=$(grep -oP '^(?!#)(?:'${NAME}')[ \t]*=[ \t]*\K(?:\w+\(.*\)[ \t\v]*$|[\w\d\.]+[ \t]*$|\{.*\}|\[.*\][ \t]*$|\(.*\)[ \t]*$|""".*"""[ \t]*$|'"'''.*'''"'[ \v]*$|".*"[ \t]*$|'"'.*'"')' ${CONFIG_FILE})
    printf "$VALUE" | sed -r -e "s/^'+(.+?)'+$/\1/g" -e 's/^"+(.+?)"+$/\1/g'
}

# $1 == attribute name
# $2 == kamailio config file
enableKamailioConfigAttrib() {
    local NAME="$1"
    local CONFIG_FILE="$2"

    sed -i -r -e "s/#+(!(define|trydef|redefine)[[:space:]]? $NAME)/#\1/g" ${CONFIG_FILE}
}

# $1 == attribute name
# $2 == kamailio config file
disableKamailioConfigAttrib() {
    local NAME="$1"
    local CONFIG_FILE="$2"

    sed -i -r -e "s/#+(!(define|trydef|redefine)[[:space:]]? $NAME)/##\1/g" ${CONFIG_FILE}
}

# $1 == name of ip to change
# $2 == value to change ip to
# $3 == kamailio config file
setKamailioConfigIP() {
    local NAME="$1"
    local VALUE="$2"
    local CONFIG_FILE="$3"

    sed -i -r -e "s|(#!substdef.*!$NAME!).*(!.*)|\1$VALUE\2|g" ${CONFIG_FILE}
}

# $1 == attribute name
# $2 == value of attribute
# $3 == rtpengine config file
setRtpengineConfigAttrib() {
    local NAME="$1"
    local VALUE="$2"
    local CONFIG_FILE="$3"

    sed -i -r -e "s|($NAME[[:space:]]?=[[:space:]]?.*)|$NAME = $VALUE|g" ${CONFIG_FILE}
}

# Install Sipsak
# Used for testing and troubleshooting
installSipsak() {
    local START_DIR="$(pwd)"
    local SRC_DIR="/usr/local/src"

	git clone https://github.com/nils-ohlmeier/sipsak.git ${SRC_DIR}/sipsak

	cd ${SRC_DIR}/sipsak
	autoreconf --install
	./configure
	make
	make install
	ret=$?

	if [ $ret -eq 0 ]; then
		echo "SipSak was installed"
	else
		echo "SipSak install failed"
	fi

	cd ${START_DIR}
}

# Remove Sipsak from the machine completely
uninstallSipsak() {
    local START_DIR="$(pwd)"
    local SRC_DIR="/usr/local/src"

	if [ -d ${SRC_DIR}/sipsak ]; then
		cd ${SRC_DIR}/sipsak
		make uninstall
		rm -rf ${SRC_DIR}/sipsak
	fi

	cd ${START_DIR}
}

# $1 == command to test
# returns: 0 == true, 1 == false
cmdExists() {
    if command -v "$1" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# $1 == directory to check for in PATH
# returns: 0 == found, 1 == not found
pathCheck() {
    case ":${PATH-}:" in
        *:"$1":*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# returns: AMI instance ID || blank string
getInstanceID() {
    curl http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null ||
    ec2-metadata -i 2>/dev/null
}

# $1 == crontab entry to append
cronAppend() {
    local ENTRY="$1"
    crontab -l | { cat; echo "$ENTRY"; } | crontab -
}

# $1 == crontab entry to remove
cronRemove() {
    local ENTRY="$1"
    crontab -l | grep -v -F -w "$ENTRY" | crontab -
}
