#!/bin/bash
# MTProxy Firewall & Status Checker for CentOS 7
# Author: ChatGPT

PORT=3418

echo "=== MTProxy Status & Firewall Checker ==="

# 1️⃣ Check if MTProxy is running
if systemctl is-active --quiet mtproxy; then
    echo "[✓] MTProxy service is running."
else
    echo "[✗] MTProxy is NOT running!"
    echo "Try: systemctl start mtproxy"
    exit 1
fi

# 2️⃣ Check if port 3418 is listening locally
if ss -tulnp | grep -q ":$PORT"; then
    echo "[✓] MTProxy is listening on port $PORT."
else
    echo "[✗] MTProxy is NOT listening on port $PORT."
    echo "Check mtproxy service logs: journalctl -u mtproxy -f"
    exit 1
fi

# 3️⃣ Check and open firewall port
if command -v firewall-cmd >/dev/null 2>&1; then
    if firewall-cmd --list-ports | grep -q "$PORT/tcp"; then
        echo "[✓] Firewall already allows port $PORT/tcp."
    else
        echo "[!] Opening port $PORT/tcp in firewalld..."
        firewall-cmd --permanent --add-port=$PORT/tcp
        firewall-cmd --reload
        echo "[✓] Port $PORT/tcp added to firewall."
    fi
else
    echo "[⚠️] firewalld not found. Make sure port $PORT is open manually."
fi

# 4️⃣ Suggest external connectivity test
echo
echo "📌 Now test from your local PC or phone:"
echo "   nc -vz YOUR_SERVER_IP $PORT"
echo "   or try the Telegram proxy link again."

echo "=== Check Complete ==="
