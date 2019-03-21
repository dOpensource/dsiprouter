#!/usr/bin/env bash

. include/common

unitname="PBX and Endpoint Registration"


# settings
username="smoketest"
password="90dsip2432x"
domain="sip.dsiprouter.org"
host="localhost"
port="5060"

# Create a new user
mysql kamailio -e "insert into subscriber values (null,'$username','$host','$password','','','','');"


# Register User
sipsak -U -C sip:$username@$domain -s sip:$username@$host:$port -u $username -a $password -H $host -i -vvv >/dev/null
ret=$?

# Clean up
# Delete user
mysql kamailio -e "delete from subscriber where username='$username' and password='$password';"


process_result "$unitname" $ret 


