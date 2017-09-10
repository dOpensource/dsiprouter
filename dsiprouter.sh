#!/bin/bash
# Uncomment if you want to debug this script.
#set -x

FLT_CARRIER=8
FLT_PBX=9
REQ_PYTHON_MAJOR_VER=3
SYSTEM_KAMAILIO_CONF_DIR=/etc/kamailio
DSIP_KAMAILIO_CONF_DIR=$(pwd)
EXTERNAL_IP=`curl -s ip.alt.io`
INTERNAL_IP=`hostname -I | awk '{print $1}'`

# Get Linux Distro

if [ -f /etc/redhat-release ]; then
 	DISTRO="centos"
    elif [ -f /etc/debian_version ]; then
	DISTRO="debian"
    fi  


# Uncomment and set this variable to an explicit Python executable file name
# If set, the script will not try and find a Python version with 3.5 as the major release number
PYTHON_CMD=/usr/bin/python3.4

function isPythonInstalled {


possible_python_versions=`find / -name "python$REQ_PYTHON_MAJOR_VER*" -type f -executable  2>/dev/null`
for i in $possible_python_versions
do
    ver=`$i -V 2>&1`
    echo $ver | grep $REQ_PYTHON_MAJOR_VER >/dev/null
    if [ $? -eq 0 ]; then
        PYTHON_CMD=$i
        return
    fi
done

#Required version of Python is not found.  So, tell the user to install the required version
    echo -e "\nPlease install at least python version $REQ_PYTHON_VER\n"
    exit

}

function configureKamailio {

# Install schema for drouting module
mysql kamailio -e "delete from version where table_name in ('dr_gateways','dr_groups','dr_gw_lists','dr_rules')"
mysql kamailio -e "drop table if exists dr_gateways,dr_groups,dr_gw_lists,dr_rules"
if [ -e  /usr/share/kamailio/mysql/drouting-create.sql ]; then
        mysql kamailio < /usr/share/kamailio/mysql/drouting-create.sql
else
        sqlscript=`find / -name drouting-create.sql | grep mysql | grep 4. | sed -n 1p`
        mysql kamailio < $sqlscript

fi


# Import Carrier Addresses

if [  -e `which mysqlimport` ]; then
        mysql kamailio -e "delete from address where grp=$FLT_CARRIER"
        sed -i s/FLT_CARRIER/$FLT_CARRIER/g address.csv
        mysqlimport --fields-terminated-by=',' --ignore-lines=0  -L kamailio address.csv
fi


mysql kamailio -e "insert into dr_gateways (gwid,type,address,strip,pri_prefix,attrs,description) select null,grp,ip_addr,'','','',tag from address;"

# Setup Outbound Rules to use Flowroute by default
mysql kamailio -e "insert into dr_rules values (null,8000,'','','','','1,2','Outbound Carriers');"

rm -rf /etc/kamailio/kamailio.cfg.before_dsiprouter
mv ${SYSTEM_KAMAILIO_CONF_DIR}/kamailio.cfg ${SYSTEM_KAMAILIO_CONF_DIR}/kamailio.cfg.before_dsiprouter
ln -s  ${DSIP_KAMAILIO_CONF_DIR}/kamailio_dsiprouter.cfg ${SYSTEM_KAMAILIO_CONF_DIR}/kamailio.cfg


}



# Start RTPEngine


function startRTPEngine {

systemctl start rtpengine

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
	
		echo "Removing RTPEngine for Debian"	
	
	fi

	if [ $DISTRO == "centos" ]; then


		echo "Removing RTPEngine for CentOS"
		systemctl stop rtpengine	
		rm /usr/sbin/rtpengine
		rm /etc/syslog.d/rtpengine 
		rm /etc/rsyslog.d/rtpengine.conf
		rm ./.rtpengineinstalled
		echo "Removed RTPEngine for CentOS"

	fi
fi

} #end of uninstallRTPEngine

# Install the RTPEngine from sipwise
# We are going to install it by default, but will users the ability to 
# to disable it if needed

