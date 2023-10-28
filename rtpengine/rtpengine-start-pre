#!/bin/sh

# defaults if config file not provided
PATH=/sbin:/bin:/usr/sbin:/usr/bin
TABLE=0
MODNAME=xt_RTPENGINE
MANAGE_IPTABLES=yes
DAEMON_OPTIONS_FILE=/var/run/rtpengine/daemon.conf

# $1 contains the path to the configuration file. It is passed in the systemd unit file 
# When calling the rtpengine command, default location:    /etc/default/rtpengine.conf
DEFAULTS="$1"

# Load rtpengine options if available
if [ -f $DEFAULTS ]; then
    . $DEFAULTS || true
fi

if [ "$RUN_RTPENGINE" != "yes" ]; then
	echo "rtpengine not yet configured. Edit $DEFAULTS first."
	exit 0
fi


# Gradually fill the options of the command rtpengine which starts the RTPEngine daemon
# The variables used are sourced from the configuration file rtpengine.conf
OPTIONS=""
MODPROBE_OPTIONS=""

if [ ! -z "$INTERFACES" ]; then
    for interface in $INTERFACES; do
        OPTIONS="$OPTIONS --interface=$interface"
    done
fi

[ -z "$CONFIG_FILE" ] || OPTIONS="$OPTIONS --config-file=$CONFIG_FILE"
[ -z "$CONFIG_SECTION" ] || OPTIONS="$OPTIONS --config-section=$CONFIG_SECTION"
[ -z "$ADDRESS" ] || OPTIONS="$OPTIONS --interface=$ADDRESS"
[ -z "$ADV_ADDRESS" ] || OPTIONS="$OPTIONS!$ADV_ADDRESS"
[ -z "$ADDRESS_IPV6" ] || OPTIONS="$OPTIONS --interface=$ADDRESS_IPV6"
[ -z "$ADV_ADDRESS_IPV6" ] || OPTIONS="$OPTIONS!$ADV_ADDRESS_IPV6"
[ -z "$LISTEN_TCP" ] || OPTIONS="$OPTIONS --listen-tcp=$LISTEN_TCP"
[ -z "$LISTEN_UDP" ] || OPTIONS="$OPTIONS --listen-udp=$LISTEN_UDP"
[ -z "$LISTEN_NG" ] || OPTIONS="$OPTIONS --listen-ng=$LISTEN_NG"
[ -z "$LISTEN_CLI" ] || OPTIONS="$OPTIONS --listen-cli=$LISTEN_CLI"
[ -z "$TIMEOUT" ] || OPTIONS="$OPTIONS --timeout=$TIMEOUT"
[ -z "$SILENT_TIMEOUT" ] || OPTIONS="$OPTIONS --silent-timeout=$SILENT_TIMEOUT"
[ -z "$PIDFILE" ] || OPTIONS="$OPTIONS --pidfile=$PIDFILE"
[ -z "$TOS" ] || OPTIONS="$OPTIONS --tos=$TOS"
[ -z "$PORT_MIN" ] || OPTIONS="$OPTIONS --port-min=$PORT_MIN"
[ -z "$PORT_MAX" ] || OPTIONS="$OPTIONS --port-max=$PORT_MAX"
[ -z "$REDIS" ] || OPTIONS="$OPTIONS --redis=$REDIS"
[ -z "$REDIS_DB" ] || OPTIONS="$OPTIONS --redis-db=$REDIS_DB"
[ -z "$REDIS_READ" ] || OPTIONS="$OPTIONS --redis-read=$REDIS_READ"
[ -z "$REDIS_READ_DB" ] || OPTIONS="$OPTIONS --redis-read-db=$REDIS_READ_DB"
[ -z "$REDIS_WRITE" ] || OPTIONS="$OPTIONS --redis-write=$REDIS_WRITE"
[ -z "$REDIS_WRITE_DB" ] || OPTIONS="$OPTIONS --redis-write-db=$REDIS_WRITE_DB"
[ -z "$B2B_URL" ] || OPTIONS="$OPTIONS --b2b-url=$B2B_URL"
[ -z "$NO_FALLBACK" -o \( "$NO_FALLBACK" != "1" -a "$NO_FALLBACK" != "yes" \) ] || OPTIONS="$OPTIONS --no-fallback"
OPTIONS="$OPTIONS --table=$TABLE"
[ -z "$LOG_LEVEL" ] || OPTIONS="$OPTIONS --log-level=$LOG_LEVEL"
[ -z "$LOG_FACILITY" ] || OPTIONS="$OPTIONS --log-facility=$LOG_FACILITY"
[ -z "$LOG_FACILITY_CDR" ] || OPTIONS="$OPTIONS --log-facility-cdr=$LOG_FACILITY_CDR"
[ -z "$LOG_FACILITY_RTCP" ] || OPTIONS="$OPTIONS --log-facility-rtcp=$LOG_FACILITY_RTCP"
[ -z "$NUM_THREADS" ] || OPTIONS="$OPTIONS --num-threads=$NUM_THREADS"
[ -z "$DELETE_DELAY" ] || OPTIONS="$OPTIONS --delete-delay=$DELETE_DELAY"
[ -z "$GRAPHITE" ] || OPTIONS="$OPTIONS --graphite=$GRAPHITE"
[ -z "$GRAPHITE_INTERVAL" ] || OPTIONS="$OPTIONS --graphite-interval=$GRAPHITE_INTERVAL"
[ -z "$GRAPHITE_PREFIX" ] || OPTIONS="$OPTIONS --graphite-prefix=$GRAPHITE_PREFIX"
[ -z "$MAX_SESSIONS" ] || OPTIONS="$OPTIONS --max-sessions=$MAX_SESSIONS"
[ -z "$HOMER" ] || OPTIONS="$OPTIONS --homer=$HOMER"
[ -z "$HOMER_PROTOCOL" ] || OPTIONS="$OPTIONS --homer-protocol=$HOMER_PROTOCOL"
[ -z "$HOMER_ID" ] || OPTIONS="$OPTIONS --homer-id=$HOMER_ID"
if [ ! -z "$RECORDING_DIR" ]; then
	OPTIONS="$OPTIONS --recording-dir=$RECORDING_DIR"
	if [ ! -d "$RECORDING_DIR" ]; then
		mkdir "$RECORDING_DIR" 2> /dev/null
		chmod 700 "$RECORDING_DIR" 2> /dev/null
	fi
