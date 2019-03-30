#!/usr/bin/env bash

. include/common

test="dSIPRouter GUI Login"

# static settings
project_dir=/opt/dsiprouter
cookie_file=/tmp/cookie

# dynamic settings
proto=$(getConfigAttrib 'DSIP_PROTO' $project_dir/gui/settings.py)
host=$(getConfigAttrib 'DSIP_HOST' $project_dir/gui/settings.py)
port=$(getConfigAttrib 'DSIP_PORT' $project_dir/gui/settings.py)
username=$(getConfigAttrib 'USERNAME' $project_dir/gui/settings.py)
password=$(getConfigAttrib 'PASSWORD' $project_dir/gui/settings.py)
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

validateDsipAuth() {
    # attempt to auth and store cookie, we will get a 200 OK on good auth
    status=$(curl -s -L --connect-timeout 3 -c "$cookie_file" -w "%{http_code}" -d "$payload" "${flat_headers[@]/#/-H}" "$base_url/login" -o /dev/null)
    [ ${status:-400} -ne 200 ] && return 1

    # try navigating to endpoint without cookie, we should get a 302 redirect
    status=$(curl -X GET -s --connect-timeout 3 -w "%{http_code}" "${flat_headers[@]/#/-H}" "$base_url/carriergroups" -o /dev/null)
    [ ${status:-400} -ne 302 ] && return 1

    # try navigating to endpoint with cookie, we should get a 200 OK
    status=$(curl -X GET -s --connect-timeout 3 -b "$cookie_file" -w "%{http_code}" "${flat_headers[@]/#/-H}" "$base_url/carriergroups" -o /dev/null)
    [ ${status:-400} -ne 200 ] && return 1

    # cleanup, remove cookie
    rm -f $cookie_file

    # if we made it this far all checks passed
    return 0
}

validateDsipAuth; ret=$?

process_result "$test" $ret
