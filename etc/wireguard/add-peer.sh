#!/bin/bash

get_peer_ip() {
	grep 'AllowedIPs' wg0.conf \
		| cut -d ' ' -f 3  \
		| sort -r -t . -n +3.0 \
		| cut -d '/' -f 1 \
		| awk -F. 'NR == 1 { printf("10.0.0.%d", $4 + 1)}'
}

peer_ip=$(get_peer_ip)
[ -z "$peer_ip" ] && peer_ip='10.0.0.2'

peer_key=$(wg genkey)
peer_pub_key=$(echo "$peer_key" | wg pubkey)

read -rp 'Peer name: ' peer_name

# Make peer config
cat <<- EOF
[Interface]
PrivateKey = $peer_key
Address = $peer_ip/24
DNS = 1.1.1.1

[Peer]
PublicKey = tz9hXqMu9ejx/ox7ae7OXBpg0ZgZ4yl00I2v6JHyAAk=
EndPoint = 37.252.6.125:51830
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 20
EOF

# Add newly created peer
cat >> wg0.conf <<- EOF

# $peer_name
[Peer]
PublicKey = $peer_pub_key
AllowedIPs = $peer_ip/32
EOF

systemctl restart wg-quick@wg0.service && {
	echo -e '\n[*] Wireguard restarted!'
}
