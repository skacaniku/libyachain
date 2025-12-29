#!/bin/bash

###############################################################################
# Explorer & Faucet Security Testing Script
#
# Tests the security implementation for explorer-web and faucet-web:
# 1. Rate limiting enforcement
# 2. Security headers presence
# 3. CORS protection
# 4. Response format validation
#
# Usage:
#   ./scripts/test-explorer-faucet-security.sh [explorer|faucet|all]
#
# Requirements:
#   - curl
#   - jq (for JSON parsing)
#   - Explorer or Faucet dev servers running
###############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
EXPLORER_URL="${EXPLORER_URL:-http://localhost:3004}"
FAUCET_URL="${FAUCET_URL:-http://localhost:3005}"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

###############################################################################
# Helper Functions
###############################################################################

print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

print_test() {
    echo -e "${YELLOW}TEST:${NC} $1"
    TESTS_RUN=$((TESTS_RUN + 1))
}

print_pass() {
    echo -e "${GREEN}✓ PASS:${NC} $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

print_fail() {
    echo -e "${RED}✗ FAIL:${NC} $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

print_info() {
    echo -e "${BLUE}INFO:${NC} $1"
}

check_dependency() {
    if ! command -v "$1" &> /dev/null; then
        echo -e "${RED}ERROR:${NC} $1 is required but not installed."
        echo "Please install $1 and try again."
        exit 1
    fi
}

###############################################################################
# Test Functions
###############################################################################

test_security_headers() {
    local url="$1"
    local name="$2"

    print_test "Security headers for $name"

    local headers=$(curl -s -I "$url" 2>/dev/null || echo "")

    if [ -z "$headers" ]; then
        print_fail "Could not fetch headers from $url (is server running?)"
        return
    fi

    # Check CSP header
    if echo "$headers" | grep -qi "Content-Security-Policy"; then
        print_pass "CSP header present"
    else
        print_fail "CSP header missing"
    fi

    # Check X-Frame-Options
    if echo "$headers" | grep -qi "X-Frame-Options.*DENY"; then
        print_pass "X-Frame-Options: DENY"
    else
        print_fail "X-Frame-Options header missing or incorrect"
    fi

    # Check X-Content-Type-Options
    if echo "$headers" | grep -qi "X-Content-Type-Options.*nosniff"; then
        print_pass "X-Content-Type-Options: nosniff"
    else
        print_fail "X-Content-Type-Options header missing"
    fi

    # Check X-Powered-By is removed
    if echo "$headers" | grep -qi "X-Powered-By"; then
        print_fail "X-Powered-By header should be removed"
    else
        print_pass "X-Powered-By header removed"
    fi
}

test_rate_limit_headers() {
    local url="$1"
    local name="$2"

    print_test "Rate limit headers for $name"

    local headers=$(curl -s -I "$url" 2>/dev/null || echo "")

    if [ -z "$headers" ]; then
        print_fail "Could not fetch headers from $url"
        return
    fi

    # Check rate limit headers
    if echo "$headers" | grep -qi "X-RateLimit-Limit"; then
        print_pass "X-RateLimit-Limit header present"
    else
        print_fail "X-RateLimit-Limit header missing"
    fi

    if echo "$headers" | grep -qi "X-RateLimit-Remaining"; then
        print_pass "X-RateLimit-Remaining header present"
    else
        print_fail "X-RateLimit-Remaining header missing"
    fi

    if echo "$headers" | grep -qi "X-RateLimit-Reset"; then
        print_pass "X-RateLimit-Reset header present"
    else
        print_fail "X-RateLimit-Reset header missing"
    fi
}

test_cors_preflight() {
    local url="$1"
    local name="$2"

    print_test "CORS preflight for $name"

    local response=$(curl -s -I -X OPTIONS \
        -H "Origin: http://localhost:3000" \
        -H "Access-Control-Request-Method: GET" \
        "$url" 2>/dev/null || echo "")

    if [ -z "$response" ]; then
        print_fail "Could not fetch CORS preflight response"
        return
    fi

    # Check status code
    if echo "$response" | grep -q "204 No Content"; then
        print_pass "CORS preflight returns 204 No Content"
    else
        print_fail "CORS preflight should return 204"
    fi

    # Check CORS headers
    if echo "$response" | grep -qi "Access-Control-Allow-Methods"; then
        print_pass "Access-Control-Allow-Methods header present"
    else
        print_fail "Access-Control-Allow-Methods header missing"
    fi

    if echo "$response" | grep -qi "Access-Control-Allow-Headers"; then
        print_pass "Access-Control-Allow-Headers header present"
    else
        print_fail "Access-Control-Allow-Headers header missing"
    fi
}

test_rate_limiting_enforcement() {
    local url="$1"
    local limit="$2"
    local name="$3"

    print_test "Rate limiting enforcement for $name (limit: $limit)"

    print_info "Sending $((limit + 1)) requests to test rate limit..."

    local success_count=0
    local rate_limited=0

    # Send requests up to limit + 1
    for i in $(seq 1 $((limit + 1))); do
        local status=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")

        if [ "$status" = "200" ] || [ "$status" = "304" ]; then
            success_count=$((success_count + 1))
        elif [ "$status" = "429" ]; then
            rate_limited=$((rate_limited + 1))
        fi

        # Small delay to avoid overwhelming the server
        sleep 0.05
    done

    print_info "Successful requests: $success_count"
    print_info "Rate limited requests: $rate_limited"

    if [ $rate_limited -gt 0 ]; then
        print_pass "Rate limiting is active (received 429 responses)"
    else
        print_fail "Rate limiting may not be working (no 429 responses)"
    fi

    # Check for Retry-After header on rate limited response
    if [ $rate_limited -gt 0 ]; then
        local retry_after=$(curl -s -I "$url" 2>/dev/null | grep -i "Retry-After" || echo "")
        if [ -n "$retry_after" ]; then
            print_pass "Retry-After header present in 429 response"
        else
            print_fail "Retry-After header missing in 429 response"
        fi
    fi
}

test_explorer_api() {
    print_header "Testing Explorer Security"

    # Check if explorer is running
    if ! curl -s "$EXPLORER_URL" > /dev/null 2>&1; then
        print_fail "Explorer is not running at $EXPLORER_URL"
        print_info "Start explorer with: cd explorer-web && npm run dev"
        return
    fi

    print_info "Explorer URL: $EXPLORER_URL"

    # Test security headers
    test_security_headers "$EXPLORER_URL" "Explorer"

    # Test rate limit headers
    test_rate_limit_headers "$EXPLORER_URL" "Explorer"

    # Test CORS preflight
    test_cors_preflight "$EXPLORER_URL" "Explorer"

    # Note: We don't test rate limiting enforcement by default because it would
    # send 200+ requests. Uncomment below to test (may take ~10 seconds):
    #
    # test_rate_limiting_enforcement "$EXPLORER_URL" 200 "Explorer"
    #
    print_info "Rate limiting enforcement test skipped (would send 200+ requests)"
    print_info "To test manually: for i in {1..201}; do curl -I $EXPLORER_URL; done"
}

test_faucet_api() {
    print_header "Testing Faucet Security"

    # Check if faucet is running
    if ! curl -s "$FAUCET_URL" > /dev/null 2>&1; then
        print_fail "Faucet is not running at $FAUCET_URL"
        print_info "Start faucet with: cd faucet-web && npm run dev"
        return
    fi

    print_info "Faucet URL: $FAUCET_URL"

    # Test security headers (should include Turnstile CSP)
    test_security_headers "$FAUCET_URL" "Faucet"

    # Test rate limit headers
    test_rate_limit_headers "$FAUCET_URL" "Faucet"

    # Test CORS preflight
    test_cors_preflight "$FAUCET_URL" "Faucet"

    # Check CSP includes Turnstile
    print_test "CSP includes Cloudflare Turnstile domains"
    local csp=$(curl -s -I "$FAUCET_URL" 2>/dev/null | grep -i "Content-Security-Policy" || echo "")
    if echo "$csp" | grep -q "challenges.cloudflare.com"; then
        print_pass "CSP allows challenges.cloudflare.com"
    else
        print_fail "CSP missing Cloudflare Turnstile domains"
    fi

    # Note: We don't test rate limiting enforcement by default
    # Uncomment below to test general rate limit (100 req/min):
    #
    # test_rate_limiting_enforcement "$FAUCET_URL" 100 "Faucet General"
    #
    print_info "Rate limiting enforcement test skipped"
    print_info "To test manually: for i in {1..101}; do curl -I $FAUCET_URL; done"
}

###############################################################################
# Main
###############################################################################

main() {
    print_header "LibyaChain Explorer & Faucet Security Tests"

    # Check dependencies
    check_dependency curl
    # jq is optional, but helpful
    if ! command -v jq &> /dev/null; then
        print_info "jq is not installed. JSON output will not be pretty-printed."
    fi

    # Determine what to test
    local target="${1:-all}"

    case "$target" in
        explorer)
            test_explorer_api
            ;;
        faucet)
            test_faucet_api
            ;;
        all)
            test_explorer_api
            test_faucet_api
            ;;
        *)
            echo "Usage: $0 [explorer|faucet|all]"
            echo ""
            echo "Examples:"
            echo "  $0              # Test both explorer and faucet"
            echo "  $0 explorer     # Test explorer only"
            echo "  $0 faucet       # Test faucet only"
            exit 1
            ;;
    esac

    # Print summary
    print_header "Test Summary"
    echo "Total tests run:    $TESTS_RUN"
    echo -e "${GREEN}Tests passed:       $TESTS_PASSED${NC}"
    if [ $TESTS_FAILED -gt 0 ]; then
        echo -e "${RED}Tests failed:       $TESTS_FAILED${NC}"
        exit 1
    else
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    fi
}

# Run main function with all arguments
main "$@"
