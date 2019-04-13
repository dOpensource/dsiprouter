#!/usr/bin/env bash
set -x

. include/common

unitname="Domain Pass-Thru"

# static settings
username="1001"
password="1RSk8l6VGKUsl0zzUFYmIwsAIFT9qARM4vGoVB0pf88="
domain="smoketest.com"
host="localhost"
port="5060"

# TODO: add some domain entries

# TODO: send invite with domain auth
# we should be using a template INVITE and replacing values with sed
#sipsak -f INVITE.sip -s sip:$username@$host:$port -H $host -vvv >/dev/null

#echo $(addPBX)
#$(addDomain)

#Reload Kamailio Modules
#kamcmd domain.reload
#kamcmd drouting.reload

# Register User
sipsak -U -C sip:$username@$domain --from sip:$username@$domain -s sip:$username@$host -u $username -a $password -p $host:$port -i -vvv #>/dev/null
ret=$?


process_result "$unitname" $ret
