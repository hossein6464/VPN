#!/bin/bash
# Check VPN server status (native ss-server)

CONFIG_DIR="$HOME/.shadowsocks-vpn"
PID_FILE="$CONFIG_DIR/ss-server.pid"
LOG_FILE="$CONFIG_DIR/ss-server.log"

echo "=== VPN Server Status ==="

if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    PID=$(cat "$PID_FILE")
    echo "✅ VPN server is RUNNING (PID $PID)"
    echo ""
    # Show port from config
    if [ -f "$CONFIG_DIR/server.conf" ]; then
        source "$CONFIG_DIR/server.conf"
        echo "Port: $VPN_PORT"
    fi
    # Show active connections
    echo ""
    echo "=== Active Connections ==="
    if [ -f "$CONFIG_DIR/server.conf" ]; then
        lsof -i ":$VPN_PORT" -n 2>/dev/null | grep ESTABLISHED || echo "No active client connections"
    fi
    echo ""
    echo "=== Recent Logs ==="
    tail -10 "$LOG_FILE" 2>/dev/null || echo "No logs found"
else
    echo "❌ VPN server is NOT running"
    echo ""
    echo "Run: bash vpn-setup/start-vpn.sh    (if previously set up)"
    echo "Run: bash vpn-setup/setup-vpn.sh    (for first-time setup)"
fi

echo ""
echo "=== Connection Info ==="
if [ -f "$CONFIG_DIR/connection-info.txt" ]; then
    cat "$CONFIG_DIR/connection-info.txt"
else
    echo "No connection info found. Run setup-vpn.sh first."
fi
