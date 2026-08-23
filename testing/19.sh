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


    # =====================================================================
    # Outbound Routes API tests (issue #686) -- 29 cases, exact-code checks
    # =====================================================================
    outbound_flag=$(getConfigAttrib 'FLT_OUTBOUND' ${DSIP_CONFIG_FILE})
    lcr_min=$(getConfigAttrib 'FLT_LCR_MIN' ${DSIP_CONFIG_FILE})
    lcr_max=$(getConfigAttrib 'FLT_FWD_MIN' ${DSIP_CONFIG_FILE})

    # local helper functions to keep curl/mysql boilerplate readable
    myql() {
        mysql --user="${kam_db_user}" --password="${kam_db_pass}" \
              --host="${kam_db_host}" --port="${kam_db_port}" \
              --database="${kam_db_name}" -sN "$@"
    }
    curlc() {
        curl -s --connect-timeout 3 -H "Authorization: Bearer ${temp_token}" \
             -H 'Content-Type: application/json' -w '%{http_code}' -o /dev/null "$@"
    }
    curlb() {
        curl -s --connect-timeout 3 -H "Authorization: Bearer ${temp_token}" \
             -H 'Content-Type: application/json' "$@"
    }

    # discover a real carrier-group id; default seed (kamailio/defaults/dr_rules.csv)
    # always ships gwgroupid=2 via dsiprouter.sh install
    test_gwgroupid=$(myql -e "SELECT id FROM dr_gw_lists WHERE description REGEXP 'name:' LIMIT 1;")
    [ -z "$test_gwgroupid" ] && test_gwgroupid=2

    # ---------- Case 1: GET list (pre-seed): expect >=1 row (the default route)
    default_count=$(curlb "$base_url/api/v1/outboundroutes" \
        | python3 -c 'import sys,json;print(len(json.load(sys.stdin)["data"]))')
    [ "$default_count" -lt 1 ] && return 1

    # ---------- Seed: 1 simple test row + 1 LCR test row + paired dsip_lcr row
    myql -e "INSERT INTO dr_rules VALUES (null,'$outbound_flag','55501','',0,'','#$test_gwgroupid','name:Test Outbound Simple Seed');" \
         -e "INSERT INTO dr_rules VALUES (null,'$lcr_min','55502','',0,'','#$test_gwgroupid','name:Test Outbound LCR Seed');" \
         -e "INSERT INTO dsip_lcr VALUES ('999313-55502','0','$lcr_min','0',0.00,'999313',0);"
    simple_ruleid=$(myql -e "SELECT ruleid FROM dr_rules WHERE description='name:Test Outbound Simple Seed';")
    lcr_ruleid=$(   myql -e "SELECT ruleid FROM dr_rules WHERE description='name:Test Outbound LCR Seed';")
    if [ -z "$simple_ruleid" ] || [ -z "$lcr_ruleid" ]; then return 1; fi

    # ---------- Case 2: GET list (post-seed): expect >=3 rows
    post_count=$(curlb "$base_url/api/v1/outboundroutes" \
        | python3 -c 'import sys,json;print(len(json.load(sys.stdin)["data"]))')
    [ "$post_count" -lt 3 ] && return 1

    # ---------- Cases 3-4: GET by path id (simple, LCR)
    [ "$(curlc -X GET "$base_url/api/v1/outboundroutes/${simple_ruleid}")" -ne 200 ] && return 1
    [ "$(curlc -X GET "$base_url/api/v1/outboundroutes/${lcr_ruleid}")"    -ne 200 ] && return 1
    [ "$(curlb -X GET "$base_url/api/v1/outboundroutes/${lcr_ruleid}" \
         | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"][0]["from_prefix"])')" != "999313" ] && return 1

    # ---------- Case 5: GET by query id
    [ "$(curlc -X GET "$base_url/api/v1/outboundroutes?ruleid=${simple_ruleid}")" -ne 200 ] && return 1

    # ---------- Case 6: nonexistent -> 404
    [ "$(curlc -X GET "$base_url/api/v1/outboundroutes/99999999")" -ne 404 ] && return 1

    # ---------- Case 7: unknown query arg -> 400
    [ "$(curlc -X GET "$base_url/api/v1/outboundroutes?doesntexist=1")" -ne 400 ] && return 1

    # ---------- Case 8: POST simple route + DB asserts
    new_simple_id=$(curlb -X POST "$base_url/api/v1/outboundroutes" \
        -d "{\"name\":\"Test Outbound API Simple\",\"prefix\":\"55503\",\"gwgroupid\":\"${test_gwgroupid}\"}" \
        | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"][0]["ruleid"])')
    [ -z "$new_simple_id" ] && return 1
    [ "$(myql -e "SELECT groupid FROM dr_rules WHERE ruleid=$new_simple_id;")" != "$outbound_flag" ] && return 1

    # ---------- Case 9: POST LCR route + DB asserts
    new_lcr_id=$(curlb -X POST "$base_url/api/v1/outboundroutes" \
        -d "{\"name\":\"Test Outbound API LCR\",\"from_prefix\":\"999316\",\"prefix\":\"55504\",\"gwgroupid\":\"${test_gwgroupid}\"}" \
        | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"][0]["ruleid"])')
    [ -z "$new_lcr_id" ] && return 1
    db_lcr_groupid=$(myql -e "SELECT groupid FROM dr_rules WHERE ruleid=$new_lcr_id;")
    [ "$db_lcr_groupid" -lt "$lcr_min" ] && return 1
    [ "$db_lcr_groupid" -ge "$lcr_max" ] && return 1
    [ "$(myql -e "SELECT COUNT(*) FROM dsip_lcr WHERE dr_groupid=$db_lcr_groupid AND from_prefix='999316' AND pattern='999316-55504';")" -ne 1 ] && return 1

    # ---------- Cases 10-14: validation errors -> 400
    [ "$(curlc -X POST "$base_url/api/v1/outboundroutes" -d '{"prefix":"1"}')"                                                                       -ne 400 ] && return 1
    [ "$(curlc -X POST "$base_url/api/v1/outboundroutes" -d '{"prefix":"1","gwgroupid":"0"}')"                                                       -ne 400 ] && return 1
    [ "$(curlc -X POST "$base_url/api/v1/outboundroutes" -d "{\"prefix\":\"1\",\"gwgroupid\":\"${test_gwgroupid}\",\"bogus\":1}")"                   -ne 400 ] && return 1
    [ "$(curlc -X POST "$base_url/api/v1/outboundroutes" -d "{\"from_prefix\":\"313\",\"gwgroupid\":\"${test_gwgroupid}\"}")"                        -ne 400 ] && return 1
    [ "$(curlc -X POST "$base_url/api/v1/outboundroutes" -d "{\"prefix\":\"abc\",\"gwgroupid\":\"${test_gwgroupid}\"}")"                             -ne 400 ] && return 1

    # ---------- Case 15: PUT plain field update + DB assert (still simple)
    [ "$(curlc -X PUT "$base_url/api/v1/outboundroutes/${new_simple_id}" -d '{"priority":5}')" -ne 200 ] && return 1
    [ "$(myql -e "SELECT priority FROM dr_rules WHERE ruleid=$new_simple_id;")" != "5" ]                && return 1
    [ "$(myql -e "SELECT groupid  FROM dr_rules WHERE ruleid=$new_simple_id;")" != "$outbound_flag" ]   && return 1

    # ---------- Case 16: PUT promote simple->LCR + DB asserts
    [ "$(curlc -X PUT "$base_url/api/v1/outboundroutes/${new_simple_id}" -d '{"from_prefix":"999317","prefix":"55503"}')" -ne 200 ] && return 1
    promoted_groupid=$(myql -e "SELECT groupid FROM dr_rules WHERE ruleid=$new_simple_id;")
    [ "$promoted_groupid" -lt "$lcr_min" ] && return 1
    [ "$promoted_groupid" -ge "$lcr_max" ] && return 1
    [ "$(myql -e "SELECT COUNT(*) FROM dsip_lcr WHERE dr_groupid=$promoted_groupid AND from_prefix='999317';")" -ne 1 ] && return 1

    # ---------- Case 17: PUT demote LCR->simple + DB asserts
    [ "$(curlc -X PUT "$base_url/api/v1/outboundroutes/${new_lcr_id}" -d '{"from_prefix":""}')" -ne 200 ] && return 1
    [ "$(myql -e "SELECT groupid FROM dr_rules WHERE ruleid=$new_lcr_id;")" != "$outbound_flag" ]        && return 1
    [ "$(myql -e "SELECT COUNT(*) FROM dsip_lcr WHERE dr_groupid=$db_lcr_groupid;")" -ne 0 ]             && return 1

    # ---------- Case 18: PUT update LCR in place
    [ "$(curlc -X PUT "$base_url/api/v1/outboundroutes/${new_simple_id}" -d '{"from_prefix":"999318","prefix":"55503"}')" -ne 200 ] && return 1
    [ "$(myql -e "SELECT pattern     FROM dsip_lcr WHERE dr_groupid=$promoted_groupid;")" != "999318-55503" ]            && return 1
    [ "$(myql -e "SELECT from_prefix FROM dsip_lcr WHERE dr_groupid=$promoted_groupid;")" != "999318" ]                  && return 1

    # ---------- Cases 19-21: PUT error paths
    [ "$(curlc -X PUT "$base_url/api/v1/outboundroutes/99999999"        -d '{"priority":5}')"     -ne 404 ] && return 1
    [ "$(curlc -X PUT "$base_url/api/v1/outboundroutes/${new_simple_id}" -d '{"bogus":1}')"       -ne 400 ] && return 1
    [ "$(curlc -X PUT "$base_url/api/v1/outboundroutes"                  -d '{"priority":5}')"    -ne 400 ] && return 1

    # ---------- Cases 22-23: DELETE (path-style; new_simple_id is currently LCR after case 16/18)
    [ "$(curlc -X DELETE "$base_url/api/v1/outboundroutes/${new_simple_id}")" -ne 200 ] && return 1
    [ "$(myql -e "SELECT COUNT(*) FROM dr_rules WHERE ruleid=$new_simple_id;")"           -ne 0 ] && return 1
    [ "$(myql -e "SELECT COUNT(*) FROM dsip_lcr WHERE dr_groupid=$promoted_groupid;")"    -ne 0 ] && return 1

    # ---------- Case 24: DELETE via query string (new_lcr_id, now simple after case 17 demote)
    [ "$(curlc -X DELETE "$base_url/api/v1/outboundroutes?ruleid=${new_lcr_id}")" -ne 200 ] && return 1
    [ "$(myql -e "SELECT COUNT(*) FROM dr_rules WHERE ruleid=$new_lcr_id;")" -ne 0 ] && return 1

    # ---------- Cases 25-26: DELETE error paths
    [ "$(curlc -X DELETE "$base_url/api/v1/outboundroutes/99999999")" -ne 404 ] && return 1
    [ "$(curlc -X DELETE "$base_url/api/v1/outboundroutes")"          -ne 400 ] && return 1

    # ---------- Case 27: kamreload flag set after a mutation
    kamreload=$(curlb -X POST "$base_url/api/v1/outboundroutes" \
        -d "{\"name\":\"Test Outbound Reload Probe\",\"prefix\":\"55505\",\"gwgroupid\":\"${test_gwgroupid}\"}" \
        | python3 -c 'import sys,json;print(json.load(sys.stdin)["kamreload"])')
    [ "$kamreload" != "True" ] && return 1

    # ---------- Cases 28-29: auth checks (no token / invalid token) -> 401
    [ "$(curl -s --connect-timeout 3 -w '%{http_code}' -o /dev/null \
           -X DELETE "$base_url/api/v1/outboundroutes/1")" -ne 401 ] && return 1
    [ "$(curl -s --connect-timeout 3 -H 'Authorization: Bearer not_the_token' \
           -w '%{http_code}' -o /dev/null \
           -X DELETE "$base_url/api/v1/outboundroutes/1")" -ne 401 ] && return 1


    # if we made it this far all checks passed
    return 0
}

# cleanup, remove cookie, remove DB entries
cleanupHandler() {
    rm -f $cookie_file
    mysql --user="${kam_db_user}" --password="${kam_db_pass}" --host="${kam_db_host}" --port="${kam_db_port}" --database="${kam_db_name}" \
        -e "delete from dr_rules where groupid='$inbound_flag' and (prefix='$prefix0' or prefix='$prefix1' or prefix='$prefix2' or prefix='$prefix3');" \
        -e "delete from dr_rules where description like 'name:Test Outbound %';" \
        -e "delete from dsip_lcr where from_prefix like '999%';"
    kamcmd cfg.sets server api_token $old_api_token
    unsetLoginOverride
}

# main
trap cleanupHandler EXIT
setLoginOverride
validate; ret=$?

process_result "$test" $ret
