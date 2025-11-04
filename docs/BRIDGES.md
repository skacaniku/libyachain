# 🌉 Cross-Chain Bridges

LibyaChain features native bridges to major blockchain networks, enabling seamless asset transfers across chains.

## Supported Chains

| Chain | Status | Confirmations | Fee | Supported Assets |
|-------|--------|---------------|-----|------------------|
| **Bitcoin** | ✅ Active | 6 blocks | 0.3% | BTC |
| **Ethereum** | ✅ Active | 12 blocks | 0.2% | ETH, USDT, USDC, DAI |
| **Solana** | ✅ Active | 32 blocks | 0.1% | SOL, USDC |
| **BNB Chain** | ✅ Active | 15 blocks | 0.2% | BNB, BUSD, USDT |
| **TRON** | ✅ Active | 19 blocks | 0.2% | TRX, USDT |
| **Dogecoin** | ✅ Active | 40 blocks | 0.3% | DOGE |

## How It Works

### Bridge Architecture

```
┌──────────────┐         ┌──────────────┐         ┌──────────────┐
│   External   │         │  LibyaChain  │         │   External   │
│    Chain     │◄───────►│    Bridge    │◄───────►│    Chain     │
│   (Source)   │  Lock   │    Module    │  Mint   │ (LibyaChain) │
└──────────────┘         └──────────────┘         └──────────────┘
                                │
                         ┌──────┴──────┐
                         │  Relayer    │
                         │   Network   │
                         └─────────────┘
```

### Deposit Flow (External Chain → LibyaChain)

1. **User locks** tokens on external chain (send to bridge address)
2. **Relayers detect** the transaction
3. **Wait for confirmations** (varies by chain)
4. **Submit proof** to LibyaChain
5. **LibyaChain mints** wrapped tokens to user
6. **User receives** wrapped tokens on LibyaChain

### Withdrawal Flow (LibyaChain → External Chain)

1. **User burns** wrapped tokens on LibyaChain
2. **Relayers detect** burn transaction
3. **Multi-sig validators** sign withdrawal
4. **Tokens released** on external chain
5. **User receives** native tokens

## Usage

### Deposit from Bitcoin

```bash
# Step 1: Get LibyaChain deposit address
libyachaind query bridge deposit-address \
    --chain bitcoin \
    --dest-address libya1...

# Output: bc1q...  (Bitcoin address controlled by bridge)

# Step 2: Send BTC to that address from any Bitcoin wallet
# Wait for 6 confirmations

# Step 3: Check deposit status
libyachaind query bridge transfer <tx-hash>

# Step 4: Once confirmed, wrapped BTC appears in your account
libyachaind query bank balances libya1...
# Shows: ibc/bitcoin/BTC
```

### Deposit from Ethereum

```bash
# Get deposit contract address
libyachaind query bridge deposit-address \
    --chain ethereum \
    --dest-address libya1...

# Send ETH/ERC20 to contract address
# Or use MetaMask:
# 1. Connect to Ethereum
# 2. Send to bridge contract: 0x...
# 3. Include LibyaChain address in data field

# Check status
libyachaind query bridge transfer <eth-tx-hash>

# Wrapped tokens: ibc/ethereum/ETH
```

### Deposit from Solana

```bash
# Get Solana program-derived address
libyachaind query bridge deposit-address \
    --chain solana \
    --dest-address libya1...

# Use Solana CLI or Phantom wallet
solana transfer <pda-address> 1 --from wallet.json

# Wrapped tokens: ibc/solana/SOL
```

### Withdraw to External Chain

```bash
# Withdraw BTC back to Bitcoin network
libyachaind tx bridge withdraw \
    --chain bitcoin \
    --to-address bc1q... \
    --amount 1000000ibc/bitcoin/BTC \
    --from mykey \
    --fees 100ulydd

# Withdraw ETH to Ethereum
libyachaind tx bridge withdraw \
    --chain ethereum \
    --to-address 0x... \
    --amount 1000000000000000000ibc/ethereum/ETH \
    --from mykey

# Withdraw to any supported chain
libyachaind tx bridge withdraw \
    --chain <chain-name> \
    --to-address <external-address> \
    --amount <wrapped-amount> \
    --from mykey
```

## Wrapped Tokens

### Naming Convention

Wrapped tokens follow the format: `ibc/<chain>/<symbol>`

