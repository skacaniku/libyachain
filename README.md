# LibyaChain SDK

JavaScript/TypeScript SDK for the LibyaChain blockchain.

## Overview

LibyaChain is a Layer 1 blockchain built on Cosmos SDK, featuring a unique three-currency ecosystem.

## Three-Currency System

- **LYDD** (ulydd) - Libyan Digital Dinar - Stablecoin  
- **LYDC** (ulydc) - Libyan Digital Currency - Cryptocurrency
- **UCBL** (uucbl) - Central Bank of Libya CBDC

## Technology Stack

- **Cosmos SDK** v0.50.11
- **IBC-Go** v8.5.2
- **CometBFT** v0.38.18
- Custom modules for three-currency system

## Network Endpoints

- **RPC**: https://rpc.libyachain.net
- **LCD/API**: https://api.libyachain.net
- **Explorer**: https://explorer.libyachain.net
- **Faucet**: https://faucet.libyachain.net

## Installation

```bash
npm install @libyachain/sdk
```

## Quick Start

```typescript
import { LibyaChainClient } from '@libyachain/sdk';

// Connect to network
const client = await LibyaChainClient.connect('https://rpc.libyachain.net');

// Check balance
const balance = await client.bank.balance(address, 'ulydc');

// Send transaction
const result = await client.bank.send(
  fromAddress,
  toAddress,
  [{ denom: 'ulydc', amount: '1000000' }]
);
```

## Features

✅ Full three-currency support  
✅ Wallet management  
✅ Transaction signing and broadcasting  
✅ WebSocket streaming  
✅ IBC transfers  
✅ Query APIs for all modules  

## Documentation

Coming soon: Comprehensive API documentation and developer guides.

## Contributing

Contributions are welcome! Please open an issue or pull request.

## Links

- **Main Repository**: https://github.com/skacaniku/libyachain
- **Website**: https://libyachain.net

---

**Building the future of Libya's digital economy**
