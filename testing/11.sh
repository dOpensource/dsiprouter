#!/usr/bin/env bash

. include/common

test="dSIPRouter GUI Login"

# static settings
project_dir=/opt/dsiprouter
cookie_file=/tmp/cookie
temp_pass='temp'

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

# overload password

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
    elif [[ "$load_from" == "db" ]]; then
        mysql --user="${kam_db_user}" --password="${kam_db_pass}" --host="${kam_db_host}" --port="${kam_db_port}" --database="${kam_db_name}" \
            -e "update dsip_settings set DSIP_PASSWORD='${temp_pass}' where dsip_id=${dsip_id}"
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

validateDsipAuth() {
    # attempt to auth and store cookie, we will get a 200 OK on good auth
    status=$(curl -s -L --connect-timeout 3 -c "$cookie_file" -w "%{http_code}" -d "$payload" "${flat_headers[@]/#/-H}" "$base_url/login" -o /dev/null)
    [ ${status:-400} -ne 200 ] && return 1

    # try navigating to endpoint without cookie, we should get a 302 redirect
    status=$(curl -X GET -s --connect-timeout 3 -w "%{http_code}" "${flat_headers[@]/#/-H}" "$base_url/carriergroups" -o /dev/null)
    [ ${status:-400} -ne 302 ] && return 1

    # try navigating to endpoint with cookie, we should get a 200 OK
    unset headers['Content-Type']; flat_headers=()
    for key in ${!headers[@]}; do flat_headers+=( "$key: ${headers[$key]}" ); done
    status=$(curl -X GET -s --connect-timeout 3 -b "$cookie_file" -w "%{http_code}" "${flat_headers[@]/#/-H}" "$base_url/carriergroups" -o /dev/null)
    [ ${status:-400} -ne 200 ] && return 1

    # cleanup, remove cookie
    rm -f $cookie_file

    # if we made it this far all checks passed
    return 0
}

cleanupHandler() {
    rm -f $cookie_file
    unsetLoginOverride
}

# main
trap cleanupHandler EXIT
setLoginOverride
validateDsipAuth; ret=$?


process_result "$test" $ret