Examples:
- `ibc/bitcoin/BTC` - Wrapped Bitcoin
- `ibc/ethereum/ETH` - Wrapped Ether
- `ibc/ethereum/USDT` - Wrapped Tether (ERC20)
- `ibc/solana/SOL` - Wrapped Solana
- `ibc/bnb/BNB` - Wrapped BNB
- `ibc/tron/TRX` - Wrapped TRON
- `ibc/dogecoin/DOGE` - Wrapped Dogecoin

### Using Wrapped Tokens

Wrapped tokens behave exactly like native LibyaChain tokens:

```bash
# Check balance
libyachaind query bank balances libya1...

# Send to another address
libyachaind tx bank send libya1... libya1... 1000ibc/bitcoin/BTC

# Use in DeFi (staking, liquidity pools, etc.)
libyachaind tx swap add-liquidity \
    ibc/bitcoin/BTC \
    ulydd \
    --amounts 1000000,50000000

# Use with privacy features
libyachaind tx privacy shield 1000000ibc/ethereum/ETH --from mykey
```

## Bridge Security

### Multi-Signature Validation

All withdrawals require multi-sig approval:

- **Threshold**: 5 of 7 validators
- **Validators**: Geographically distributed
- **Rotation**: Validator set rotated periodically
- **Slashing**: Misbehaving validators are penalized

### Collateralization

Bridge is over-collateralized for security:

- **Reserve Ratio**: 120% of wrapped supply
- **Insurance Fund**: Additional 10% buffer
- **Real-time Monitoring**: Automated alerts
- **Pause Mechanism**: Emergency shutdown capability

### Audits

- Smart contracts audited by: [Audit Firm]
- Multi-sig setup reviewed by: [Security Team]
- Continuous monitoring: 24/7 relayer network

## Fees

### Fee Structure

| Chain | Deposit Fee | Withdrawal Fee | Min Amount | Max Amount |
|-------|-------------|----------------|------------|------------|
| Bitcoin | 0.3% | 0.3% + network fee | 0.001 BTC | 1000 BTC |
| Ethereum | 0.2% | 0.2% + gas | 0.01 ETH | 1000 ETH |
| Solana | 0.1% | 0.1% + 0.000005 SOL | 0.01 SOL | 100,000 SOL |
| BNB | 0.2% | 0.2% + gas | 0.01 BNB | 1000 BNB |
| TRON | 0.2% | 0.2% + bandwidth | 10 TRX | 1M TRX |
| Dogecoin | 0.3% | 0.3% + network fee | 1 DOGE | 100K DOGE |

### Fee Distribution

Bridge fees are distributed:
- **60%**: Validators/relayers
- **20%**: Insurance fund
- **10%**: Protocol treasury
- **10%**: Stakers

## Relayer Network

### How to Run a Relayer

```bash
# Install relayer software
git clone https://github.com/skacaniku/libyachain-relayer
cd libyachain-relayer
make install

# Configure relayer
libyachain-relayer config init \
    --chains bitcoin,ethereum,solana,bnb,tron,dogecoin

# Start relaying
libyachain-relayer start \
    --libyachain-endpoint https://rpc.libyachain.net \
    --bitcoin-rpc <btc-node> \
    --ethereum-rpc <eth-node> \
    --solana-rpc <sol-node> \
    --bnb-rpc <bnb-node> \
    --tron-rpc <trx-node> \
    --dogecoin-rpc <doge-node>
```

### Relayer Requirements

- **Stake**: 100,000 LYDD minimum
- **Uptime**: 99%+ required
- **Hardware**: 8 core CPU, 32GB RAM, 1TB SSD
- **Network**: Low latency, high bandwidth
- **Nodes**: Full nodes for each supported chain

### Relayer Rewards

Earn fees for facilitating transfers:

```bash
# Check relayer earnings
libyachaind query bridge relayer-stats <relayer-address>

# Claim rewards
libyachaind tx bridge claim-relayer-rewards --from relayer-key
```

## Advanced Features

### Atomic Swaps

Swap tokens across chains atomically:

```bash
# Swap BTC for ETH (cross-chain)
libyachaind tx bridge atomic-swap \
    --from-chain bitcoin \
    --to-chain ethereum \
    --from-token BTC \
    --to-token ETH \
    --amount 1000000 \
    --rate 15.5
```

