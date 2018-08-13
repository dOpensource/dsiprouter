#!/bin/bash
# Uncomment if you want to debug this script.
#set -x

# Define some global variables
SERVERNAT=0
FLT_CARRIER=8
FLT_PBX=9
REQ_PYTHON_MAJOR_VER=3
SYSTEM_KAMAILIO_CONF_DIR="/etc/kamailio"
DSIP_KAMAILIO_CONF_DIR=$(pwd)
DEFAULTS_DIR=${DSIP_KAMAILIO_CONF_DIR}/kamailio/defaults
DEBUG=0 # By default debugging is turned off, but can be enabled during startup by using "start -debug" parameters

# Default MYSQL install values
MYSQL_KAM_DEF_USERNAME="kamailio"
MYSQL_KAM_DEF_PASSWORD="kamailiorw"
MYSQL_KAM_DEF_DATABASE="kamailio"

# Grab dynamic values
DSIP_PORT=$(cat ${DSIP_KAMAILIO_CONF_DIR}/gui/settings.py | grep -oP 'DSIP_PORT[[:space:]]?=[[:space:]]?\K[0-9]*')
EXTERNAL_IP=`curl -s ip.alt.io`
INTERNAL_IP=`hostname -I | awk '{print $1}'`
INTERNAL_NET=$(awk -F"." '{print $1"."$2"."$3".*"}' <<<$INTERNAL_IP)

# Get Linux Distro
if [ -f /etc/redhat-release ]; then
 	DISTRO="centos"
elif [ -f /etc/debian_version ]; then
	DISTRO="debian"
	DEB_REL=`grep -w "VERSION=" /etc/os-release | sed 's/VERSION=".* (\(.*\))"/\1/'`
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

function validateOSInfo {

if [ "$DISTRO" == "debian" ]; then
	case "$DEB_REL" in

		stretch|jessie)
			KAM_VERSION=51
			;;
		wheezy)
			KAM_VERSION=44
			;;
		*)
			echo "Your operating system is not supported yet. Please open an issue at https://github.com/dOpensource/dsiprouter/"
			exit 1
			;;
	esac
fi

}

# Validate OS and get supported Kamailio versions
validateOSInfo

#Force the installation of a Kamailio version by uncommenting
#KAM_VERSION=44 # Version 4.4.x 
#KAM_VERSION=51 # Version 5.1.x

# Uncomment and set this variable to an explicit Python executable file name
# If set, the script will not try and find a Python version with 3.5 as the major release number
#PYTHON_CMD=/usr/bin/python3.4

function isPythonInstalled {

possible_python_versions=`find /usr/bin -name "python$REQ_PYTHON_MAJOR_VER*" -type f -executable  2>/dev/null`
for i in $possible_python_versions
do
    ver=`$i -V 2>&1`
    if [ $? -eq 0 ]; then  #Check if the version parameter is working correctly
    	echo $ver | grep $REQ_PYTHON_MAJOR_VER >/dev/null
    	if [ $? -eq 0 ]; then
        	PYTHON_CMD=$i
       		return
    	fi
    fi
done

#Required version of Python is not found.  So, tell the user to install the required version
echo -e "\nPlease install at least python version $REQ_PYTHON_MAJOR_VER\n"
exit

}

# set some of the default settings
function configurePythonSettings {

    sed -i -r "s|(KAM_CFG_PATH[[:space:]]?=.*)|KAM_CFG_PATH = '${SYSTEM_KAMAILIO_CONF_DIR}/kamailio.cfg'|g" gui/settings.py

}

