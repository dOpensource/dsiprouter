#!/usr/bin/env bash

#========================== NOTES ==========================#
#
# Supported OS:
# Debian 9 (stretch)
# Debian 8 (jessie)
# Debian 7 (wheezy)
# CentOS 7
#
# Notes:
# In general exported variables & functions
# are used in externally called scripts / programs
#
# TODO:
# move reusable vars/funcs to a util/library script
# allow remote db configuration on install
# allow user to move carriers freely between carrier groups
# allow a carrier to be in more than one carrier group
# add colored error output when installing / uninstalling
# add ncurses selection menu for enabling / disabling modules
# create templating schema for changing kam config values on install
#
#===========================================================#

# Set project dir (where src and install files go)
export DSIP_PROJECT_DIR="$(pwd)"
# Import dsip_lib utility / shared functions
. ${DSIP_PROJECT_DIR}/dsiprouter/dsip_lib.sh

#================== USER_CONFIG_SETTINGS ===================#

# Uncomment if you want to debug this script.
#set -x

# Define some global variables
SERVERNAT=0
FLT_CARRIER=8
FLT_PBX=9
DEBUG=0     # By default debugging is turned off
WITH_SSL=0
export REQ_PYTHON_MAJOR_VER=3
export DSIP_KAMAILIO_CONFIG_DIR="${DSIP_PROJECT_DIR}/kamailio"
export DSIP_KAMAILIO_CONFIG_FILE="${DSIP_KAMAILIO_CONFIG_DIR}/kamailio51_dsiprouter.cfg"
export DSIP_DEFAULTS_DIR="${DSIP_KAMAILIO_CONFIG_DIR}/defaults"
export DSIP_CONFIG_FILE="${DSIP_PROJECT_DIR}/gui/settings.py"
export SYSTEM_KAMAILIO_CONFIG_DIR="/etc/kamailio"
export SYSTEM_KAMAILIO_CONFIG_FILE="${SYSTEM_KAMAILIO_CONFIG_DIR}/kamailio.cfg" # will be symlinked

# Default MYSQL db root user values
MYSQL_ROOT_DEF_USERNAME="root"
MYSQL_ROOT_DEF_PASSWORD=""
MYSQL_ROOT_DEF_DATABASE="mysql"

# Default MYSQL db kamailio user values
MYSQL_KAM_DEF_USERNAME="kamailio"
MYSQL_KAM_DEF_PASSWORD="kamailiorw"
MYSQL_KAM_DEF_DATABASE="kamailio"

# Default SSL options
# If you created your own certs prior to installing set this to match your certs
if [ ${WITH_SSL} -eq 1 ]; then
    DSIP_SSL_CERT_DIR="/etc/ssl/certs"                                      # certs general location
    DSIP_DSIP_SSL_CERT_DIR="${DSIP_SSL_CERT_DIR}/$(hostname -f)"            # domain specific cert dir
    DSIP_SSL_KEY="${DSIP_DSIP_SSL_CERT_DIR}/key.pem"                        # private key
    DSIP_SSL_CHAIN="${DSIP_DSIP_SSL_CERT_DIR}/chain.pem"                    # full chain cert
    DSIP_SSL_CERT="${DSIP_DSIP_SSL_CERT_DIR}/cert.pem"                      # full chain + csr cert
    DSIP_SSL_EMAIL="admin@$(hostname -f)"                                  # email in certs (for renewal)
    DSIP_GUI_PROTOCOL="https"     
else
    DSIP_GUI_PROTOCOL="http"
fi


# Force the installation of a Kamailio version by uncommenting
#KAM_VERSION=44 # Version 4.4.x
#KAM_VERSION=51 # Version 5.1.x

# Uncomment and set this variable to an explicit Python executable file name
# If set, the script will not try and find a Python version with 3.5 as the major release number
#export PYTHON_CMD=/usr/bin/python3.4

# Network configuration values
export RTP_PORT_MIN=10000
export RTP_PORT_MAX=20000
export KAM_SIP_PORT=5060

#===========================================================#

#================= DYNAMIC_CONFIG_SETTINGS =================#
# updated dynamically!

export DSIP_PORT=$(getConfigAttrib 'DSIP_PORT' ${DSIP_CONFIG_FILE})
export EXTERNAL_IP=$(curl -s https://api.ipify.org)
export INTERNAL_IP=$(hostname -I | awk '{print $1}')
export INTERNAL_NET=$(awk -F"." '{print $1"."$2"."$3".*"}' <<<$INTERNAL_IP)

#===========================================================#
DSIP_SERVER_DOMAIN="$(hostname -f)"    # DNS domain we are using

# Get Linux Distro
if [ -f /etc/redhat-release ]; then
 	export DISTRO="centos"
 	export DISTRO_VER=$(cat /etc/redhat-release | cut -d ' ' -f 4 | cut -d '.' -f 1)
elif [ -f /etc/debian_version ]; then
	export DISTRO="debian"
	export DISTRO_VER=$(grep -w "VERSION_ID" /etc/os-release | cut -d '"' -f 2)
fi
# Check if we are on AWS Instance
AWS_ENABLED=0
if cmdExists "ec2-metadata" || curl http://169.254.169.254 &>/dev/null; then
    AWS_ENABLED=1
fi

function displayLogo {
echo "CiAgICAgXyAgX19fX18gX19fX18gX19fX18gIF9fX19fICAgICAgICAgICAgIF8gCiAgICB8IHwv
IF9fX198XyAgIF98ICBfXyBcfCAgX18gXCAgICAgICAgICAgfCB8ICAgICAgICAgICAKICBfX3wg
fCAoX19fICAgfCB8IHwgfF9fKSB8IHxfXykgfF9fXyAgXyAgIF98IHxfIF9fXyBfIF9fIAogLyBf
YCB8XF9fXyBcICB8IHwgfCAgX19fL3wgIF8gIC8vIF8gXHwgfCB8IHwgX18vIF8gXCAnX198Cnwg
KF98IHxfX19fKSB8X3wgfF98IHwgICAgfCB8IFwgXCAoXykgfCB8X3wgfCB8fCAgX18vIHwgICAK
IFxfXyxffF9fX19fL3xfX19fX3xffCAgICB8X3wgIFxfXF9fXy8gXF9fLF98XF9fXF9fX3xffCAg
IAoKQnVpbHQgaW4gRGV0cm9pdCwgVVNBIC0gUG93ZXJlZCBieSBLYW1haWxpbyAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgClN1cHBv
cnQgY2FuIGJlIHB1cmNoYXNlZCBmcm9tIGh0dHBzOi8vZE9wZW5Tb3VyY2UuY29tL2RzaXByb3V0
ZXIKClRoYW5rcyB0byBvdXIgc3BvbnNvcjogU2t5ZXRlbCAoc2t5ZXRlbC5jb20pCg==" | base64 -d
}

# Cleanup exported variables on exit
function cleanupAndExit {
    unset DSIP_PROJECT_DIR DSIP_INSTALL_DIR DSIP_KAMAILIO_CONFIG_DIR DSIP_KAMAILIO_CONFIG DSIP_DEFAULTS_DIR SYSTEM_KAMAILIO_CONFIG_DIR DSIP_CONFIG_FILE
    unset REQ_PYTHON_MAJOR_VER DISTRO DISTRO_VER PYTHON_CMD
    unset MYSQL_ROOT_PASSWORD MYSQL_ROOT_USERNAME MYSQL_ROOT_DATABASE MYSQL_KAM_PASSWORD MYSQL_KAM_USERNAME MYSQL_KAM_DATABASE
    unset RTP_PORT_MIN RTP_PORT_MAX DSIP_PORT EXTERNAL_IP INTERNAL_IP INTERNAL_NET
    unset -f setPythonCmd
    exit $1
}

# Validate OS and get supported Kamailio versions
function validateOSInfo {
    if [[ "$DISTRO" == "debian" ]]; then
        case "$DISTRO_VER" in
            8|9)
                if [[ -z "$KAM_VERSION" ]]; then
                   KAM_VERSION=51
                fi
                ;;
            7)
                if [[ -z "$KAM_VERSION" ]]; then
                    KAM_VERSION=44
                fi
                ;;
            *)
                echo "Your Operating System Version is not supported yet. Please open an issue at https://github.com/dOpensource/dsiprouter/"
                cleanupAndExit 1
                ;;
        esac
    elif [[ "$DISTRO" == "centos" ]]; then
        case "$DISTRO_VER" in
        7)
            if [[ -z "$KAM_VERSION" ]]; then
                KAM_VERSION=51
            fi
            ;;
        *)
            echo "Your Operating System Version is not supported yet. Please open an issue at https://github.com/dOpensource/dsiprouter/"
            cleanupAndExit 1
            ;;
        esac
    else
        echo "Your Operating System is not supported yet. Please open an issue at https://github.com/dOpensource/dsiprouter/"
        cleanupAndExit 1
    fi
}

