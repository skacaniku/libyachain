## 🔐 Privacy Features

This guide covers LibyaChain's privacy-preserving features built on zero-knowledge proof technology.

## Overview

LibyaChain implements privacy features inspired by Zcash's Sapling protocol, providing:

- **Shielded Transactions**: Fully private transfers that hide sender, receiver, and amount
- **Selective Disclosure**: Optional viewing keys for auditing and compliance
- **Multi-Currency Privacy**: Privacy for LYDD, LYDC, and UCBL
- **Regulatory Compliance**: Built-in mechanisms for authorized disclosure

## Architecture

### Privacy Model

```
┌─────────────────────────────────────────────────────────┐
│                   LibyaChain Privacy Layer               │
├─────────────────────────────────────────────────────────┤
│  Transparent Pool  │   Shielded Pool  │  Privacy Module │
│  (Public Balances) │  (Private Notes) │  (zk-SNARKs)   │
├─────────────────────────────────────────────────────────┤
│          Shield/Unshield Operations                      │
│          ↓                    ↑                          │
│   [Public Funds] ←→ [Private Funds]                     │
└─────────────────────────────────────────────────────────┘
```

### Key Components

1. **Shielded Pool**: Private balance pool using note-based accounting
2. **Commitments**: Cryptographic commitments to transaction outputs
3. **Nullifiers**: Prevents double-spending without revealing which note was spent
4. **zk-SNARKs**: Zero-knowledge proofs for transaction validity

## Usage

### Creating a Private Account

```bash
# Generate private account credentials
libyachaind keys add mykey --privacy

# This generates:
# - Regular address (libya...)
# - Viewing key (for selective disclosure)
# - Shielded public key (for receiving private funds)
```

### Shielding Funds (Public → Private)

Move funds from transparent pool to shielded pool:

```bash
# Shield 1000 LYDD
libyachaind tx privacy shield \
    1000ulydd \
    --from mykey \
    --chain-id libyachain \
    --fees 100ulydd
```

**What happens:**
1. Transparent coins are locked in the privacy module
2. A commitment is added to the merkle tree
3. Private notes are created (only you can see/spend)
4. Transaction is publicly visible but amounts/recipients are hidden

### Private Transfers

Transfer funds within the shielded pool:

```bash
# Send shielded transaction
libyachaind tx privacy transfer \
    --to <shielded-address> \
    --amount 500ulydd \
    --from mykey \
    --chain-id libyachain

# The transaction reveals:
# - That a transaction occurred
# - Which nullifiers were consumed (but not which notes)
# - New commitments (but not amounts or recipients)
```

**Privacy guarantees:**
- ✅ Sender identity hidden
- ✅ Receiver identity hidden
- ✅ Amount hidden
- ✅ Token type hidden (if using same denomination)
- ✅ Unlinkable to previous transactions

### Unshielding Funds (Private → Public)

Move funds from shielded pool back to transparent:

```bash
# Unshield 300 LYDD to transparent address
libyachaind tx privacy unshield \
    300ulydd \
    --to libya1... \
    --from mykey \
    --chain-id libyachain
```

### Viewing Private Balance

```bash
# View your shielded balance (requires viewing key)
libyachaind query privacy balance <address> \
    --viewing-key <your-viewing-key>

# View shielded pool total (public information)
libyachaind query privacy pool-balance
```

## Advanced Features

### Selective Disclosure

Share transaction details for compliance without revealing everything:

```bash
# Generate disclosure proof for specific transaction
libyachaind tx privacy disclose <tx-hash> \
    --to-address <auditor-address> \
    --from mykey

# Auditor can verify with your viewing key
libyachaind query privacy verify-disclosure <proof> \
    --viewing-key <provided-viewing-key>
```

### Multi-Currency Privacy

```bash
# Shield multiple currencies
libyachaind tx privacy shield \
    1000ulydd,500ulydc,100uucbl \
    --from mykey

# Private transfer mixing currencies
libyachaind tx privacy transfer \
    --to <shielded-address> \
    --amount 300ulydd,200ulydc \
    --from mykey
```

### Memo Field

Attach encrypted messages to private transactions:

```bash
libyachaind tx privacy transfer \
    --to <shielded-address> \
    --amount 100ulydd \
    --memo "Payment for services" \
    --from mykey

# Memo is encrypted and only readable by recipient
```

## Technical Details

### Zero-Knowledge Proofs

LibyaChain uses **zk-SNARKs** (Zero-Knowledge Succinct Non-Interactive Arguments of Knowledge):

- **Groth16**: High-performance proving system
- **Circuit**: Custom circuit for transaction validation
- **Trusted Setup**: Multi-party computation for security

### Note Structure

Each private note contains:

```
Note {
    value:      Amount (hidden)
    denom:      Token type (hidden)
    rcm:        Randomness (unique per note)
    owner:      Shielded public key (hidden)
    commitment: Hash of above fields (public)
}
```

### Nullifier Mechanism

Prevents double-spending:

```
Nullifier = Hash(note_commitment, spending_key)
```

- Computed when spending a note
- Publicly revealed (but unlinkable to specific note)
- Prevents same note from being spent twice

### Merkle Tree

All commitments are stored in an incremental merkle tree:

- **Depth**: 32 levels
- **Leaves**: Note commitments
- **Root**: Used in zk-SNARK proofs
- **Witnesses**: Prove note existence without revealing which note

