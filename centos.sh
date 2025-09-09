#!/bin/bash
# MTProxy Auto Installer for CentOS 7
# Author: ChatGPT

set -e

echo "=== MTProxy Auto Installer (CentOS 7) ==="

# Update system
yum update -y

# Install dependencies
yum install -y epel-release
yum install -y git curl gcc make zlib-devel openssl-devel

# Clone MTProxy repo
if [ ! -d "/opt/MTProxy" ]; then
    git clone https://github.com/TelegramMessenger/MTProxy /opt/MTProxy
fi

cd /opt/MTProxy
make

# Fetch proxy secret and config
curl -s https://core.telegram.org/getProxySecret -o /opt/MTProxy/proxy-secret
curl -s https://core.telegram.org/getProxyConfig -o /opt/MTProxy/proxy-multi.conf

# Generate random secret
SECRET=$(head -c 16 /dev/urandom | xxd -ps)
echo "Your generated secret: $SECRET"

# Create systemd service
cat <<EOF > /etc/systemd/system/mtproxy.service
[Unit]
Description=MTProxy Telegram Proxy
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/MTProxy
ExecStart=/opt/MTProxy/objs/bin/mtproto-proxy -u nobody -p 8888 -H 443 -S $SECRET --aes-pwd proxy-secret proxy-multi.conf -M 1
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and start service
systemctl daemon-reload
systemctl enable mtproxy
systemctl start mtproxy

# Show status
systemctl status mtproxy --no-pager

echo
echo "=== MTProxy Installed Successfully ==="
echo "Telegram Proxy Link:"
echo "tg://proxy?server=$(curl -s ifconfig.me)&port=443&secret=$SECRET"