# run prior to any cmd being processed
function initialChecks {
    validateOSInfo

    if [[ "$DISTRO" == "debian" ]]; then
        # comment out cdrom in sources as it can halt install
        sed -i -E 's/(^\w.*cdrom.*)/#\1/g' /etc/apt/sources.list
    fi

    # make sure root db settings set
    if [[ "$MYSQL_ROOT_PASSWORD" == "" ]]; then
        export MYSQL_ROOT_PASSWORD="$MYSQL_ROOT_DEF_PASSWORD"
    else
        export MYSQL_ROOT_PASSWORD
    fi
    if [[ "$MYSQL_ROOT_USERNAME" == "" ]]; then
        export MYSQL_ROOT_USERNAME="$MYSQL_ROOT_DEF_USERNAME"
    else
        export MYSQL_ROOT_USERNAME
    fi
    if [[ "$MYSQL_ROOT_DATABASE" == "" ]]; then
        export MYSQL_ROOT_DATABASE="$MYSQL_ROOT_DEF_DATABASE"
    else
        export MYSQL_ROOT_DATABASE
    fi

    # make sure kamailio db settings set
    if [[ "$MYSQL_KAM_PASSWORD" == "" ]]; then
        export MYSQL_KAM_PASSWORD="$MYSQL_KAM_DEF_PASSWORD"
    else
        export MYSQL_KAM_PASSWORD
    fi
    if [[ "$MYSQL_KAM_USERNAME" == "" ]]; then
        export MYSQL_KAM_USERNAME="$MYSQL_KAM_DEF_USERNAME"
    else
        export MYSQL_KAM_USERNAME
    fi
    if [[ "$MYSQL_KAM_DATABASE" == "" ]]; then
        export MYSQL_KAM_DATABASE="$MYSQL_KAM_DEF_DATABASE"
    else
        export MYSQL_KAM_DATABASE
    fi

    # SSL config checks if enabled
    if [ ${WITH_SSL} -eq 1 ]; then
        # check that hostname or fqdn  is set & not empty (must be set for SSL cert renewal to work)
        if [ -z "$(hostname -f)" ]; then
            echo "You must configure a host name or DNS domain name to enable SSL.. Either configure your server domain or disable SSL."
            exit 1
        fi

        # make sure SSL options are set & not empty
        if [ -z "$DSIP_SSL_KEY" ] || [ -z "$DSIP_SSL_CERT" ] || [ -z "$DSIP_SSL_EMAIL" ]; then
            echo "SSL configs are invalid. Configure SSL options or disable SSL."
            exit 1
        fi
    fi
}

# exported because its used throughout called scripts as well
function setPythonCmd {
    if [[ -z "$PYTHON_CMD" ]]; then
        export PYTHON_CMD="$PYTHON_CMD"
    fi

    possible_python_versions=$(find /usr/bin -name "python$REQ_PYTHON_MAJOR_VER*" -type f -executable  2>/dev/null)
    for i in $possible_python_versions; do
        ver=$($i -V 2>&1)
        if [ $? -eq 0 ]; then  #Check if the version parameter is working correctly
            echo $ver | grep $REQ_PYTHON_MAJOR_VER >/dev/null
            if [ $? -eq 0 ]; then
                export PYTHON_CMD="$i"
                return 0
            fi
        fi
    done
}
export -f setPythonCmd

# set dynamic python config settings
function configurePythonSettings {
    setConfigAttrib -q 'KAM_KAMCMD_PATH' "$(type -p kamcmd)" ${DSIP_CONFIG_FILE}
    setConfigAttrib -q 'KAM_CFG_PATH' "$SYSTEM_KAMAILIO_CONFIG_FILE" ${DSIP_CONFIG_FILE}
    sed -i -r "s|(DSIP_SSL_KEY[[:space:]]?=.*)|DSIP_SSL_KEY = '${DSIP_SSL_KEY}'|g" gui/settings.py
    sed -i -r "s|(DSIP_SSL_KEY[[:space:]]?=.*)|DSIP_SSL_CERT = '${DSIP_SSL_CERT}'|g" gui/settings.py
    sed -i -r "s|(DSIP_SSL_KEY[[:space:]]?=.*)|DSIP_SSL_EMAIL = '${DSIP_SSL_EMAIL}'|g" gui/settings.py
#    sed -i -r "s|(DOMAIN[[:space:]]?=.*)|DOMAIN = '${DSIP_SERVER_DOMAIN}'|g" gui/settings.py
}

