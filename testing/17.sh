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
internalip=$INTERNAL_IP

$(addPBX)
$(addDomain)

#Reload Kamailio Modules
kamcmd domain.reload
kamcmd drouting.reload

# Register User
# Try external ip
sipsak -U -C sip:$username@home.com --from sip:$username@$domain -u $username -a $password -p $externalip:$port -s sip:$username@$domain -i -vvv >/dev/null
ret=$?
# Try internal ip if it fails
if [ "$ret" != "0" ]; then
	sipsak -U -C sip:$username@home.com --from sip:$username@$domain -u $username -a $password -p $internalip:$port -s sip:$username@$domain -i -vvv >/dev/null
	ret=$?
fi

#Clean Up
deletePBX
deleteDomain

process_result "$unitname" $ret
