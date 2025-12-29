#!/bin/bash
#
# Security Setup Verification Script
# Verifies all security components are properly configured for LibyaChain
#
# Usage: ./scripts/verify-security-setup.sh [--production]
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if running in production mode
PRODUCTION_MODE=false
if [ "$1" == "--production" ]; then
  PRODUCTION_MODE=true
  echo -e "${BLUE}Running in PRODUCTION verification mode${NC}\n"
else
  echo -e "${BLUE}Running in DEVELOPMENT verification mode${NC}"
  echo -e "${YELLOW}Use --production flag for production checks${NC}\n"
fi

# Counter for issues
ERRORS=0
WARNINGS=0
PASSED=0

# Helper functions
check_pass() {
  echo -e "${GREEN}✅ PASS${NC}: $1"
  ((PASSED++))
}

check_warn() {
  echo -e "${YELLOW}⚠️  WARN${NC}: $1"
  ((WARNINGS++))
}

check_fail() {
  echo -e "${RED}❌ FAIL${NC}: $1"
  ((ERRORS++))
}

section_header() {
  echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}$1${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

# Check 1: Environment Variables
section_header "1. Environment Variables"

if [ -n "$JWT_SECRET" ] || [ -n "$JWT_KEY_CONFIG" ]; then
  check_pass "JWT secret configured"
else
  if [ "$PRODUCTION_MODE" = true ]; then
    check_fail "JWT_SECRET or JWT_KEY_CONFIG not set (REQUIRED in production)"
  else
    check_warn "JWT_SECRET or JWT_KEY_CONFIG not set (OK for development)"
  fi
fi

if [ -n "$DASHBOARD_SESSION_SECRET" ]; then
  check_pass "DASHBOARD_SESSION_SECRET configured"
else
  if [ "$PRODUCTION_MODE" = true ]; then
    check_fail "DASHBOARD_SESSION_SECRET not set (REQUIRED in production)"
  else
    check_warn "DASHBOARD_SESSION_SECRET not set (OK for development)"
  fi
fi

if [ "$DEMO_USER_ENABLED" == "false" ] || [ -z "$DEMO_USER_ENABLED" ]; then
  check_pass "Demo users disabled or not set"
else
  if [ "$PRODUCTION_MODE" = true ]; then
    check_fail "DEMO_USER_ENABLED=true in production (SECURITY RISK)"
  else
    check_warn "DEMO_USER_ENABLED=true (disable for production)"
  fi
fi

# Check 2: Redis Configuration
section_header "2. Redis Configuration"

if command -v redis-cli &> /dev/null; then
  check_pass "redis-cli installed"

  if redis-cli ping &> /dev/null; then
    check_pass "Redis server responding"

    # Check Redis version
    REDIS_VERSION=$(redis-cli INFO server | grep redis_version | cut -d: -f2 | tr -d '\r')
    echo -e "  ${BLUE}ℹ${NC}  Redis version: $REDIS_VERSION"

    # Check if password protected
    if redis-cli CONFIG GET requirepass | grep -q "\"\""; then
      if [ "$PRODUCTION_MODE" = true ]; then
        check_warn "Redis password not set (recommended for production)"
      else
        check_pass "Redis password not required (OK for development)"
      fi
    else
      check_pass "Redis password protected"
    fi
  else
    check_warn "Redis server not responding (session revocation disabled)"
    echo -e "  ${YELLOW}Note: System works without Redis (graceful degradation)${NC}"
  fi
else
  check_warn "redis-cli not installed (session revocation disabled)"
  echo -e "  ${YELLOW}Note: System works without Redis (graceful degradation)${NC}"
fi

# Check 3: Node.js Dependencies
section_header "3. Node.js Dependencies"

cd "$(dirname "$0")/.."

for DIR in admin-web faucet-web explorer-web; do
  if [ -d "$DIR" ]; then
    echo -e "${BLUE}Checking $DIR...${NC}"

    if [ -f "$DIR/package.json" ]; then
      # Check for Playwright (if e2e tests exist)
      if [ -d "$DIR/e2e" ]; then
        if grep -q "@playwright/test" "$DIR/package.json"; then
          check_pass "$DIR: Playwright installed"
        else
          check_warn "$DIR: Playwright not in package.json (run npm install)"
        fi
      fi

      # Check for CosmJS
      if grep -q "@cosmjs/stargate" "$DIR/package.json" || grep -q "@cosmjs/crypto" "$DIR/package.json"; then
        check_pass "$DIR: CosmJS dependencies present"
      fi
    else
      check_warn "$DIR: No package.json found"
    fi
  fi
done

# Check for ioredis in root package.json
if [ -f "package.json" ] && grep -q "ioredis" "package.json"; then
  check_pass "ioredis dependency installed"
else
  check_warn "ioredis not found in root package.json"
fi

# Check 4: Security Modules
section_header "4. Security Modules"

REQUIRED_MODULES=(
  "shared-utils/jwt-rotation.ts"
  "shared-utils/session-store.ts"
  "shared-utils/csrf-protection.ts"
  "shared-utils/redis-client.ts"
)

for MODULE in "${REQUIRED_MODULES[@]}"; do
  if [ -f "$MODULE" ]; then
    check_pass "$(basename $MODULE) exists"
  else
    check_fail "$(basename $MODULE) missing"
  fi
done

# Check 5: Build Status
section_header "5. Build Verification"

echo -e "${BLUE}Checking if blockchain builds...${NC}"
if [ -f "Makefile" ]; then
  if make build 2>&1 | grep -q "error"; then
    check_fail "Blockchain build has errors"
  else
    check_pass "Blockchain builds successfully"
  fi
else
  check_warn "Makefile not found, skipping build check"
fi

# Check 6: Configuration Files
section_header "6. Configuration Files"

CONFIG_FILES=(
  ".env.example"
  "admin-web/playwright.config.ts"
  "faucet-web/playwright.config.ts"
)

for FILE in "${CONFIG_FILES[@]}"; do
  if [ -f "$FILE" ]; then
    check_pass "$(basename $FILE) exists"
  else
    check_warn "$(basename $FILE) not found"
  fi
done

# Check 7: Documentation
section_header "7. Documentation"

DOC_FILES=(
  "SECURITY-STATUS-FINAL.md"
  "SECURITY-REMEDIATION-COMPLETE.md"
  "SECURITY-ENHANCEMENTS-SESSION-REVOCATION.md"
  "DEPLOYMENT-GUIDE.md"
  "FAUCET-E2E-TESTS-READY.md"
)

for FILE in "${DOC_FILES[@]}"; do
  if [ -f "$FILE" ]; then
    check_pass "$FILE"
  else
    check_warn "$FILE not found"
  fi
done

# Check 8: Git Status
section_header "8. Git Status"

if [ -d ".git" ]; then
  MODIFIED_FILES=$(git status --short | grep -c "^.M" || true)
  UNTRACKED_FILES=$(git status --short | grep -c "^??" || true)

  echo -e "  ${BLUE}ℹ${NC}  Modified files: $MODIFIED_FILES"
  echo -e "  ${BLUE}ℹ${NC}  Untracked files: $UNTRACKED_FILES"

  if [ $MODIFIED_FILES -gt 0 ] || [ $UNTRACKED_FILES -gt 0 ]; then
    check_warn "Uncommitted changes present"
    echo -e "  ${YELLOW}Run 'git status' to see details${NC}"
  else
    check_pass "Working directory clean"
  fi
fi

# Check 9: Production-Specific Checks
if [ "$PRODUCTION_MODE" = true ]; then
  section_header "9. Production Readiness"

  # HTTPS check
  if [ "$NODE_ENV" == "production" ]; then
    check_pass "NODE_ENV=production"
  else
    check_warn "NODE_ENV not set to 'production'"
  fi

  # Check for test/demo code
  if grep -r "DEMO_USER" admin-web/lib 2>/dev/null | grep -v "DEMO_USER_ENABLED" &> /dev/null; then
    check_warn "Demo user code found in admin-web/lib"
  else
    check_pass "No demo user code in admin-web/lib"
  fi

  # Check for hardcoded secrets
  if grep -r "secret.*=.*['\"]" shared-utils/*.ts 2>/dev/null | grep -v "process.env" | grep -v "//" &> /dev/null; then
    check_fail "Possible hardcoded secrets found"
  else
    check_pass "No hardcoded secrets detected"
  fi
fi

# Final Summary
section_header "VERIFICATION SUMMARY"

TOTAL=$((PASSED + WARNINGS + ERRORS))

echo -e "${GREEN}✅ Passed${NC}:  $PASSED/$TOTAL"
echo -e "${YELLOW}⚠️  Warnings${NC}: $WARNINGS/$TOTAL"
echo -e "${RED}❌ Failed${NC}:  $ERRORS/$TOTAL"

echo ""

if [ $ERRORS -gt 0 ]; then
  echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${RED}VERIFICATION FAILED${NC}"
  echo -e "${RED}Fix errors above before deploying to production${NC}"
  echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  exit 1
elif [ $WARNINGS -gt 0 ] && [ "$PRODUCTION_MODE" = true ]; then
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${YELLOW}VERIFICATION PASSED WITH WARNINGS${NC}"
  echo -e "${YELLOW}Review warnings before deploying to production${NC}"
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  exit 0
else
  echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${GREEN}✅ VERIFICATION PASSED${NC}"
  echo -e "${GREEN}System is ready for deployment${NC}"
  echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  exit 0
fi
