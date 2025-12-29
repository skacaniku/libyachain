#!/bin/bash
# Quick AWS Deployment Script for LibyaChain
# This script automates the complete AWS ECS deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}╔═══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  LibyaChain AWS Deployment Automation    ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════╝${NC}"
echo ""

# Check prerequisites
command -v aws >/dev/null 2>&1 || { echo -e "${RED}AWS CLI not found. Please install it first.${NC}" >&2; exit 1; }
command -v docker >/dev/null 2>&1 || { echo -e "${RED}Docker not found. Please install it first.${NC}" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo -e "${RED}jq not found. Please install it first.${NC}" >&2; exit 1; }

# Configuration
AWS_REGION="${AWS_REGION:-us-east-1}"
DOMAIN="${DOMAIN:-libyachain.net}"
CLUSTER_NAME="libyachain-cluster"

echo -e "${YELLOW}Configuration:${NC}"
echo "  AWS Region: $AWS_REGION"
echo "  Domain: $DOMAIN"
echo ""

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo -e "${GREEN}✓${NC} AWS Account ID: $AWS_ACCOUNT_ID"

# Create resources file
RESOURCES_FILE="aws-resources.env"
touch $RESOURCES_FILE

# Function to save resource ID
save_resource() {
    local key=$1
    local value=$2
    echo "$key=$value" >> $RESOURCES_FILE
    echo -e "${GREEN}✓${NC} Saved: $key=$value"
}

# Function to load resources
load_resources() {
    if [ -f "$RESOURCES_FILE" ]; then
        source $RESOURCES_FILE
    fi
}

# Step 1: Build and Push Docker Images
echo ""
echo -e "${YELLOW}Step 1: Building and pushing Docker images to ECR...${NC}"
echo "This will take 10-15 minutes..."

ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# Login to ECR
echo "Logging in to ECR..."
aws ecr get-login-password --region $AWS_REGION | \
    docker login --username AWS --password-stdin $ECR_REGISTRY

# Create repositories
services=("libyachain-node" "admin-web" "explorer-web" "faucet-web" "landing-web" "docs-web" "swap-web" "explorer-api" "callisto")

for service in "${services[@]}"; do
    echo "Creating ECR repository: $service"
    aws ecr create-repository \
        --repository-name libyachain/$service \
        --region $AWS_REGION \
        --image-scanning-configuration scanOnPush=true \
        2>/dev/null || echo "  Repository already exists"
done

# Build and push images
echo "Building libyachain-node..."
docker build -t libyachain-node -f docker/Dockerfile.node .
docker tag libyachain-node:latest $ECR_REGISTRY/libyachain/libyachain-node:latest
docker push $ECR_REGISTRY/libyachain/libyachain-node:latest

for service in admin-web explorer-web faucet-web landing-web docs-web swap-web; do
    if [ -d "$service" ]; then
        echo "Building $service..."
        cd $service
        docker build -t $service .
        docker tag $service:latest $ECR_REGISTRY/libyachain/$service:latest
        docker push $ECR_REGISTRY/libyachain/$service:latest
        cd ..
    fi
done

if [ -d "explorer-api" ]; then
    echo "Building explorer-api..."
    cd explorer-api
    docker build -t explorer-api .
    docker tag explorer-api:latest $ECR_REGISTRY/libyachain/explorer-api:latest
    docker push $ECR_REGISTRY/libyachain/explorer-api:latest
    cd ..
fi

echo -e "${GREEN}✓${NC} All images pushed to ECR"

# Step 2: Create VPC and Networking
echo ""
echo -e "${YELLOW}Step 2: Creating VPC and networking...${NC}"

VPC_ID=$(aws ec2 create-vpc \
    --cidr-block 10.0.0.0/16 \
    --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=libyachain-vpc}]' \
    --query 'Vpc.VpcId' \
    --output text)
save_resource "VPC_ID" "$VPC_ID"

aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-support

# Create Internet Gateway
IGW_ID=$(aws ec2 create-internet-gateway \
    --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=libyachain-igw}]' \
    --query 'InternetGateway.InternetGatewayId' \
    --output text)
save_resource "IGW_ID" "$IGW_ID"

aws ec2 attach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $IGW_ID

# Create subnets
SUBNET_PUB_1=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block 10.0.1.0/24 \
    --availability-zone ${AWS_REGION}a \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=libyachain-public-1}]' \
    --query 'Subnet.SubnetId' \
    --output text)
save_resource "SUBNET_PUB_1" "$SUBNET_PUB_1"

SUBNET_PUB_2=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block 10.0.2.0/24 \
    --availability-zone ${AWS_REGION}b \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=libyachain-public-2}]' \
    --query 'Subnet.SubnetId' \
    --output text)
save_resource "SUBNET_PUB_2" "$SUBNET_PUB_2"

SUBNET_PRIV_1=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block 10.0.10.0/24 \
    --availability-zone ${AWS_REGION}a \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=libyachain-private-1}]' \
    --query 'Subnet.SubnetId' \
    --output text)
save_resource "SUBNET_PRIV_1" "$SUBNET_PRIV_1"

SUBNET_PRIV_2=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block 10.0.11.0/24 \
    --availability-zone ${AWS_REGION}b \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=libyachain-private-2}]' \
    --query 'Subnet.SubnetId' \
    --output text)
save_resource "SUBNET_PRIV_2" "$SUBNET_PRIV_2"

# Create route tables
RTB_ID=$(aws ec2 create-route-table \
    --vpc-id $VPC_ID \
    --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=libyachain-public-rtb}]' \
    --query 'RouteTable.RouteTableId' \
    --output text)