### Batch Transfers

Reduce fees with batched operations:

```bash
# Batch multiple withdrawals
libyachaind tx bridge batch-withdraw \
    --chain ethereum \
    --transfers transfers.json \
    --from mykey

# transfers.json:
[
  {"to": "0x123...", "amount": "1000000", "token": "ETH"},
  {"to": "0x456...", "amount": "500000", "token": "USDT"}
]
```

### Bridge Limits

Per-transaction and daily limits for security:

```bash
# Check current limits
libyachaind query bridge limits --chain ethereum

# Check your daily usage
libyachaind query bridge usage \
    --address libya1... \
    --chain ethereum
```

## Monitoring

### Bridge Status

```bash
# Check overall bridge health
libyachaind query bridge status

# Chain-specific status
libyachaind query bridge chain-status --chain ethereum

# Pending transfers
libyachaind query bridge pending --limit 100

# Your transfers
libyachaind query bridge transfers \
    --address libya1... \
    --status all
```

### Explorer

View bridge transactions on the explorer:
- https://explorer.libyachain.net/bridge

### Alerts

Set up alerts for your transfers:

```bash
# Subscribe to transfer notifications
libyachaind tx bridge subscribe \
    --webhook https://myapp.com/webhook \
    --from mykey
```

## Integration Guide

### For dApps

```typescript
import { LibyaChainClient } from '@libyachain/sdk';

const client = new LibyaChainClient({
  rpc: 'https://rpc.libyachain.net'
});

// Deposit from Ethereum
const tx = await client.bridge.deposit({
  sourceChain: 'ethereum',
  sourceTxHash: '0x...',
  destAddress: 'libya1...',
  amount: '1000000000000000000', // 1 ETH
  token: 'ETH'
});

// Monitor status
const status = await client.bridge.getTransferStatus(tx.id);

// Withdraw to Ethereum
const withdrawal = await client.bridge.withdraw({
  destChain: 'ethereum',
  destAddress: '0x...',
  amount: '1000000000000000000',
  token: 'ibc/ethereum/ETH'
});
```

### For Exchanges

```bash
# Generate deposit addresses for users
libyachaind tx bridge generate-deposit-address \
    --chain ethereum \
    --user-id user123 \
    --callback https://exchange.com/callback

# Monitor deposits
libyachaind query bridge deposits \
    --since 2024-01-01 \
    --chain ethereum

# Batch withdrawals for efficiency
libyachaind tx bridge batch-withdraw \
    --chain ethereum \
    --withdrawals withdrawals.json \
    --from exchange-hot-wallet
```

## Troubleshooting

### Deposit Not Appearing

```bash
# 1. Check transaction confirmations
# Bitcoin: Need 6 confirmations
# Ethereum: Need 12 confirmations
# etc.

# 2. Verify transaction was sent to correct address
libyachaind query bridge verify-deposit \
    --chain bitcoin \
    --tx-hash <btc-tx-hash>

# 3. Check relayer status
libyachaind query bridge relayer-status

# 4. Contact support with transfer ID
```

### Withdrawal Stuck

```bash
# Check withdrawal status
libyachaind query bridge transfer <transfer-id>

# Check multi-sig threshold
libyachaind query bridge multisig-status <transfer-id>

# If delayed, check bridge pause status
libyachaind query bridge pause-status --chain ethereum
```

## Roadmap

- [ ] Add support for Cosmos chains via IBC
- [ ] Polygon bridge integration
- [ ] Avalanche C-Chain support
- [ ] Cardano bridge (when smart contracts mature)
- [ ] Polkadot parachain bridge
- [ ] Lightning Network integration (Bitcoin)
- [ ] Optimistic rollup bridges (Arbitrum, Optimism)
- [ ] ZK rollup bridges (zkSync, StarkNet)

## Resources

- **Bridge Module**: `/x/bridge`
- **Relayer Software**: https://github.com/skacaniku/libyachain-relayer
- **Bridge API**: https://api.libyachain.net/bridge
- **Bridge Explorer**: https://explorer.libyachain.net/bridge
- **Audit Reports**: https://libyachain.net/audits

## Support

For bridge-related questions:
- Discord: #bridge-support
- Email: bridge@libyachain.net
- Telegram: @libyachain_bridge

**Security Contact**: security@libyachain.net (for vulnerabilities)
