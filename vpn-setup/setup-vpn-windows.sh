#!/bin/bash
#
# VPN Server setup for Windows (WSL2)
# Run this inside WSL: bash vpn-setup/setup-vpn-windows.sh
#

# Check we're running in WSL
if ! grep -qi microsoft /proc/version 2>/dev/null; then
    echo "⚠️  This script is meant for WSL2 on Windows."
    echo "   On macOS/Linux, use: bash vpn-setup/setup-vpn.sh"
    exit 1
fi

# Install shadowsocks-libev if missing
if ! command -v ss-server &>/dev/null; then
    echo "Installing shadowsocks-libev..."
    sudo apt update && sudo apt install -y shadowsocks-libev
    if ! command -v ss-server &>/dev/null; then
        echo "❌ Failed to install shadowsocks-libev"
        exit 1
    fi
    echo "✅ shadowsocks-libev installed"
fi

CONFIG_DIR="$HOME/.shadowsocks-vpn"
mkdir -p "$CONFIG_DIR"
PID_FILE="$CONFIG_DIR/ss-server.pid"
LOG_FILE="$CONFIG_DIR/ss-server.log"

# Use existing config or generate new
if [ -f "$CONFIG_DIR/server.conf" ]; then
    source "$CONFIG_DIR/server.conf"
    echo "Using existing config: port=$VPN_PORT"
else
    VPN_PORT=$(( ( RANDOM % 10000 ) + 40000 ))
    SS_SECRET=$(openssl rand -base64 16 | tr -d '=+/' | head -c 16)
fi

cat > "$CONFIG_DIR/server.conf" <<EOF
VPN_PORT=$VPN_PORT
SS_SECRET=$SS_SECRET
EOF

echo "=========================================="
echo "  Shadowsocks VPN Server (WSL2 / Windows)"
echo "=========================================="
echo ""

# Kill any existing ss-server
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    kill "$OLD_PID" 2>/dev/null
    sleep 1
fi
pkill -f "ss-server.*$VPN_PORT" 2>/dev/null
sleep 1

echo "Starting ss-server on port $VPN_PORT..."

ss-server \
    -s 0.0.0.0 \
    -p "$VPN_PORT" \
    -k "$SS_SECRET" \
    -m chacha20-ietf-poly1305 \
    -d 8.8.8.8,8.8.4.4 \
    -u \
    -v \
    > "$LOG_FILE" 2>&1 &

echo $! > "$PID_FILE"
sleep 2

if kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo "✅ VPN server is running! PID=$(cat "$PID_FILE")"
else
    echo "❌ Server failed to start. Check log:"
    cat "$LOG_FILE"
    exit 1
fi

# Get IPs
PUBLIC_IP=$(curl -4 -s --max-time 5 ifconfig.me 2>/dev/null || echo "YOUR_PUBLIC_IP")
# WSL local IP (visible from Windows host)
WSL_IP=$(hostname -I | awk '{print $1}')
# Windows host IP (for LAN access)
WIN_IP=$(ip route show default | awk '{print $3}' 2>/dev/null || echo "YOUR_WINDOWS_IP")

# Generate ss:// links
SS_URI_B64=$(echo -n "chacha20-ietf-poly1305:${SS_SECRET}" | base64 | tr -d '\n')
SS_LINK="ss://${SS_URI_B64}@${PUBLIC_IP}:${VPN_PORT}#VPN-Home"

cat > "$CONFIG_DIR/connection-info.txt" <<CONNEOF
============================================
  YOUR VPN CONNECTION INFO
============================================

Public IP:  $PUBLIC_IP
WSL IP:     $WSL_IP
Windows IP: $WIN_IP
Port:       $VPN_PORT
Password:   $SS_SECRET
Encryption: chacha20-ietf-poly1305

=== ACCESS KEY ===
$SS_LINK

=== MANUAL CONFIG ===
Server: $PUBLIC_IP
Port: $VPN_PORT
Password: $SS_SECRET
Encryption: chacha20-ietf-poly1305
============================================
CONNEOF

echo ""
echo "=========================================="
echo "  ✅ VPN SERVER IS READY!"
echo "=========================================="
echo ""
echo "Public IP:  $PUBLIC_IP"
echo "WSL IP:     $WSL_IP"
echo "Port:       $VPN_PORT"
echo "Password:   $SS_SECRET"
echo "Cipher:     chacha20-ietf-poly1305"
echo ""
echo "=== ACCESS KEY ==="
echo "$SS_LINK"
echo ""
echo "=========================================="
echo "  ⚠️  WINDOWS FIREWALL — RUN IN POWERSHELL (AS ADMIN):"
echo "=========================================="
echo ""
echo "  netsh interface portproxy add v4tov4 listenport=$VPN_PORT listenaddress=0.0.0.0 connectport=$VPN_PORT connectaddress=$WSL_IP"
echo "  netsh advfirewall firewall add rule name=\"Shadowsocks TCP\" dir=in action=allow protocol=TCP localport=$VPN_PORT"
echo "  netsh advfirewall firewall add rule name=\"Shadowsocks UDP\" dir=in action=allow protocol=UDP localport=$VPN_PORT"
echo ""
echo "Then forward port $VPN_PORT (TCP+UDP) on your router to your Windows PC's LAN IP."
echo ""
echo "Log file: $LOG_FILE"
echo ""

