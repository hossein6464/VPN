#!/bin/bash
echo "=== Docker Check ==="

if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed"
    echo "Please install Docker and try again"
    exit 1
fi

if docker info >/dev/null 2>&1; then
    echo "✅ Docker is running"
    docker --version
else
    echo "❌ Docker is NOT running"
    echo "Please start Docker (e.g., Docker Desktop or 'systemctl start docker')"
    echo "Then re-run this script"
    exit 1
fi

