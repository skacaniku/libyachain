#!/usr/bin/env bash
# LibyaChain Complete Service Stop Script
# Stops all services (except blockchain core)
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

stop_service() {
    local name=$1
    local port=$2

    if lsof -ti:$port > /dev/null 2>&1; then
        local pid=$(lsof -ti:$port)
        print_status "$YELLOW" "Stopping $name (PID: $pid)..."
        kill $pid 2>/dev/null || kill -9 $pid 2>/dev/null
        sleep 1
        if lsof -ti:$port > /dev/null 2>&1; then
            print_status "$RED" "  ✗ Failed to stop"
        else
            print_status "$GREEN" "  ✓ Stopped"
        fi
    else
        print_status "$BLUE" "$name not running"
    fi
}

print_status "$BLUE" "======================================"
print_status "$BLUE" "  Stopping LibyaChain Services"
print_status "$BLUE" "======================================"
echo ""

print_status "$YELLOW" "Stopping web applications..."
stop_service "landing-web" 4000
stop_service "docs-web" 3000
stop_service "faucet-web" 3001
stop_service "swap-web" 3002
stop_service "admin-web" 3003
stop_service "explorer-web" 3004

print_status "$YELLOW" "\nStopping DPWAC services..."
stop_service "dpwac-public" 3010
stop_service "dpwac-admin" 3011
stop_service "dpwac-onboarding" 18095

print_service "LYDX services..."
stop_service "lydx-gateway" 4010
stop_service "lydx-mobile" 4020

print_status "$YELLOW" "\nStopping backend services..."
stop_service "explorer-api" 8080
stop_service "explorer-proxy" 18080

print_status "$GREEN" "\n✓ All services stopped"
print_status "$YELLOW" "\nNote: Blockchain core (libyachaind) was not stopped"
print_status "$YELLOW" "To stop the blockchain, run: pkill libyachaind"
echo ""
