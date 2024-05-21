#!/bin/sh

mkdir -p /run/systemd/network/
rm -f /run/systemd/network/00-nm_managed-*.network 2>/dev/null

# check whether nmcli reports that network manager is managing the interface
# ref: https://gitlab.freedesktop.org/NetworkManager/NetworkManager/-/blob/main/src/libnmc-base/nm-client-utils.c?ref_type=heads#L288
# blacklist those managed interfaces from being managed by systemd-networkd
for IFACE in $(nmcli -t -m tabular device status | awk -F ':' '$3 !~ /unmanaged|[^ ]+ \(externally\)/ {print $1}'); do
    cat <<EOF >"/run/systemd/network/00-nm_managed-$IFACE.network"
[Match]
Name=$IFACE

[Link]
Unmanaged=yes
EOF
done

exit 0