save_resource "RTB_ID" "$RTB_ID"

aws ec2 create-route --route-table-id $RTB_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID
aws ec2 associate-route-table --subnet-id $SUBNET_PUB_1 --route-table-id $RTB_ID
aws ec2 associate-route-table --subnet-id $SUBNET_PUB_2 --route-table-id $RTB_ID

echo -e "${GREEN}✓${NC} VPC and networking created"

# Step 3: Create RDS Database
echo ""
echo -e "${YELLOW}Step 3: Creating RDS PostgreSQL database...${NC}"
echo "This will take 5-10 minutes..."

# Create DB subnet group
aws rds create-db-subnet-group \
    --db-subnet-group-name libyachain-db-subnet \
    --db-subnet-group-description "LibyaChain database subnet group" \
    --subnet-ids $SUBNET_PRIV_1 $SUBNET_PRIV_2 \
    2>/dev/null || echo "  Subnet group already exists"

# Create security group for RDS
SG_RDS=$(aws ec2 create-security-group \
    --group-name libyachain-rds-sg \
    --description "Security group for LibyaChain RDS" \
    --vpc-id $VPC_ID \
    --query 'GroupId' \
    --output text 2>/dev/null || \
    aws ec2 describe-security-groups --filters "Name=group-name,Values=libyachain-rds-sg" --query 'SecurityGroups[0].GroupId' --output text)
save_resource "SG_RDS" "$SG_RDS"

aws ec2 authorize-security-group-ingress \
    --group-id $SG_RDS \
    --protocol tcp \
    --port 5432 \
    --cidr 10.0.0.0/16 \
    2>/dev/null || echo "  Ingress rule already exists"

# Generate password
DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
save_resource "DB_PASSWORD" "$DB_PASSWORD"

# Create RDS instance
aws rds create-db-instance \
    --db-instance-identifier libyachain-db \
    --db-instance-class db.t3.medium \
    --engine postgres \
    --engine-version 15.4 \
    --master-username bdjuno \
    --master-user-password "$DB_PASSWORD" \
    --allocated-storage 100 \
    --storage-type gp3 \
    --db-subnet-group-name libyachain-db-subnet \
    --vpc-security-group-ids $SG_RDS \
    --backup-retention-period 7 \
    --no-multi-az \
    --storage-encrypted \
    2>/dev/null || echo "  Database already exists"

echo "Waiting for database to be available..."
aws rds wait db-instance-available --db-instance-identifier libyachain-db

DB_ENDPOINT=$(aws rds describe-db-instances \
    --db-instance-identifier libyachain-db \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text)
save_resource "DB_ENDPOINT" "$DB_ENDPOINT"

echo -e "${GREEN}✓${NC} RDS PostgreSQL created: $DB_ENDPOINT"

# Step 4: Create ECS Cluster
echo ""
echo -e "${YELLOW}Step 4: Creating ECS cluster...${NC}"

aws ecs create-cluster \
    --cluster-name $CLUSTER_NAME \
    --tags key=Name,value=$CLUSTER_NAME \
    2>/dev/null || echo "  Cluster already exists"

# Create CloudWatch log group
aws logs create-log-group --log-group-name /ecs/libyachain 2>/dev/null || echo "  Log group already exists"

# Create task execution role
cat > /tmp/task-execution-role-trust-policy.json <<'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

aws iam create-role \
    --role-name ecsTaskExecutionRole \
    --assume-role-policy-document file:///tmp/task-execution-role-trust-policy.json \
    2>/dev/null || echo "  Role already exists"

aws iam attach-role-policy \
    --role-name ecsTaskExecutionRole \
    --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy \
    2>/dev/null || echo "  Policy already attached"

# Create security group for ECS
SG_ECS=$(aws ec2 create-security-group \
    --group-name libyachain-ecs-sg \
    --description "Security group for LibyaChain ECS tasks" \
    --vpc-id $VPC_ID \
    --query 'GroupId' \
    --output text 2>/dev/null || \
    aws ec2 describe-security-groups --filters "Name=group-name,Values=libyachain-ecs-sg" --query 'SecurityGroups[0].GroupId' --output text)
save_resource "SG_ECS" "$SG_ECS"

aws ec2 authorize-security-group-ingress --group-id $SG_ECS --protocol tcp --port 3000-4010 --cidr 0.0.0.0/0 2>/dev/null || true
aws ec2 authorize-security-group-ingress --group-id $SG_ECS --protocol tcp --port 26657 --cidr 0.0.0.0/0 2>/dev/null || true
aws ec2 authorize-security-group-ingress --group-id $SG_ECS --protocol tcp --port 8080 --cidr 0.0.0.0/0 2>/dev/null || true

echo -e "${GREEN}✓${NC} ECS cluster created"

# Summary
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  AWS Infrastructure Setup Complete!      ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════╝${NC}"
echo ""
echo "Resources created:"
echo "  - VPC: $VPC_ID"
echo "  - RDS Endpoint: $DB_ENDPOINT"
echo "  - ECS Cluster: $CLUSTER_NAME"
echo ""
echo "All resource IDs saved to: $RESOURCES_FILE"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Review the AWS-DEPLOYMENT-GUIDE.md for complete instructions"
echo "  2. Create Application Load Balancer and Target Groups"
echo "  3. Register ECS task definitions"
echo "  4. Deploy ECS services"
echo "  5. Configure Route53 DNS records"
echo "  6. Setup SSL certificates with ACM"
echo ""
echo -e "${GREEN}Deployment automation complete!${NC}"
