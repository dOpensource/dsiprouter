#!/usr/bin/env bash

. include/common

test="dSIPRouter API Test"

# static settings
project_dir=/opt/dsiprouter
cookie_file=/tmp/cookie

# dynamic settings
proto=$(getConfigAttrib 'DSIP_PROTO' $project_dir/gui/settings.py)
host=$(getConfigAttrib 'DSIP_HOST' $project_dir/gui/settings.py)
port=$(getConfigAttrib 'DSIP_PORT' $project_dir/gui/settings.py)
username=$(getConfigAttrib 'USERNAME' $project_dir/gui/settings.py)
password=$(getConfigAttrib 'PASSWORD' $project_dir/gui/settings.py)
inbound_flag=$(getConfigAttrib 'FLT_INBOUND' $project_dir/gui/settings.py)
# if dsip is bound to all available addresses use localhost
[ "$host" = "0.0.0.0" ] && host="localhost"

# attempt to login to dsiprouter
base_url="${proto}://${host}:${port}"
payload="username=$(uriEncode ${username})&password=$(uriEncode ${password})&nextpage="

declare -a flat_headers=()
declare -A headers=(
    ['Accept']='text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8'
    ['Accept-Encoding']='gzip, deflate'
    ['Accept-Language']='en-US,en;q=0.9'
    ['Cache-Control']='max-age=0'
    ['Connection']='keep-alive'
    ['Content-Type']='application/x-www-form-urlencoded'
    ['User-Agent']='Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/71.0.3578.98 Safari/537.36'
    ['Referer']="${proto}://${host}:${port}/"
    ['Host']="${host}:${port}"
    ['Origin']="${proto}://${host}:${port}"
    ['DNT']='1'
    ['Upgrade-Insecure-Requests']='1'
)
for key in ${!headers[@]}; do flat_headers+=( "$key: ${headers[$key]}" ); done

