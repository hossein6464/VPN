#!/bin/bash
# Check VPN server status
echo "=== VPN Server Status ==="
if docker ps | grep -q shadowsocks-vpn; then
    echo "✅ VPN server is RUNNING"
    echo ""
    docker ps --filter name=shadowsocks-vpn --format "Container: {{.Names}}\nStatus: {{.Status}}\nPorts: {{.Ports}}"
    echo ""
    echo "=== Recent Logs ==="
    docker logs shadowsocks-vpn --tail 10 2>&1
else
    echo "❌ VPN server is NOT running"
    echo ""
    echo "Run: bash start-vpn.sh    (if previously set up)"
    echo "Run: bash setup-vpn.sh    (for first-time setup)"
fi
echo ""
echo "=== Your Connection Info ==="
if [ -f "$HOME/.shadowsocks-vpn/connection-info.txt" ]; then
    cat "$HOME/.shadowsocks-vpn/connection-info.txt"
else
    echo "No connection info found. Run setup-vpn.sh first."
fi
