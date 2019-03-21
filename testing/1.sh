#!/usr/bin/env bash

. include/common

test="Mysql Started"

# Is service started
systemctl is-active --quiet mysql; ret=$?

process_result "$test" $ret 
