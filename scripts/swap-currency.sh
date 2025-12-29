#!/bin/bash
# Utility script for swapping between LYDC, LYDD, and UCBL currencies

set -e

CHAIN_ID=${1:-libyachain-1}
NODE=${2:-tcp://localhost:26657}
FROM_KEY=${3:-user}
FROM_CURRENCY=${4}
TO_CURRENCY=${5}
AMOUNT=${6}
HOME_DIR=${7:-~/.libyachain}

if [ -z "$FROM_CURRENCY" ] || [ -z "$TO_CURRENCY" ] || [ -z "$AMOUNT" ]; then
    echo "Usage: $0 <chain-id> <node> <from-key> <from-currency> <to-currency> <amount> [home-dir]"
    echo ""
    echo "Currencies: lydc, lydd, ucbl"
    echo ""
    echo "Example: $0 libyachain-1 tcp://localhost:26657 alice lydc lydd 1000000"
    echo "  (Swaps 1 LYDC to LYDD)"
    exit 1
fi

# Map display denoms to base denoms
case "$FROM_CURRENCY" in
    lydc|LYDC) FROM_DENOM="ulydc" ;;
    lydd|LYDD) FROM_DENOM="ulydd" ;;
    ucbl|UCBL) FROM_DENOM="uucbl" ;;
    *) echo "Invalid from currency: $FROM_CURRENCY"; exit 1 ;;
esac

case "$TO_CURRENCY" in
    lydc|LYDC) TO_DENOM="ulydc" ;;
    lydd|LYDD) TO_DENOM="ulydd" ;;
    ucbl|UCBL) TO_DENOM="uucbl" ;;
    *) echo "Invalid to currency: $TO_CURRENCY"; exit 1 ;;
esac

if [ "$FROM_DENOM" = "$TO_DENOM" ]; then
    echo "Error: Cannot swap same currency"
    exit 1
fi

# Determine pool ID based on pair
# Pool IDs are deterministic based on denom pair (sorted)
SORTED_A=$(echo -e "$FROM_DENOM\n$TO_DENOM" | sort | head -1)
SORTED_B=$(echo -e "$FROM_DENOM\n$TO_DENOM" | sort | tail -1)

echo "Swapping $AMOUNT $FROM_CURRENCY to $TO_CURRENCY"
echo "Pool pair: $SORTED_A/$SORTED_B"
echo ""

# Query pool to get ID
echo "Finding pool..."
POOL_ID=$(libyachaind q lydex pools \
    --node "$NODE" \
    --chain-id "$CHAIN_ID" \
    --home "$HOME_DIR" \
    --output json 2>/dev/null | \
    jq -r ".pools[] | select(.denom_a == \"$SORTED_A\" and .denom_b == \"$SORTED_B\") | .id" | head -1)

if [ -z "$POOL_ID" ] || [ "$POOL_ID" = "null" ]; then
    echo "Error: No pool found for $FROM_CURRENCY/$TO_CURRENCY"
    echo "Please create the pool first using init-currency-pools.sh"
    exit 1
fi

echo "Using pool ID: $POOL_ID"

# Get quote
echo "Getting quote..."
QUOTE=$(libyachaind q lydex quote \
    "$POOL_ID" \
    "${AMOUNT}${FROM_DENOM}" \
    --node "$NODE" \
    --chain-id "$CHAIN_ID" \
    --home "$HOME_DIR" \
    --output json 2>/dev/null)

AMOUNT_OUT=$(echo "$QUOTE" | jq -r '.amount_out')
echo "Expected output: $AMOUNT_OUT $TO_CURRENCY"

# Calculate minimum with 1% slippage
MIN_OUT=$(echo "$AMOUNT_OUT" | awk '{print int($1 * 0.99)}')

# Execute swap
echo "Executing swap..."
libyachaind tx lydex swap \
    "$POOL_ID" \
    "${AMOUNT}${FROM_DENOM}" \
    "$MIN_OUT" \
    --from "$FROM_KEY" \
    --chain-id "$CHAIN_ID" \
    --node "$NODE" \
    --home "$HOME_DIR" \
    --fees 5000ulydc \
    --yes

echo ""
echo "✅ Swap transaction submitted!"
echo "Check transaction status with: libyachaind q tx <txhash>"
