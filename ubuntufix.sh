#!/bin/bash
# MTProto Proxy Auto Installer (alexbers/mtprotoproxy)
# Port: 3418

set -e

PORT=3418
SECRET=$(head -c 16 /dev/urandom | xxd -ps)

echo "Updating system..."
apt update && apt upgrade -y

echo "Installing dependencies..."
apt install -y git python3 python3-pip python3-venv curl

echo "Cloning MTProtoProxy (Python)..."
if [ ! -d "/opt/mtprotoproxy" ]; then
    git clone https://github.com/alexbers/mtprotoproxy.git /opt/mtprotoproxy
fi

cd /opt/mtprotoproxy

echo "Creating virtual environment..."
python3 -m venv venv
source venv/bin/activate
pip install -U pip
pip install -r requirements.txt
deactivate

echo "Writing config.json..."
cat >/opt/mtprotoproxy/config.json <<EOF
{
  "proxy": {
    "host": "0.0.0.0",
    "port": ${PORT}
  },
  "users": {
    "${SECRET}": "user1"
  }
}
EOF

echo "Creating systemd service..."
cat >/etc/systemd/system/mtprotoproxy.service <<EOF
[Unit]
Description=MTProto Proxy (Python)
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/mtprotoproxy
ExecStart=/opt/mtprotoproxy/venv/bin/python3 /opt/mtprotoproxy/mtprotoproxy.py -c /opt/mtprotoproxy/config.json
Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo "Starting proxy..."
systemctl daemon-reload
systemctl enable mtprotoproxy
systemctl restart mtprotoproxy

IP=$(curl -s ifconfig.me)
TG_LINK="tg://proxy?server=${IP}&port=${PORT}&secret=${SECRET}"

echo "============================================"
echo "✅ MTProto Proxy is installed and running!"
echo "Server IP: $IP"
echo "Port: $PORT"
echo "Secret: $SECRET"
echo "Telegram Proxy Link:"
echo "$TG_LINK"
echo "============================================"