function configureSSL {
    ## Configure self signed certificate
    CERT_DIR="/etc/ssl/certs/"
  
    mkdir -p ${DSIP_DSIP_SSL_CERT_DIR} 
    openssl req -new -newkey rsa:4096 -x509 -sha256 -days 365 -nodes -out ${DSIP_SSL_CERT} -keyout ${DSIP_SSL_KEY} -subj "/C=US/ST=MI/L=Detroit/O=dSIPRouter/CN=`hostname`" 
    sed -i -r "s|(SSL_KEY[[:space:]]?=.*)|SSL_KEY = '${DSIP_SSL_KEY}'|g" gui/settings.py
    sed -i -r "s|(SSL_CERT[[:space:]]?=.*)|SSL_CERT = '${DSIP_SSL_CERT}'|g" gui/settings.py
   
}

function configureKamailio {
    # copy template of kamailio configuration to a working copy
    cp ${DSIP_KAMAILIO_CONFIG_DIR}/kamailio51_dsiprouter.tpl ${DSIP_KAMAILIO_CONFIG_DIR}/kamailio51_dsiprouter.cfg
    # set kamailio version in kam config
    sed -i -e "s/KAMAILIO_VERSION/${KAM_VERSION}/" ${DSIP_KAMAILIO_CONFIG_FILE}

    # get kam db connection settings
    local KAM_DB_HOST=$(getConfigAttrib 'KAM_DB_HOST' ${DSIP_CONFIG_FILE})
    local KAM_DB_TYPE=$(getConfigAttrib 'KAM_DB_TYPE' ${DSIP_CONFIG_FILE})
    local KAM_DB_PORT=$(getConfigAttrib 'KAM_DB_PORT' ${DSIP_CONFIG_FILE})
    local KAM_DB_NAME=$(getConfigAttrib 'KAM_DB_NAME' ${DSIP_CONFIG_FILE})
    local KAM_DB_USER=$(getConfigAttrib 'KAM_DB_USER' ${DSIP_CONFIG_FILE})
    local KAM_DB_PASS=$(getConfigAttrib 'KAM_DB_PASS' ${DSIP_CONFIG_FILE})

    # check for cluster db connection and set kam config settings appropriately
    if printf "$KAM_DB_HOST" | grep -q -oP '.*\[.*\]'; then
        # db connection is clustered
        enableKamailioConfigAttrib 'WITH_DBCLUSTER' ${DSIP_KAMAILIO_CONFIG_FILE}

        # TODO: support different type/user/pass/port/name per connection
        # TODO: support multiple clusters
        local KAM_DB_CLUSTER_CONNS=""
        local KAM_DB_CLUSTER_MODES=""
        KAM_DB_HOST=$(printf "$KAM_DB_HOST" | tr -d '[]'"'"'"' | tr ',' ' ')

        local i=1
        for HOST in $KAM_DB_HOST; do
            KAM_DB_CLUSTER_CONNS+="modparam('db_cluster', 'connection', 'c${i}=>${KAM_DB_TYPE}://${KAM_DB_USER}:${KAM_DB_PASS}@${HOST}:${KAM_DB_PORT}/${KAM_DB_NAME}')\n"
            KAM_DB_CLUSTER_MODES+="c${i}=9r9r;"
            i=$((i+1))
        done
        KAM_DB_CLUSTER_MODES="modparam('db_cluster', 'cluster', 'dbcluster=>${KAM_DB_CLUSTER_MODES}')"
        sed -i -e "s~DB_CLUSTER_PARAMS~${KAM_DB_CLUSTER_CONNS}${KAM_DB_CLUSTER_MODES}~" ${DSIP_KAMAILIO_CONFIG_FILE}
    else
        sed -i -e "s~DB_CONNECTION_URI~${KAM_DB_TYPE}://${KAM_DB_USER}:${KAM_DB_PASS}@${KAM_DB_HOST}:${KAM_DB_PORT}/${KAM_DB_NAME}~" ${DSIP_KAMAILIO_CONFIG_FILE}
    fi

    # make sure kamailio user exists
    mysql --user="$MYSQL_ROOT_USERNAME" --password="$MYSQL_ROOT_PASSWORD" $MYSQL_ROOT_DATABASE \
        -e "GRANT ALL PRIVILEGES ON $MYSQL_KAM_DATABASE.* TO '$MYSQL_KAM_USERNAME'@'localhost' IDENTIFIED BY '$MYSQL_KAM_PASSWORD';"

    # Check the username and password
    #mysql --user="$MYSQL_KAM_USERNAME" --password="$MYSQL_KAM_PASSWORD" $MYSQL_KAM_DATABASE -e "select * from version limit 1" >/dev/null 2>&1
    #if [ $? -eq 1 ]; then
    #	echo "Your credentials for the kamailio schema is invalid.  Please try again!"
    #	configureKamailio
    #fi

    # Install schema for drouting module
    mysql --user="$MYSQL_KAM_USERNAME" --password="$MYSQL_KAM_PASSWORD" $MYSQL_KAM_DATABASE \
        -e "delete from version where table_name in ('dr_gateways','dr_groups','dr_gw_lists','dr_rules')"
    mysql --user="$MYSQL_KAM_USERNAME" --password="$MYSQL_KAM_PASSWORD" $MYSQL_KAM_DATABASE \
        -e "drop table if exists dr_gateways,dr_groups,dr_gw_lists,dr_rules"
    if [ -e  /usr/share/kamailio/mysql/drouting-create.sql ]; then
        mysql --user="$MYSQL_KAM_USERNAME" --password="$MYSQL_KAM_PASSWORD" $MYSQL_KAM_DATABASE < /usr/share/kamailio/mysql/drouting-create.sql
    else
        sqlscript=`find / -name 'drouting-create.sql' | grep mysql | grep 4. | sed -n 1p`
        mysql --user="$MYSQL_KAM_USERNAME" --password="$MYSQL_KAM_PASSWORD" $MYSQL_KAM_DATABASE < $sqlscript
    fi

    # Install schema for custom drouting
    mysql --user="$MYSQL_KAM_USERNAME" --password="$MYSQL_KAM_PASSWORD" $MYSQL_KAM_DATABASE < ${DSIP_KAMAILIO_CONFIG_DIR}/custom_routing.sql

    # Install schema for single & multi tenant pbx domain mapping
    mysql --user="$MYSQL_KAM_USERNAME" --password="$MYSQL_KAM_PASSWORD" $MYSQL_KAM_DATABASE < ${DSIP_KAMAILIO_CONFIG_DIR}/domain_mapping.sql

    # reset auto incrementers for related tables
    #resetIncrementers "dr_gw_lists"
    #resetIncrementers "uacreg"

    # Import Default Carriers
    if [ -e `which mysqlimport` ]; then
        mysql --user="$MYSQL_KAM_USERNAME" --password="$MYSQL_KAM_PASSWORD" $MYSQL_KAM_DATABASE -e "delete from address where grp=$FLT_CARRIER"

        # sub in dynamic values
        sed -i s/FLT_CARRIER/$FLT_CARRIER/g ${DSIP_DEFAULTS_DIR}/address.csv
        sed -i s/FLT_CARRIER/$FLT_CARRIER/g ${DSIP_DEFAULTS_DIR}/dr_gateways.csv
        sed -i s/EXTERNAL_IP/$EXTERNAL_IP/g ${DSIP_DEFAULTS_DIR}/uacreg.csv

        # import default carriers
        mysqlimport --user="$MYSQL_KAM_USERNAME" --password="$MYSQL_KAM_PASSWORD" --fields-terminated-by=';' --ignore-lines=0  \
            -L $MYSQL_KAM_DATABASE ${DSIP_DEFAULTS_DIR}/address.csv
        mysqlimport --user="$MYSQL_KAM_USERNAME" --password="$MYSQL_KAM_PASSWORD" --fields-terminated-by=';' --ignore-lines=0  \
            -L $MYSQL_KAM_DATABASE ${DSIP_DEFAULTS_DIR}/dr_gw_lists.csv
        mysqlimport --user="$MYSQL_KAM_USERNAME" --password="$MYSQL_KAM_PASSWORD" --fields-terminated-by=',' --ignore-lines=0  \
            -L $MYSQL_KAM_DATABASE ${DSIP_DEFAULTS_DIR}/uacreg.csv
        mysqlimport --user="$MYSQL_KAM_USERNAME" --password="$MYSQL_KAM_PASSWORD" --fields-terminated-by=';' --ignore-lines=0  \
            -L $MYSQL_KAM_DATABASE ${DSIP_DEFAULTS_DIR}/dr_gateways.csv
    fi

    # Setup Outbound Rules to use Skyetel by default
    mysql --user="$MYSQL_KAM_USERNAME" --password="$MYSQL_KAM_PASSWORD" $MYSQL_KAM_DATABASE \
        -e "insert into dr_rules values (null,8000,'','','','','1,2','Default Outbound Route');"

    # Backup kamcfg and link the dsiprouter kamcfg
    cp -f ${SYSTEM_KAMAILIO_CONFIG_FILE} ${SYSTEM_KAMAILIO_CONFIG_FILE}.$(date +%Y%m%d_%H%M%S)
    rm -f ${SYSTEM_KAMAILIO_CONFIG_FILE}
    ln -s ${DSIP_KAMAILIO_CONFIG_FILE} ${SYSTEM_KAMAILIO_CONFIG_FILE}

    # Fix the mpath
    fixMPATH

    # Enable SERVERNAT
    if [ "$SERVERNAT" == "1" ]; then
        enableSERVERNAT
    fi
}

 # required if tables exist and we are updating
    function resetIncrementers {
        SQL_TABLES=$(
            (for t in "$@"; do printf ",'$t'"; done) | cut -d ',' -f '2-'
        )

        # reset auto increment for related tables to max btwn the related tables
        INCREMENT=$(
            mysql --skip-column-names --user="$MYSQL_ROOT_USERNAME" --password="$MYSQL_ROOT_PASSWORD" $MYSQL_ROOT_DATABASE \ -e "\
                SELECT MAX(AUTO_INCREMENT) FROM INFORMATION_SCHEMA.TABLES \
                WHERE TABLE_SCHEMA = '$MYSQL_KAM_DATABASE' \
                AND TABLE_NAME IN($SQL_TABLES);"
        )
        for t in "$@"; do
            mysql --user="$MYSQL_KAM_USERNAME" --password="$MYSQL_KAM_PASSWORD" $MYSQL_KAM_DATABASE \
                -e "ALTER TABLE $t AUTO_INCREMENT=$INCREMENT"
        done
    }

