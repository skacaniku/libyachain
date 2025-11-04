# LibyaChain

A Layer 1 blockchain built on Cosmos SDK featuring a unique three-currency ecosystem for Libya's digital economy.

## Overview

LibyaChain is a sovereign blockchain designed to support Libya's digital currency infrastructure with three distinct currencies operating in harmony.

## Three-Currency System

- **LYDD (ulydd)** - Libyan Digital Dinar - Stablecoin for everyday transactions
- **LYDC (ulydc)** - Libyan Digital Currency - Cryptocurrency with asset backing
- **UCBL (uucbl)** - Central Bank of Libya CBDC - Institutional currency

## Technology Stack

- **Cosmos SDK** v0.50.11 - Modular blockchain framework
- **IBC-Go** v8.5.2 - Inter-Blockchain Communication protocol
- **CometBFT** v0.38.18 - Byzantine fault-tolerant consensus engine
- **Go** 1.21+ - Implementation language
- **gRPC** - High-performance RPC framework
- **Tendermint** - Consensus algorithm
- Custom modules for three-currency system

## Architecture

### Blockchain Layers

```
┌─────────────────────────────────────────┐
│        Application Layer (ABCI)         │
│  ┌─────────────────────────────────┐   │
│  │   Bank │ Staking │ Gov │ IBC    │   │
│  │   LYDD │  LYDC   │ UCBL System  │   │
│  └─────────────────────────────────┘   │
├─────────────────────────────────────────┤
│         Consensus Layer                 │
│         (CometBFT/Tendermint)           │
├─────────────────────────────────────────┤
│         Networking Layer                │
│         (P2P Communication)             │
└─────────────────────────────────────────┘
```

### Module Architecture

- **Auth**: Account management and authentication
- **Bank**: Multi-currency balance management (LYDD, LYDC, UCBL)
- **Staking**: Validator delegation using LYDD
- **Distribution**: Reward distribution to validators and delegators
- **Governance**: On-chain governance with multi-currency support
- **Slashing**: Validator penalty mechanism
- **Mint**: LYDD token inflation
- **IBC**: Cross-chain communication
- **Evidence**: Byzantine behavior detection

## Network Endpoints

- **RPC**: https://rpc.libyachain.net
- **API**: https://api.libyachain.net
- **Explorer**: https://explorer.libyachain.net
- **Faucet**: https://faucet.libyachain.net

## Features

✅ Three-currency system with seamless interoperability  
✅ IBC-enabled for cross-chain transfers  
✅ Custom policy and treasury modules  
✅ WebSocket streaming for real-time updates  
✅ Production-ready explorer and faucet  

## Developer Tools

- **TypeScript SDK** - `@libyachain/sdk` (coming soon)
- **React Components** - UI components for dApps
- **CLI Tools** - Command-line blockchain operations

## Getting Started

### Prerequisites

- **Go**: 1.21 or higher
- **Make**: For build automation
- **GCC**: For cgo dependencies (optional, for ledger support)

### Installation

#### From Source

```bash
# Clone repository
git clone https://github.com/skacaniku/libyachain
cd libyachain

# Download dependencies
go mod download

# Build and install
make install

# Verify installation
libyachaind version
```

#### Using Docker

```bash
# Build Docker image
docker build -t libyachain:latest .

# Run with Docker Compose
docker-compose up -d

# Check logs
docker-compose logs -f node0
```

### Quick Start - Local Development

```bash
# Initialize single-node testnet
./scripts/init-testnet.sh

# Start the node
libyachaind start

# In another terminal, check status
libyachaind status

# Query balances
libyachaind query bank balances <address>
```

### Multi-Node Testnet

```bash
# Initialize 4-node testnet
./scripts/init-multi-node.sh

# Start all nodes
~/.libyachain-testnet/start-all.sh

# Stop all nodes
~/.libyachain-testnet/stop-all.sh
```

### Connecting to Testnet

```bash
# Configure RPC endpoint
libyachaind config node https://rpc.libyachain.net

# Set chain ID
libyachaind config chain-id libyachain-testnet-1

# Query account balance (all currencies)
libyachaind query bank balances <address>

# Query specific currency
libyachaind query bank balances <address> --denom ulydd
```

### Sending Transactions

```bash
# Send LYDD
libyachaind tx bank send <from> <to> 1000ulydd \
    --chain-id libyachain-testnet-1 \
    --fees 100ulydd

# Send multiple currencies
libyachaind tx bank send <from> <to> 1000ulydd,500ulydc,100uucbl \
    --chain-id libyachain-testnet-1

# Delegate to validator
libyachaind tx staking delegate <validator> 1000000ulydd \
    --from <key> \
    --chain-id libyachain-testnet-1
```

## Documentation

### Available Documentation

- **[Developer Guide](DEVELOPERS.md)** - Comprehensive development documentation
- **[Contributing Guide](CONTRIBUTING.md)** - How to contribute to the project
- **[Changelog](CHANGELOG.md)** - Version history and changes
- **API Reference** - Available at http://localhost:1317/swagger/ when running
- **Architecture** - See [Architecture](#architecture) section above

### Development Resources

- **Build Commands**: See [Makefile](Makefile)
- **Scripts**: Development scripts in [scripts/](scripts/)
- **Genesis Template**: [config/genesis-template.json](config/genesis-template.json)
- **Docker Setup**: [docker-compose.yml](docker-compose.yml)

## Contributing

We welcome contributions! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for details.

## Links

- **Website**: https://libyachain.net
- **Explorer**: https://explorer.libyachain.net
- **Faucet**: https://faucet.libyachain.net

---

**Building the future of Libya's digital economy**
