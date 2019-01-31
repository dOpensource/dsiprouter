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
# $3 == whether to 'quote' value (use for strings)
setConfigAttrib() {
    local NAME="$1"
    local VALUE="$2"

    if (( $# >= 3 )); then
        VALUE="'${VALUE}'"
    fi
    sed -i -r -e "s|($NAME[[:space:]]?=.*)|$NAME = $VALUE|g" ${DSIP_CONFIG_FILE}
}

# $1 == attribute name
# returns: attribute value
getConfigAttrib() {
    local NAME="$1"

    local VALUE=$(grep -oP '^(?!#)(?:'${NAME}')[ \t]*=[ \t]*\K(?:\w+\(.*\)[ \t\v]*$|[\w\d\.]+[ \t]*$|\{.*\}|\[.*\][ \t]*$|\(.*\)[ \t]*$|""".*"""[ \t]*$|'"'''.*'''"'[ \v]*$|".*"[ \t]*$|'"'.*'"')' ${DSIP_CONFIG_FILE})
    printf "$VALUE" | sed -r -e "s/^'+(.+?)'+$/\1/g" -e 's/^"+(.+?)"+$/\1/g'
}

# Install Sipsak
# Used for testing and troubleshooting
install_Sipsak() {
	
	git clone https://github.com/nils-ohlmeier/sipsak.git /usr/src/sipsak

	cd /usr/src/sipsak
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


}

# Remove Sipsak from the machine completely
uninstall_Sipsak() {

	if [ -d /usr/src/sipsak ]; then
		cd /usr/src/sipsak
		make uninstall
		rm -rf /usr/src/sipsak
	fi

}