validate() {
    # attempt to auth and store cookie, we will get a 200 OK on good auth
    status=$(curl -s -L --connect-timeout 3 -c "$cookie_file" -w "%{http_code}" -d "$payload" "${flat_headers[@]/#/-H}" "$base_url/login" -o /dev/null)
    [ ${status:-400} -ne 200 ] && return 1

    # try navigating to endpoint with cookie, we should get a 200 OK
    status=$(curl -X GET -s --connect-timeout 3 -b "$cookie_file" -w "%{http_code}" "${flat_headers[@]/#/-H}" "$base_url/api/v1/kamailio/stats" -o /dev/null)
    [ ${status:-400} -ne 200 ] && return 1

    # get API Token/Key and try again
    token=$(getConfigAttrib 'DSIP_API_TOKEN' $project_dir/gui/settings.py) 
    status=$(curl -X GET -s --connect-timeout 3 -H "Authorization: Bearer ${token}" -w "%{http_code}" "$base_url/api/v1/kamailio/stats" -o /dev/null)
    [ ${status:-400} -ne 200 ] && return 1

    # create entries for testing /api/v1/mapping endpoint
    prefix0='123456789'
    prefix1='987654321'
    prefix2='01234'
    prefix3='56789'
    mysql kamailio -e "insert into dr_rules values (null,'$inbound_flag','$prefix0','',0,'','66,67','Test DID Mapping 1');"
    mysql kamailio -e "insert into dr_rules values (null,'$inbound_flag','$prefix1','',0,'','66','Test DID Mapping 2');"
    ruleid0=$(mysql kamailio -sA -e "select ruleid from dr_rules where groupid='9000' limit 1;")


    # ==========================
    # GET /api/v1/inboundmapping
    # ==========================
    # valid requests
    [ $(curl -s -X GET --connect-timeout 3 -H "Authorization: Bearer ${token}" -w "%{http_code}" "$base_url/api/v1/inboundmapping" -o /dev/null) -ne 200 ] && return 1
    [ $(curl -s -X GET --connect-timeout 3 -H "Authorization: Bearer ${token}" -w "%{http_code}" "$base_url/api/v1/inboundmapping?ruleid=${ruleid0}" -o /dev/null) -ne 200 ] && return 1
    [ $(curl -s -X GET --connect-timeout 3 -H "Authorization: Bearer ${token}" -w "%{http_code}" "$base_url/api/v1/inboundmapping?did='"${prefix1}"'" -o /dev/null) -ne 200 ] && return 1
    [ $(curl -s -X GET --connect-timeout 3 -H "Authorization: Bearer ${token}" -w "%{http_code}" "$base_url/api/v1/inboundmapping?ruleid=1000000" -o /dev/null) -ne 200 ] && return 1
    [ $(curl -s -X GET --connect-timeout 3 -H "Authorization: Bearer ${token}" -w "%{http_code}" "$base_url/api/v1/inboundmapping?did=1000000" -o /dev/null) -ne 200 ] && return 1
    [ $(curl -s -X GET --connect-timeout 3 -H "Authorization: Bearer ${token}" -w "%{http_code}" "$base_url/api/v1/inboundmapping?ruleid=abcdef" -o /dev/null) -ne 200 ] && return 1
    [ $(curl -s -X GET --connect-timeout 3 -H "Authorization: Bearer ${token}" -w "%{http_code}" "$base_url/api/v1/inboundmapping?did=abcdef" -o /dev/null) -ne 200 ] && return 1
    # invalid requests
    [ $(curl -s -X GET --connect-timeout 3 -H "Authorization: Bearer ${token}" -w "%{http_code}" "$base_url/api/v1/inboundmapping?doesntexist=123" -o /dev/null) -eq 200 ] && return 1

    # ===========================
    # POST /api/v1/inboundmapping
    # ===========================
    # valid requests
    [ $(curl -s -X POST --connect-timeout 3 -H "Authorization: Bearer ${token}" -w "%{http_code}" --connect-timeout 3 -H "Content-Type: application/json" "$base_url/api/v1/inboundmapping" \
        -d '{"did": "'"${prefix2}"'", "servers": ["66","67"], "notes": "'"${prefix2}"' DID Mapping"}' -o /dev/null) -ne 200 ] && return 1
    [ $(curl -s -X POST --connect-timeout 3 -H "Authorization: Bearer ${token}" -w "%{http_code}" --connect-timeout 3 -H "Content-Type: application/json" "$base_url/api/v1/inboundmapping" \
        -d '{"did": "'"${prefix3}"'","servers": ["66","67"]}' -o /dev/null) -ne 200 ] && return 1
    [ $(curl -s -X POST --connect-timeout 3 -H "Authorization: Bearer ${token}" -w "%{http_code}" --connect-timeout 3 -H "Content-Type: application/json" "$base_url/api/v1/inboundmapping" \
        -d '{"did": "", "servers": ["66"], "notes": "Default DID Mapping"}' -o /dev/null) -ne 200 ] && return 1
    # invalid requests
    [ $(curl -s -X POST --connect-timeout 3 -H "Authorization: Bearer ${token}" -w "%{http_code}" --connect-timeout 3 -H "Content-Type: application/json" "$base_url/api/v1/inboundmapping" \
        -d '{"servers": ["66","67"], "notes": "'"${prefix2}"' DID Mapping"}' -o /dev/null) -eq 200 ] && return 1
    [ $(curl -s -X POST --connect-timeout 3 -H "Authorization: Bearer ${token}" -w "%{http_code}" --connect-timeout 3 -H "Content-Type: application/json" "$base_url/api/v1/inboundmapping" \
        -d '{"did": "0", "servers": ["66","67","68","69","70","71","71"], "notes": "0 DID Mapping"}' -o /dev/null) -eq 200 ] && return 1
    [ $(curl -s -X POST --connect-timeout 3 -H "Authorization: Bearer ${token}" -w "%{http_code}" --connect-timeout 3 -H "Content-Type: application/json" "$base_url/api/v1/inboundmapping" \
        -d '{"did": "00", "servers": ["",""], "notes": "00 DID Mapping"}' -o /dev/null) -eq 200 ] && return 1
    [ $(curl -s -X POST --connect-timeout 3 -H "Authorization: Bearer ${token}" -w "%{http_code}" --connect-timeout 3 -H "Content-Type: application/json" "$base_url/api/v1/inboundmapping" \
        -d '{"did": "000", "servers": ["abc","efg"], "notes": "000 DID Mapping"}' -o /dev/null) -eq 200 ] && return 1
    [ $(curl -s -X POST --connect-timeout 3 -H "Authorization: Bearer ${token}" -w "%{http_code}" --connect-timeout 3 -H "Content-Type: application/json" "$base_url/api/v1/inboundmapping" \
        -d '{"did": "0000", "servers": [], "notes": "0000 DID Mapping"}' -o /dev/null) -eq 200 ] && return 1
    [ $(curl -s -X POST --connect-timeout 3 -H "Authorization: Bearer ${token}" -w "%{http_code}" --connect-timeout 3 -H "Content-Type: application/json" "$base_url/api/v1/inboundmapping" \
        -d '{"did": "00000", "notes": "00000 DID Mapping"}' -o /dev/null) -eq 200 ] && return 1

    # ==========================
    # PUT /api/v1/inboundmapping
    # ==========================
    # valid requests
    [ $(curl -s -X PUT --connect-timeout 3 -H "Authorization: Bearer ${token}" -w "%{http_code}" --connect-timeout 3 -H "Content-Type: application/json" "$base_url/api/v1/inboundmapping?ruleid=${ruleid0}" \
        -d '{"did": "01234", "notes": "01234 DID Mapping"}' -o /dev/null) -ne 200 ] && return 1
    [ $(curl -s -X PUT --connect-timeout 3 -H "Authorization: Bearer ${token}" -w "%{http_code}" --connect-timeout 3 -H "Content-Type: application/json" "$base_url/api/v1/inboundmapping?did='"${prefix1}"'" \
        -d '{"servers": ["67"]}' -o /dev/null) -ne 200 ] && return 1
    [ $(curl -s -X PUT --connect-timeout 3 -H "Authorization: Bearer ${token}" -w "%{http_code}" --connect-timeout 3 -H "Content-Type: application/json" "$base_url/api/v1/inboundmapping?did=10000000" \
        -d '{"did": "01234", "notes": "01234 DID Mapping"}' -o /dev/null) -ne 200 ] && return 1
    # invalid requests
    [ $(curl -s -X PUT --connect-timeout 3 -H "Authorization: Bearer ${token}" -w "%{http_code}" --connect-timeout 3 -H "Content-Type: application/json" "$base_url/api/v1/inboundmapping?doesntexist=123" \
        -d '{"notes": "New DID Mapping"}' -o /dev/null) -eq 200 ] && return 1
    [ $(curl -s -X PUT --connect-timeout 3 -H "Authorization: Bearer ${token}" -w "%{http_code}" --connect-timeout 3 -H "Content-Type: application/json" "$base_url/api/v1/inboundmapping" \
        -d '{"notes": "Newer DID Mapping"}' -o /dev/null) -eq 200 ] && return 1
    [ $(curl -s -X PUT --connect-timeout 3 -H "Authorization: Bearer ${token}" -w "%{http_code}" --connect-timeout 3 -H "Content-Type: application/json" "$base_url/api/v1/inboundmapping?did='"${prefix1}"'" \
        -d '{}' -o /dev/null) -eq 200 ] && return 1
    [ $(curl -s -X PUT --connect-timeout 3 -H "Authorization: Bearer ${token}" -w "%{http_code}" --connect-timeout 3 -H "Content-Type: application/json" "$base_url/api/v1/inboundmapping?did=01234" \
        -d '{"doesntexist": "2"}' -o /dev/null) -eq 200 ] && return 1
    [ $(curl -s -X PUT --connect-timeout 3 -H "Authorization: Bearer ${token}" -w "%{http_code}" --connect-timeout 3 -H "Content-Type: application/json" "$base_url/api/v1/inboundmapping?did=01234" \
        -d '{"doesntexist": "2", "notes": "New DID Mapping"}' -o /dev/null) -eq 200 ] && return 1

    # =============================
    # DELETE /api/v1/inboundmapping
    # =============================
    # valid requests
    [ $(curl -s -X DELETE --connect-timeout 3 -H "Authorization: Bearer ${token}" -w "%{http_code}" "$base_url/api/v1/inboundmapping?ruleid=${ruleid0}" -o /dev/null) -ne 200 ] && return 1
    [ $(curl -s -X DELETE --connect-timeout 3 -H "Authorization: Bearer ${token}" -w "%{http_code}" "$base_url/api/v1/inboundmapping?did='"${prefix1}"'" -o /dev/null) -ne 200 ] && return 1
    # invalid requests
    [ $(curl -s -X DELETE --connect-timeout 3 -H "Authorization: Bearer ${token}" -w "%{http_code}" "$base_url/api/v1/inboundmapping?doesntexist=123" -o /dev/null) -eq 200 ] && return 1
    [ $(curl -s -X DELETE --connect-timeout 3 -H "Authorization: Bearer ${token}" -w "%{http_code}" "$base_url/api/v1/inboundmapping" -o /dev/null) -eq 200 ] && return 1


    # if we made it this far all checks passed
    return 0
}

# cleanup, remove cookie, remove DB entries
cleanupHandler() {
    rm -f $cookie_file
    mysql kamailio -e "delete from dr_rules where groupid='$inbound_flag';"
}

trap cleanupHandler EXIT

validate; ret=$?

process_result "$test" $ret
