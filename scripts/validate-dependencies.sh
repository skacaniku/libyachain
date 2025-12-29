#!/bin/bash

# LibyaChain Dependency Validation Script
# Ensures only stable, production-ready versions are used
# Created: 2025-10-15

set -e

echo "🔍 Validating LibyaChain dependencies..."
echo ""

ERRORS=0

# Check for release candidate versions
echo "Checking for release candidate (-rc) versions..."
if grep -E "v[0-9]+\.[0-9]+\.[0-9]+-rc" go.mod; then
  echo "❌ ERROR: Release candidate versions found in go.mod"
  echo "   Policy: Only stable versions allowed (no -rc)"
  echo "   See: DEPENDENCY_POLICY.md"
  ERRORS=$((ERRORS + 1))
else
  echo "✅ No release candidate versions found"
fi
echo ""

# Check for beta versions (with documented exceptions)
echo "Checking for beta versions..."
BETA_EXCEPTIONS="cosmossdk.io/client/v2"
if grep -E "v[0-9]+\.[0-9]+\.[0-9]+-beta" go.mod | grep -v "$BETA_EXCEPTIONS"; then
  echo "❌ ERROR: Beta versions found in go.mod (not in exception list)"
  echo "   Policy: Only stable versions allowed (no -beta)"
  echo "   Exceptions: $BETA_EXCEPTIONS"
  echo "   See: DEPENDENCY_POLICY.md"
  ERRORS=$((ERRORS + 1))
else
  echo "✅ No unauthorized beta versions found"
fi
echo ""

# Check for alpha versions
echo "Checking for alpha versions..."
if grep -E "v[0-9]+\.[0-9]+\.[0-9]+-alpha" go.mod; then
  echo "❌ ERROR: Alpha versions found in go.mod"
  echo "   Policy: Only stable versions allowed (no -alpha)"
  echo "   See: DEPENDENCY_POLICY.md"
  ERRORS=$((ERRORS + 1))
else
  echo "✅ No alpha versions found"
fi
echo ""

# Verify Cosmos SDK version is v0.50.x
echo "Checking Cosmos SDK version..."
if grep "github.com/cosmos/cosmos-sdk v0.50" go.mod > /dev/null; then
  SDK_VERSION=$(grep "github.com/cosmos/cosmos-sdk" go.mod | head -1 | awk '{print $2}')
  echo "✅ Cosmos SDK version: $SDK_VERSION (v0.50.x line - correct)"
elif grep "github.com/cosmos/cosmos-sdk v0.54" go.mod > /dev/null; then
  SDK_VERSION=$(grep "github.com/cosmos/cosmos-sdk" go.mod | head -1 | awk '{print $2}')
  echo "❌ ERROR: Cosmos SDK version: $SDK_VERSION"
  echo "   Policy: Must use v0.50.x (stable) not v0.54.x (RC)"
  echo "   This is likely a RELEASE CANDIDATE version"
  echo "   See: DEPENDENCY_POLICY.md"
  ERRORS=$((ERRORS + 1))
else
  SDK_VERSION=$(grep "github.com/cosmos/cosmos-sdk" go.mod | head -1 | awk '{print $2}' || echo "NOT FOUND")
  echo "⚠️  WARNING: Cosmos SDK version: $SDK_VERSION"
  echo "   Expected: v0.50.x"
  echo "   Please verify this is correct"
  ERRORS=$((ERRORS + 1))
fi
echo ""

# Verify IBC-Go version is v8.x
echo "Checking IBC-Go version..."
if grep "github.com/cosmos/ibc-go/v8" go.mod > /dev/null; then
  IBC_VERSION=$(grep "github.com/cosmos/ibc-go/v8" go.mod | head -1 | awk '{print $2}')
  echo "✅ IBC-Go version: $IBC_VERSION (v8.x - correct)"
else
  echo "⚠️  WARNING: IBC-Go v8 not found in go.mod"
fi
echo ""

# Verify CometBFT version is v0.38.x
echo "Checking CometBFT version..."
if grep "github.com/cometbft/cometbft v0.38" go.mod > /dev/null; then
  COMETBFT_VERSION=$(grep "github.com/cometbft/cometbft v0.38" go.mod | head -1 | awk '{print $2}')
  echo "✅ CometBFT version: $COMETBFT_VERSION (v0.38.x - correct)"
elif grep "github.com/cometbft/cometbft/v2" go.mod > /dev/null; then
  COMETBFT_VERSION=$(grep "github.com/cometbft/cometbft/v2" go.mod | head -1 | awk '{print $2}')
  echo "❌ ERROR: CometBFT version: $COMETBFT_VERSION"
  echo "   Policy: Must use v0.38.x (stable) not v2.x (incompatible with IBC-Go v8)"
  echo "   This causes type incompatibilities and build failures"
  echo "   See: DEPENDENCY_POLICY.md"
  ERRORS=$((ERRORS + 1))
else
  echo "⚠️  WARNING: CometBFT v0.38.x not found in go.mod"
fi
echo ""

# Check for development versions
echo "Checking for development (-dev) versions..."
if grep -E "\-dev\." go.mod; then
  echo "❌ ERROR: Development versions found in go.mod"
  echo "   Policy: Only stable versions allowed (no -dev)"
  ERRORS=$((ERRORS + 1))
else
  echo "✅ No development versions found"
fi
echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $ERRORS -eq 0 ]; then
  echo "✅ All dependencies validated successfully!"
  echo "   All versions are stable and compatible."
  echo "   Build should succeed."
  exit 0
else
  echo "❌ Dependency validation FAILED with $ERRORS error(s)"
  echo ""
  echo "Action Required:"
  echo "1. Review DEPENDENCY_POLICY.md"
  echo "2. Update go.mod to use stable versions"
  echo "3. Run: go mod tidy"
  echo "4. Run: make build"
  echo "5. Run: make test"
  echo ""
  echo "For Cosmos SDK v0.54 -> v0.50.11 downgrade:"
  echo "  See: coordination/EMERGENCY_BUILD_BROKEN.md"
  exit 1
fi
