#!/usr/bin/env bash

. include/common

test="dSIPRouter API Test"

# static settings
project_dir=/opt/dsiprouter
cookie_file=/tmp/cookie
temp_pass='temp'
temp_token='temp'

# dynamic settings
proto=$(getConfigAttrib 'DSIP_PROTO' ${DSIP_CONFIG_FILE})
host='127.0.0.1'
port=$(getConfigAttrib 'DSIP_PORT' ${DSIP_CONFIG_FILE})
username=$(getConfigAttrib 'DSIP_USERNAME' ${DSIP_CONFIG_FILE})
dsip_id=$(getConfigAttrib 'DSIP_ID' ${DSIP_CONFIG_FILE})
pid_file=$(getConfigAttrib 'DSIP_PID_FILE' ${DSIP_CONFIG_FILE})
load_from=$(getConfigAttrib 'LOAD_SETTINGS_FROM' ${DSIP_CONFIG_FILE})
kam_db_host=$(getConfigAttrib 'KAM_DB_HOST' ${DSIP_CONFIG_FILE})
kam_db_port=$(getConfigAttrib 'KAM_DB_PORT' ${DSIP_CONFIG_FILE})
kam_db_name=$(getConfigAttrib 'KAM_DB_NAME' ${DSIP_CONFIG_FILE})
kam_db_user=$(getConfigAttrib 'KAM_DB_USER' ${DSIP_CONFIG_FILE})
kam_db_pass=$(decryptConfigAttrib 'KAM_DB_PASS' ${DSIP_CONFIG_FILE})
old_api_token=$(kamcmd cfg.get server api_token)
inbound_flag=$(getConfigAttrib 'FLT_INBOUND' ${DSIP_CONFIG_FILE})

# if dsip is bound to all available addresses use localhost
[ "$host" = "0.0.0.0" ] && host="localhost"

# attempt to login to dsiprouter
base_url="${proto}://${host}:${port}"
payload="username=$(uriEncode ${username})&password=$(uriEncode ${temp_pass})&nextpage="

declare -a flat_headers=()
declare -A headers=(
    ['Accept']='text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8'
    ['Accept-Encoding']='gzip, deflate'
    ['Accept-Language']='en-US,en;q=0.9'
    ['Cache-Control']='max-age=0'
    ['Connection']='keep-alive'
    ['Content-Type']='application/x-www-form-urlencoded'
    ['DNT']='1'
    ['Host']="${host}:${port}"
    ['Origin']="${proto}://${host}:${port}"
    ['Referer']="${proto}://${host}:${port}/"
    ['Upgrade-Insecure-Requests']='1'
    ['User-Agent']='Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.130 Safari/537.36'
)
for key in ${!headers[@]}; do flat_headers+=( "$key: ${headers[$key]}" ); done

setLoginOverride() {
    # make copy of settings
    cp -f ${DSIP_CONFIG_FILE} ${DSIP_CONFIG_FILE}.bak
    # update setting
    if [[ "$load_from" == "file" ]]; then
        setConfigAttrib 'DSIP_PASSWORD' "${temp_pass}" ${DSIP_CONFIG_FILE} -q
        setConfigAttrib 'DSIP_API_TOKEN' "${temp_pass}" ${DSIP_CONFIG_FILE} -q
    elif [[ "$load_from" == "db" ]]; then
        mysql --user="${kam_db_user}" --password="${kam_db_pass}" --host="${kam_db_host}" --port="${kam_db_port}" --database="${kam_db_name}" \
            -e "update dsip_settings set DSIP_PASSWORD='${temp_pass}', DSIP_API_TOKEN='${temp_token}' where dsip_id=${dsip_id}"
    fi
    # sync settings
    kill -SIGUSR1 $(cat $pid_file) 2>/dev/null
    sleep 1
}

unsetLoginOverride() {
    # revert changes
    mv -f ${DSIP_CONFIG_FILE}.bak ${DSIP_CONFIG_FILE}
    # sync settings
    kill -SIGUSR1 $(cat $pid_file) 2>/dev/null
    sleep 1
}

