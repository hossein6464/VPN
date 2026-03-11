#!/bin/bash
#
# VPN Server - runs ss-server natively on macOS (no Docker needed)
#

CONFIG_DIR="$HOME/.shadowsocks-vpn"
mkdir -p "$CONFIG_DIR"
PID_FILE="$CONFIG_DIR/ss-server.pid"
LOG_FILE="$CONFIG_DIR/ss-server.log"

# Use existing port and password if available, otherwise generate new ones
if [ -f "$CONFIG_DIR/server.conf" ]; then
    source "$CONFIG_DIR/server.conf"
    echo "Using existing config: port=$VPN_PORT"
else
    VPN_PORT=$(( ( RANDOM % 10000 ) + 40000 ))
    SS_SECRET=$(openssl rand -base64 16 | tr -d '=+/' | head -c 16)
fi

# Save config for reuse
cat > "$CONFIG_DIR/server.conf" <<EOF
VPN_PORT=$VPN_PORT
SS_SECRET=$SS_SECRET
EOF

echo "=========================================="
echo "  Shadowsocks VPN Server (Native macOS)"
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

# Start ss-server natively
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

# Verify it's running
if kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo "✅ VPN server is running! PID=$(cat "$PID_FILE")"
else
    echo "❌ Server failed to start. Check log:"
    cat "$LOG_FILE"
    exit 1
fi

# Get IPs
PUBLIC_IP=$(curl -4 -s --max-time 5 ifconfig.me 2>/dev/null || curl -s --max-time 5 ifconfig.me 2>/dev/null || echo "YOUR_PUBLIC_IP")
LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null || echo "YOUR_LOCAL_IP")

# Generate ss:// links
SS_URI_B64=$(echo -n "chacha20-ietf-poly1305:${SS_SECRET}" | base64 | tr -d '\n')
SS_LINK="ss://${SS_URI_B64}@${PUBLIC_IP}:${VPN_PORT}#VPN-Home"
SS_LINK_LOCAL="ss://${SS_URI_B64}@${LOCAL_IP}:${VPN_PORT}#VPN-Local-Test"

# Save connection info
cat > "$CONFIG_DIR/connection-info.txt" <<CONNEOF
============================================
  YOUR VPN CONNECTION INFO
============================================

Public IP: $PUBLIC_IP
Local IP: $LOCAL_IP
Port: $VPN_PORT
Password: $SS_SECRET
Encryption: chacha20-ietf-poly1305

=== ACCESS KEY (share with client) ===
$SS_LINK

=== LOCAL TEST KEY (same WiFi) ===
$SS_LINK_LOCAL

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
echo "Public IP: $PUBLIC_IP"
echo "Local IP:  $LOCAL_IP"
echo "Port:      $VPN_PORT"
echo "Password:  $SS_SECRET"
echo "Cipher:    chacha20-ietf-poly1305"
echo ""
echo "=== ACCESS KEY (external) ==="
echo "$SS_LINK"
echo ""
echo "=== LOCAL TEST KEY (same WiFi) ==="
echo "$SS_LINK_LOCAL"
echo ""
echo "=== MANUAL ENTRY ==="
echo "Server: $PUBLIC_IP  (or $LOCAL_IP for local test)"
echo "Port: $VPN_PORT"
echo "Password: $SS_SECRET"
echo "Method: chacha20-ietf-poly1305"
echo ""
echo "Port forwarding: $VPN_PORT (TCP+UDP) -> $LOCAL_IP"
echo "Log file: $LOG_FILE"
echo ""