function configureKamailio {

if [ "$MYSQL_KAM_PASSWORD" == "" ]; then
    MYSQL_KAM_PASSWORD="-p$MYSQL_KAM_DEF_PASSWORD"
else
    MYSQL_KAM_PASSWORD="-p$MYSQL_KAM__PASSWORD"
fi

if [ "$MYSQL_KAM_USERNAME" == "" ]; then
    MYSQL_KAM_USERNAME=$MYSQL_KAM_DEF_USERNAME
fi

if [ "$MYSQL_KAM_DATABASE" == "" ]; then
    MYSQL_KAM_DATABASE=$MYSQL_KAM_DEF_DATABASE
fi

# required if tables exist and we are updating
function resetIncrementers {
    SQL_TABLES=$(
        (for t in "$@"; do printf ",'$t'"; done) | cut -d ',' -f '2-'
    )

    # reset auto increment for related tables to max btwn the related tables
    INCREMENT=$(
mysql --skip-column-names <<- EOF
    SELECT MAX(AUTO_INCREMENT) FROM  INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = '$MYSQL_KAM_DATABASE'
    AND TABLE_NAME IN($SQL_TABLES);
EOF
    )
    for t in "$@"; do
        mysql -u $MYSQL_KAM_USERNAME $MYSQL_KAM_PASSWORD $MYSQL_KAM_DATABASE \
            -e "ALTER TABLE $t AUTO_INCREMENT=$INCREMENT"
    done
}

# Check the username and password

#mysql -u $MYSQL_KAM_USERNAME $MYSQL_KAM_PASSWORD $MYSQL_KAM_DATABASE -e "select * from version limit 1" >/dev/null 2>&1
#if [ $? -eq 1 ]; then
#	echo "Your credentials for the kamailio schema is invalid.  Please try again!"
#	configureKamailio
#fi

# Install schema for drouting module
mysql -u $MYSQL_KAM_USERNAME $MYSQL_KAM_PASSWORD $MYSQL_KAM_DATABASE \
    -e "delete from version where table_name in ('dr_gateways','dr_groups','dr_gw_lists','dr_rules')"
mysql -u $MYSQL_KAM_USERNAME $MYSQL_KAM_PASSWORD $MYSQL_KAM_DATABASE \
    -e "drop table if exists dr_gateways,dr_groups,dr_gw_lists,dr_rules"
if [ -e  /usr/share/kamailio/mysql/drouting-create.sql ]; then
    mysql -u $MYSQL_KAM_USERNAME $MYSQL_KAM_PASSWORD $MYSQL_KAM_DATABASE < /usr/share/kamailio/mysql/drouting-create.sql
else
        sqlscript=`find / -name 'drouting-create.sql' | grep mysql | grep 4. | sed -n 1p`
    mysql -u $MYSQL_KAM_USERNAME $MYSQL_KAM_PASSWORD $MYSQL_KAM_DATABASE < $sqlscript
fi

# Install schema for custom drouting
mysql -u $MYSQL_KAM_USERNAME $MYSQL_KAM_PASSWORD $MYSQL_KAM_DATABASE < ${DSIP_KAMAILIO_CONF_DIR}/kamailio/custom_routing.sql

# reset auto incrementers for related tables
resetIncrementers "dr_gw_lists" "uacreg"

# Import Default Carriers
if [ -e `which mysqlimport` ]; then
    mysql -u $MYSQL_KAM_USERNAME $MYSQL_KAM_PASSWORD $MYSQL_KAM_DATABASE -e "delete from address where grp=$FLT_CARRIER"

    # sub in dynamic values
    sed -i s/FLT_CARRIER/$FLT_CARRIER/g ${DEFAULTS_DIR}/address.csv
    sed -i s/FLT_CARRIER/$FLT_CARRIER/g ${DEFAULTS_DIR}/dr_gateways.csv
    sed -i s/EXTERNAL_IP/$EXTERNAL_IP/g ${DEFAULTS_DIR}/uacreg.csv

    # import default carriers
    mysqlimport -u $MYSQL_KAM_USERNAME $MYSQL_KAM_PASSWORD --fields-terminated-by=';' --ignore-lines=0  \
        -L $MYSQL_KAM_DATABASE ${DEFAULTS_DIR}/address.csv
    mysqlimport -u $MYSQL_KAM_USERNAME $MYSQL_KAM_PASSWORD --fields-terminated-by=';' --ignore-lines=0  \
        -L $MYSQL_KAM_DATABASE ${DEFAULTS_DIR}/dr_gw_lists.csv
    mysqlimport -u $MYSQL_KAM_USERNAME $MYSQL_KAM_PASSWORD --fields-terminated-by=',' --ignore-lines=0  \
        -L $MYSQL_KAM_DATABASE ${DEFAULTS_DIR}/uacreg.csv
    mysqlimport -u $MYSQL_KAM_USERNAME $MYSQL_KAM_PASSWORD --fields-terminated-by=';' --ignore-lines=0  \
        -L $MYSQL_KAM_DATABASE ${DEFAULTS_DIR}/dr_gateways.csv
fi

# Setup Outbound Rules to use Skyetel by default
mysql  -u $MYSQL_KAM_USERNAME $MYSQL_KAM_PASSWORD $MYSQL_KAM_DATABASE \
    -e "insert into dr_rules values (null,8000,'','','','','1,2','Default Outbound Route');"

# Backup kamcfg and link the dsiprouter kamcfg
cp -f ${SYSTEM_KAMAILIO_CONF_DIR}/kamailio.cfg ${SYSTEM_KAMAILIO_CONF_DIR}/kamailio.cfg.`(date +%Y%m%d_%H%M%S)`
rm -f ${SYSTEM_KAMAILIO_CONF_DIR}/kamailio.cfg
ln -s  ${DSIP_KAMAILIO_CONF_DIR}/kamailio/kamailio${KAM_VERSION}_dsiprouter.cfg ${SYSTEM_KAMAILIO_CONF_DIR}/kamailio.cfg


#Fix the mpath
fixMPATH

#Enable SERVERNAT
if [ "$SERVERNAT" == "1" ]; then
	enableSERVERNAT

fi
}

