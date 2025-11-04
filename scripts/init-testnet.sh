#!/bin/bash

# LibyaChain Local Development Setup Script
# This script sets up a single-node testnet for development

set -e

CHAIN_ID="libyachain-testnet-1"
MONIKER="libya-validator"
KEY_NAME="validator"
KEYRING_BACKEND="test"
HOMEDIR="$HOME/.libyachaind"

echo "🔧 Setting up LibyaChain development environment..."

# Remove existing data
echo "📁 Cleaning up old data..."
rm -rf "$HOMEDIR"

# Initialize chain
echo "🌍 Initializing chain..."
libyachaind init "$MONIKER" --chain-id "$CHAIN_ID" --home "$HOMEDIR"

# Create a key for the validator
echo "🔑 Creating validator key..."
libyachaind keys add "$KEY_NAME" --keyring-backend "$KEYRING_BACKEND" --home "$HOMEDIR" 2>&1 | tee validator-key.txt

# Get the address
VALIDATOR_ADDR=$(libyachaind keys show "$KEY_NAME" -a --keyring-backend "$KEYRING_BACKEND" --home "$HOMEDIR")
echo "✅ Validator address: $VALIDATOR_ADDR"

# Add genesis account with all three currencies
echo "💰 Adding genesis account with three currencies..."
libyachaind add-genesis-account "$VALIDATOR_ADDR" \
    100000000000ulydd,100000000000ulydc,100000000000uucbl \
    --keyring-backend "$KEYRING_BACKEND" \
    --home "$HOMEDIR"

# Create genesis transaction
echo "📝 Creating genesis transaction..."
libyachaind gentx "$KEY_NAME" \
    1000000000ulydd \
    --chain-id "$CHAIN_ID" \
    --keyring-backend "$KEYRING_BACKEND" \
    --home "$HOMEDIR"

# Collect genesis transactions
echo "📦 Collecting genesis transactions..."
libyachaind collect-gentxs --home "$HOMEDIR"

# Validate genesis file
echo "✓ Validating genesis file..."
libyachaind validate-genesis --home "$HOMEDIR"

# Update config for development
echo "⚙️  Updating configuration..."
CONFIG_FILE="$HOMEDIR/config/config.toml"
APP_CONFIG_FILE="$HOMEDIR/config/app.toml"

# Enable API server
sed -i 's/enable = false/enable = true/g' "$APP_CONFIG_FILE"
sed -i 's/swagger = false/swagger = true/g' "$APP_CONFIG_FILE"

# Set minimum gas prices for all three currencies
sed -i 's/minimum-gas-prices = ""/minimum-gas-prices = "0.001ulydd,0.001ulydc,0.001uucbl"/g' "$APP_CONFIG_FILE"

# Enable unsafe CORS for development
sed -i 's/enabled-unsafe-cors = false/enabled-unsafe-cors = true/g' "$APP_CONFIG_FILE"

# Reduce block time for development
sed -i 's/timeout_commit = "5s"/timeout_commit = "1s"/g' "$CONFIG_FILE"

echo "
✅ LibyaChain development environment ready!

📋 Configuration:
   Chain ID: $CHAIN_ID
   Home Dir: $HOMEDIR
   Validator: $VALIDATOR_ADDR

💰 Initial Balances:
   LYDD (ulydd): 100,000,000,000
   LYDC (ulydc): 100,000,000,000
   UCBL (uucbl): 100,000,000,000

🚀 Start the chain with:
   libyachaind start --home $HOMEDIR

🔍 Query balances:
   libyachaind query bank balances $VALIDATOR_ADDR

📡 API Server: http://localhost:1317
🌐 RPC Server: http://localhost:26657
🔌 gRPC Server: localhost:9090

⚠️  Validator key saved to: validator-key.txt
    Keep this file safe - it contains your mnemonic!
"
