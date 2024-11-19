#!/bin/bash

set -xe

[ "$UID" -ne 0 ] && {
    echo 'Run as root!'
    exit 1
}

apt install -y wireguard-dkms wireguard-tools

# TODO: Don't store keys
wg genkey | tee /etc/wireguard/wg0_id | wg pubkey | tee /etc/wireguard/wg0_id.pub

chmod 600 /etc/wireguard/wg0_id

cat > /etc/wireguard/wg0.conf << EOF
[Interface]
PrivateKey = $(cat /etc/wireguard/wg0_id)
Address = 10.0.0.1/24
ListenPort = 51830
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
EOF

# FIXME: use grep for this
[ "$(sysctl -n net.ipv4.ip_forward)" -ne 1 ] && {
    echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
    sysctl -p
}

systemctl enable wg-quick@wg0.service
systemctl start wg-quick@wg0.service
