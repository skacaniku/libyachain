#!/bin/bash
# LibyaChain Local Deployment Script
# This script initializes and starts a local LibyaChain node with all modules configured

set -e

BINARY="./build/libyachaind"
CHAIN_ID="libyachain-1"
NODE_HOME="$HOME/.libyachain"
KEYRING="test"
MASTER_ADMIN_KEY="master-admin"
VALIDATOR_KEY="validator"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

echo_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

echo_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if binary exists
if [ ! -f "$BINARY" ]; then
    echo_error "Binary not found at $BINARY"
    echo_info "Run 'make build' first"
    exit 1
fi

echo_info "Starting LibyaChain local deployment..."
echo_info "Chain ID: $CHAIN_ID"
echo_info "Home Directory: $NODE_HOME"
echo ""

# Ask if user wants to reset
if [ -d "$NODE_HOME" ]; then
    echo_warning "Existing blockchain data found at $NODE_HOME"
    read -p "Do you want to reset and start fresh? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo_info "Removing existing data..."
        rm -rf "$NODE_HOME"
        echo_success "Data removed"
    else
        echo_info "Keeping existing data. Will try to start node..."
        # Try to start existing node
        echo_info "Starting existing node..."
        $BINARY start --home "$NODE_HOME"
        exit 0
    fi
fi

echo ""
echo_info "Step 1: Initializing chain..."
$BINARY init mynode --chain-id "$CHAIN_ID" --home "$NODE_HOME"
echo_success "Chain initialized"

echo ""
echo_info "Step 2: Creating master admin key..."
# Check if key already exists
if $BINARY keys show "$MASTER_ADMIN_KEY" --keyring-backend "$KEYRING" --home "$NODE_HOME" &> /dev/null; then
    echo_warning "Master admin key already exists"
    MASTER_ADMIN_ADDR=$($BINARY keys show "$MASTER_ADMIN_KEY" -a --keyring-backend "$KEYRING" --home "$NODE_HOME")
else
    # Create master admin key
    echo "Creating new master admin key (press enter for default password)..."
    MASTER_ADMIN_ADDR=$($BINARY keys add "$MASTER_ADMIN_KEY" --keyring-backend "$KEYRING" --home "$NODE_HOME" --output json 2>&1 | jq -r '.address')
fi
echo_success "Master admin address: $MASTER_ADMIN_ADDR"

echo ""
echo_info "Step 3: Creating validator key..."
if $BINARY keys show "$VALIDATOR_KEY" --keyring-backend "$KEYRING" --home "$NODE_HOME" &> /dev/null; then
    echo_warning "Validator key already exists"
    VALIDATOR_ADDR=$($BINARY keys show "$VALIDATOR_KEY" -a --keyring-backend "$KEYRING" --home "$NODE_HOME")
else
    echo "Creating new validator key (press enter for default password)..."
    VALIDATOR_ADDR=$($BINARY keys add "$VALIDATOR_KEY" --keyring-backend "$KEYRING" --home "$NODE_HOME" --output json 2>&1 | jq -r '.address')
fi
echo_success "Validator address: $VALIDATOR_ADDR"

echo ""
echo_info "Step 4: Adding genesis accounts..."
# Add master admin with generous balance
$BINARY genesis add-genesis-account "$MASTER_ADMIN_ADDR" 1000000000000ulydc,1000000000000ulydd,1000000000000uucbl --home "$NODE_HOME"
echo_success "Master admin account added"

# Add validator account
$BINARY genesis add-genesis-account "$VALIDATOR_ADDR" 100000000000ulydc,100000000000ulydd --home "$NODE_HOME"
echo_success "Validator account added"

echo ""
echo_info "Step 5: Creating validator genesis transaction..."
$BINARY genesis gentx "$VALIDATOR_KEY" 100000000ulydc \
    --chain-id "$CHAIN_ID" \
    --keyring-backend "$KEYRING" \
    --home "$NODE_HOME"
echo_success "Genesis transaction created"

echo ""
echo_info "Step 6: Collecting genesis transactions..."
$BINARY genesis collect-gentxs --home "$NODE_HOME"
echo_success "Genesis transactions collected"

echo ""
echo_info "Step 7: Validating genesis..."
$BINARY genesis validate-genesis --home "$NODE_HOME"
echo_success "Genesis validated"

echo ""
echo_info "Step 8: Configuring node..."
# Update config.toml
CONFIG_FILE="$NODE_HOME/config/config.toml"
if [ -f "$CONFIG_FILE" ]; then
    # Enable API and set CORS
    sed -i.bak 's/enable = false/enable = true/g' "$NODE_HOME/config/app.toml"
    sed -i.bak 's/enabled-unsafe-cors = false/enabled-unsafe-cors = true/g' "$NODE_HOME/config/app.toml"

    # Set minimum gas prices
    sed -i.bak 's/minimum-gas-prices = ""/minimum-gas-prices = "0.0025ulydc"/g' "$NODE_HOME/config/app.toml"

    echo_success "Node configuration updated"
fi

echo ""
echo_success "============================================"
echo_success "LibyaChain Deployment Complete!"
echo_success "============================================"
echo ""
echo_info "Master Admin Address: $MASTER_ADMIN_ADDR"
echo_info "Validator Address: $VALIDATOR_ADDR"
echo_info "Chain ID: $CHAIN_ID"
echo ""
echo_info "Keys created (keyring: $KEYRING):"
echo_info "  - $MASTER_ADMIN_KEY: $MASTER_ADMIN_ADDR"
echo_info "  - $VALIDATOR_KEY: $VALIDATOR_ADDR"
echo ""
echo_info "Next steps:"
echo_info "1. Start the node:"
echo_info "   $BINARY start --home $NODE_HOME"
echo ""
echo_info "2. Query the node (in another terminal):"
echo_info "   $BINARY status"
echo ""
echo_info "3. Check balances:"
echo_info "   $BINARY query bank balances $MASTER_ADMIN_ADDR"
echo ""
echo_info "4. Create admins (admin module):"
echo_info "   $BINARY tx admin create-admin [address] [role] --from $MASTER_ADMIN_KEY --keyring-backend $KEYRING"
echo ""
echo_info "5. Create DEX pools:"
echo_info "   $BINARY tx lydex create-pool 1000000000ulydc 1000000000ulydd --from $MASTER_ADMIN_KEY --keyring-backend $KEYRING"
echo ""
echo_info "6. Launch tokens:"
echo_info "   $BINARY tx launchpad create-project \"MyToken\" \"MTK\" --base-price 0.1 --from $MASTER_ADMIN_KEY --keyring-backend $KEYRING"
echo ""

# Ask if user wants to start the node
read -p "Do you want to start the node now? (Y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    echo ""
    echo_info "Starting LibyaChain node..."
    echo_info "Press Ctrl+C to stop"
    echo ""
    $BINARY start --home "$NODE_HOME"
else
    echo ""
    echo_info "To start the node later, run:"
    echo_info "  $BINARY start --home $NODE_HOME"
    echo ""
fi
