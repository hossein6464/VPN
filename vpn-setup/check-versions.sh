#!/bin/bash
echo "=== Mac ss-local version ==="
ss-local --help 2>&1 | head -5

echo ""
echo "=== Docker ss-server version ==="
docker exec outline-vpn ss-server --help 2>&1 | head -5

echo ""
echo "=== Docker ss-server full command ==="
docker inspect outline-vpn --format '{{.Config.Cmd}}' 2>&1

echo ""
echo "=== Docker image details ==="
docker inspect shadowsocks/shadowsocks-libev:latest --format '{{.Created}}' 2>&1