function enableSERVERNAT {
	sed -i 's/##!define WITH_SERVERNAT/#!define WITH_SERVERNAT/' ${DSIP_KAMAILIO_CONFIG_FILE}
	sed -i 's/!INTERNAL_IP_ADDR!.*!g/!INTERNAL_IP_ADDR!'$INTERNAL_IP'!g/' ${DSIP_KAMAILIO_CONFIG_FILE}
	sed -i 's/!INTERNAL_IP_NET!.*!g/!INTERNAL_IP_NET!'$INTERNAL_NET'!g/' ${DSIP_KAMAILIO_CONFIG_FILE}
	sed -i 's/!EXTERNAL_IP_ADDR!.*!g/!EXTERNAL_IP_ADDR!'$EXTERNAL_IP'!g/' ${DSIP_KAMAILIO_CONFIG_FILE}
}

function disableSERVERNAT {
	sed -i 's/#!define WITH_SERVERNAT/##!define WITH_SERVERNAT/' ${DSIP_KAMAILIO_CONFIG_FILE}
}

# Try to locate the Kamailio modules directory.  It will use the last modules directory found
function fixMPATH {
    for i in `find /usr -name drouting.so`; do
        mpath=`dirname $i| grep 'modules$'`
        if [ "$mpath" != '' ]; then
            mpath=$mpath/
            break #found a mpath
        fi
    done

    echo "The Kamailio mpath has been updated to:$mpath"
    if [ "$mpath" != '' ]; then
        sed -i 's#mpath=.*#mpath=\"'$mpath'\"#g' ${DSIP_KAMAILIO_CONFIG_FILE}
    else
        echo "Can't find the module path for Kamailio.  Please ensure Kamailio is installed and try again!"
        cleanupAndExit 1
    fi
}


# Start RTPEngine
function startRTPEngine {
    if [ $DISTRO == "debian" ]; then
        systemctl start ngcp-rtpengine-daemon
    fi

    if [ $DISTRO == "centos" ]; then
        systemctl start rtpengine
    fi
}