function installRTPEngine {


#Install required libraries

if [ $DISTRO == "debian" ]; then

	#Install required libraries
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

	rm -rf rtpengine.bak
	mv -f rtpengine rtpengine.bak
	git clone https://github.com/sipwise/rtpengine
        cd rtpengine
	./debian/flavors/no_ngcp
	dpkg-buildpackage
	cd ..
	dpkg -i ngcp-rtpengine-daemon_*

	#cp /etc/rtpengine/rtpengine.sample.conf /etc/rtpengine/rtpengine.conf

	echo -e "
	[rtpengine]
	table = -1
	interface = $EXTERNAL_IP
	listen-udp = 7722
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

        #Enable the RTPEngine to start during boot
        systemctl enable ngcp-rtpengine-daemon
	

fi #end of installing RTPEngine for Debian

if [ $DISTRO == "centos" ]; then

	#Install required libraries
	yum install -y glib2 glib2-devel gcc zlib zlib-devel openssl openssl-devel pcre pcre-devel libcurl libcurl-devel xmlrpc-c xmlrpc-c-devel libpcap-devel hiredis hiredis-devel json-glib json-glib-devel libevent libevent-devel  
	
	#wget https://github.com/libevent/libevent/releases/download/release-2.0.22-stable/libevent-2.0.22-stable.tar.gz
	#tar -xvzf libevent-2.0.22-stable.tar.gz 
	#cd libevent-2.0.22-stable
	#./configure
	#make && make install

	
	if [ $? -ne 0 ]; then
		echo "Problem with installing the required libraries for RTPEngine"
		exit 1
	fi


fi # end of RTPEngine for CentOS Install

#Make and Configure RTPEngine
#It's the same for CentOS and Debian
	
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
		firewall-cmd --zone=public --add-port=10000-20000/udp --permanent
		firewall-cmd --reload

		#Enable the RTPEngine to start during boot
		systemctl enable rtpengine
		
		#File to signify that the install happened
		if [ $? -eq 0 ]; then
			cd ../..
			touch ./.rtpengineinstalled
			echo "RTPEngine has been installed!"
		fi
	fi  #end of configing RTPEngine for CentOS



} #end of installing RTPEngine


function install {

if [ ! -f "./.installed" ]; then
	if [ $DISTRO == "centos" ]; then
        	yum -y install mysql-devel gcc gcc-devel python34  python34-pip python34-devel	
	elif [ $DISTRO == "debian" ]; then
		apt-get -y install build-essential python3-pip python-dev libmysqlclient-dev libmariadb-client-lgpl-dev
		#Setup Firewall for port 5000
		firewall-cmd --zone=public --add-port=5000/tcp --permanent
        	firewall-cmd --reload
        fi
	$PYTHON_CMD -m pip install -r ./gui/requirements.txt
	configureKamailio
	if [ $? -eq 0 ]; then
		echo "dSIPRouter is installed"
		touch ./.installed
		#Let's start it
		start
	else
		echo "dSIPRouter install failed"
		exit 1
	fi

else
	echo "dSIPRouter is already installed"
	exit 1

fi


} #end of install

function uninstall {

if [ ! -f "./.installed" ]; then
	echo "dSIPRouter is not installed!"
else
	#Stop dSIPRouter, remove ./.installed file, close firewall
	stop
	firewall-cmd --zone=public --remove-port=5000/tcp --permanent
        firewall-cmd --reload
	rm ./.installed
	
fi
	


} #end of uninstall


function start {

	#Check if Python is installed before trying to start up the process

	if [ -z ${PYTHON_CMD+x} ]; then
    		isPythonInstalled
	fi

	#Check if the dSIPRouter process is already running

	PID=`cat /var/run/dsiprouter/dsiprouter.pid`
	ps -ef | grep $PID
	if [ $? -eq 0 ]; then
		echo "dSIPRouter is already running under process id $PID"
		exit
	fi

	#Start the process
	
	nohup $PYTHON_CMD ./gui/dsiprouter.py runserver -h 0.0.0.0 -p 5000 >/dev/null 2>&1 &
	# Store the PID of the process
	PID=$!
	if [ $PID -gt 0 ]; then
	      mkdir /var/run/dsiprouter/
	      echo $PID > /var/run/dsiprouter/dsiprouter.pid

              echo "dSIPRouter was started under process id $PID"

        fi
		
	

} #end of start



function stop {

	if [ -e /var/run/dsiprouter/dsiprouter.pid ]; then

		kill -9 `cat /var/run/dsiprouter/dsiprouter.pid`
		rm -rf /var/run/dsiprouter/dsiprouter.pid
		echo "dSIPRouter was stopped"
	fi 	
	

}

function restart {
	stop
	start
	exit
}

function usageOptions {

 echo -e "Usage: $0 install|uninstall [-rtpengine]"
 echo -e "Usage: $0 start|stop|restart"
 echo -e "\ndSIPRouter is a Web Management GUI for Kamailio based on use case design, with a focus on ITSP and Carrier use cases.   This means that we aren’t a general purpose GUI for Kamailio." 
 echo -e "If you want that then use Siremis, which is located at http://siremis.asipto.com/."
 echo -e "\nThis script is used for installing and uninstalling dSIPRouter, which includes installing the Web GUI portion, Kamailio Configuration file and optionally for installing the RTPEngine by SIPwise"
 echo -e "This script can also be used to start, stop and restart dSIPRouter.  It will not restart Kamailio."
 echo -e "\nSupport is available from dOpenSource.  Visit us at https://dopensource.com/dsiprouter or call us at 888-907-2085"
 echo -e "\n\ndOpenSource | A Flyball Company\nMade in Detroit, MI USA"

 exit 0
}

function processCMD {

	while [[ $# > 0 ]]
	do
		key="$1"
		case $key in
			install)
			shift
			if [ "$1" == "-rtpengine" ]; then
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
			stop 
 			start
		 	shift
			exit 0
			;;
			rtpengineonly)
			installRTPEngine
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
