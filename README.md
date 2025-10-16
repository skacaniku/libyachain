# LibyaChain

A Layer 1 blockchain built on Cosmos SDK featuring a unique three-currency ecosystem for Libya's digital economy.

## Overview

LibyaChain is a sovereign blockchain designed to support Libya's digital currency infrastructure with three distinct currencies operating in harmony.

## Three-Currency System

- **LYDD (ulydd)** - Libyan Digital Dinar - Stablecoin for everyday transactions
- **LYDC (ulydc)** - Libyan Digital Currency - Cryptocurrency with asset backing
- **UCBL (uucbl)** - Central Bank of Libya CBDC - Institutional currency

## Technology Stack

- **Cosmos SDK** v0.50.11
- **IBC-Go** v8.5.2  
- **CometBFT** v0.38.18
- Custom modules for three-currency system

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

### Running a Node

```bash
# Clone repository
git clone https://github.com/skacaniku/libyachain
cd libyachain

# Build
make install

# Initialize
libyachaind init <moniker> --chain-id libyachain

# Start node
libyachaind start
```

### Connecting to Testnet

```bash
# Configure RPC endpoint
libyachaind config node https://rpc.libyachain.net

# Query account balance
libyachaind query bank balances <address>
```

## Documentation

- Developer guides and API references (coming soon)
- Architecture documentation
- Deployment guides

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
