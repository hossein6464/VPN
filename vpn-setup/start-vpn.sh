#!/bin/bash
# Start the VPN server (native ss-server, using saved config)

CONFIG_DIR="$HOME/.shadowsocks-vpn"
PID_FILE="$CONFIG_DIR/ss-server.pid"
LOG_FILE="$CONFIG_DIR/ss-server.log"

if [ ! -f "$CONFIG_DIR/server.conf" ]; then
    echo "❌ No config found. Run setup-vpn.sh first."
    exit 1
fi

# Check if already running
if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo "⚠️  VPN server is already running (PID $(cat "$PID_FILE"))"
    exit 0
fi

source "$CONFIG_DIR/server.conf"

echo "Starting ss-server on port $VPN_PORT..."

ss-server \
    -s 0.0.0.0 \
    -p "$VPN_PORT" \
    -k "$SS_SECRET" \
    -m chacha20-ietf-poly1305 \
    -d 8.8.8.8,8.8.4.4 \
    -u \
    -v \
    >> "$LOG_FILE" 2>&1 &

echo $! > "$PID_FILE"
sleep 2

if kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo "✅ VPN server started (PID $(cat "$PID_FILE"), port $VPN_PORT)"
else
    echo "❌ Server failed to start. Check: tail $LOG_FILE"
    exit 1
fi
