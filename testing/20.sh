#!/usr/bin/env bash

. include/common

test="DNSmasq Started"

# Is service started
systemctl is-active --quiet dnsmasq; ret=$?

process_result "$test" $ret
