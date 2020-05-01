#!/usr/bin/env bash

. include/common

test="RTPEngine Started"

# Is service started
systemctl is-active --quiet rtpengine; ret=$?

process_result "$test" $ret 
