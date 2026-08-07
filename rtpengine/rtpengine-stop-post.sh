#!/bin/sh

# defaults if config file not provided
PATH=/sbin:/bin:/usr/sbin:/usr/bin
TABLE=0
MODNAME=xt_RTPENGINE
MANAGE_IPTABLES=yes

# $1 contains the path to the configuration file. It is passed in the systemd unit file
# When calling the rtpengine command, default location:    /etc/default/rtpengine.conf
DEFAULTS="$1"

# Load rtpengine options if available
if [ -f $DEFAULTS ]; then
    . $DEFAULTS || true
fi


MODPROBE_OPTIONS=""

# Handle requested setuid/setgid.
if ! test -z "$SET_USER"; then
    PUID=$(id -u "$SET_USER" 2> /dev/null)
    test -z "$PUID" || MODPROBE_OPTIONS="$MODPROBE_OPTIONS proc_uid=$PUID"
    if test -z "$SET_GROUP"; then
        PGID=$(id -g "$SET_USER" 2> /dev/null)
        test -z "$PGID" || MODPROBE_OPTIONS="$MODPROBE_OPTIONS proc_gid=$PGID"
    fi
fi

if ! test -z "$SET_GROUP"; then
    PGID=$(grep "^$SET_GROUP:" /etc/group | cut -d: -f3 2> /dev/null)
    test -z "$PGID" || MODPROBE_OPTIONS="$MODPROBE_OPTIONS proc_gid=$PGID"
fi

# VM / Container Specific - don't use kernel forwarding
if [ -x /usr/sbin/ngcp-virt-identify ]; then
    if /usr/sbin/ngcp-virt-identify --type container; then
        VIRT="yes"
    fi
fi

# After systemd send kill signal to the rtpengine daemon,
# Wait 3 sec, then clean the iptables stuffs:
# 1- delete the forwarding table, 
# 2- delete the iptables rules related to rtpengine
# 3- Unload the kernel module xt_RTPENGINE
firewallTeardown() {
    if [ "$TABLE" -lt 0 ] || [ "$VIRT" = "yes" ]; then
        return
    fi

    sleep 3

    # Delete the Table
    if [ -e /proc/rtpengine/control ]; then
        echo "del $TABLE" > /proc/rtpengine/control 2>/dev/null
    fi

    if [ "$MANAGE_IPTABLES" != "yes" ]; then
        return
    fi

    # Remove iptables forwarding rules
    iptables -D rtpengine -p udp -j RTPENGINE --id "$TABLE" 2>/dev/null
    iptables -D INPUT -j rtpengine 2> /dev/null
    iptables -D rtpengine 2> /dev/null

    # The same for ip6tables rules
    ip6tables -D rtpengine -p udp -j RTPENGINE --id "$TABLE" 2>/dev/null
    ip6tables -D INPUT -j rtpengine 2> /dev/null
    ip6tables -D rtpengine 2> /dev/null

    # Remove kernel module if loaded
    if lsmod | grep -q "$MODNAME" 2>/dev/null; then
        rmmod $MODNAME 2>/dev/null
    fi
}

firewallTeardown
exit 0