function enableSERVERNAT {
	sed -i 's/##!define WITH_SERVERNAT/#!define WITH_SERVERNAT/' ${DSIP_KAMAILIO_CONF_DIR}/kamailio/kamailio${KAM_VERSION}_dsiprouter.cfg
	sed -i 's/!INTERNAL_IP_ADDR!.*!g/!INTERNAL_IP_ADDR!'$INTERNAL_IP'!g/' ${DSIP_KAMAILIO_CONF_DIR}/kamailio/kamailio${KAM_VERSION}_dsiprouter.cfg
	sed -i 's/!INTERNAL_IP_NET!.*!g/!INTERNAL_IP_NET!'$INTERNAL_NET'!g/' ${DSIP_KAMAILIO_CONF_DIR}/kamailio/kamailio${KAM_VERSION}_dsiprouter.cfg
	sed -i 's/!EXTERNAL_IP_ADDR!.*!g/!EXTERNAL_IP_ADDR!'$EXTERNAL_IP'!g/' ${DSIP_KAMAILIO_CONF_DIR}/kamailio/kamailio${KAM_VERSION}_dsiprouter.cfg
}

function disableSERVERNAT {
	sed -i 's/#!define WITH_SERVERNAT/##!define WITH_SERVERNAT/' ${DSIP_KAMAILIO_CONF_DIR}/kamailio/kamailio${KAM_VERSION}_dsiprouter.cfg
}

#Try to locate the Kamailio modules directory.  It will use the last modules directory found

