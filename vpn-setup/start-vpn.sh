#!/bin/bash
# Start the VPN server (after it was stopped)
echo "Starting VPN server..."
docker start shadowsocks-vpn 2>/dev/null && echo "✅ VPN started" || echo "❌ VPN container not found. Run setup-vpn.sh first."
