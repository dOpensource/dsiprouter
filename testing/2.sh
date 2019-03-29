#!/usr/bin/env bash

. include/common

test="dsip-init Service Started"

# Is service started
systemctl is-active --quiet dsip-init; ret=$?

process_result "$test" $ret 
