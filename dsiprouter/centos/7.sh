#PYTHON_CMD=python3.5
DSIP_KAMAILIO_CONF_DIR=$(pwd)

set -x 


function install {
    # Install dependencies for dSIPRouter
    yum remove -y rs-epel-release*

    yum install -y yum-utils
    yum groupinstall -y development
    yum install -y https://centos7.iuscommunity.org/ius-release.rpm
    yum install -y python36u python36u-libs python36u-devel python36u-pip

    yum install -y mariadb mariadb-libs mariadb-devel mariadb-server
    ln -s /usr/share/mariadb/ /usr/share/mysql
    rm -f ~/.my.cnf
    systemctl start mariadb
    systemctl enable mariadb

    # Setup Firewall for DSIP_PORT
    systemctl start firewalld
    systemctl enable firewalld
    firewall-cmd --zone=public --add-port=${DSIP_PORT}/tcp --permanent
    firewall-cmd --reload

    PIP_CMD="pip"
    $PYTHON_CMD -m ${PIP_CMD} install -r ./gui/requirements.txt
    if [ $? -eq 1 ]; then
            echo "dSIPRouter install failed: Couldn't install required libraries"
            exit 1
    fi

    # Install dSIPRouter as a service
    cp ${DSIP_KAMAILIO_CONF_DIR}/dsiprouter/debian/dsiprouter.service ${DSIP_KAMAILIO_CONF_DIR}/dsiprouter/debian/dsiprouter.service.tmp
    sed -i s+PYTHON_CMD+$PYTHON_CMD+g ${DSIP_KAMAILIO_CONF_DIR}/dsiprouter/debian/dsiprouter.service.tmp
    sed -i s+DSIP_KAMAILIO_CONF_DIR+$DSIP_KAMAILIO_CONF_DIR+g ${DSIP_KAMAILIO_CONF_DIR}/dsiprouter/debian/dsiprouter.service.tmp

    cp  ${DSIP_KAMAILIO_CONF_DIR}/dsiprouter/debian/dsiprouter.service.tmp /lib/systemd/system/dsiprouter.service
    chmod 644 /lib/systemd/system/dsiprouter.service
    systemctl daemon-reload
    systemctl enable dsiprouter.service
}


function uninstall {
    # Uninstall dependencies for dSIPRouter
    yum remove -y python36u python36u-libs python36u-devel python36u-pip
    yum remove -y https://centos7.iuscommunity.org/ius-release.rpm
    yum groupremove -y development

    # backup and remove mysql??
    #systemctl stop mariadb
    #systemctl disable mariadb
    #mysqldump --events --routines --triggers --opt --all-databases > dump_$(date +"%y-%m-%d-%H%M").sql 
    #yum remove -y mariadb mariadb-libs mariadb-devel mariadb-server
    #rm -rf /usr/share/mysql; rm -rf /etc/my.cnf*; rm -f /etc/my.cnf*

    # Remove Firewall for DSIP_PORT
    firewall-cmd --zone=public --remove-port=${DSIP_PORT}/tcp --permanent
    firewall-cmd --reload

    # Remove dSIProuter as a service
    systemctl disable dsiprouter.service
    rm /lib/systemd/system/dsiprouter.service
    systemctl daemon-reload

    PIP_CMD="pip"

    /usr/bin/yes | ${PYTHON_CMD} -m ${PIP_CMD} uninstall -r ./gui/requirements.txt
    if [ $? -eq 1 ]; then
            echo "dSIPRouter uninstall failed or the libraries are already uninstalled"
            exit 1
    else
            echo "DSIPRouter uninstall was successful"
            exit 0
    fi
}


case "$1" in 

uninstall|remove)
#Remove 
 PYTHON_CMD=$3
 DSIP_PORT=$2
 $1
 ;;
install)
#Install 
 PYTHON_CMD=$3
 DSIP_PORT=$2
 $1
 ;;
*)
        echo "usage $0 [install <dsip_port> <python_cmd> | uninstall <dsip_port> <python_cmd>]"   
;;
esac
