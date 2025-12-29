#!/bin/bash

# LibyaChain Production Monitoring Script
# Run this script to check the health of the production blockchain

set -e

EC2_HOST="51.20.135.155"
KEY_FILE="$HOME/.ssh/libyachain-key.pem"

echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║              LIBYACHAIN PRODUCTION MONITORING DASHBOARD                      ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo ""

# Function to format numbers with commas
format_number() {
    echo "$1" | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'
}

# Check if EC2 RPC is reachable (skip ping since ICMP may be blocked)
echo "🔍 Checking EC2 RPC connectivity..."
if ! curl -s -f --connect-timeout 5 http://$EC2_HOST:26657/health >/dev/null 2>&1; then
    echo "❌ ERROR: Cannot reach blockchain RPC at $EC2_HOST:26657"
    echo "   Ensure the EC2 instance is running and security groups allow access"
    exit 1
fi
echo "✅ RPC endpoint is reachable"
echo ""

# Get blockchain status
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "BLOCKCHAIN STATUS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

STATUS=$(curl -s http://$EC2_HOST:26657/status 2>/dev/null)

if [ $? -ne 0 ] || [ -z "$STATUS" ]; then
    echo "❌ ERROR: Cannot connect to blockchain RPC endpoint"
    exit 1
fi

CHAIN_ID=$(echo "$STATUS" | jq -r '.result.node_info.network')
BLOCK_HEIGHT=$(echo "$STATUS" | jq -r '.result.sync_info.latest_block_height')
BLOCK_TIME=$(echo "$STATUS" | jq -r '.result.sync_info.latest_block_time')
CATCHING_UP=$(echo "$STATUS" | jq -r '.result.sync_info.catching_up')
VOTING_POWER=$(echo "$STATUS" | jq -r '.result.validator_info.voting_power')
NODE_VERSION=$(echo "$STATUS" | jq -r '.result.node_info.version')

echo "  Chain ID:            $CHAIN_ID"
echo "  Block Height:        $(format_number $BLOCK_HEIGHT)"
echo "  Latest Block Time:   $BLOCK_TIME"
echo "  Catching Up:         $CATCHING_UP"
echo "  Validator Power:     $(format_number $VOTING_POWER)"
echo "  CometBFT Version:    $NODE_VERSION"
echo ""

# Check if catching up
if [ "$CATCHING_UP" = "true" ]; then
    echo "⚠️  WARNING: Node is catching up with the network"
else
    echo "✅ Node is fully synced"
fi
echo ""

# Get validator status
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "VALIDATOR STATUS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

VALIDATORS=$(curl -s http://$EC2_HOST:1317/cosmos/staking/v1beta1/validators 2>/dev/null)
VAL_STATUS=$(echo "$VALIDATORS" | jq -r '.validators[0].status')
VAL_TOKENS=$(echo "$VALIDATORS" | jq -r '.validators[0].tokens')
VAL_JAILED=$(echo "$VALIDATORS" | jq -r '.validators[0].jailed')

echo "  Status:              $VAL_STATUS"
echo "  Staked Tokens:       $(format_number $VAL_TOKENS) ulydc"
echo "  Jailed:              $VAL_JAILED"
echo ""

if [ "$VAL_JAILED" = "true" ]; then
    echo "❌ ERROR: Validator is jailed!"
elif [ "$VAL_STATUS" = "BOND_STATUS_BONDED" ]; then
    echo "✅ Validator is active and bonded"
else
    echo "⚠️  WARNING: Validator status is $VAL_STATUS"
fi
echo ""

# Check EC2 system resources
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "SYSTEM RESOURCES (EC2)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ssh -i $KEY_FILE -o StrictHostKeyChecking=no -o ConnectTimeout=5 ec2-user@$EC2_HOST "
  UPTIME=\$(uptime | awk '{print \$3, \$4}' | sed 's/,//')
  LOAD=\$(uptime | awk -F'load average:' '{print \$2}')
  DISK_USED=\$(df -h / | awk 'NR==2 {print \$3}')
  DISK_AVAIL=\$(df -h / | awk 'NR==2 {print \$4}')
  DISK_PERCENT=\$(df -h / | awk 'NR==2 {print \$5}')
  MEM_USED=\$(free -h | awk 'NR==2 {print \$3}')
  MEM_TOTAL=\$(free -h | awk 'NR==2 {print \$2}')

  echo \"  Uptime:              \$UPTIME\"
  echo \"  Load Average:       \$LOAD\"
  echo \"  Disk Usage:          \$DISK_USED / 100G (\$DISK_PERCENT used, \$DISK_AVAIL available)\"
  echo \"  Memory Usage:        \$MEM_USED / \$MEM_TOTAL\"
"
echo ""

# Check process status
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PROCESS STATUS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

PROCESS_CHECK=$(ssh -i $KEY_FILE -o StrictHostKeyChecking=no ec2-user@$EC2_HOST "ps aux | grep '[l]ibyachaind start'")

if [ -z "$PROCESS_CHECK" ]; then
    echo "❌ ERROR: libyachaind process is not running!"
else
    echo "✅ libyachaind process is running"
    echo ""
    echo "$PROCESS_CHECK" | awk '{printf "  PID:                 %s\n  CPU:                 %s%%\n  Memory:              %s%%\n", $2, $3, $4}'
fi
echo ""

# Check endpoints
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ENDPOINT HEALTH CHECKS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# RPC endpoint
if curl -s -f http://$EC2_HOST:26657/health >/dev/null 2>&1; then
    echo "  ✅ RPC Endpoint:        http://$EC2_HOST:26657 (healthy)"
else
    echo "  ❌ RPC Endpoint:        http://$EC2_HOST:26657 (unhealthy)"
fi

# REST API endpoint
if curl -s -f http://$EC2_HOST:1317/cosmos/base/tendermint/v1beta1/node_info >/dev/null 2>&1; then
    echo "  ✅ REST API:            http://$EC2_HOST:1317 (healthy)"
else
    echo "  ❌ REST API:            http://$EC2_HOST:1317 (unhealthy)"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "RECENT ACTIVITY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Calculate blocks per minute
sleep 6
NEW_STATUS=$(curl -s http://$EC2_HOST:26657/status 2>/dev/null)
NEW_BLOCK_HEIGHT=$(echo "$NEW_STATUS" | jq -r '.result.sync_info.latest_block_height')
BLOCKS_PER_6SEC=$(($NEW_BLOCK_HEIGHT - $BLOCK_HEIGHT))

if [ $BLOCKS_PER_6SEC -eq 1 ]; then
    echo "  ✅ Block Production:    ~1 block per 6 seconds (normal)"
elif [ $BLOCKS_PER_6SEC -eq 0 ]; then
    echo "  ⚠️  Block Production:    Slow or stalled"
else
    echo "  ✅ Block Production:    $BLOCKS_PER_6SEC blocks in 6 seconds"
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                          MONITORING COMPLETE                                 ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "For detailed logs, run:"
echo "  ssh -i $KEY_FILE ec2-user@$EC2_HOST 'journalctl -u libyachaind -f'"
echo ""
echo "To query the blockchain, use:"
echo "  curl http://$EC2_HOST:26657/status"
echo "  curl http://$EC2_HOST:1317/cosmos/bank/v1beta1/supply"
echo ""
