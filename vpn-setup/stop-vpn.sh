#!/bin/bash
# Stop the VPN server
echo "Stopping VPN server..."
docker stop shadowsocks-vpn 2>/dev/null && echo "✅ VPN stopped" || echo "VPN was not running"
