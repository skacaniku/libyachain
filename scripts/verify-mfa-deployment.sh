#!/bin/bash
# MFA Deployment Verification Script
# HIGH-005 Phases 1-8 Complete
# Generated: 2025-10-16

set -e

echo "=============================================="
echo "MFA System Deployment Verification"
echo "=============================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

# Function to print success
success() {
  echo -e "${GREEN}✅ $1${NC}"
}

# Function to print error
error() {
  echo -e "${RED}❌ $1${NC}"
  ERRORS=$((ERRORS + 1))
}

# Function to print warning
warning() {
  echo -e "${YELLOW}⚠️  $1${NC}"
  WARNINGS=$((WARNINGS + 1))
}

# Function to print info
info() {
  echo "ℹ️  $1"
}

echo "=== Step 1: Environment Variables ==="
echo ""

# Check DASHBOARD_SESSION_SECRET
if [ -z "$DASHBOARD_SESSION_SECRET" ]; then
  error "DASHBOARD_SESSION_SECRET not set"
else
  if [ ${#DASHBOARD_SESSION_SECRET} -lt 32 ]; then
    warning "DASHBOARD_SESSION_SECRET is less than 32 characters (weak)"
  else
    success "DASHBOARD_SESSION_SECRET is set (${#DASHBOARD_SESSION_SECRET} chars)"
  fi
fi

# Check JWT_SECRET
if [ -z "$JWT_SECRET" ]; then
  error "JWT_SECRET not set"
else
  if [ ${#JWT_SECRET} -lt 32 ]; then
    warning "JWT_SECRET is less than 32 characters (weak)"
  else
    success "JWT_SECRET is set (${#JWT_SECRET} chars)"
  fi
fi

# Check MFA_ENCRYPTION_KEY (optional but recommended)
if [ -z "$MFA_ENCRYPTION_KEY" ]; then
  warning "MFA_ENCRYPTION_KEY not set (TOTP secrets will not be encrypted)"
else
  if [ ${#MFA_ENCRYPTION_KEY} -lt 32 ]; then
    warning "MFA_ENCRYPTION_KEY is less than 32 characters (weak)"
  else
    success "MFA_ENCRYPTION_KEY is set (${#MFA_ENCRYPTION_KEY} chars)"
  fi
fi

# Check NODE_ENV
if [ "$NODE_ENV" != "production" ]; then
  warning "NODE_ENV is not set to 'production' (current: ${NODE_ENV:-not set})"
else
  success "NODE_ENV is set to production"
fi

echo ""
echo "=== Step 2: Redis Connection ==="
echo ""

# Check if Redis is running
if command -v redis-cli &> /dev/null; then
  if redis-cli ping &> /dev/null; then
    success "Redis is running and responding to PING"

    # Check Redis version
    REDIS_VERSION=$(redis-cli INFO server | grep redis_version | cut -d: -f2 | tr -d '\r')
    info "Redis version: $REDIS_VERSION"

    # Check Redis memory usage
    REDIS_MEMORY=$(redis-cli INFO memory | grep used_memory_human | cut -d: -f2 | tr -d '\r')
    info "Redis memory usage: $REDIS_MEMORY"
  else
    error "Redis is installed but not responding"
  fi
else
  error "redis-cli command not found (Redis may not be installed)"
fi

echo ""
echo "=== Step 3: File Structure ==="
echo ""

# Check MFA API files
MFA_FILES=(
  "admin-web/pages/api/auth/mfa/enroll.ts"
  "admin-web/pages/api/auth/mfa/verify.ts"
  "admin-web/pages/api/auth/mfa/complete-enrollment.ts"
  "admin-web/pages/api/auth/mfa/status.ts"
  "admin-web/pages/api/auth/mfa/disable.ts"
  "admin-web/pages/api/auth/mfa/recovery-codes.ts"
  "admin-web/pages/api/auth/mfa/regenerate-secret.ts"
  "admin-web/pages/api/auth/mfa/enforcement-status.ts"
  "admin-web/pages/api/auth/mfa/devices/list.ts"
  "admin-web/pages/api/auth/mfa/devices/revoke.ts"
  "admin-web/pages/api/admin/mfa/reset.ts"
  "admin-web/pages/api/admin/mfa/approve-reset.ts"
)

for file in "${MFA_FILES[@]}"; do
  if [ -f "$file" ]; then
    success "$file exists"
  else
    error "$file missing"
  fi
done

# Check MFA components
MFA_COMPONENTS=(
  "admin-web/components/MFAEnrollmentModal.tsx"
  "admin-web/components/MFAVerificationModal.tsx"
  "admin-web/components/MFASettings.tsx"
  "admin-web/components/MFAEnforcementBanner.tsx"
  "admin-web/components/AdminMFAReset.tsx"
)

for file in "${MFA_COMPONENTS[@]}"; do
  if [ -f "$file" ]; then
    success "$file exists"
  else
    error "$file missing"
  fi
done

# Check MFA utilities
MFA_UTILS=(
  "shared-utils/mfa-core.ts"
  "shared-utils/mfa-database.ts"
  "shared-utils/mfa-device-trust.ts"
  "admin-web/lib/server/mfa-enforcement.ts"
  "admin-web/hooks/useMFAStatus.ts"
)

for file in "${MFA_UTILS[@]}"; do
  if [ -f "$file" ]; then
    success "$file exists"
  else
    error "$file missing"
  fi
done

# Check MFA policy
if [ -f "admin-web/config/mfa-policy.json" ]; then
  success "MFA policy configuration exists"

  # Validate JSON
  if command -v jq &> /dev/null; then
    if jq empty admin-web/config/mfa-policy.json 2>/dev/null; then
      success "MFA policy is valid JSON"
    else
      error "MFA policy has invalid JSON syntax"
    fi
  fi
else
  error "MFA policy configuration missing"
fi

echo ""
echo "=== Step 4: Dependencies ==="
echo ""

# Check if admin-web has required dependencies
if [ -f "admin-web/package.json" ]; then
  success "admin-web/package.json exists"

  # Check for required MFA dependencies
  REQUIRED_DEPS=("qrcode" "otplib" "bcrypt" "jose" "crypto")

  for dep in "${REQUIRED_DEPS[@]}"; do
    if grep -q "\"$dep\"" admin-web/package.json; then
      success "Dependency '$dep' found in package.json"
    else
      warning "Dependency '$dep' not found in package.json"
    fi
  done
else
  error "admin-web/package.json missing"
fi

echo ""
echo "=== Step 5: Build Status ==="
echo ""

# Check if admin-web has been built
if [ -d "admin-web/.next" ]; then
  success "admin-web has been built (.next directory exists)"

  # Check build age
  BUILD_AGE=$(find admin-web/.next -name "BUILD_ID" -mtime +1 2>/dev/null | wc -l)
  if [ "$BUILD_AGE" -gt 0 ]; then
    warning "Build is older than 1 day (consider rebuilding)"
  fi
else
  warning "admin-web has not been built yet (.next directory missing)"
fi

echo ""
echo "=== Step 6: API Endpoint Accessibility ==="
echo ""

# Check if service is running on expected port
PORT=${PORT:-3000}
BASE_URL="http://localhost:$PORT"

if curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/api/auth/mfa/status" | grep -q "401"; then
  success "MFA status endpoint is accessible (returns 401 without auth as expected)"
elif curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/api/auth/mfa/status" | grep -q "000"; then
  warning "Service does not appear to be running on port $PORT"
else
  info "MFA status endpoint returned unexpected status code"
fi

echo ""
echo "=== Step 7: TypeScript Compilation ==="
echo ""

# Check TypeScript compilation
if [ -f "admin-web/tsconfig.json" ]; then
  cd admin-web
  if npx tsc --noEmit --skipLibCheck 2>&1 | grep -q "error TS"; then
    error "TypeScript compilation has errors"
  else
    success "TypeScript compilation successful"
  fi
  cd ..
else
  warning "admin-web/tsconfig.json not found"
fi

echo ""
echo "=== Step 8: Documentation ==="
echo ""

# Check for deployment documentation
if [ -f "docs/MFA_DEPLOYMENT_GUIDE.md" ]; then
  success "MFA deployment guide exists"
else
  warning "MFA deployment guide missing"
fi

# Check for phase completion reports
PHASE_REPORTS=(
  "coordination/work_bridge/results/HIGH-005-PHASE-1-COMPLETE-D04.md"
  "coordination/work_bridge/results/HIGH-005-PHASE-8-COMPLETE-D04.md"
)

for report in "${PHASE_REPORTS[@]}"; do
  if [ -f "$report" ]; then
    success "$(basename $report) exists"
  else
    warning "$(basename $report) missing"
  fi
done

echo ""
echo "=============================================="
echo "Verification Summary"
echo "=============================================="
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
  echo -e "${GREEN}✅ All checks passed!${NC}"
  echo ""
  echo "Your MFA system is ready for deployment."
  exit 0
elif [ $ERRORS -eq 0 ]; then
  echo -e "${YELLOW}⚠️  $WARNINGS warning(s) found${NC}"
  echo ""
  echo "Your MFA system can be deployed, but review warnings above."
  exit 0
else
  echo -e "${RED}❌ $ERRORS error(s) and $WARNINGS warning(s) found${NC}"
  echo ""
  echo "Please fix errors before deploying."
  exit 1
fi