# TODO: update these tests for new endpoint args, etc..
validate() {
    # update kams api token for testing
    kamcmd cfg.sets server api_token $temp_token

    # attempt to auth and store cookie, we will get a 200 OK on good auth
    status=$(curl -s -L --connect-timeout 3 -c "$cookie_file" -w "%{http_code}" -d "$payload" "${flat_headers[@]/#/-H}" "$base_url/login" -o /dev/null)
    [ ${status:-400} -ne 200 ] && return 1

    # try navigating to endpoint with cookie, we should get a 200 OK
    status=$(curl -X GET -s --connect-timeout 3 -b "$cookie_file" -w "%{http_code}" "${flat_headers[@]/#/-H}" "$base_url/api/v1/kamailio/stats" -o /dev/null)
    [ ${status:-400} -ne 200 ] && return 1

    # try again with API token
    status=$(curl -X GET -s --connect-timeout 3 -H "Authorization: Bearer ${temp_token}" -w "%{http_code}" "$base_url/api/v1/kamailio/stats" -o /dev/null)
    [ ${status:-400} -ne 200 ] && return 1

    # create entries for testing /api/v1/mapping endpoint
    prefix0='123456789'
    prefix1='987654321'
    prefix2='01234'
    prefix3='56789'
    mysql --user="${kam_db_user}" --password="${kam_db_pass}" --host="${kam_db_host}" --port="${kam_db_port}" --database="${kam_db_name}" \
        -e "insert into dr_rules values (null,'$inbound_flag','$prefix0','',0,'','66,67','name:Test DID Mapping 1');" \
        -e "insert into dr_rules values (null,'$inbound_flag','$prefix1','',0,'','66','name:Test DID Mapping 2');"
    ruleid0=$(mysql --user="${kam_db_user}" --password="${kam_db_pass}" --host="${kam_db_host}" --port="${kam_db_port}" --database="${kam_db_name}" \
        -sA -e "select ruleid from dr_rules where groupid='$inbound_flag' limit 1;")


    # ==========================
    # GET /api/v1/inboundmapping
    # ==========================
    # valid requests
    [ $(curl -s -X GET --connect-timeout 3 -H "Authorization: Bearer ${temp_token}" -w "%{http_code}" "$base_url/api/v1/inboundmapping" -o /dev/null) -ne 200 ] && return 1
    [ $(curl -s -X GET --connect-timeout 3 -H "Authorization: Bearer ${temp_token}" -w "%{http_code}" "$base_url/api/v1/inboundmapping?ruleid=${ruleid0}" -o /dev/null) -ne 200 ] && return 1
    [ $(curl -s -X GET --connect-timeout 3 -H "Authorization: Bearer ${temp_token}" -w "%{http_code}" "$base_url/api/v1/inboundmapping?did='"${prefix1}"'" -o /dev/null) -ne 200 ] && return 1
    [ $(curl -s -X GET --connect-timeout 3 -H "Authorization: Bearer ${temp_token}" -w "%{http_code}" "$base_url/api/v1/inboundmapping?ruleid=1000000" -o /dev/null) -ne 200 ] && return 1
    [ $(curl -s -X GET --connect-timeout 3 -H "Authorization: Bearer ${temp_token}" -w "%{http_code}" "$base_url/api/v1/inboundmapping?did=1000000" -o /dev/null) -ne 200 ] && return 1
    [ $(curl -s -X GET --connect-timeout 3 -H "Authorization: Bearer ${temp_token}" -w "%{http_code}" "$base_url/api/v1/inboundmapping?ruleid=abcdef" -o /dev/null) -ne 200 ] && return 1
    [ $(curl -s -X GET --connect-timeout 3 -H "Authorization: Bearer ${temp_token}" -w "%{http_code}" "$base_url/api/v1/inboundmapping?did=abcdef" -o /dev/null) -ne 200 ] && return 1
    # invalid requests
    [ $(curl -s -X GET --connect-timeout 3 -H "Authorization: Bearer ${temp_token}" -w "%{http_code}" "$base_url/api/v1/inboundmapping?doesntexist=123" -o /dev/null) -eq 200 ] && return 1

    # ===========================
    # POST /api/v1/inboundmapping
    # ===========================
    # valid requests
    [ $(curl -s -X POST --connect-timeout 3 -H "Authorization: Bearer ${temp_token}" -w "%{http_code}" --connect-timeout 3 -H "Content-Type: application/json" "$base_url/api/v1/inboundmapping" \
        -d '{"did": "'"${prefix2}"'", "servers": ["66","67"], "name": "'"${prefix2}"' DID Mapping"}' -o /dev/null) -ne 200 ] && return 1
    [ $(curl -s -X POST --connect-timeout 3 -H "Authorization: Bearer ${temp_token}" -w "%{http_code}" --connect-timeout 3 -H "Content-Type: application/json" "$base_url/api/v1/inboundmapping" \
        -d '{"did": "'"${prefix3}"'","servers": ["66","67"]}' -o /dev/null) -ne 200 ] && return 1
    [ $(curl -s -X POST --connect-timeout 3 -H "Authorization: Bearer ${temp_token}" -w "%{http_code}" --connect-timeout 3 -H "Content-Type: application/json" "$base_url/api/v1/inboundmapping" \
        -d '{"did": "", "servers": ["66"], "name": "Default DID Mapping"}' -o /dev/null) -ne 200 ] && return 1
    # invalid requests
    [ $(curl -s -X POST --connect-timeout 3 -H "Authorization: Bearer ${temp_token}" -w "%{http_code}" --connect-timeout 3 -H "Content-Type: application/json" "$base_url/api/v1/inboundmapping" \
        -d '{"servers": ["66","67"], "name": "'"${prefix2}"' DID Mapping"}' -o /dev/null) -eq 200 ] && return 1
    [ $(curl -s -X POST --connect-timeout 3 -H "Authorization: Bearer ${temp_token}" -w "%{http_code}" --connect-timeout 3 -H "Content-Type: application/json" "$base_url/api/v1/inboundmapping" \
        -d '{"did": "0", "servers": ["66","67","68","69","70","71","71"], "name": "0 DID Mapping"}' -o /dev/null) -eq 200 ] && return 1
    [ $(curl -s -X POST --connect-timeout 3 -H "Authorization: Bearer ${temp_token}" -w "%{http_code}" --connect-timeout 3 -H "Content-Type: application/json" "$base_url/api/v1/inboundmapping" \
        -d '{"did": "00", "servers": ["",""], "name": "00 DID Mapping"}' -o /dev/null) -eq 200 ] && return 1
    [ $(curl -s -X POST --connect-timeout 3 -H "Authorization: Bearer ${temp_token}" -w "%{http_code}" --connect-timeout 3 -H "Content-Type: application/json" "$base_url/api/v1/inboundmapping" \
        -d '{"did": "000", "servers": ["abc","efg"], "name": "000 DID Mapping"}' -o /dev/null) -eq 200 ] && return 1
    [ $(curl -s -X POST --connect-timeout 3 -H "Authorization: Bearer ${temp_token}" -w "%{http_code}" --connect-timeout 3 -H "Content-Type: application/json" "$base_url/api/v1/inboundmapping" \
        -d '{"did": "0000", "servers": [], "name": "0000 DID Mapping"}' -o /dev/null) -eq 200 ] && return 1
    [ $(curl -s -X POST --connect-timeout 3 -H "Authorization: Bearer ${temp_token}" -w "%{http_code}" --connect-timeout 3 -H "Content-Type: application/json" "$base_url/api/v1/inboundmapping" \
        -d '{"did": "00000", "name": "00000 DID Mapping"}' -o /dev/null) -eq 200 ] && return 1

    # ==========================
    # PUT /api/v1/inboundmapping
    # ==========================
    # valid requests
    [ $(curl -s -X PUT --connect-timeout 3 -H "Authorization: Bearer ${temp_token}" -w "%{http_code}" --connect-timeout 3 -H "Content-Type: application/json" "$base_url/api/v1/inboundmapping?ruleid=${ruleid0}" \
        -d '{"did": "01234", "name": "01234 DID Mapping"}' -o /dev/null) -ne 200 ] && return 1
    [ $(curl -s -X PUT --connect-timeout 3 -H "Authorization: Bearer ${temp_token}" -w "%{http_code}" --connect-timeout 3 -H "Content-Type: application/json" "$base_url/api/v1/inboundmapping?did='"${prefix1}"'" \
        -d '{"servers": ["67"]}' -o /dev/null) -ne 200 ] && return 1
    [ $(curl -s -X PUT --connect-timeout 3 -H "Authorization: Bearer ${temp_token}" -w "%{http_code}" --connect-timeout 3 -H "Content-Type: application/json" "$base_url/api/v1/inboundmapping?did=10000000" \
        -d '{"did": "01234", "name": "01234 DID Mapping"}' -o /dev/null) -ne 200 ] && return 1
    # invalid requests
    [ $(curl -s -X PUT --connect-timeout 3 -H "Authorization: Bearer ${temp_token}" -w "%{http_code}" --connect-timeout 3 -H "Content-Type: application/json" "$base_url/api/v1/inboundmapping?doesntexist=123" \
        -d '{"name": "New DID Mapping"}' -o /dev/null) -eq 200 ] && return 1
    [ $(curl -s -X PUT --connect-timeout 3 -H "Authorization: Bearer ${temp_token}" -w "%{http_code}" --connect-timeout 3 -H "Content-Type: application/json" "$base_url/api/v1/inboundmapping" \
        -d '{"name": "Newer DID Mapping"}' -o /dev/null) -eq 200 ] && return 1
    [ $(curl -s -X PUT --connect-timeout 3 -H "Authorization: Bearer ${temp_token}" -w "%{http_code}" --connect-timeout 3 -H "Content-Type: application/json" "$base_url/api/v1/inboundmapping?did='"${prefix1}"'" \
        -d '{}' -o /dev/null) -eq 200 ] && return 1
    [ $(curl -s -X PUT --connect-timeout 3 -H "Authorization: Bearer ${temp_token}" -w "%{http_code}" --connect-timeout 3 -H "Content-Type: application/json" "$base_url/api/v1/inboundmapping?did=01234" \
        -d '{"doesntexist": "2"}' -o /dev/null) -eq 200 ] && return 1
    [ $(curl -s -X PUT --connect-timeout 3 -H "Authorization: Bearer ${temp_token}" -w "%{http_code}" --connect-timeout 3 -H "Content-Type: application/json" "$base_url/api/v1/inboundmapping?did=01234" \
        -d '{"doesntexist": "2", "name": "New DID Mapping"}' -o /dev/null) -eq 200 ] && return 1

    # =============================
    # DELETE /api/v1/inboundmapping
    # =============================
    # valid requests
    [ $(curl -s -X DELETE --connect-timeout 3 -H "Authorization: Bearer ${temp_token}" -w "%{http_code}" "$base_url/api/v1/inboundmapping?ruleid=${ruleid0}" -o /dev/null) -ne 200 ] && return 1
    [ $(curl -s -X DELETE --connect-timeout 3 -H "Authorization: Bearer ${temp_token}" -w "%{http_code}" "$base_url/api/v1/inboundmapping?did='"${prefix1}"'" -o /dev/null) -ne 200 ] && return 1
    # invalid requests
    [ $(curl -s -X DELETE --connect-timeout 3 -H "Authorization: Bearer ${temp_token}" -w "%{http_code}" "$base_url/api/v1/inboundmapping?doesntexist=123" -o /dev/null) -eq 200 ] && return 1
    [ $(curl -s -X DELETE --connect-timeout 3 -H "Authorization: Bearer ${temp_token}" -w "%{http_code}" "$base_url/api/v1/inboundmapping" -o /dev/null) -eq 200 ] && return 1


    # if we made it this far all checks passed
    return 0
}

# cleanup, remove cookie, remove DB entries
cleanupHandler() {
    rm -f $cookie_file
    mysql --user="${kam_db_user}" --password="${kam_db_pass}" --host="${kam_db_host}" --port="${kam_db_port}" --database="${kam_db_name}" \
        -e "delete from dr_rules where groupid='$inbound_flag' and (prefix='$prefix0' or prefix='$prefix1' or prefix='$prefix2' or prefix='$prefix3');"
    kamcmd cfg.sets server api_token $old_api_token
    unsetLoginOverride
}

# main
trap cleanupHandler EXIT
setLoginOverride
validate; ret=$?

process_result "$test" $ret
