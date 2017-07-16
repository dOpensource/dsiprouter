#!/bin/bash
# Uncomment if you want to debug this script
set -x

FLT_CARRIER=8
FLT_PBX=9
REQ_PYTHON_MAJOR_VER=3
SYSTEM_KAMAILIO_CONF_DIR=/etc/kamailio
DSIP_KAMAILIO_CONF_DIR=$(pwd)

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


if [ ! -f "./.installed" ]; then
        yum install yum install mysql-devel gcc gcc-devel i python34  python34-pip python34-devel	
	$PYTHON_CMD -m pip install -r ./gui/requirements.txt
	configureKamailio
	if [ $? -eq 0 ]; then
		echo "dSIPRouter is installed"
		touch ./.installed
    		isPythonInstalled
		nohup $PYTHON_CMD ./gui/dsiprouter.py runserver -h 0.0.0.0 -p 5000 >/dev/null 2>&1 &
		if [ $? -eq 0 ]; then
			echo "dSIPRouter is running"
		fi
	else
		echo "dSIPRouter install failed"
		exit 1
	fi


else

	if [ -z ${PYTHON_CMD+x} ]; then
    		isPythonInstalled
	fi

	nohup $PYTHON_CMD ./gui/dsiprouter.py runserver -h 0.0.0.0 -p 5000 >/dev/null 2>&1 &
	if [ $? -eq 0 ]; then
              echo "dSIPRouter is running"
        fi
fi
