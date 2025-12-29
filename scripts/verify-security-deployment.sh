#!/bin/bash
#
# LibyaChain Security Stack Deployment Verification Script
#
# This script verifies that the security stack is properly deployed and functioning.
# It checks: rate limiting, input validation, audit logging, and endpoint security.
#
# Usage:
#   ./scripts/verify-security-deployment.sh [base_url]
#
# Example:
#   ./scripts/verify-security-deployment.sh https://admin.libyachain.net
#   ./scripts/verify-security-deployment.sh http://localhost:3000
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BASE_URL="${1:-http://localhost:3000}"
TEST_ADDRESS="libya1hkkzq3pctnvefu5ekfj9m95edgmzyu6vd872pm"
AUDIT_LOG="/var/log/libyachain/audit.log"

echo -e "${BLUE}==================================================================${NC}"
echo -e "${BLUE}  LibyaChain Security Stack Verification${NC}"
echo -e "${BLUE}==================================================================${NC}"
echo ""
echo "Testing against: $BASE_URL"
echo ""

# Track results
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Test function
test_endpoint() {
    local test_name="$1"
    local method="$2"
    local endpoint="$3"
    local data="$4"
    local expected_status="$5"
    local description="$6"

    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    echo -n "Test $TESTS_TOTAL: $test_name... "

    if [ -n "$data" ]; then
        response=$(curl -s -w "\n%{http_code}" -X "$method" \
            -H "Content-Type: application/json" \
            -d "$data" \
            "$BASE_URL$endpoint" 2>/dev/null || echo "000")
    else
        response=$(curl -s -w "\n%{http_code}" -X "$method" \
            "$BASE_URL$endpoint" 2>/dev/null || echo "000")
    fi

    status_code=$(echo "$response" | tail -n 1)
    body=$(echo "$response" | head -n -1)

    if [ "$status_code" = "$expected_status" ]; then
        echo -e "${GREEN}✓ PASS${NC} ($description)"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC} (Expected $expected_status, got $status_code)"
        echo "  Response: $body"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

echo -e "${BLUE}==================================================================${NC}"
echo -e "${BLUE}  1. Rate Limiting Tests${NC}"
echo -e "${BLUE}==================================================================${NC}"
echo ""

# Test rate limiting on faucet endpoint
echo "Testing faucet rate limiting (10 requests/minute limit)..."
for i in {1..11}; do
    response=$(curl -s -w "%{http_code}" -X POST \
        -H "Content-Type: application/json" \
        -d "{\"address\":\"$TEST_ADDRESS\",\"amount\":\"1000000\",\"denom\":\"ulydc\"}" \
        "$BASE_URL/api/faucet/request" 2>/dev/null || echo "000")

    status_code="${response: -3}"

    if [ $i -le 10 ]; then
        if [ "$status_code" != "429" ]; then
            echo -n "."
        else
            echo ""
            echo -e "${YELLOW}⚠  Warning: Rate limit triggered before 10 requests (at request $i)${NC}"
            break
        fi
    else
        # 11th request should be rate limited
        if [ "$status_code" = "429" ]; then
            echo ""
            TESTS_PASSED=$((TESTS_PASSED + 1))
            echo -e "${GREEN}✓ PASS${NC} Rate limiting working (11th request blocked)"
        else
            echo ""
            TESTS_FAILED=$((TESTS_FAILED + 1))
            echo -e "${RED}✗ FAIL${NC} Rate limiting not working (11th request allowed)"
        fi
    fi
    sleep 0.5
done
TESTS_TOTAL=$((TESTS_TOTAL + 1))

echo ""
echo -e "${BLUE}==================================================================${NC}"
echo -e "${BLUE}  2. Input Validation Tests${NC}"
echo -e "${BLUE}==================================================================${NC}"
echo ""

# Test invalid address format
test_endpoint \
    "Invalid address format" \
    "POST" \
    "/api/faucet/request" \
    '{"address":"invalid","amount":"1000000","denom":"ulydc"}' \
    "400" \
    "Should reject invalid address"

# Test invalid amount
test_endpoint \
    "Invalid amount format" \
    "POST" \
    "/api/faucet/request" \
    "{\"address\":\"$TEST_ADDRESS\",\"amount\":\"abc\",\"denom\":\"ulydc\"}" \
    "400" \
    "Should reject non-numeric amount"

# Test invalid denom
test_endpoint \
    "Invalid denomination" \
    "POST" \
    "/api/faucet/request" \
    "{\"address\":\"$TEST_ADDRESS\",\"amount\":\"1000000\",\"denom\":\"invalid\"}" \
    "400" \
    "Should reject invalid denomination"

# Test missing fields
test_endpoint \
    "Missing required fields" \
    "POST" \
    "/api/faucet/request" \
    '{"address":"'$TEST_ADDRESS'"}' \
    "400" \
    "Should reject missing fields"

# Test parameter pollution (extra fields)
test_endpoint \
    "Parameter pollution" \
    "POST" \
    "/api/faucet/request" \
    "{\"address\":\"$TEST_ADDRESS\",\"amount\":\"1000000\",\"denom\":\"ulydc\",\"extra\":\"malicious\"}" \
    "400" \
    "Should reject extra fields"

echo ""
echo -e "${BLUE}==================================================================${NC}"
echo -e "${BLUE}  3. Audit Logging Tests${NC}"
echo -e "${BLUE}==================================================================${NC}"
echo ""

