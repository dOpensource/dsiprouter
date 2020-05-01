#!/usr/bin/env bash

. include/common

test="dSIPRouter Started"

# Is service started
systemctl is-active --quiet dsiprouter; ret=$?

process_result "$test" $ret 
