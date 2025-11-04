# LibyaChain

A **privacy-focused, EVM-compatible** Layer 1 blockchain built on Cosmos SDK featuring a unique three-currency ecosystem for Libya's digital economy.

## Overview

LibyaChain is a sovereign blockchain that combines the best of Cosmos SDK modularity, Ethereum smart contract compatibility, and privacy-preserving technology to support Libya's digital currency infrastructure.

## 🌟 Key Features

- 🔐 **Privacy-Preserving**: zk-SNARK-based private transactions protecting sender, receiver, and amount
- 🔷 **EVM-Compatible**: Full Ethereum compatibility - deploy Solidity contracts, use MetaMask, Web3 tools
- 🌉 **Multi-Chain Bridges**: Native bridges to Bitcoin, Ethereum, Solana, BNB Chain, TRON, and Dogecoin
- 💰 **Three-Currency System**: LYDD (stablecoin), LYDC (asset-backed), UCBL (CBDC) working in harmony
- 🔗 **IBC-Enabled**: Inter-Blockchain Communication for Cosmos ecosystem integration
- ⚡ **High Performance**: 1-2 second finality, 1000+ transactions per second
- 🛡️ **Enterprise Security**: Multi-signature validation, audited bridges, regulatory compliance

## Three-Currency System

- **LYDD (ulydd)** - Libyan Digital Dinar - Stablecoin for everyday transactions, gas fees, and staking
- **LYDC (ulydc)** - Libyan Digital Currency - Asset-backed crypto for investment, DeFi, and cross-border trade
- **UCBL (uucbl)** - Central Bank of Libya CBDC - Institutional currency for government, banks, and settlements

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

### Core Blockchain
✅ Three-currency system with seamless interoperability
✅ IBC-enabled for cross-chain transfers
✅ Cosmos SDK v0.50.11 with CometBFT consensus
✅ 1-2 second block time with instant finality
✅ Custom modules for treasury and policy management

### Privacy Features
✅ zk-SNARK-based private transactions
✅ Shielded pool for confidential balances
✅ Selective disclosure for compliance
✅ Multi-currency privacy (LYDD, LYDC, UCBL)
✅ Optional viewing keys for auditing

### EVM Compatibility
✅ Full Ethereum Virtual Machine support
✅ Solidity smart contracts (0.8.x)
✅ Web3, MetaMask, Hardhat, Truffle compatible
✅ Ethereum JSON-RPC endpoints
✅ Custom precompiles for Cosmos features
✅ Multi-currency gas payments

### Cross-Chain Bridges
✅ Bitcoin (BTC) - 6 confirmations, 0.3% fee
✅ Ethereum (ETH, USDT, USDC, DAI) - 12 confirmations, 0.2% fee
✅ Solana (SOL, USDC) - 32 confirmations, 0.1% fee
✅ BNB Chain (BNB, BUSD) - 15 confirmations, 0.2% fee
✅ TRON (TRX, USDT) - 19 confirmations, 0.2% fee
✅ Dogecoin (DOGE) - 40 confirmations, 0.3% fee

## Developer Tools

- **libyachaind CLI** - Complete command-line interface
- **EVM RPC** - Ethereum-compatible JSON-RPC endpoints
- **TypeScript SDK** - `@libyachain/sdk` (coming soon)
- **Hardhat Plugin** - Deploy and test smart contracts
- **MetaMask** - Browser wallet integration
- **Explorer** - Block explorer and contract verification

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
