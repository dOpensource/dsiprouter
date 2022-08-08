#!/usr/bin/env bash

TIMEOUT=5
MAINPID="$1"
PIDFILE="$2"

if [[ -z "$(ps -p $MAINPID -o pid= 2>/dev/null)" ]]; then
    rm -f ${PIDFILE} 2>/dev/null
    exit 0
fi

kill -s SIGSTOP $MAINPID
for (( ROUND=0; ROUND<$TIMEOUT; ROUND++ )); do
    if [[ -z "$(ps -p $MAINPID -o pid= 2>/dev/null)" ]]; then
        rm -f ${PIDFILE} 2>/dev/null
        exit 0
    fi
    sleep 1
done

kill -s SIGQUIT $MAINPID
for (( ROUND=0; ROUND<$TIMEOUT; ROUND++ )); do
    if [[ -z "$(ps -p $MAINPID -o pid= 2>/dev/null)" ]]; then
        rm -f ${PIDFILE} 2>/dev/null
        exit 0
    fi
    sleep 1
done

exit 1