# Stop RTPEngine
function stopRTPEngine {
    if [ $DISTRO == "debian" ]; then
        systemctl stop ngcp-rtpengine-daemon
    fi

    if [ $DISTRO == "centos" ]; then
        systemctl stop rtpengine
    fi
}


# Remove RTPEngine
function uninstallRTPEngine {
    if [ ! -e ./.rtpengineinstalled ]; then
        echo -e "RTPEngine is not installed!"
    else
#        if [ ! -e ./.rtpengineinstalled ]; then
#
#            echo -e "We did not install RTPEngine.  Would you like us to install it? [y/n]:\c"
#            read installrtpengine
#            case "$installrtpengine" in
#                [yY][eE][sS]|[yY])
#                installRTPEngine
#                cleanupAndExit 0
#                ;;
#                *)
#                cleanupAndExit 1
#                ;;
#            esac
#        fi

        if [ $DISTRO == "debian" ]; then
            echo "Removing RTPEngine for $DISTRO"
            systemctl stop rtpengine
            rm -f /usr/sbin/rtpengine
            rm -f /etc/syslog.d/rtpengine
            rm -f /etc/rsyslog.d/rtpengine.conf
            rm -f ./.rtpengineinstalled
            echo "Removed RTPEngine for $DISTRO"
        fi

        if [ $DISTRO == "centos" ]; then
            echo "Removing RTPEngine for $DISTRO"
            systemctl stop rtpengine
            rm -f /usr/sbin/rtpengine
            rm -f /etc/syslog.d/rtpengine
            rm -f /etc/rsyslog.d/rtpengine.conf
            rm -f ./.rtpengineinstalled
            echo "Removed RTPEngine for $DISTRO"
        fi
    fi
} #end of uninstallRTPEngine

# Install the RTPEngine from sipwise
# We are going to install it by default, but will users the ability to
# to disable it if needed

# TODO: seperate source dir from install dir
# makes upgrading / git merging much easier
function installRTPEngine {
    cd ${DSIP_PROJECT_DIR}

    if [[ $DISTRO == "debian" ]]; then

        # Install required libraries
        apt-get install -y firewalld
        apt-get install -y debhelper
        apt-get install -y iptables-dev
        apt-get install -y libcurl4-openssl-dev
        apt-get install -y libpcre3-dev libxmlrpc-core-c3-dev
        apt-get install -y markdown
        apt-get install -y libglib2.0-dev
        apt-get install -y libavcodec-dev
        apt-get install -y libevent-dev
        apt-get install -y libhiredis-dev
        apt-get install -y libjson-glib-dev libpcap0.8-dev libpcap-dev libssl-dev
        apt-get install -y libavfilter-dev
        apt-get install -y libavformat-dev
        apt-get install -y libmysqlclient-dev
        apt-get install -y libmariadbclient-dev
        apt-get install -y default-libmysqlclient-dev

        rm -rf rtpengine.bak
        mv -f rtpengine rtpengine.bak
        git clone -b mr6.1.1.1 https://github.com/sipwise/rtpengine
        cd rtpengine
        ./debian/flavors/no_ngcp
        dpkg-buildpackage
        cd ..
        dpkg -i ngcp-rtpengine-daemon_*

        #cp /etc/rtpengine/rtpengine.sample.conf /etc/rtpengine/rtpengine.conf

        if [ "$SERVERNAT" == "0" ]; then
            INTERFACE=$EXTERNAL_IP
        else
            INTERFACE=$INTERNAL_IP!$EXTERNAL_IP
        fi

         (cat << EOF
[rtpengine]
table = -1
interface = ${INTERFACE}
listen-ng = 7722
port-min = ${RTP_PORT_MIN}
port-max = ${RTP_PORT_MAX}
log-level = 7
log-facility = local1
EOF
         ) > /etc/rtpengine/rtpengine.conf


        #sed -i -r  "s/# interface = [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/interface = "$EXTERNAL_IP"/" /etc/rtpengine/rtpengine.conf
        sed -i 's/RUN_RTPENGINE=no/RUN_RTPENGINE=yes/' /etc/default/ngcp-rtpengine-daemon
        #sed -i 's/# listen-udp = 12222/listen-udp = 7222/' /etc/rtpengine/rtpengine.conf

        # Enable and start firewalld if not already running
        systemctl enable firewalld
        systemctl start firewalld

        # Setup Firewall rules for RTPEngine
        firewall-cmd --zone=public --add-port=${RTP_PORT_MIN}-${RTP_PORT_MAX}/udp --permanent
        firewall-cmd --reload

        # Setup RTPEngine Logging
        echo "local1.*     -/var/log/rtpengine" >> /etc/rsyslog.d/rtpengine.conf
        touch /var/log/rtpengine
        systemctl restart rsyslog

        # Setup tmp files
        echo "d /var/run/rtpengine.pid  0755 rtpengine rtpengine - -" > /etc/tmpfiles.d/rtpengine.conf
        cp -f ./dsiprouter/debian/ngcp-rtpengine-daemon.init /etc/init.d/ngcp-rtpengine-daemon

        # Enable the RTPEngine to start during boot
        systemctl enable ngcp-rtpengine-daemon
        # Start RTPEngine
        systemctl start ngcp-rtpengine-daemon

        # Start manually if the service fails to start
        if [ $? -eq 1 ]; then
            /usr/sbin/rtpengine --config-file=/etc/rtpengine/rtpengine.conf --pidfile=/var/run/ngcp-rtpengine-daemon.pid
        fi

        # File to signify that the install happened
        if [ $? -eq 0 ]; then
           touch ./.rtpengineinstalled
           echo "RTPEngine has been installed!"
        else
            echo "FAILED: RTPEngine could not be installed!"
        fi

    elif [[ $DISTRO == "centos" ]]; then

        # Install required libraries
        yum install -y epel-release
        yum update -y
        rpm --import http://li.nux.ro/download/nux/RPM-GPG-KEY-nux.ro
        rpm -Uh http://li.nux.ro/download/nux/dextop/el7/x86_64/nux-dextop-release-0-5.el7.nux.noarch.rpm
        yum install -y gcc glib2 glib2-devel zlib zlib-devel openssl openssl-devel pcre pcre-devel libcurl libcurl-devel \
            xmlrpc-c xmlrpc-c-devel libpcap libpcap-devel hiredis hiredis-devel json-glib json-glib-devel libevent libevent-devel \
            iptables-devel kernel-devel kernel-headers xmlrpc-c-devel ffmpeg ffmpeg-devel &&
        # VPS kernel headers are generally custom-named or outdated
        # so we have to grab them from archives (if on a VPS)
        if (( $AWS_ENABLED == 0 )); then
            yum install -y "kernel-devel-uname-r == $(uname -r)"
        else
            yum install -y https://rpmfind.net/linux/centos/$(cat /etc/redhat-release | cut -d ' ' -f 4)/updates/$(uname -m)/Packages/kernel-devel-$(uname -r).rpm ||
            yum install -y https://rpmfind.net/linux/centos/$(cat /etc/redhat-release | cut -d ' ' -f 4)/os/$(uname -m)/Packages/kernel-devel-$(uname -r).rpm
        fi

        if [ $? -ne 0 ]; then
            echo "Problem with installing the required libraries for RTPEngine"
            cleanupAndExit 1
        fi

        # Make and Configure RTPEngine
        rm -rf rtpengine.bak
        mv -f rtpengine rtpengine.bak
        git clone https://github.com/sipwise/rtpengine.git
        cd rtpengine/daemon && make

        if [ $? -eq 0 ]; then

            # Copy binary to /usr/sbin
            cp -f ${DSIP_PROJECT_DIR}/rtpengine/daemon/rtpengine /usr/sbin/rtpengine

            # Remove RTPEngine kernel module if previously inserted
            if lsmod | grep 'xt_RTPENGINE'; then
                rmmod xt_RTPENGINE
            fi

            # Configure RTPEngine to support kernel packet forwarding
            cd ${DSIP_PROJECT_DIR}/rtpengine/kernel-module && make && insmod xt_RTPENGINE.ko
            if [ $? -ne 0 ]; then
                echo "Problem installing RTPEngine kernel-module"
                cleanupAndExit 1
            fi
            cd ${DSIP_PROJECT_DIR}/rtpengine/iptables-extension && make && cp -f libxt_RTPENGINE.so /lib64/xtables/
            if [ $? -ne 0 ]; then
                echo "Problem installing RTPEngine iptables-extension"
                cleanupAndExit 1
            fi

            # Add startup script
            (cat << EOF
[Unit]
Description=Kernel based rtp proxy
After=syslog.target
After=network.target

[Service]
Type=forking
PIDFile=/var/run/rtpengine.pid
EnvironmentFile=-/etc/sysconfig/rtpengine
ExecStart=/usr/sbin/rtpengine -p /var/run/rtpengine.pid \$OPTIONS

Restart=always

[Install]
WantedBy=multi-user.target
EOF
            ) > /etc/systemd/system/rtpengine.service

            # Add Options File
            (cat << EOF
# Add extra options here
# We dont support the NG protocol in this release
#
OPTIONS="-F -i ${INTERNAL_IP}!${EXTERNAL_IP} -u 127.0.0.1:7722 -m ${RTP_PORT_MIN} -M ${RTP_PORT_MAX} -p /var/run/rtpengine.pid --log-level=7 --log-facility=local1"
EOF
            ) > /etc/sysconfig/rtpengine

            # Setup RTPEngine Logging
            echo "local1.*      -/var/log/rtpengine" >> /etc/rsyslog.d/rtpengine.conf
            touch /var/log/rtpengine
            systemctl restart rsyslog

            # Enable and start firewalld if not already running
            systemctl enable firewalld
            systemctl start firewalld

            # Setup Firewall rules for RTPEngine
            firewall-cmd --zone=public --add-port=${RTP_PORT_MIN}-${RTP_PORT_MAX}/udp --permanent
            firewall-cmd --reload

            # Reload systemd configs
            systemctl daemon-reload
            # Enable the RTPEngine to start during boot
            systemctl enable rtpengine
            # Start RTPEngine
            systemctl start rtpengine

            # Start manually if the service fails to start
            if [ $? -ne 0 ]; then
                /usr/sbin/rtpengine --config-file=/etc/sysconfig/rtpengine --pidfile=/var/run/rtpengine.pid
            fi

            # File to signify that the install happened
            if [ $? -eq 0 ]; then
                cd ../..
                touch ./.rtpengineinstalled
                echo "RTPEngine has been installed!"
            fi
        fi
    fi

} # end of installing RTPEngine