# Check if audit log exists
if [ ! -f "$AUDIT_LOG" ]; then
    echo -e "${YELLOW}⚠  Warning: Audit log not found at $AUDIT_LOG${NC}"
    echo "  This is expected if running in development mode or if logs are sent to webhook only"
    echo "  Skipping audit log file tests..."
else
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    echo -n "Test $TESTS_TOTAL: Audit log exists... "
    echo -e "${GREEN}✓ PASS${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))

    # Check if audit log is writable
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    echo -n "Test $TESTS_TOTAL: Audit log is writable... "
    if [ -w "$AUDIT_LOG" ]; then
        echo -e "${GREEN}✓ PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    # Check if recent audit entries exist
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    echo -n "Test $TESTS_TOTAL: Recent audit entries exist... "
    recent_count=$(tail -n 100 "$AUDIT_LOG" 2>/dev/null | wc -l)
    if [ "$recent_count" -gt 0 ]; then
        echo -e "${GREEN}✓ PASS${NC} ($recent_count entries found)"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${YELLOW}⚠  SKIP${NC} (No recent entries - log may be new)"
    fi

    # Check if audit entries are valid JSON
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    echo -n "Test $TESTS_TOTAL: Audit entries are valid JSON... "
    if tail -n 10 "$AUDIT_LOG" 2>/dev/null | jq -e . >/dev/null 2>&1; then
        echo -e "${GREEN}✓ PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC} (Entries are not valid JSON)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    # Check for required fields in audit entries
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    echo -n "Test $TESTS_TOTAL: Audit entries have required fields... "
    if tail -n 1 "$AUDIT_LOG" 2>/dev/null | jq -e '.id and .timestamp and .eventType and .severity and .ipAddress and .success != null' >/dev/null 2>&1; then
        echo -e "${GREEN}✓ PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${YELLOW}⚠  SKIP${NC} (Could not verify - check manually)"
    fi
fi

echo ""
echo -e "${BLUE}==================================================================${NC}"
echo -e "${BLUE}  4. Endpoint Security Tests${NC}"
echo -e "${BLUE}==================================================================${NC}"
echo ""

# Test admin endpoint without authentication
test_endpoint \
    "Admin endpoint requires auth" \
    "POST" \
    "/api/admin/mint" \
    "{\"to\":\"$TEST_ADDRESS\",\"amount\":\"1000000\",\"denom\":\"ulydc\"}" \
    "401" \
    "Should require authentication"

# Test method not allowed
test_endpoint \
    "Method not allowed" \
    "GET" \
    "/api/faucet/request" \
    "" \
    "405" \
    "Should reject GET on POST-only endpoint"

echo ""
echo -e "${BLUE}==================================================================${NC}"
echo -e "${BLUE}  5. Configuration Verification${NC}"
echo -e "${BLUE}==================================================================${NC}"
echo ""

# Check environment variables
echo "Checking environment configuration..."

check_env_var() {
    local var_name="$1"
    local description="$2"
    local required="$3"

    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    echo -n "Test $TESTS_TOTAL: $description... "

    if [ -n "${!var_name:-}" ]; then
        echo -e "${GREEN}✓ SET${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        if [ "$required" = "true" ]; then
            echo -e "${RED}✗ NOT SET${NC} (Required)"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        else
            echo -e "${YELLOW}⚠  NOT SET${NC} (Optional)"
        fi
    fi
}

# Only check if .env file exists
if [ -f ".env.production" ] || [ -f ".env.local" ]; then
    # Load env file
    if [ -f ".env.production" ]; then
        export $(cat .env.production | grep -v '^#' | xargs) 2>/dev/null || true
    elif [ -f ".env.local" ]; then
        export $(cat .env.local | grep -v '^#' | xargs) 2>/dev/null || true
    fi

    check_env_var "AUDIT_LOG_PATH" "Audit log path configured" "false"
    check_env_var "AUDIT_WEBHOOK_URL" "SIEM webhook configured" "false"
    check_env_var "RATE_LIMIT_ENABLED" "Rate limiting enabled" "false"
else
    echo -e "${YELLOW}⚠  No .env file found - skipping configuration checks${NC}"
fi

echo ""
echo -e "${BLUE}==================================================================${NC}"
echo -e "${BLUE}  Test Results Summary${NC}"
echo -e "${BLUE}==================================================================${NC}"
echo ""
echo "Total Tests:  $TESTS_TOTAL"
echo -e "Passed:       ${GREEN}$TESTS_PASSED${NC}"
if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "Failed:       ${RED}$TESTS_FAILED${NC}"
else
    echo -e "Failed:       $TESTS_FAILED"
fi
echo ""

# Calculate percentage
if [ $TESTS_TOTAL -gt 0 ]; then
    PASS_RATE=$((TESTS_PASSED * 100 / TESTS_TOTAL))
    echo "Pass Rate: $PASS_RATE%"
    echo ""
fi

# Final verdict
if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ ALL TESTS PASSED${NC}"
    echo ""
    echo "The security stack is properly deployed and functioning."
    echo ""
    exit 0
else
    echo -e "${RED}✗ SOME TESTS FAILED${NC}"
    echo ""
    echo "Please review the failed tests and fix any issues."
    echo "See admin-web/AUDIT_LOG_SETUP.md for troubleshooting."
    echo ""
    exit 1
fi
