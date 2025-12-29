#!/bin/bash
# Push all LibyaChain Docker images to AWS ECR
# This script pushes existing Docker images to ECR

set -e

export AWS_REGION="eu-north-1"
export AWS_ACCOUNT_ID="251986419274"
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

echo "══════════════════════════════════════════════════"
echo "Pushing All LibyaChain Images to ECR"
echo "══════════════════════════════════════════════════"
echo "Registry: $ECR_REGISTRY"
echo ""

# List of services
services=(
  "admin-web"
  "explorer-web"
  "faucet-web"
  "landing-web"
  "docs-web"
  "swap-web"
  "explorer-api"
  "callisto"
  "dpwac-public-web"
  "dpwac-admin-web"
)

total=${#services[@]}
current=0

for service in "${services[@]}"; do
  current=$((current+1))
  echo "[$current/$total] 📦 Processing $service..."

  local_image="libyachain-$service:latest"
  ecr_image="$ECR_REGISTRY/libyachain/$service:latest"

  # Check if local image exists
  if docker image inspect $local_image >/dev/null 2>&1; then
    echo "  Tagging..."
    docker tag $local_image $ecr_image

    echo "  Pushing..."
    docker push $ecr_image

    echo "  ✅ $service pushed successfully"
  else
    echo "  ⚠️  Local image not found, skipping..."
  fi

  echo ""
done

echo "══════════════════════════════════════════════════"
echo "✅ Image push complete!"
echo "══════════════════════════════════════════════════"
echo ""
echo "Verify images in ECR:"
echo "aws ecr list-images --repository-name libyachain/admin-web --region $AWS_REGION"