# Enable RTP within the Kamailio configuration so that it uses the RTPEngine
function enableRTP {

    sed -i 's/#!define WITH_NAT/##!define WITH_NAT/' ./kamailio_dsiprouter.cfg

} #end of enableRTP

# Disable RTP within the Kamailio configuration so that it doesn't use the RTPEngine
function disableRTP {

    sed -i 's/##!define WITH_NAT/#!define WITH_NAT/' ./kamailio_dsiprouter.cfg

} #end of disableRTP


function install {
    if [ ! -f "./.installed" ]; then
        cd ${DSIP_PROJECT_DIR}

        echo -e "Attempting to install Kamailio...\n"
        ./kamailio/${DISTRO}/${DISTRO_VER}.sh install ${KAM_VERSION} ${DSIP_PORT}
        if [ $? -eq 0 ]; then
            echo "Kamailio was installed!"
        else
            echo "dSIPRouter install failed: Couldn't install Kamailio"
            cleanupAndExit 1
        fi
        echo -e "Attempting to install dSIPRouter...\n"
        ./dsiprouter/${DISTRO}/${DISTRO_VER}.sh install ${DSIP_PORT} ${PYTHON_CMD}

        # Configure Kamailio and Install dSIPRouter Modules
        if [ $? -eq 0 ]; then
            configureKamailio
            installModules
        fi

        # set some defaults in settings.py
        configurePythonSettings

        # configure SSL
        if [ ${WITH_SSL} -eq 1 ]; then
            configureSSL
        fi

        # Restart Kamailio with the new configurations
        systemctl restart kamailio
        if [ $? -eq 0 ]; then
            touch ./.installed
            echo -e "\e[32m-------------------------\e[0m"
            echo -e "\e[32mInstallation is complete! \e[0m"
            echo -e "\e[32m-------------------------\e[0m\n"
            displayLogo
            echo -e "\n\nThe username and dynamically generated password are below:\n"

            # Generate a unique admin password
            generatePassword

            # Start dSIPRouter
            start

            # Tell them how to access the URL
            echo -e "You can access the dSIPRouter web gui by going to:\n"
            echo -e "External IP:  ${DSIP_GUI_PROTOCOL}://${EXTERNAL_IP}:${DSIP_PORT}\n"
            if [ "$EXTERNAL_IP" != "$INTERNAL_IP" ];then
                echo -e "Internal IP:  ${DSIP_GUI_PROTOCOL}://${INTERNAL_IP}:${DSIP_PORT}\n"
            fi

            #echo -e "Your Kamailio configuration has been backed up and a new configuration has been installed.  Please restart Kamailio so that the changes can become active\n"
        else
            echo "dSIPRouter install failed: Couldn't configure Kamailio correctly"
            cleanupAndExit 1
        fi
    else
        echo "dSIPRouter is already installed"
        cleanupAndExit 1
    fi
} #end of install

