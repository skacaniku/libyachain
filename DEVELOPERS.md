# LibyaChain Developer Guide

Welcome to the LibyaChain developer documentation. This guide will help you set up, develop, and deploy the LibyaChain blockchain.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Building from Source](#building-from-source)
- [Running a Local Node](#running-a-local-node)
- [Multi-Node Testnet](#multi-node-testnet)
- [Docker Setup](#docker-setup)
- [Development Workflow](#development-workflow)
- [Three-Currency System](#three-currency-system)
- [Module Development](#module-development)
- [Testing](#testing)
- [Deployment](#deployment)

## Prerequisites

- **Go**: 1.21 or higher
- **Make**: For build automation
- **Git**: For version control
- **Docker** (optional): For containerized deployment
- **GCC**: For cgo dependencies (ledger support)

### Installing Go

```bash
# Linux/macOS
wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin

# Verify installation
go version
```

## Quick Start

### 1. Clone and Build

```bash
# Clone the repository
git clone https://github.com/skacaniku/libyachain
cd libyachain

# Download dependencies
go mod download

# Build and install
make install

# Verify installation
libyachaind version
```

### 2. Initialize Single Node

```bash
# Run the init script
./scripts/init-testnet.sh

# Start the node
libyachaind start
```

### 3. Query the Chain

```bash
# Check node status
libyachaind status

# Query account balance
libyachaind query bank balances $(libyachaind keys show validator -a --keyring-backend test)

# Query all three currencies
libyachaind query bank balances <address> --denom ulydd
libyachaind query bank balances <address> --denom ulydc
libyachaind query bank balances <address> --denom uucbl
```

## Building from Source

### Standard Build

```bash
# Build binary (output: build/libyachaind)
make build

# Install to $GOPATH/bin
make install

# Build for Linux
make build-linux

# Clean build artifacts
make clean
```

### Build Options

```bash
# Build with ledger support (default)
LEDGER_ENABLED=true make install

# Build without ledger support
LEDGER_ENABLED=false make install

# Build with RocksDB backend
COSMOS_BUILD_OPTIONS=rocksdb make install
```

## Running a Local Node

### Manual Setup

```bash
# Initialize chain
libyachaind init mynode --chain-id libyachain-local

# Create validator key
libyachaind keys add validator

# Add genesis account with all three currencies
libyachaind add-genesis-account $(libyachaind keys show validator -a) \
    100000000000ulydd,100000000000ulydc,100000000000uucbl

# Create genesis transaction
libyachaind gentx validator 1000000000ulydd \
    --chain-id libyachain-local

# Collect genesis transactions
libyachaind collect-gentxs

# Start node
libyachaind start
```

### Using Init Script

```bash
# Single command setup
./scripts/init-testnet.sh

# The script will:
# - Clean old data
# - Initialize chain
# - Create validator key
# - Add genesis account
# - Create and collect gentx
# - Configure for development
# - Print connection details
```

## Multi-Node Testnet

### Setup 4-Node Testnet

```bash
# Initialize 4-node testnet
./scripts/init-multi-node.sh

# Start all nodes
~/.libyachain-testnet/start-all.sh

# Check logs
tail -f ~/.libyachain-testnet/node0/node.log

# Stop all nodes
~/.libyachain-testnet/stop-all.sh
```

### Node Endpoints

| Node | RPC Port | API Port | gRPC Port | P2P Port |
|------|----------|----------|-----------|----------|
| 0    | 26657    | 1317     | 9090      | 26656    |
| 1    | 26658    | 1318     | 9091      | 26657    |
| 2    | 26659    | 1319     | 9092      | 26658    |
| 3    | 26660    | 1320     | 9093      | 26659    |

## Docker Setup

### Single Node with Docker Compose

```bash
# Build and start
docker-compose up -d

# View logs
docker-compose logs -f node0

# Stop
docker-compose down

# Stop and remove volumes
docker-compose down -v
```

### Build Docker Image

```bash
# Build image
docker build -t libyachain:latest .

# Run container
docker run -d \
    -p 26657:26657 \
    -p 1317:1317 \
    -p 9090:9090 \
    --name libyachain-node \
    libyachain:latest
```

## Development Workflow

### Code Structure

```
libyachain/
├── app/                    # Application logic
│   ├── app.go             # Main app structure
│   └── encoding.go        # Codec configuration
├── cmd/libyachaind/       # CLI commands
│   ├── main.go            # Entry point
│   └── cmd/               # Command definitions
├── config/                # Configuration templates
├── scripts/               # Development scripts
├── go.mod                 # Go dependencies
└── Makefile              # Build automation
```

### Making Changes

1. **Create a feature branch**
   ```bash
   git checkout -b feature/my-feature
   ```

2. **Make your changes**
   ```bash
   # Edit code
   vim app/app.go
   ```

3. **Format and lint**
   ```bash
   make format
   make lint
   ```

4. **Test**
   ```bash
   make test
   ```

5. **Build**
   ```bash
   make install
   ```

6. **Commit and push**
   ```bash
   git add .
   git commit -m "feat: add new feature"
   git push origin feature/my-feature
   ```

## Three-Currency System

LibyaChain implements three distinct currencies:

### LYDD (Libyan Digital Dinar)

- **Symbol**: LYDD
- **Base Denomination**: ulydd (micro-lydd)
- **Purpose**: Stablecoin for everyday transactions
- **Backing**: Fiat-collateralized
- **Use Cases**:
  - Daily payments
  - Remittances
  - E-commerce
  - Staking (bond denom)

### LYDC (Libyan Digital Currency)

- **Symbol**: LYDC
- **Base Denomination**: ulydc (micro-lydc)
- **Purpose**: Asset-backed cryptocurrency
- **Backing**: Commodity-backed (oil, gold reserves)
- **Use Cases**:
  - Investment vehicle
  - Cross-border trade
  - Store of value
  - IBC transfers

### UCBL (Central Bank CBDC)

- **Symbol**: UCBL
- **Base Denomination**: uucbl (micro-ucbl)
- **Purpose**: Central Bank Digital Currency
- **Backing**: Central bank reserves
- **Use Cases**:
  - Institutional settlements
  - Government transactions
  - Banking operations
  - Monetary policy implementation

### Working with Multiple Currencies

```bash
# Send LYDD
libyachaind tx bank send <from> <to> 1000ulydd --chain-id libyachain

# Send LYDC
libyachaind tx bank send <from> <to> 1000ulydc --chain-id libyachain

# Send UCBL
libyachaind tx bank send <from> <to> 1000uucbl --chain-id libyachain

# Send multiple currencies
libyachaind tx bank send <from> <to> 1000ulydd,500ulydc,100uucbl \
    --chain-id libyachain

# Query specific currency balance
libyachaind query bank balances <address> --denom ulydd
```

## Module Development

### Adding Custom Modules

1. **Create module directory**
   ```bash
   mkdir -p x/mymodule
   ```

2. **Define module structure**
   ```
   x/mymodule/
   ├── keeper/
   ├── types/
   ├── client/cli/
   └── module.go
   ```

3. **Register in app.go**
   ```go
   import mymodule "github.com/skacaniku/libyachain/x/mymodule"

   // In ModuleBasics
   mymodule.AppModuleBasic{},
   ```

4. **Add to module manager**
   ```go
   app.mm = module.NewManager(
       // ... existing modules
       mymodule.NewAppModule(app.MyModuleKeeper),
   )
   ```

## Testing

### Unit Tests

```bash
# Run all tests
make test

# Run specific package
go test ./app/...

# Run with coverage
go test -cover ./...

# Verbose output
go test -v ./x/mymodule/...
```

### Integration Tests

```bash
# Run integration tests
make test-all

# Run with race detector
go test -race ./...
```

### Local Testing

```bash
# Start fresh testnet
./scripts/init-testnet.sh

# Run test transactions
libyachaind tx bank send validator <recipient> 1000ulydd \
    --keyring-backend test \
    --chain-id libyachain-testnet-1 \
    --yes

# Query results
libyachaind query tx <txhash>
```

## Deployment

### Mainnet Deployment Checklist

- [ ] Security audit completed
- [ ] All tests passing
- [ ] Genesis file prepared
- [ ] Validator set confirmed
- [ ] Network parameters finalized
- [ ] Monitoring setup
- [ ] Backup procedures established
- [ ] Documentation complete

### Production Configuration

```bash
# Production genesis
cp config/genesis-template.json ~/.libyachaind/config/genesis.json

# Configure for production
vim ~/.libyachaind/config/app.toml
# Set minimum-gas-prices
# Disable unsafe CORS
# Configure API access

vim ~/.libyachaind/config/config.toml
# Set persistent_peers
# Configure mempool
# Set timeout_commit
```

### Systemd Service

```bash
# Create service file
sudo vim /etc/systemd/system/libyachaind.service
```

```ini
[Unit]
Description=LibyaChain Node
After=network-online.target

[Service]
User=libyachain
ExecStart=/usr/local/bin/libyachaind start --home /home/libyachain/.libyachaind
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
```

```bash
# Enable and start
sudo systemctl enable libyachaind
sudo systemctl start libyachaind
sudo systemctl status libyachaind
```

## Useful Commands

### Key Management

```bash
# List keys
libyachaind keys list

# Add key
libyachaind keys add mykey

# Recover key from mnemonic
libyachaind keys add mykey --recover

# Export key
libyachaind keys export mykey

# Delete key
libyachaind keys delete mykey
```

### Query Commands

```bash
# Node info
libyachaind status

# Block info
libyachaind query block <height>

# Transaction
libyachaind query tx <hash>

# Account
libyachaind query auth account <address>

# Validator info
libyachaind query staking validator <validator-addr>

# Proposals
libyachaind query gov proposals
```

### Transaction Commands

```bash
# Send tokens
libyachaind tx bank send <from> <to> <amount> --chain-id <chain-id>

# Delegate
libyachaind tx staking delegate <validator> <amount> --from <key>

# Submit proposal
libyachaind tx gov submit-proposal <proposal.json> --from <key>

# Vote
libyachaind tx gov vote <proposal-id> yes --from <key>
```

## Troubleshooting

### Common Issues

**Error: connection refused**
```bash
# Check if node is running
ps aux | grep libyachaind

# Check RPC endpoint
curl http://localhost:26657/status
```

**Error: account sequence mismatch**
```bash
# Query account
libyachaind query auth account <address>

# Reset sequence
libyachaind tx bank send <from> <to> 1ulydd --sequence <correct-sequence>
```

**Error: insufficient gas**
```bash
# Estimate gas
libyachaind tx bank send <from> <to> 1000ulydd --dry-run

# Set higher gas
libyachaind tx bank send <from> <to> 1000ulydd --gas 200000
```

## Resources

- **Documentation**: [GitHub README](README.md)
- **API Reference**: http://localhost:1317/swagger/
- **RPC Docs**: http://localhost:26657/
- **Cosmos SDK**: https://docs.cosmos.network
- **IBC Protocol**: https://ibc.cosmos.network

## Support

For questions and support:
- GitHub Issues: https://github.com/skacaniku/libyachain/issues
- Email: dev@libyachain.net
- Discord: [Join our community]

## License

Apache License 2.0 - See [LICENSE](LICENSE) for details.
