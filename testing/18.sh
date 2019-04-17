#!/usr/bin/env bash

. include/common

unitname="DoS and SIP Security - Doesn't Block Known Carrier IP(s)"

# settings
source_ip="127.0.0.11"
username="smoketest"
host="localhost"

# Add Carrier IP to address table
mysql kamailio -e "insert into address values (null,8,'$source_ip',32,0,'name:Smoke Test Carrier,gwgroup:0');"

# Reload the address table
kamcmd permissions.addressReload >/dev/null

# Send a bunch of of requests to the server
sipsak -F -d -k $source_ip  -e 500 -s sip:$username@$host >/dev/null

sleep 1
# Check the ipban htable to see if the ipaddress is being blocked after sending a 
# bunch of SIP requests
# Using '!' to negate the return code.  I want return code of 1 to negate to a 0 if the source_ip is not found in the ipban table
! kamcmd htable.dump ipban | grep -q "$source_ip"
ret=$?

# Clean up, remove the entry
kamcmd htable.delete ipban $source_ip

# TODO: Add a test to validate that the Server user agent is no longer sento

# Remove IP from Carrier table
mysql kamailio -e "delete from address where tag like '%Smoke Test Carrier%';"

process_result "$unitname" $ret 
