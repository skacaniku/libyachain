#!/usr/bin/env bash
# LibyaChain Service Status Checker
# Version: 1.0 - October 15, 2025

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

check_service() {
    local name=$1
    local port=$2
    local url=$3

    printf "%-25s %-8s " "$name" "($port)"

    if lsof -ti:$port > /dev/null 2>&1; then
        local pid=$(lsof -ti:$port)
        # Test HTTP response if URL provided
        if [ -n "$url" ]; then
            local http_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 "$url" 2>/dev/null || echo "000")
            if [ "$http_code" = "200" ] || [ "$http_code" = "404" ]; then
                print_status "$GREEN" "✓ Running (PID: $pid, HTTP: $http_code)"
            else
                print_status "$YELLOW" "⚠ Running but HTTP $http_code (PID: $pid)"
            fi
        else
            print_status "$GREEN" "✓ Running (PID: $pid)"
        fi
    else
        print_status "$RED" "✗ Not running"
    fi
}

print_status "$BLUE" "=============================================="
print_status "$BLUE" "  LibyaChain Service Status"
print_status "$BLUE" "=============================================="
echo ""

print_status "$YELLOW" "Blockchain Core:"
check_service "RPC" "26657" "http://localhost:26657/health"
check_service "REST API" "1317" "http://localhost:1317/cosmos/base/tendermint/v1beta1/node_info"

print_status "$YELLOW" "\nBackend Services:"
check_service "Explorer API" "8080" "http://localhost:8080/health"
check_service "Explorer Proxy" "18080" "http://localhost:18080/health"

print_status "$YELLOW" "\nLYDX Services:"
check_service "LYDX Gateway" "4010" "http://localhost:4010/healthz"
check_service "LYDX Mobile App" "4020" "http://localhost:4020"

print_status "$YELLOW" "\nDPWAC Services:"
check_service "DPWAC Public" "3010" "http://localhost:3010"
check_service "DPWAC Admin" "3011" "http://localhost:3011"
check_service "DPWAC Onboarding" "18095" "http://localhost:18095/healthz"

print_status "$YELLOW" "\nWeb Applications:"
check_service "Landing Page" "4000" "http://localhost:4000"
check_service "Docs Portal" "3000" "http://localhost:3000"
check_service "Faucet" "3001" "http://localhost:3001"
check_service "Swap" "3002" "http://localhost:3002"
check_service "Admin Dashboard" "3003" "http://localhost:3003"
check_service "Explorer" "3004" "http://localhost:3004"

print_status "$BLUE" "\n=============================================="
print_status "$BLUE" "  Cloudflare Tunnel Status"
print_status "$BLUE" "=============================================="
echo ""

if pgrep -f "cloudflared tunnel" > /dev/null; then
    tunnel_pid=$(pgrep -f "cloudflared tunnel")
    print_status "$GREEN" "✓ Cloudflare Tunnel running (PID: $tunnel_pid)"
    print_status "$BLUE" "\nTesting public endpoints..."

    printf "%-30s " "admin.libyachain.net"
    code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "https://admin.libyachain.net" 2>/dev/null || echo "000")
    [ "$code" = "200" ] && print_status "$GREEN" "✓ $code" || print_status "$RED" "✗ $code"

    printf "%-30s " "explorer.libyachain.net"
    code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "https://explorer.libyachain.net" 2>/dev/null || echo "000")
    [ "$code" = "200" ] && print_status "$GREEN" "✓ $code" || print_status "$RED" "✗ $code"

    printf "%-30s " "lydx.libyachain.net"
    code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "https://lydx.libyachain.net" 2>/dev/null || echo "000")
    [ "$code" = "200" ] && print_status "$GREEN" "✓ $code" || print_status "$RED" "✗ $code"
else
    print_status "$RED" "✗ Cloudflare Tunnel not running"
fi

echo ""
print_status "$BLUE" "=============================================="
echo ""
