#!/bin/bash
# Stop the VPN server (native ss-server)

CONFIG_DIR="$HOME/.shadowsocks-vpn"
PID_FILE="$CONFIG_DIR/ss-server.pid"

if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
        kill "$PID" 2>/dev/null
        sleep 1
        if kill -0 "$PID" 2>/dev/null; then
            kill -9 "$PID" 2>/dev/null
        fi
        echo "✅ VPN server stopped (PID $PID)"
    else
        echo "VPN server was not running (stale PID $PID)"
    fi
    rm -f "$PID_FILE"
else
    # Try to find and kill any ss-server process
    if pkill -f "ss-server" 2>/dev/null; then
        echo "✅ VPN server stopped"
    else
        echo "VPN server was not running"
    fi
fi
