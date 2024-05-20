#!/bin/sh

rm -f /run/network/ifupdown.conf 2>/dev/null

NM_IFACES=$(nmcli -t -m tabular device status | awk -F ':' '$3 != "unmanaged" {print $1}')
SN_IFACES=$(networkctl list --json=short | jq -r -e '.Interfaces[] | select(.AdministrativeState!="unmanaged").Name')
EXCLUSIONS=''
for IFACE in $NM_IFACES $SN_IFACES; do
    EXCLUSIONS="$EXCLUSIONS $IFACE ${IFACE}:*"
done

[ -n "$EXCLUSIONS" ] && echo "EXCLUDE_INTERFACES='$EXCLUSIONS'" >/run/network/ifupdown.conf

exit 0