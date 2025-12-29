#!/bin/bash
# Environment Variable Validation Script
# Validates that all required secrets are set before deployment

set -e

echo "🔍 LibyaChain Environment Validation"
echo "===================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track validation status
VALIDATION_FAILED=0
WARNINGS=0

# Function to check if a variable is set and not empty
check_secret() {
  local var_name=$1
  local var_value="${!var_name}"
  local service=$2
  local required_in_prod=${3:-true}

  if [ -z "$var_value" ]; then
    if [ "$NODE_ENV" = "production" ] && [ "$required_in_prod" = "true" ]; then
      echo -e "${RED}✗${NC} $var_name (required for $service)"
      VALIDATION_FAILED=1
    else
      echo -e "${YELLOW}⚠${NC} $var_name (recommended for $service)"
      WARNINGS=$((WARNINGS + 1))
    fi
  else
    # Check minimum length (32 characters recommended)
    local length=${#var_value}
    if [ $length -lt 32 ]; then
      echo -e "${YELLOW}⚠${NC} $var_name (set but length=$length, recommend >=32 characters)"
      WARNINGS=$((WARNINGS + 1))
    else
      echo -e "${GREEN}✓${NC} $var_name"
    fi
  fi
}

echo "Environment: ${NODE_ENV:-development}"
echo ""

# Admin Web Secrets
echo "Admin Web:"
check_secret "DASHBOARD_SESSION_SECRET" "admin-web" true

echo ""

# Swap Web Secrets
echo "Swap Web:"
check_secret "JWT_SECRET" "swap-web" true

echo ""

# LYDX Mobile App Secrets
echo "LYDX Mobile App:"
check_secret "JWT_SECRET" "lydx/mobile-app" true

echo ""

# DPWAC Onboarding Secrets
echo "DPWAC Onboarding:"
check_secret "DPWAC_ONBOARDING_JWT_SECRET" "dpwac-onboarding" true
check_secret "DPWAC_ONBOARDING_ADDR" "dpwac-onboarding" false

echo ""

# Faucet Admin Token
echo "Faucet:"
check_secret "FAUCET_ADMIN_TOKEN" "faucet" false

echo ""
echo "===================================="
echo ""

# Print summary
if [ $VALIDATION_FAILED -eq 1 ]; then
  echo -e "${RED}❌ VALIDATION FAILED${NC}"
  echo ""
  echo "Required secrets are missing. Please set all required environment"
  echo "variables before deploying to production."
  echo ""
  echo "See docs/REQUIRED_SECRETS.md for details on how to generate and set secrets."
  echo ""
  exit 1
elif [ $WARNINGS -gt 0 ]; then
  echo -e "${YELLOW}⚠️  VALIDATION PASSED WITH WARNINGS${NC}"
  echo ""
  echo "Found $WARNINGS warning(s). Consider addressing these for improved security."
  echo ""
  exit 0
else
  echo -e "${GREEN}✅ VALIDATION PASSED${NC}"
  echo ""
  echo "All required secrets are properly configured."
  echo ""
  exit 0
fi
