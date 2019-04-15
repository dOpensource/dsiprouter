#!/usr/bin/env bash
#set -x

. include/common

unitname="Domain Pass-Thru using FreePBX"

# static settings
username="1001"
password="1RSk8l6VGKUsl0zzUFYmIwsAIFT9qARM4vGoVB0pf88="
domain="smoketest.com"
host="localhost"
port="5060"
externalip=$(getExternalIP)


$(addPBX)
$(addDomain)

#Reload Kamailio Modules
kamcmd domain.reload
kamcmd drouting.reload

# Register User
sipsak -U -C sip:$username@home.com --from sip:$username@$domain -u $username -a $password -p $externalip:$port -s sip:$username@$domain -i -vvv >/dev/null
ret=$?

#Clean Up
deletePBX
deleteDomain

process_result "$unitname" $ret
