#!/usr/bin/env bash

. include/common

unitname="DoS and SIP Security - Block Unknown IP"

# settings
source_ip="127.0.0.10"
username="smoketest"
host="localhost"

# Send a bunch of of requests to the server
sipsak -F -d -k $source_ip  -e 500 -s sip:$username@$host >/dev/null

sleep 1
# Check the ipban htable to see if the ipaddress is being blocked after sending a 
# bunch of SIP requests
kamcmd htable.dump ipban | grep -q "$source_ip"
ret=$?

# Clean up, remove the entry
kamcmd htable.delete ipban $source_ip

# TODO: Add a test to validate that the Server user agent is no longer sent

process_result "$unitname" $ret 