function fixMPATH {

for i in `find /usr -name drouting.so`; 
do 
    mpath=`dirname $i| grep 'modules$'`
    if [ "$mpath" != '' ]; then 
        mpath=$mpath/ 
        break #found a mpath
    fi 
done
echo "The Kamailio mpath has been updated to:$mpath"
if [ "$mpath" != '' ]; then 
    sed -i 's#mpath=.*#mpath=\"'$mpath'\"#g' ${DSIP_KAMAILIO_CONF_DIR}/kamailio/kamailio${KAM_VERSION}_dsiprouter.cfg

else
    echo "Can't find the module path for Kamailio.  Please ensure Kamailio is installed and try again!"
    exit 1
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


#Remove RTPEngine

function uninstallRTPEngine {

if [ ! -e ./.rtpengineinstalled ]; then
	echo -e "RTPEngine is not installed!"
else 


#if [ ! -e ./.rtpengineinstalled ]; then
#
#	echo -e "We did not install RTPEngine.  Would you like us to install it? [y/n]:\c"
#	read installrtpengine
#	case "$installrtpengine" in
#		[yY][eE][sS]|[yY])
#		installRTPEngine
#		exit 
#		;;
#		*)
#		exit 1
#		;;
#	esac
#fi 


	if [ $DISTRO == "debian" ]; then
	
		echo "Removing RTPEngine for $DISTRO"	
		systemctl stop rtpengine
                rm /usr/sbin/rtpengine
                rm /etc/syslog.d/rtpengine
                rm /etc/rsyslog.d/rtpengine.conf
                rm ./.rtpengineinstalled
                echo "Removed RTPEngine for $DISTRO"	
	fi

	if [ $DISTRO == "centos" ]; then


		echo "Removing RTPEngine for $DISTRO"
		systemctl stop rtpengine	
		rm /usr/sbin/rtpengine
		rm /etc/syslog.d/rtpengine 
		rm /etc/rsyslog.d/rtpengine.conf
		rm ./.rtpengineinstalled
		echo "Removed RTPEngine for $DISTRO"

	fi
fi

} #end of uninstallRTPEngine

# Install the RTPEngine from sipwise
# We are going to install it by default, but will users the ability to 
# to disable it if needed

function installRTPEngine {

# Install required libraries

if [ $DISTRO == "debian" ]; then

	#Install required libraries
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

	echo -e "
	[rtpengine]
	table = -1
	interface = $INTERFACE
	listen-ng = 7722
	port-min = 10000
	port-max = 30000
        log-level = 7
        log-facility = local1" > /etc/rtpengine/rtpengine.conf

 	
        #sed -i -r  "s/# interface = [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/interface = "$EXTERNAL_IP"/" /etc/rtpengine/rtpengine.conf
	sed -i 's/RUN_RTPENGINE=no/RUN_RTPENGINE=yes/' /etc/default/ngcp-rtpengine-daemon
	#sed -i 's/# listen-udp = 12222/listen-udp = 7222/' /etc/rtpengine/rtpengine.conf

	 #Setup Firewall rules for RTPEngine
         
	firewall-cmd --zone=public --add-port=10000-20000/udp --permanent
        firewall-cmd --reload

	 #Setup RTPEngine Logging
         echo "local1.*                                          -/var/log/rtpengine" >> /etc/rsyslog.d/rtpengine.conf
         touch /var/log/rtpengine
         systemctl restart rsyslog

	#Setup tmp files
	echo "d /var/run/rtpengine.pid  0755 rtpengine rtpengine - -" > /etc/tmpfiles.d/rtpengine.conf

	cp ./dsiprouter/debian/ngcp-rtpengine-daemon.init /etc/init.d/ngcp-rtpengine-daemon

        #Enable the RTPEngine to start during boot
        systemctl enable ngcp-rtpengine-daemon

        #Start RTPEngine
        systemctl start ngcp-rtpengine-daemon
	#Start manually if the service fials to start
	if [ $? -eq 1 ]; then

		/usr/sbin/rtpengine --config-file=/etc/rtpengine/rtpengine.conf --pidfile=/var/run/ngcp-rtpengine-daemon.pid
	fi

	#File to signify that the install happened
        if [ $? -eq 0 ]; then
               touch ./.rtpengineinstalled
               echo "RTPEngine has been installed!"
	else
		echo "FAILED: RTPEngine could not be installed!"
        fi


fi #end of installing RTPEngine for Debian

if [ $DISTRO == "centos" ]; then

	#Install required libraries
	yum install -y glib2 glib2-devel gcc zlib zlib-devel openssl openssl-devel pcre pcre-devel libcurl libcurl-devel xmlrpc-c xmlrpc-c-devel libpcap libpcap-devel hiredis hiredis-devel json-glib json-glib-devel libevent libevent-devel  
	
	#wget https://github.com/libevent/libevent/releases/download/release-2.0.22-stable/libevent-2.0.22-stable.tar.gz
	#tar -xvzf libevent-2.0.22-stable.tar.gz 
	#cd libevent-2.0.22-stable
	#./configure
	#make && make install

	
	if [ $? -ne 0 ]; then
		echo "Problem with installing the required libraries for RTPEngine"
		exit 1
	fi


	#Make and Configure RTPEngine
	
	rm -rf rtpengine.bak
	mv -f rtpengine rtpengine.bak
	git clone https://github.com/sipwise/rtpengine
	cd rtpengine/daemon
	make
	if [ $? -eq 0 ]; then

		# Copy binary to /usr/sbin
		cp rtpengine /usr/sbin/rtpengine

		# Add startup script
		echo -e "[Unit]
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
		" > /etc/systemd/system/rtpengine.service

		#Add Options File
		echo -e "
		# Add extra options here
		# We don't support the NG protocol in this release 
		# 
		OPTIONS="\"-F -i $INTERNAL_IP!$EXTERNAL_IP -u 127.0.0.1:7722 -m 10000 -M 20000 -p /var/run/rtpengine.pid --log-level=7 --log-facility=local1\""
		" > /etc/sysconfig/rtpengine

		#Setup RTPEngine Logging
		echo "local1.*						-/var/log/rtpengine" >> /etc/rsyslog.d/rtpengine.conf
		touch /var/log/rtpengine
		systemctl restart rsyslog

		#Setup Firewall rules for RTPEngine
		firewall-cmd --zone=public --add-port=10000-30000/udp --permanent
		firewall-cmd --reload

		#Enable the RTPEngine to start during boot
		systemctl enable rtpengine
		
		#File to signify that the install happened
		if [ $? -eq 0 ]; then
			cd ../..
			touch ./.rtpengineinstalled
			echo "RTPEngine has been installed!"
		fi
	fi
fi  #end of configing RTPEngine for CentOS



} #end of installing RTPEngine

#Enable RTP within the Kamailio configuration so that it uses the RTPEngine

function enableRTP {

sed -i 's/#!define WITH_NAT/##!define WITH_NAT/' ./kamailio_dsiprouter.cfg

} #end of enableRTP

#Disable RTP within the Kamailio configuration so that it doesn't use the RTPEngine

function disableRTP {

sed -i 's/##!define WITH_NAT/#!define WITH_NAT/' ./kamailio_dsiprouter.cfg

} #end of disableRTP


function install {

if [ ! -f "./.installed" ]; then

	cd ${DSIP_KAMAILIO_CONF_DIR} 

	# Check if Python is installed before trying to start up the process
        if [ -z ${PYTHON_CMD+x} ]; then
            isPythonInstalled
        fi
	
	if [ $DISTRO == "centos" ]; then
	    PIP_CMD="pip"
        yum -y install mysql-devel gcc gcc-devel python34  python34-pip python34-devel
		firewall-cmd --zone=public --add-port=${DSIP_PORT}/tcp --permanent
        firewall-cmd --reload

	elif [ $DISTRO == "debian" ]; then
		echo -e "Attempting to install Kamailio...\n"
        	./kamailio/$DISTRO/$DEB_REL.sh install ${KAM_VERSION} ${DSIP_PORT}
		if [ $? -eq 0 ]; then
			echo "Kamailio was installed!"
		else
			echo "dSIPRouter install failed: Couldn't install Kamailio"
			exit
		fi
		echo -e "Attempting to install dSIPRouter...\n" 	
		./dsiprouter/$DISTRO/$DEB_REL.sh install ${DSIP_PORT} $PYTHON_CMD
    fi

	# Configure Kamailio and Install dSIPRouter Modules
	if [ $? -eq 0 ]; then
		configureKamailio
        installModules
	fi

	# set some defaults in settings.py
	configurePythonSettings

	# Restart Kamailio with the new configurations
	systemctl restart kamailio
	if [ $? -eq 0 ]; then
		touch ./.installed
		echo -e "\e[32m-------------------------\e[0m"
		echo -e "\e[32mInstallation is complete! \e[0m"
		echo -e "\e[32m-------------------------\e[0m\n"
		displayLogo
        	echo -e "\n\nThe username and dynamically generated password are below:\n"
		
		#Generate a unique admin password
       		generatePassword
		
		#Start dSIPRouter
		start

		#Tell them how to access the URL

		echo -e "You can access the dSIPRouter web gui by going to:\n"
		echo -e "External IP:  http://$EXTERNAL_IP:$DSIP_PORT\n"
		
		if [ "$EXTERNAL_IP" != "$INTERNAL_IP" ];then
			echo -e "Internal IP:  http://$INTERNAL_IP:$DSIP_PORT"
		fi

		#echo -e "Your Kamailio configuration has been backed up and a new configuration has been installed.  Please restart Kamailio so that the changes can become active\n"
	else
		echo "dSIPRouter install failed: Couldn't configure Kamailio correctly"
		exit 1
	fi
else
	echo "dSIPRouter is already installed"
	exit 1

fi


} #end of install

function uninstall {

if [ ! -f "./.installed" ]; then
	echo "dSIPRouter is not installed or failed during install - uninstalling anyway to be safe"
fi
	#Stop dSIPRouter, remove ./.installed file, close firewall
	stop
    
	if [ $DISTRO == "centos" ]; then
        PIP_CMD="pip"
        yum -y remove mysql-devel gcc gcc-devel python34  python34-pip python34-devel
		firewall-cmd --zone=public --add-port=${DSIP_PORT}/tcp --permanent
        firewall-cmd --reload
	
	elif [ $DISTRO == "debian" ]; then
		echo -e "Attempting to uninstall dSIPRouter...\n" 	
		./dsiprouter/$DISTRO/$DEB_REL.sh uninstall ${DSIP_PORT} ${PYTHON_CMD}
		
		echo -e "Attempting to uninstall Kamailio...\n"
        ./kamailio/$DISTRO/$DEB_REL.sh uninstall ${KAM_VERSION} ${DSIP_PORT} ${PYTHON_CMD}
		if [ $? -eq 0 ]; then
			echo "Kamailio was uninstalled!"
		else
			echo "dSIPRouter uninstall failed: Couldn't install Kamailio"
			exit
		fi

        fi

     
    #Remove crontab entry
    echo "Removing crontab entry"
    crontab -l | grep -v -F -w dsiprouter_cron | crontab -

    #Remove the hidden installed file, which denotes if it's installed or not
	rm ./.installed

    echo "dSIPRouter was uninstalled"
	


} #end of uninstall


function installModules {

    #if [ -z "${MYSQL_KAM_USERNAME-}" ]; then
	MYSQL_KAM_USERNAME=$MYSQL_KAM_DEF_USERNAME
    #fi
    #if [ -z "${MYSQL_KAM_PASSWORD-}" ]; then
	MYSQL_KAM_PASSWORD=$MYSQL_KAM_DEF_PASSWORD
    #fi
    #if [ -z "${MYSQL_KAM_DATABASE-}" ]; then
	MYSQL_KAM_DATABASE=$MYSQL_KAM_DEF_DATABASE
    #fi

    #Install dSIPModules
    for dir in ./gui/modules/*; 
    do 
        $dir/install.sh $MYSQL_KAM_USERNAME $MYSQL_KAM_PASSWORD $MYSQL_KAM_DATABASE $PYTHON_CMD
    done

    #Setup dSIPRouter Cron scheduler
    crontab -l | grep -v -F -w dsiprouter_cron | crontab -
    echo -e "*/1 * * * *  $PYTHON_CMD `(pwd)`/gui/dsiprouter_cron.py" | crontab -


}


function start {

	#Check if Python is installed before trying to start up the process

	if [ -z ${PYTHON_CMD+x} ]; then
    		isPythonInstalled
	fi

	#Check if the dSIPRouter process is already running
	
	if [ -e /var/run/dsiprouter/dsiprouter.pid ]; then 
		PID=`cat /var/run/dsiprouter/dsiprouter.pid`
		ps -ef | grep $PID > /dev/null
		if [ $? -eq 0 ]; then
			echo "dSIPRouter is already running under process id $PID"
			exit
		fi
	fi

	#Start RTPEngine if it was installed

	if [ -e ./.rtpengineinstalled ]; then

		startRTPEngine
        fi

	#Start the process
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
        kill -9 `pgrep -f runserver`
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
	exit
}

function resetPassword {

echo -e "The admin account has been reset to the following:\n"

#Call the bash function that generates the password
generatePassword

#dSIPRouter will be restarted to make the new password active
echo -e "Restart dSIPRouter to make the password active!\n"

}

# Generate password and set it in the ${DSIP_KAMAILIO_CONF_DIR}/gui/settings.py PASSWORD field
function generatePassword {

password=`date +%s | sha256sum | base64 | head -c 16`

#Add single quotes

password1=\'$password\'
sed -i 's/PASSWORD[[:space:]]\?=[[:space:]]\?.*/PASSWORD = '$password1'/g' ${DSIP_KAMAILIO_CONF_DIR}/gui/settings.py

echo -e "username: admin\npassword: $password\n"

}

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

 exit 1
}


