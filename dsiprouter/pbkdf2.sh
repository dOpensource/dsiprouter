#!/usr/bin/env bash

# Inspired By: https://gist.github.com/grondilu/abe50de34f6c838dbc9388fe797ea4e4
# Credit to: https://github.com/stayradiated/pbkdf2-sha512
# Copyright (c) 2014, JP Richardson Copyright (c) 2010-2011 Intalio Pte, All Rights Reserved
# Original Author: Lucien Grondin, 2022

declare hash_name="$1" key_str="$2" salt_str="$3"
declare -ai key salt u t block1 dk
declare -i hLen="$(openssl dgst "-$hash_name" -binary <<<"foo" |wc -c)"
declare -i iterations=$4 dkLen=${5:-hLen}
declare -i i j k l=$(( (dkLen+hLen-1)/hLen ))

for ((i=0; i<${#key_str}; i++)); do
    printf -v "key[$i]" "%d" "'${key_str:i:1}"
done

for ((i=0; i<${#salt_str}; i++)); do
    printf -v "salt[$i]" "%d" "'${salt_str:i:1}"
done

block1=(${salt[@]} 0 0 0 0)

step() {
    printf '%02x' "$@" |
    xxd -p -r |
    openssl dgst -"$hash_name" -hmac "$key_str" -binary |
    xxd -p -c 1 |
    sed 's/^/0x/'
}

for ((i=1;i<=l;i++)); do
    for k in {0..3}; do 
        block1[${#salt[@]}+$k]=$((i >> (8*(3-k)) & 0xff))
    done
    
    u=($(step "${block1[@]}"))
    t=(${u[@]})
    for ((j=1; j<iterations; j++)); do
        u=($(step "${u[@]}"))
        for ((k=0; k<hLen; k++)); do
            t[k]=$((t[k]^u[k]))
        done
    done
    
    dk+=(${t[@]})
done

printf "%02x" "${dk[@]:0:dkLen}"; echo '';

