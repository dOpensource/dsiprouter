#!/bin/bash
. include/common
set -x 

unitname="JSON over HTTP Access to Kamailio RPC Commands"

source_ip=127.0.0.1

# Send a bunch of of requests to the server
curl -s -X GET --data-raw '{"jsonrpc": "2.0", "method": "core.psx","id": 1}' http://localhost:5060/api/kamailio > /dev/null

ret=$?

process_result "$unitname" $ret 


