#!/bin/bash

# Multi-node testnet setup script for LibyaChain

set -e

CHAIN_ID="libyachain-testnet-1"
NUM_NODES=4
KEYRING_BACKEND="test"
BASE_DIR="$HOME/.libyachain-testnet"

echo "🌐 Setting up $NUM_NODES-node LibyaChain testnet..."

# Clean up
rm -rf "$BASE_DIR"
mkdir -p "$BASE_DIR"

# Initialize nodes
for i in $(seq 0 $((NUM_NODES - 1))); do
    NODE_DIR="$BASE_DIR/node$i"
    MONIKER="node$i"

    echo "🔧 Initializing $MONIKER..."
    libyachaind init "$MONIKER" --chain-id "$CHAIN_ID" --home "$NODE_DIR"

    # Create validator key
    libyachaind keys add "validator$i" --keyring-backend "$KEYRING_BACKEND" --home "$NODE_DIR" 2>&1 | tee "$BASE_DIR/validator$i-key.txt"

    # Get validator address
    VALIDATOR_ADDR=$(libyachaind keys show "validator$i" -a --keyring-backend "$KEYRING_BACKEND" --home "$NODE_DIR")

    # Add genesis account
    libyachaind add-genesis-account "$VALIDATOR_ADDR" \
        100000000000ulydd,100000000000ulydc,100000000000uucbl \
        --keyring-backend "$KEYRING_BACKEND" \
        --home "$NODE_DIR"

    echo "✅ Node $i initialized with address: $VALIDATOR_ADDR"
done

# Create genesis transactions
for i in $(seq 0 $((NUM_NODES - 1))); do
    NODE_DIR="$BASE_DIR/node$i"

    echo "📝 Creating gentx for node$i..."
    libyachaind gentx "validator$i" \
        1000000000ulydd \
        --chain-id "$CHAIN_ID" \
        --keyring-backend "$KEYRING_BACKEND" \
        --home "$NODE_DIR"
done

# Copy genesis transactions to node0
for i in $(seq 1 $((NUM_NODES - 1))); do
    cp "$BASE_DIR/node$i/config/gentx"/* "$BASE_DIR/node0/config/gentx/"
done

# Collect gentxs on node0
echo "📦 Collecting genesis transactions..."
libyachaind collect-gentxs --home "$BASE_DIR/node0"

# Copy genesis file to all nodes
for i in $(seq 1 $((NUM_NODES - 1))); do
    cp "$BASE_DIR/node0/config/genesis.json" "$BASE_DIR/node$i/config/genesis.json"
done

# Get node0 ID for persistent peers
NODE0_ID=$(libyachaind tendermint show-node-id --home "$BASE_DIR/node0")

# Configure nodes
for i in $(seq 0 $((NUM_NODES - 1))); do
    NODE_DIR="$BASE_DIR/node$i"
    CONFIG_FILE="$NODE_DIR/config/config.toml"
    APP_CONFIG_FILE="$NODE_DIR/config/app.toml"

    # Set ports
    RPC_PORT=$((26657 + i))
    P2P_PORT=$((26656 + i))
    GRPC_PORT=$((9090 + i))
    API_PORT=$((1317 + i))

    # Update ports in config
    sed -i "s/laddr = \"tcp:\/\/127.0.0.1:26657\"/laddr = \"tcp:\/\/127.0.0.1:$RPC_PORT\"/g" "$CONFIG_FILE"
    sed -i "s/laddr = \"tcp:\/\/0.0.0.0:26656\"/laddr = \"tcp:\/\/0.0.0.0:$P2P_PORT\"/g" "$CONFIG_FILE"
    sed -i "s/address = \"localhost:9090\"/address = \"localhost:$GRPC_PORT\"/g" "$APP_CONFIG_FILE"
    sed -i "s/address = \"tcp:\/\/localhost:1317\"/address = \"tcp:\/\/localhost:$API_PORT\"/g" "$APP_CONFIG_FILE"

    # Enable API
    sed -i 's/enable = false/enable = true/g' "$APP_CONFIG_FILE"

    # Set minimum gas prices
    sed -i 's/minimum-gas-prices = ""/minimum-gas-prices = "0.001ulydd,0.001ulydc,0.001uucbl"/g' "$APP_CONFIG_FILE"

    # Configure persistent peers (connect all nodes to node0)
    if [ $i -ne 0 ]; then
        PERSISTENT_PEERS="$NODE0_ID@127.0.0.1:26656"
        sed -i "s/persistent_peers = \"\"/persistent_peers = \"$PERSISTENT_PEERS\"/g" "$CONFIG_FILE"
    fi

    # Reduce block time
    sed -i 's/timeout_commit = "5s"/timeout_commit = "1s"/g' "$CONFIG_FILE"

    echo "✅ Node $i configured (RPC: $RPC_PORT, P2P: $P2P_PORT, gRPC: $GRPC_PORT, API: $API_PORT)"
done

# Create start script
cat > "$BASE_DIR/start-all.sh" << 'EOF'
#!/bin/bash
BASE_DIR="$HOME/.libyachain-testnet"

for i in $(seq 0 3); do
    NODE_DIR="$BASE_DIR/node$i"
    echo "🚀 Starting node$i..."
    libyachaind start --home "$NODE_DIR" > "$NODE_DIR/node.log" 2>&1 &
    echo $! > "$NODE_DIR/node.pid"
done

echo "✅ All nodes started! Check logs in $BASE_DIR/node*/node.log"
echo "📋 Node 0 RPC: http://localhost:26657"
echo "📋 Node 1 RPC: http://localhost:26658"
echo "📋 Node 2 RPC: http://localhost:26659"
echo "📋 Node 3 RPC: http://localhost:26660"
EOF

cat > "$BASE_DIR/stop-all.sh" << 'EOF'
#!/bin/bash
BASE_DIR="$HOME/.libyachain-testnet"

for i in $(seq 0 3); do
    NODE_DIR="$BASE_DIR/node$i"
    if [ -f "$NODE_DIR/node.pid" ]; then
        PID=$(cat "$NODE_DIR/node.pid")
        echo "🛑 Stopping node$i (PID: $PID)..."
        kill $PID 2>/dev/null || true
        rm "$NODE_DIR/node.pid"
    fi
done

echo "✅ All nodes stopped!"
EOF

chmod +x "$BASE_DIR/start-all.sh"
chmod +x "$BASE_DIR/stop-all.sh"

echo "
✅ Multi-node testnet configured!

📋 Configuration:
   Chain ID: $CHAIN_ID
   Nodes: $NUM_NODES
   Base Dir: $BASE_DIR

🚀 Start all nodes:
   $BASE_DIR/start-all.sh

🛑 Stop all nodes:
   $BASE_DIR/stop-all.sh

📡 RPC Endpoints:
   Node 0: http://localhost:26657
   Node 1: http://localhost:26658
   Node 2: http://localhost:26659
   Node 3: http://localhost:26660

🔌 API Endpoints:
   Node 0: http://localhost:1317
   Node 1: http://localhost:1318
   Node 2: http://localhost:1319
   Node 3: http://localhost:1320
"
