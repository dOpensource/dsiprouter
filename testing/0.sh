#!/usr/bin/env bash

. include/common

test="Syslog Started"

# Is service started
systemctl is-active --quiet syslog; ret=$?

process_result "$test" $ret 