## Security Considerations

### Anonymity Set

Privacy improves with more users:
- Larger shielded pool = better privacy
- More transactions = harder to trace
- Mixing currencies increases anonymity

### Viewing Keys

Three types of keys:

1. **Spending Key**: Full control (keep secret!)
2. **Viewing Key**: See incoming/outgoing transactions (for auditing)
3. **Shielded Public Key**: Receive private funds (can share)

### Best Practices

1. **Never share spending keys**
2. **Backup keys securely** (encrypted, offline)
3. **Use unique addresses** for different purposes
4. **Mix amounts** when possible
5. **Wait for confirmations** before spending notes
6. **Use memo field** for payment references

### Regulatory Compliance

Built-in compliance features:

- **Selective Disclosure**: Prove transaction details to authorities
- **Viewing Keys**: Share with authorized auditors
- **Transaction Metadata**: Timestamp, block height (public)
- **Opt-in Transparency**: Can use transparent addresses

## Performance

### Gas Costs

| Operation | Gas Cost | Time |
|-----------|----------|------|
| Shield | ~100,000 | ~2s |
| Unshield | ~150,000 | ~3s |
| Private Transfer | ~200,000 | ~5s |
| Generate Proof | N/A (client-side) | ~10s |

### Limits

- **Max notes per tx**: 4 inputs, 4 outputs
- **Min shielded amount**: 1000 base units
- **Proof generation**: Requires 4GB RAM
- **Shielded pool reserve**: Minimum 1M tokens

## Use Cases

### Personal Privacy

```bash
# Salary payment - employer to employee (private)
libyachaind tx privacy transfer \
    --to employee-shielded-key \
    --amount 5000ulydd \
    --memo "Monthly salary" \
    --from company
```

### Business Transactions

```bash
# Private B2B payment
libyachaind tx privacy transfer \
    --to supplier-shielded-key \
    --amount 50000ulydd \
    --memo "Invoice #12345" \
    --from company
```

### Cross-Border Payments

```bash
# International remittance with privacy
libyachaind tx privacy transfer \
    --to recipient-shielded-key \
    --amount 1000ulydd \
    --memo "Family support" \
    --from sender
```

## Privacy vs. IBC

When using IBC with privacy:

1. **Shield first** on source chain
2. **Transfer privately** on source chain
3. **Unshield** (if needed) before IBC transfer
4. **Re-shield** on destination chain

```bash
# Private cross-chain workflow
libyachaind tx privacy shield 1000ulydd --from alice
libyachaind tx ibc-transfer transfer transfer <channel> <recipient> 1000ulydd
# On destination:
destinationd tx privacy shield 1000ulydd --from recipient
```

## Comparison with Other Privacy Solutions

| Feature | LibyaChain | Monero | Zcash | Ethereum + Tornado |
|---------|------------|--------|-------|-------------------|
| Privacy by default | Optional | Yes | Optional | Optional |
| Multi-currency | Yes (3) | No | No | Multiple deployments |
| Regulatory compliance | Built-in | No | Limited | No |
| IBC compatible | Yes | No | No | No |
| EVM compatible | Yes | No | No | Yes |
| zk-SNARK based | Yes | No | Yes | Yes |
| Trusted setup | Yes | No | Yes | Yes |

## Development

### Testing Privacy Features

```bash
# Test shielding
libyachaind tx privacy shield 1000ulydd --from test1 --keyring-backend test

# Test private transfer
libyachaind tx privacy transfer \
    --to $(libyachaind keys show test2 -a --keyring-backend test) \
    --amount 500ulydd \
    --from test1 \
    --keyring-backend test

# Query shielded balance
libyachaind query privacy balance \
    $(libyachaind keys show test1 -a --keyring-backend test) \
    --viewing-key $(libyachaind keys export-viewing-key test1)
```

### Monitoring

```bash
# Monitor shielded pool
libyachaind query privacy pool-balance

# List recent shielded transactions (only metadata visible)
libyachaind query privacy transactions --limit 10

# Check nullifier status
libyachaind query privacy nullifier <nullifier-hash>
```

## Troubleshooting

### Common Issues

**Error: Insufficient shielded balance**
```bash
# Solution: Check actual shielded balance
libyachaind query privacy balance <address> --viewing-key <key>
```

**Error: Nullifier already used**
```bash
# Solution: Note was already spent, sync your wallet
libyachaind query privacy sync --from <address>
```

**Error: Proof verification failed**
```bash
# Solution: Ensure proof generation completed successfully
# Check client logs for proof generation errors
```

## Future Enhancements

- [ ] Hardware wallet support for shielded keys
- [ ] Mobile wallet integration
- [ ] Improved proof generation speed
- [ ] Recursive SNARKs for better scalability
- [ ] Threshold decryption for multi-sig
- [ ] Payment channels with privacy
- [ ] Anonymous credentials
- [ ] Private smart contract calls

## Resources

- **Privacy Module Code**: `/x/privacy`
- **Proof System**: Groth16 via bellman
- **Circuit**: `/x/privacy/circuit`
- **Research Paper**: [Coming soon]

## Support

For privacy-related questions:
- GitHub Issues: Tag with `privacy`
- Discord: #privacy channel
- Email: privacy@libyachain.net

**Remember**: Privacy is a right, not a crime. Use these features responsibly.
