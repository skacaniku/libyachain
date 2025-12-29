#!/bin/bash
# Initialize liquidity pools for three-currency conversion
# Creates pools: LYDC/LYDD, LYDC/UCBL, LYDD/UCBL

set -e

CHAIN_ID=${1:-libyachain-1}
NODE=${2:-tcp://localhost:26657}
ADMIN_KEY=${3:-admin}
HOME_DIR=${4:-~/.libyachain}

echo "Initializing currency conversion pools on chain: $CHAIN_ID"
echo "Using node: $NODE"
echo "Admin key: $ADMIN_KEY"
echo ""

# Check if libyachaind is available
if ! command -v libyachaind &> /dev/null; then
    echo "Error: libyachaind not found in PATH"
    exit 1
fi

# Pool 1: LYDC/LYDD
echo "Creating LYDC/LYDD liquidity pool..."
libyachaind tx lydex create-pool \
    ulydc \
    ulydd \
    --from "$ADMIN_KEY" \
    --chain-id "$CHAIN_ID" \
    --node "$NODE" \
    --home "$HOME_DIR" \
    --fees 5000ulydc \
    --yes \
    2>&1 | grep -i "txhash\|code" || echo "Pool creation submitted"

sleep 6

# Pool 2: LYDC/UCBL
echo "Creating LYDC/UCBL liquidity pool..."
libyachaind tx lydex create-pool \
    ulydc \
    uucbl \
    --from "$ADMIN_KEY" \
    --chain-id "$CHAIN_ID" \
    --node "$NODE" \
    --home "$HOME_DIR" \
    --fees 5000ulydc \
    --yes \
    2>&1 | grep -i "txhash\|code" || echo "Pool creation submitted"

sleep 6

# Pool 3: LYDD/UCBL
echo "Creating LYDD/UCBL liquidity pool..."
libyachaind tx lydex create-pool \
    ulydd \
    uucbl \
    --from "$ADMIN_KEY" \
    --chain-id "$CHAIN_ID" \
    --node "$NODE" \
    --home "$HOME_DIR" \
    --fees 5000ulydc \
    --yes \
    2>&1 | grep -i "txhash\|code" || echo "Pool creation submitted"

sleep 6

echo ""
echo "✅ Currency conversion pools initialized!"
echo ""
echo "Available pools:"
echo "  1. LYDC/LYDD - Base currency to stablecoin"
echo "  2. LYDC/UCBL - Base currency to central bank CBDC"
echo "  3. LYDD/UCBL - Stablecoin to central bank CBDC"
echo ""
echo "Next steps:"
echo "  1. Add initial liquidity: libyachaind tx lydex add-liquidity <pool-id> <amount-a> <amount-b>"
echo "  2. Test swaps: libyachaind tx lydex swap <pool-id> <token-in> <amount-in> <min-out>"
echo "  3. Query pools: libyachaind q lydex pools"
