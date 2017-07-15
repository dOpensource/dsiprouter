# Setup Kamailio tables to support a carrier

# Continute the bash script even if it fails
set +e

# The flags used to define if a source system is a Carrier or PBX

FLT_CARRIER=8
FLT_PBX=9

# Address Rules for testing from the dOpenSource Networks

#mysql -e "insert into kamailio.address values (null,$FLT_CARRIER,'50.253.243.17',32,0,'dOpenSource VPN');"
#mysql -e "insert into kamailio.address values (null,$FLT_CARRIER,'23.253.160.175',32,0,'dOpenSource Jumpbox');"

# Install schema for drouting module
mysql kamailio -e "delete from version where table_name in ('dr_gateways','dr_groups','dr_gw_lists','dr_rules')"
mysql kamailio -e "drop table if exists dr_gateways,dr_groups,dr_gw_lists,dr_rules"
if [ -e  /usr/share/kamailio/mysql/drouting-create.sql ]; then
	mysql kamailio < /usr/share/kamailio/mysql/drouting-create.sql
else
	sqlscript=`find / -name drouting-create.sql | grep mysql | grep 4. | sed -n 1p`
	mysql kamailio < $sqlscript	 

fi

# Import DRouting Gateways 
if [  -e `which mysqlimport` ]; then
	mysql kamailio -e "truncate table dr_gateways"
	mysqlimport --fields-terminated-by=',' --ignore-lines=2  -L kamailio dr_gateways.csv
	
fi

# Import Carrier Addresses

if [  -e `which mysqlimport` ]; then
        mysql kamailio -e "delete from address where grp=$FLT_CARRIER"
        sed s/FLT_CARRIER/$FLT_CARRIER/g carriers.csv > address.csv
        mysqlimport --fields-terminated-by=',' --ignore-lines=0  -L kamailio address.csv
	rm address.csv
fi

# Import PBX Addresses

if [  -e `which mysqlimport` ]; then
        mysql kamailio -e "delete from address where grp=$FLT_PBX"
        sed s/FLT_PBX/$FLT_PBX/g pbxs.csv > address.csv
        mysqlimport --fields-terminated-by=',' --ignore-lines=0  -L kamailio address.csv
	rm address.csv
fi

# Setup Outbound Rules to use Flowroute
mysql kamailio -e "insert into dr_rules values (null,8000,'.','','','','1,2','Outbound Carriers');"
 
# Symbolic link this configuaration file to the /etc/kamailio.cfg file

KAMAILIO_CONF_DIR=/etc/kamailio
LOCAL_KAMAILIO_CONF_FILE=$(pwd)/kamailio_carrier.cfg

#Use these to create gateway tables after crateing addresses
#insert into dr_gateways (gwid,type,address,strip,pri_prefix,attrs,description) select null,grp,ip_addr,'','','',tag from address;

mv ${KAMAILIO_CONF_DIR}/kamailio.cfg ${KAMAILIO_CONF_DIR}/kamailio.cfg.bak
rm -f ${KAMAILIO_CONF_DIR}/kamailio.cfg
ln -s ${LOCAL_KAMAILIO_CONF_FILE} /etc/kamailio/kamailio.cfg
