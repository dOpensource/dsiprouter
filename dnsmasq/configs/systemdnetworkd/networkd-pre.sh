#!/bin/sh

mkdir -p /run/systemd/network/
rm -f /run/systemd/network/00-nm_managed-*.network 2>/dev/null

# check whether nmcli reports that network manager is actively managing the interface (connecting/connected)
# interfaces left "disconnected" by no-auto-default have no profile and must fall through to systemd-networkd
# "connected (externally)" means another manager (networkd/ifupdown) configured it, NM is only observing
# ref: https://gitlab.freedesktop.org/NetworkManager/NetworkManager/-/blob/main/src/libnmc-base/nm-client-utils.c?ref_type=heads#L288
# blacklist those managed interfaces from being managed by systemd-networkd
for IFACE in $(nmcli -t -f DEVICE,STATE device status | awk -F ':' '$2 ~ /^connect/ && $2 !~ /\(externally\)/ {print $1}'); do
    cat <<EOF >"/run/systemd/network/00-nm_managed-$IFACE.network"
[Match]
Name=$IFACE

[Link]
Unmanaged=yes
EOF
done

exit 0