function uninstall {
    if [ ! -f "./.installed" ]; then
        echo "dSIPRouter is not installed or failed during install - uninstalling anyway to be safe"
    fi

	# Stop dSIPRouter, remove ./.installed file, close firewall
	stop

    echo -e "Attempting to uninstall dSIPRouter...\n"
    ./dsiprouter/$DISTRO/$DISTRO_VER.sh uninstall ${DSIP_PORT} ${PYTHON_CMD}

    echo -e "Attempting to uninstall Kamailio...\n"
    ./kamailio/$DISTRO/$DISTRO_VER.sh uninstall ${KAM_VERSION} ${DSIP_PORT} ${PYTHON_CMD}
    if [ $? -eq 0 ]; then
        echo "Kamailio was uninstalled!"
    else
        echo "dSIPRouter uninstall failed: Couldn't install Kamailio"
        cleanupAndExit 1
    fi

    # Remove crontab entry
    echo "Removing crontab entry"
    crontab -l | grep -v -F -w dsiprouter_cron | crontab -

    # Remove the hidden installed file, which denotes if it's installed or not
	rm -f ./.installed

    echo "dSIPRouter was uninstalled"
} #end of uninstall


function installModules {
    # Install / Uninstall dSIPModules
    for dir in ./gui/modules/*; do
        if [[ -e ${dir}/install.sh ]]; then
            ./${dir}/install.sh $MYSQL_ROOT_USERNAME $MYSQL_ROOT_PASSWORD $MYSQL_ROOT_DATABASE $PYTHON_CMD
        fi
    done

    # Setup dSIPRouter Cron scheduler
    crontab -l | grep -v -F -w dsiprouter_cron | crontab -
    echo -e "*/1 * * * *  $PYTHON_CMD $(pwd)/gui/dsiprouter_cron.py" | crontab -
}


function start {
    # Check if the dSIPRouter process is already running
    if [ -e /var/run/dsiprouter/dsiprouter.pid ]; then
        PID=`cat /var/run/dsiprouter/dsiprouter.pid`
        ps -ef | grep $PID > /dev/null
        if [ $? -eq 0 ]; then
            echo "dSIPRouter is already running under process id $PID"
            cleanupAndExit 1
        fi
    fi

    # Start RTPEngine if it was installed
    if [ -e ./.rtpengineinstalled ]; then
        startRTPEngine
    fi

    # Start the process
    if [ $DEBUG -eq 0 ]; then
        nohup $PYTHON_CMD ./gui/dsiprouter.py runserver >/dev/null 2>&1 &
    else
        nohup $PYTHON_CMD ./gui/dsiprouter.py runserver >/var/log/dsiprouter.log 2>&1 &
    fi

    # Store the PID of the process
    PID=$!
    if [ $PID -gt 0 ]; then
        if [ ! -e /var/run/dsiprouter ]; then
            mkdir /var/run/dsiprouter/
        fi

        echo $PID > /var/run/dsiprouter/dsiprouter.pid
        echo "dSIPRouter was started under process id $PID"
    fi
} #end of start



function stop {
	if [ -e /var/run/dsiprouter/dsiprouter.pid ]; then
		#kill -9 `cat /var/run/dsiprouter/dsiprouter.pid`
        kill -9 $(pgrep -f runserver) &>/dev/null
		rm -rf /var/run/dsiprouter/dsiprouter.pid
		echo "dSIPRouter was stopped"
	else
		echo "dSIPRouter is not running"
	fi

	if [ -e ./.rtpengineinstalled ]; then
		stopRTPEngine
	 	if [ $? -eq 0 ]; then
			echo "RTPEngine was stopped"
		fi
	else
		echo "RTPEngine was not installed"
	fi
}

function restart {
	stop
	start
	cleanupAndExit 0
}

function resetPassword {
    echo -e "The admin account has been reset to the following:\n"

    #Call the bash function that generates the password
    generatePassword

    #dSIPRouter will be restarted to make the new password active
    echo -e "Restart dSIPRouter to make the password active!\n"
}

