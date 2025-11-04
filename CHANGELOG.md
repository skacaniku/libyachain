# Changelog

All notable changes to LibyaChain will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial blockchain implementation based on Cosmos SDK v0.50.11
- Three-currency system support (LYDD, LYDC, UCBL)
- Complete CLI implementation with libyachaind binary
- IBC support for cross-chain transfers
- Interchain Accounts (ICA) integration
- Docker and docker-compose configuration
- Development scripts for single and multi-node testnets
- Comprehensive developer documentation
- GitHub Actions CI/CD workflows
- Genesis configuration templates
- Custom address prefixes (libya, libyavaloper, libyavalcons)

### Module Integration
- Auth module for account management
- Bank module with multi-currency support
- Staking module with LYDD as bond denomination
- Governance module with multi-currency deposits
- Distribution module for rewards
- Slashing module for validator penalties
- Mint module for LYDD inflation
- Evidence module for misbehavior handling
- Crisis module for invariant checking
- Upgrade module for chain upgrades
- Fee grant module for fee allowances
- IBC Core for cross-chain communication
- IBC Transfer for token transfers
- IBC Fee middleware
- Capability module for IBC
- Params module for parameter management
- Consensus module for consensus params
- Vesting module for account vesting

### Development Tools
- Makefile with build, test, and lint targets
- Single-node testnet initialization script
- Multi-node (4-node) testnet setup script
- Docker image for containerized deployment
- Docker Compose configuration for easy setup

### Documentation
- Comprehensive README.md
- Developer guide (DEVELOPERS.md)
- Contributing guidelines (CONTRIBUTING.md)
- GitHub issue templates
- API documentation structure

## [0.1.0] - 2024-11-04

### Added
- Initial project setup
- Core blockchain architecture
- Three-currency ecosystem design
- Project structure and organization
- Apache 2.0 license

---

## Version History

### Version Naming Convention

- **v0.x.x**: Development/testnet versions
- **v1.x.x**: Mainnet-ready versions
- **v2.x.x**: Major upgrades with breaking changes

### Upgrade Policy

- **Major versions**: May include breaking changes
- **Minor versions**: Backwards-compatible new features
- **Patch versions**: Backwards-compatible bug fixes

### Support Policy

- **Latest version**: Full support
- **Previous major version**: Security updates only
- **Older versions**: No support

---

## Release Notes Template

When creating a new release, use the following template:

```markdown
## [Version] - YYYY-MM-DD

### Added
- New features

### Changed
- Changes to existing functionality

### Deprecated
- Features marked for removal

### Removed
- Removed features

### Fixed
- Bug fixes

### Security
- Security improvements

### Breaking Changes
- List all breaking changes with migration guide
```

---

## Upgrade Guide

### From v0.x to v1.0

Upgrading from testnet to mainnet:

1. **Backup your data**
   ```bash
   cp -r ~/.libyachaind ~/.libyachaind.backup
   ```

2. **Stop the node**
   ```bash
   pkill libyachaind
   ```

3. **Download new binary**
   ```bash
   wget https://github.com/skacaniku/libyachain/releases/download/v1.0.0/libyachaind
   chmod +x libyachaind
   sudo mv libyachaind /usr/local/bin/
   ```

4. **Export state**
   ```bash
   libyachaind export > genesis_export.json
   ```

5. **Update genesis**
   ```bash
   cp genesis_export.json ~/.libyachaind/config/genesis.json
   ```

6. **Restart node**
   ```bash
   libyachaind start
   ```

---

## Compatibility Matrix

| LibyaChain | Cosmos SDK | IBC-Go | CometBFT | Go  |
|------------|------------|--------|----------|-----|
| v0.1.0     | v0.50.11   | v8.5.2 | v0.38.18 | 1.21+ |

---

## Migration Guides

### State Migrations

When upgrading between versions that require state migrations:

1. Stop the node at the specified upgrade height
2. Export the state
3. Run migration script
4. Replace genesis file
5. Restart with new binary

### Genesis Migrations

Instructions for migrating genesis files between versions will be provided with each release.

---

## Known Issues

### v0.1.0

No known issues in the initial release.

---

## Roadmap

### v0.2.0 (Planned)
- Custom governance module for multi-currency proposals
- Enhanced treasury management
- Policy module for currency controls
- Faucet integration
- Explorer backend API

### v0.3.0 (Planned)
- Smart contract support (CosmWasm)
- Advanced staking features
- Cross-chain bridges
- Mobile wallet integration
- Hardware wallet support

### v1.0.0 (Mainnet)
- Full security audit
- Production-ready features
- Comprehensive monitoring
- High-availability setup
- Disaster recovery procedures

---

For more details on each release, visit the [releases page](https://github.com/skacaniku/libyachain/releases).
