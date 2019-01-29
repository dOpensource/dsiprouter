#!/bin/bash

. include/common

test="Kamailio Started"

# Is Kam started
pidof kamailio >> /dev/null
ret=$?

process_result "$test" $ret 


