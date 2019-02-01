#!/bin/bash

. include/common

unitname="DoS and SIP Security"

source_ip=127.0.0.10

# Send a bunch of of requests to the server
sipsak -F -d -k $source_ip  -e500 -s sip:smoketest@localhost > /dev/null

# Check the ipban htable to see if the ipaddress is being blocked after sending a 
# bunch of SIP requests
kamcmd htable.dump ipban | grep $source_ip > /dev/null
ret=$?

# TODO: Add a test to validate that the Server user agent is no longer sent

# Clean up
# Restart Kamailio so that the ipban htable is cleaned up
systemctl restart kamailio

process_result "$unitname" $ret 


