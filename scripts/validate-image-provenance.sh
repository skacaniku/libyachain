#!/bin/bash
# Validate OCI image provenance labels on built Docker images
#
# Usage: ./scripts/validate-image-provenance.sh [service-name]
#
# Examples:
#   ./scripts/validate-image-provenance.sh                  # Check all services
#   ./scripts/validate-image-provenance.sh explorer-api     # Check specific service

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Services to check (from docker-compose.yml)
SERVICES=(
    "explorer-api"
    "explorer-web"
    "admin-web"
    "landing-web"
    "docs-web"
    "faucet-web"
    "swap-web"
    "dpwac-public-web"
    "dpwac-admin-web"
    "callisto"
)

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo -e "${RED}✗ Docker is not running${NC}"
    exit 1
fi

# Function to check a single service
check_service() {
    local service=$1
    local image_name="libyachain-${service}"

    # Try different image name patterns
    local image=""
    if docker image inspect "${image_name}:latest" >/dev/null 2>&1; then
        image="${image_name}:latest"
    elif docker image inspect "${service}:latest" >/dev/null 2>&1; then
        image="${service}:latest"
    elif docker image inspect "libyachain_${service}:latest" >/dev/null 2>&1; then
        image="libyachain_${service}:latest"
    fi

    if [ -z "$image" ]; then
        echo -e "${YELLOW}⊘ ${service}: image not found${NC}"
        return 1
    fi

    # Get the revision label
    local revision
    revision=$(docker inspect "$image" 2>/dev/null | \
        jq -r '.[0].Config.Labels."org.opencontainers.image.revision" // "NOT_SET"')

    if [ "$revision" = "NOT_SET" ]; then
        echo -e "${RED}✗ ${service}: label missing${NC}"
        return 1
    elif [ "$revision" = "unknown" ]; then
        echo -e "${YELLOW}⚠ ${service}: $revision (no VCS_REF during build)${NC}"
        return 2
    else
        echo -e "${GREEN}✓ ${service}: ${revision:0:12}${NC}"
        return 0
    fi
}

# Main execution
echo "=== Container Image Provenance Validation ==="
echo ""

CHECKED=0
PASSED=0
WARNED=0
FAILED=0
NOTFOUND=0

if [ -n "$1" ]; then
    # Check specific service
    SERVICES=("$1")
fi

for service in "${SERVICES[@]}"; do
    CHECKED=$((CHECKED + 1))
    if check_service "$service"; then
        PASSED=$((PASSED + 1))
    else
        status=$?
        if [ $status -eq 2 ]; then
            WARNED=$((WARNED + 1))
        elif [ $status -eq 1 ]; then
            NOTFOUND=$((NOTFOUND + 1))
        else
            FAILED=$((FAILED + 1))
        fi
    fi
done

echo ""
echo "=== Summary ==="
echo "Checked: $CHECKED"
echo -e "${GREEN}Passed: $PASSED${NC}"
if [ $WARNED -gt 0 ]; then
    echo -e "${YELLOW}Warned: $WARNED (built without VCS_REF)${NC}"
fi
if [ $NOTFOUND -gt 0 ]; then
    echo -e "${YELLOW}Not Found: $NOTFOUND (images not built)${NC}"
fi
if [ $FAILED -gt 0 ]; then
    echo -e "${RED}Failed: $FAILED (label missing)${NC}"
fi

echo ""
echo "To rebuild with provenance labels:"
echo "  export VCS_REF=\"\$(git rev-parse HEAD)\""
echo "  docker-compose build [service-name]"
echo ""
echo "To inspect labels manually:"
echo "  docker inspect <image> | jq '.[0].Config.Labels'"

# Exit with error if any checks failed (excluding not found and warnings)
if [ $FAILED -gt 0 ]; then
    exit 1
fi

exit 0