function processCMD {

	while [[ $# > 0 ]]
	do
		key="$1"
		case $key in
			install)
			shift
			if [ "$1" == "-rtpengine" ] && [ "$2" == "-servernat" ]; then
				SERVERNAT=1
				installRTPEngine
			
			elif [ "$1" == "-rtpengine" ]; then
				installRTPEngine
			fi
			install
			shift
			exit 0
			;;
			uninstall)
			shift
			if [ "$1" == "-rtpengine" ]; then
				uninstallRTPEngine
			fi
			uninstall
			exit 0
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
			shift
			exit 0
			;;
			stop)
			stop
			shift
			exit 0
			;;
			restart)
			if [ "$1" == "-debug" ]; then
                                DEBUG=1
				set -x
            		fi
			stop 
 			start
		 	shift
			exit 0
			;;
			rtpengineonly)
			shift
			if [ "$1" == "-servernat" ]; then
				SERVERNAT=1
			fi
			installRTPEngine
			exit 0
			;;
			configurekam)
			configureKamailio
			exit 0
			;;	
            		installmodules)
            		installModules
            		exit 0
            		;;
            		fixmpath)
            		fixMPATH
            		exit 0
            		;;
    	    		enableservernat)
	    		enableSERVERNAT
	    		echo "SERVERNAT is enabled - Restarting Kamailio is required.  You can restart it by excuting: systemctl restart kamailio"
	   		exit 0
	    		;;
    	    		disableservernat)
	    		disableSERVERNAT
	    		echo "SERVERNAT is disabled - Restarting Kamailio is required.  You can restart it by excuting: systemctl restart kamailio"
	    		exit 0
	    		;;
           		 resetpassword)
            		resetPassword
            		exit 0
           		 ;;
			-h)
			usageOptions
			exit 0
			;;
			*)
			usageOptions
			exit 0
			;;
		esac
	done

	#Display usage options if no options are specified

	usageOptions	
	
	

} #end of processCMD



processCMD "$@"
