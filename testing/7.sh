#!/usr/bin/env bash

. include/common

unitname="SIP INVITE via Carrier using Username/Password Auth"

# settings
username="smoketest"
password="90dsip2432x"
domain="sip.dsiprouter.org"
host="localhost"
port="5060"

# Create a new user
mysql kamailio -e "insert into subscriber values (null,'$username','$host','$password','','','','');"

# Add Carrier Group
mysql kamailio -e "insert into dr_gw_lists values (null,'','name:Smoketest CarrierGroup');"
gwgroupid=`mysql kamailio -s -N -e "select id from dr_gw_lists where description like '%Smoketest%';"`

# Add Carrier
mysql kamailio -e "insert into dr_gateways values (null,8,'demo.dsiprouter.org',0,'','','name:Smoketest Carrier,gwgroup:$gwgroupid');"
gwid=`mysql kamailio -s -N -e "select gwid from dr_gateways where description like '%Smoketest%';"`

# Update the Carrier Group with the Carrier id
mysql kamailio -e "update dr_gw_lists set gwlist=$gwid where id=$gwgroupid;"

# Add Carrier Username/Password Auth info
externalip=$(getExternalIP)
mysql kamailio -e "insert into uacreg values (null,$gwgroupid,'$username','$externalip','$username','$domain','$domain','$username','$password','','','60','1','0','');"

# Test auth credentials of the user created
sipsak -U -C sip:$username@$domain -s sip:$username@$host:$port -u $username -a $password -H $host -i -vvv >/dev/null
ret=$?

# TODO: we need to send INVITE, but sipsak won't allow us to change contact header on invite:
#sipsak -I -U -C sip:$username@$domain -s sip:$username@$host:$port -u $username -a $password -H $host -i -vvv >/dev/null
#sipsak -I -U -s sip:$username@$host:$port -u $username -a $password -H $host -i -vvv >/dev/null

# Clean up
# Delete all database entries
mysql kamailio -e "delete from subscriber where username='$username' and password='$password';"
mysql kamailio -e "delete from dr_gw_lists where id=$gwgroupid;"
mysql kamailio -e "delete from dr_gateways where gwid=$gwid;"
mysql kamailio -e "delete from uacreg where l_uuid=$gwgroupid;"

process_result "$unitname" $ret
