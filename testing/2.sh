#!/bin/bash

. include/common

unitname="PBX and Endpoint Registration"

#username

username="smoketest"
password="90dsip2432x"

# Create a new user
mysql kamailio -e "insert into subscriber values (null,'$username','localhost','$password','','','','');"


# Register User
sipsak -U -C sip:client@sip.dsiprouter.org  -s sip:$username@localhost -a $password -vvv -i > /dev/null
ret=$?

# Clean up
# Delete user
mysql kamailio -e "delete from subscriber where username='$username' and password='$password';"


process_result "$unitname" $ret 


