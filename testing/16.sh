#!/usr/bin/env bash

. include/common

unitname="JSONRPC Access to Kamailio"

# static settings
project_dir=/opt/dsiprouter
source_ip="127.0.0.1"
sip_port="5060"
rpc_proto="http"
host="localhost"

# Send a bunch of of requests to the server
curl -s -X GET --connect-timeout 3 -d '{"jsonrpc": "2.0", "method": "core.psx", "id": 1}' "${rpc_proto}://${host}:${sip_port}/api/kamailio" > /dev/null
ret=$?

process_result "$unitname" $ret