#!/bin/bash

SS_RELEASE='v0.1.5'
SS_DIST='shadowsocks2-linux.gz'
SS_DIST_URL="https://github.com/shadowsocks/go-shadowsocks2/releases/download/$SS_RELEASE/$SS_DIST"

SERVICE_NAME='go-shadowsocks2'
PREFIX="/usr/local"

PORT=8388

[ "$UID" -ne 0 ] && {
    echo 'Run as root'
    exit 1
}

cd /tmp

echo "[*] Downloading $SS_DIST"
wget -q --show-progress "$SS_DIST_URL"
gzip -d "$SS_DIST"

echo "[*] Installing to $PREFIX/bin"
chmod +x shadowsocks2-linux
mv shadowsocks2-linux "$PREFIX/bin/$SERVICE_NAME"

echo "[*] Creating service file"
read -s -p 'Enter server password: ' PASSWD

cat > /etc/systemd/system/$SERVICE_NAME.service << EOF
[Unit]
Description=go-shadowsocks2 server
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/$SERVICE_NAME -s 'ss://AEAD_CHACHA20_POLY1305:$PASSWD@:$PORT'
Restart=on-abort
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF

echo "[*] Enabling $SERVICE_NAME service"
systemctl daemon-reload 
systemctl enable $SERVICE_NAME
systemctl start $SERVICE_NAME && {
    echo '[*] Done, use ss-local to connect'
}
