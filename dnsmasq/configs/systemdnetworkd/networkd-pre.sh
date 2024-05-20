#!/bin/sh

rm -f /run/systemd/network/00-nm_managed-*.network 2>/dev/null

for IFACE in $(nmcli -t -m tabular device status | awk -F ':' '$3 != "unmanaged" {print $1}'); do
    cat <<EOF >"/run/systemd/network/00-nm_managed-$IFACE.network"
[Match]
Name=$IFACE

[Link]
Unmanaged=yes
EOF
done

exit 0