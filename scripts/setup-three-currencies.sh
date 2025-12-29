#!/bin/bash
# Setup three-currency ecosystem for LibyaChain
# This script configures LYDC, LYDD, and UCBL in genesis

set -e

HOME_DIR=${1:-~/.libyachain}
CHAIN_ID=${2:-libyachain-1}

echo "Setting up three-currency ecosystem in $HOME_DIR"

# Ensure jq is available
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed"
    exit 1
fi

GENESIS_FILE="$HOME_DIR/config/genesis.json"

if [ ! -f "$GENESIS_FILE" ]; then
    echo "Error: Genesis file not found at $GENESIS_FILE"
    echo "Please run 'libyachaind init' first"
    exit 1
fi

echo "Configuring denom metadata for three currencies..."

# Create temporary file
TMP_GENESIS=$(mktemp)

# Add denom metadata for all three currencies
jq '.app_state.bank.denom_metadata = [
  {
    "description": "Libyan Digital Currency - The base cryptocurrency of Libya, backed by oil, gas, and compute resources",
    "denom_units": [
      {
        "denom": "ulydc",
        "exponent": 0,
        "aliases": ["microlydc"]
      },
      {
        "denom": "mlydc",
        "exponent": 3,
        "aliases": ["millilydc"]
      },
      {
        "denom": "lydc",
        "exponent": 6,
        "aliases": []
      }
    ],
    "base": "ulydc",
    "display": "lydc",
    "name": "Libyan Digital Currency",
    "symbol": "LYDC",
    "uri": "",
    "uri_hash": ""
  },
  {
    "description": "Libyan Digital Dinar - CBDC stablecoin for general use, pegged to Libyan Dinar",
    "denom_units": [
      {
        "denom": "ulydd",
        "exponent": 0,
        "aliases": ["microlydd"]
      },
      {
        "denom": "mlydd",
        "exponent": 3,
        "aliases": ["millilydd"]
      },
      {
        "denom": "lydd",
        "exponent": 6,
        "aliases": []
      }
    ],
    "base": "ulydd",
    "display": "lydd",
    "name": "Libyan Digital Dinar",
    "symbol": "LYDD",
    "uri": "",
    "uri_hash": ""
  },
  {
    "description": "Central Bank of Libya CBDC - For banking sector and institutional use",
    "denom_units": [
      {
        "denom": "uucbl",
        "exponent": 0,
        "aliases": ["microucbl"]
      },
      {
        "denom": "mucbl",
        "exponent": 3,
        "aliases": ["milliucbl"]
      },
      {
        "denom": "ucbl",
        "exponent": 6,
        "aliases": []
      }
    ],
    "base": "uucbl",
    "display": "ucbl",
    "name": "Central Bank of Libya CBDC",
    "symbol": "UCBL",
    "uri": "",
    "uri_hash": ""
  }
]' "$GENESIS_FILE" > "$TMP_GENESIS"

# Move temp file to genesis
mv "$TMP_GENESIS" "$GENESIS_FILE"

echo "✅ Denom metadata configured for LYDC, LYDD, and UCBL"

# Set initial balances for testing (optional)
if [ -n "$3" ]; then
    TEST_ADDRESS="$3"
    echo "Adding test balances for address: $TEST_ADDRESS"

    TMP_GENESIS=$(mktemp)
    jq --arg addr "$TEST_ADDRESS" '.app_state.bank.balances += [
      {
        "address": $addr,
        "coins": [
          {"denom": "ulydc", "amount": "1000000000000"},
          {"denom": "ulydd", "amount": "1000000000000"},
          {"denom": "uucbl", "amount": "1000000000000"}
        ]
      }
    ]' "$GENESIS_FILE" > "$TMP_GENESIS"

    mv "$TMP_GENESIS" "$GENESIS_FILE"
    echo "✅ Test balances added"
fi

echo ""
echo "Three-currency ecosystem setup complete!"
echo ""
echo "Currencies configured:"
echo "  - LYDC (ulydc): Base cryptocurrency, backed by assets"
echo "  - LYDD (ulydd): CBDC stablecoin for general use"
echo "  - UCBL (uucbl): Central Bank CBDC for banking sector"
echo ""
echo "Next steps:"
echo "  1. Create liquidity pools between currencies using lydex module"
echo "  2. Set up conversion rates and policies"
echo "  3. Configure admin permissions for each currency"
