#!/usr/bin/env bash

. include/common

test="DNS Resolver Test"

validateResolver() {
    # can localhost be resolved
    nslookup localhost 2>&1 >/dev/null || return 1

    # can DMQ domain local.cluster be resolved
    nslookup local.cluster 2>&1 >/dev/null || return 1

    # can an external host be resolved
    nslookup www.google.com 2>&1 >/dev/null || return 1

    return 0
}

validateResolver; ret=$?

process_result "$test" $ret