# Generate password and set it in the ${DSIP_CONFIG_FILE} PASSWORD field
function generatePassword {
    if (( $AWS_ENABLED == 1 )); then
        password=$(curl http://169.254.169.254/latest/meta-data/instance-id)
    else
        password=$(date +%s | sha256sum | base64 | head -c 16)
    fi

    # Add single quotes
    password1="'$password'"
    sed -i 's/PASSWORD[[:space:]]\?=[[:space:]]\?.*/PASSWORD = '$password1'/g' ${DSIP_CONFIG_FILE}

    echo -e "username: admin\npassword: $password\n"
}

function upgrade {
    # TODO: set / handle parsed args
    UPGRADE_RELEASE="v0.51"

    BACKUP_DIR="/var/opt/dsip/backups"
    CURR_BACKUP_DIR="${BACKUP_DIR}/$(date '+%Y-%m-%d')"
    mkdir -p ${BACKUP_DIR} ${CURR_BACKUP_DIR}
    mkdir -p ${CURR_BACKUP_DIR}/{etc,var/lib,${HOME},$(dirname "$DSIP_PROJECT_DIR"),$(dirname "$DSIP_PROJECT_DIR")}

    mysqldump --single-transaction --opt --events --routines --triggers --all-databases --add-drop-database --flush-privileges \
        --user="$MYSQL_KAM_USERNAME" --password="$MYSQL_KAM_PASSWORD" > ${CURR_BACKUP_DIR}/mysql_full.sql
    mysqldump --single-transaction --skip-triggers --skip-add-drop-table --insert-ignore \
        --user="$MYSQL_KAM_USERNAME" --password="$MYSQL_KAM_PASSWORD" ${MYSQL_KAM_DATABASE} \
        | perl -0777 -pi -e 's/CREATE TABLE (`(.+?)`.+?;)/CREATE TABLE IF NOT EXISTS \1\n\nTRUNCATE TABLE `\2`;\n/gs' \
        > ${CURR_BACKUP_DIR}/kamdb_merge.sql

    systemctl stop rtpengine
    systemctl stop kamailio
    systemctl stop dsiprouter
    systemctl stop mysql

    mv -f ${DSIP_PROJECT_DIR} ${CURR_BACKUP_DIR}/${DSIP_PROJECT_DIR}
    mv -f ${SYSTEM_KAMAILIO_CONFIG_DIR} ${CURR_BACKUP_DIR}/${SYSTEM_KAMAILIO_CONFIG_DIR}
    # in case mysqldumps failed silently, backup mysql binary data
    mv -f /var/lib/mysql ${CURR_BACKUP_DIR}/var/lib/
    cp -f /etc/my.cnf* ${CURR_BACKUP_DIR}/etc/
    cp -rf /etc/my.cnf* ${CURR_BACKUP_DIR}/etc/
    cp -rf /etc/mysql ${CURR_BACKUP_DIR}/etc/
    cp -f ${HOME}/.my.cnf* ${CURR_BACKUP_DIR}/${HOME}/

    iptables-save > ${CURR_BACKUP_DIR}/iptables.dump
    ip6tables-save > ${CURR_BACKUP_DIR}/ip6tables.dump

    git clone https://github.com/dOpensource/dsiprouter.git --branch="$UPGRADE_RELEASE" ${DSIP_PROJECT_DIR}
    cd ${DSIP_PROJECT_DIR}

    # TODO: figure out what settings they installed with previously
    # or we can simply store them in a text file (./installed)
    # after a succesfull install completes
    ./dsiprouter.sh uninstall
    ./dsiprouter.sh install

    mysql --user="$MYSQL_KAM_USERNAME" --password="$MYSQL_KAM_PASSWORD" ${MYSQL_KAM_DATABASE} < ${CURR_BACKUP_DIR}/kamdb_merge.sql

    # TODO: fix any conflicts that would arise from our new modules / tables in KAMDB

    # TODO: print backup location info to user

    # TODO: transfer / merge backup configs to new configs
    # kam configs
    # dsip configs
    # iptables configs
    # mysql configs

    # TODO: restart services, check for good startup
}

# TODO: update usage options
function usageOptions {
    echo -e "\nUsage: $0 install|uninstall [-rtpengine [-servernat]]"
    echo -e "Usage: $0 start|stop|restart"
    echo -e "Usage: $0 resetpassword"
    echo -e "\ndSIPRouter is a Web Management GUI for Kamailio based on use case design, with a focus on ITSP and Carrier use cases.This means that we aren’t a general purpose GUI for Kamailio."
    echo -e "If that's required then use Siremis, which is located at http://siremis.asipto.com/."
    echo -e "\nThis script is used for installing and uninstalling dSIPRouter, which includes installing the Web GUI portion, Kamailio Configuration file and optionally for installing the RTPEngine by SIPwise"
    echo -e "This script can also be used to start, stop and restart dSIPRouter.  It will not restart Kamailio."
    echo -e "\nSupport is available from dOpenSource.  Visit us at https://dopensource.com/dsiprouter or call us at 888-907-2085"
    echo -e "\n\ndOpenSource | A Flyball Company\nMade in Detroit, MI USA\n"

    cleanupAndExit 1
}


function processCMD {
    # prep before processing commands
    initialChecks
    setPythonCmd # may be overridden in distro install script

	while (( $# > 0 )); do
		key="$1"
		case $key in
			install)
                shift
                if [ "$1" == "-debug" ]; then
                    DEBUG=1
                    set -x
                    shift
                fi
                if [ "$1" == "-rtpengine" ] && [ "$2" == "-servernat" ]; then
                    SERVERNAT=1
                    installRTPEngine
                elif [ "$1" == "-rtpengine" ]; then
                    installRTPEngine
                fi
                install
                cleanupAndExit 0
                ;;
			uninstall)
                shift
                if [ "$1" == "-debug" ]; then
                    DEBUG=1
                    set -x
                    shift
                fi
                if [ "$1" == "-rtpengine" ]; then
                    uninstallRTPEngine
                fi
                uninstall
                cleanupAndExit 0
                ;;
            start)
                shift
                if [ "$1" == "-debug" ]; then
                    DEBUG=1
                    set -x
                    shift
                fi
                if [ "$1" == "-rtpengine" ]; then
                    startRTPEngine
                fi
                start
                cleanupAndExit 0
                ;;
			stop)
			    shift
                if [ "$1" == "-debug" ]; then
                    DEBUG=1
                    set -x
                    shift
                fi
                stop
                cleanupAndExit 0
                ;;
            restart)
                shift
                if [ "$1" == "-debug" ]; then
                    DEBUG=1
                    set -x
                fi
                stop
                start
                cleanupAndExit 0
                ;;
			rtpengineonly)
                shift
                if [ "$1" == "-debug" ]; then
                    DEBUG=1
                    set -x
                fi
                if [ "$1" == "-servernat" ]; then
                    SERVERNAT=1
                fi
                installRTPEngine
                cleanupAndExit 0
                ;;
			configurekam)
			    shift
                if [ "$1" == "-debug" ]; then
                    DEBUG=1
                    set -x
                fi
                configureKamailio
                cleanupAndExit 0
                ;;
            sslenable)
                configureSSL
                cleanupAndExit 0
                ;;
            installmodules)
			    shift
                if [ "$1" == "-debug" ]; then
                    DEBUG=1
                    set -x
                fi
                installModules
                cleanupAndExit 0
                ;;
            fixmpath)
			    shift
                if [ "$1" == "-debug" ]; then
                    DEBUG=1
                    set -x
                fi
                fixMPATH
                cleanupAndExit 0
                ;;
            enableservernat)
			    shift
                if [ "$1" == "-debug" ]; then
                    DEBUG=1
                    set -x
                fi
                enableSERVERNAT
	    		echo "SERVERNAT is enabled - Restarting Kamailio is required.  You can restart it by executing: systemctl restart kamailio"
	   		    cleanupAndExit 0
                ;;
            disableservernat)
			    shift
                if [ "$1" == "-debug" ]; then
                    DEBUG=1
                    set -x
                fi
                disableSERVERNAT
                echo "SERVERNAT is disabled - Restarting Kamailio is required.  You can restart it by executing: systemctl restart kamailio"
                cleanupAndExit 0
                ;;
            resetpassword)
			    shift
                if [ "$1" == "-debug" ]; then
                    DEBUG=1
                    set -x
                fi
                resetPassword
                cleanupAndExit 0
                ;;
			-h)
                usageOptions
                cleanupAndExit 0
                ;;
			*)
                usageOptions
                cleanupAndExit 0
                ;;
		esac
	done

	# Display usage options if no options are specified
	usageOptions

} #end of processCMD

processCMD "$@"
