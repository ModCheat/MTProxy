#!/bin/bash
# MTProxy Auto Installer for Ubuntu
# Port: 3418

# Exit on errors
set -e

PORT=3418
TAG="00000000000000000000000000000000"   # Replace with your Telegram TAG (optional)
SECRET=$(head -c 16 /dev/urandom | xxd -ps)  # Auto-generate secret key

echo "Updating system..."
apt update && apt upgrade -y

echo "Installing dependencies..."
apt install -y git curl build-essential libssl-dev zlib1g-dev

echo "Cloning MTProxy source..."
if [ ! -d "/opt/MTProxy" ]; then
    git clone https://github.com/TelegramMessenger/MTProxy.git /opt/MTProxy
fi

cd /opt/MTProxy

echo "Building MTProxy..."
make

echo "Creating systemd service..."
cat >/etc/systemd/system/mtproxy.service <<EOF
[Unit]
Description=MTProto Proxy Server
After=network.target

[Service]
Type=simple
ExecStart=/opt/MTProxy/objs/bin/mtproto-proxy -u nobody -p 8888 -H ${PORT} -S ${SECRET} --aes-pwd /opt/MTProxy/objs/bin/mtproto-proxy.conf --nat-info 127.0.0.1:0 --tag ${TAG}
Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo "Enabling and starting MTProxy..."
systemctl daemon-reload
systemctl enable mtproxy
systemctl restart mtproxy

# Generate proxy link
IP=$(curl -s ifconfig.me)
TG_LINK="tg://proxy?server=${IP}&port=${PORT}&secret=${SECRET}"

echo "============================================"
echo "✅ MTProxy is installed and running!"
echo "Server IP: $IP"
echo "Port: $PORT"
echo "Secret: $SECRET"
echo "Telegram Proxy Link:"
echo "$TG_LINK"
echo "============================================"