fi
[ -z "$RECORDING_METHOD" ] || OPTIONS="$OPTIONS --recording-method=$RECORDING_METHOD"
[ -z "$RECORDING_FORMAT" ] || OPTIONS="$OPTIONS --recording-format=$RECORDING_FORMAT"
[ -z "$DTLS_PASSIVE" ] || ( [ "$DTLS_PASSIVE" != "yes" ] && [ "$DTLS_PASSIVE" != "1" ] ) || OPTIONS="$OPTIONS --dtls-passive"

if test "$FORK" = "no" ; then
	OPTIONS="$OPTIONS --foreground"
fi

if test "$LOG_STDERR" = "yes" ; then
	OPTIONS="$OPTIONS --log-stderr"
fi

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

firewallSetup() {
    if [ "$TABLE" -lt 0 ] || [ "$VIRT" = "yes" ]; then
        return
    fi

    if [ "$MANAGE_IPTABLES" != "yes" ]; then
        return
    fi

    # shellcheck disable=SC2086
    modprobe $MODNAME $MODPROBE_OPTIONS

    # ensure that the table we want to use doesn't exist
    if [ -e /proc/rtpengine/control ]; then
        echo "del $TABLE" > /proc/rtpengine/control 2>/dev/null
    fi

    # Freshly add the iptables rules to forward the udp packets to the iptables-extension "RTPEngine":
    # Remember iptables table = chains, rules stored in the chains
    # -N (create a new chain with the name rtpengine)
    iptables -N rtpengine 2> /dev/null
    # -D: Delete the rule for the target "rtpengine" if exists. -j (target): chain name or extension name
    # from the table "filter" (the default -without the option '-t')
    iptables -D INPUT -j rtpengine 2> /dev/null
    # Add the rule again so the packets will go to rtpengine chain after the (filter-INPUT) hook point.
    iptables -I INPUT -j rtpengine
    # Delete and Insert a rule in the rtpengine chain to forward the UDP traffic
    iptables -D rtpengine -p udp -j RTPENGINE --id "$TABLE" 2>/dev/null
    iptables -I rtpengine -p udp -j RTPENGINE --id "$TABLE"
    # The same for IPv6
    ip6tables -N rtpengine 2> /dev/null
    ip6tables -D INPUT -j rtpengine 2> /dev/null
    ip6tables -I INPUT -j rtpengine
    ip6tables -D rtpengine -p udp -j RTPENGINE --id "$TABLE" 2>/dev/null
    ip6tables -I rtpengine -p udp -j RTPENGINE --id "$TABLE"
}

firewallSetup
echo "Start Command:    /usr/bin/rtpengine $OPTIONS"
echo "OPTIONS='$OPTIONS'" > $DAEMON_OPTIONS_FILE
exit 0
