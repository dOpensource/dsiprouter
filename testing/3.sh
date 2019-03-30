#!/usr/bin/env bash

. include/common

test="Kamailio Started"

# Is service started
systemctl is-active --quiet kamailio; ret=$?

process_result "$test" $ret 
