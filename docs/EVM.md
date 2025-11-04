# 🔷 EVM Compatibility

LibyaChain is fully compatible with the Ethereum Virtual Machine (EVM), allowing developers to deploy Solidity smart contracts alongside native Cosmos SDK modules.

## Overview

LibyaChain integrates **Ethermint**, providing:

- **100% EVM Compatibility**: Deploy any Ethereum smart contract
- **Web3 Support**: Use MetaMask, Hardhat, Truffle, Remix
- **Ethereum JSON-RPC**: Standard Ethereum RPC endpoints
- **Cosmos Interoperability**: Access Cosmos modules from smart contracts
- **Multi-Currency**: Use LYDD, LYDC, or UCBL for gas

## Key Features

### Ethereum Compatibility

- ✅ Solidity 0.8.x support
- ✅ EVM opcodes (London, Shanghai forks)
- ✅ Web3.js and ethers.js libraries
- ✅ Ethereum transaction format (EIP-155, EIP-1559)
- ✅ Event logs and filters
- ✅ eth_call and eth_estimateGas
- ✅ Contract verification

### Cosmos Integration

- ✅ Access bank module from contracts
- ✅ IBC transfers from smart contracts
- ✅ Governance proposals via contracts
- ✅ Staking from contracts
- ✅ Privacy features accessible

## Quick Start

### MetaMask Setup

1. **Add LibyaChain Network**

Click "Add Network" in MetaMask and enter:

```
Network Name: LibyaChain
RPC URL: https://evm.libyachain.net
Chain ID: 10100
Currency Symbol: LYDD
Block Explorer: https://explorer.libyachain.net
```

2. **Get Testnet Funds**

Visit the faucet: https://faucet.libyachain.net

### Deploy with Remix

1. Open [Remix IDE](https://remix.ethereum.org)
2. Create/import your Solidity contract
3. Select "Injected Provider - MetaMask"
4. Connect to LibyaChain network
5. Deploy!

### Deploy with Hardhat

```bash
# Install Hardhat
npm install --save-dev hardhat

# Create Hardhat project
npx hardhat init

# Configure hardhat.config.js
module.exports = {
  networks: {
    libyachain: {
      url: "https://evm.libyachain.net",
      chainId: 10100,
      accounts: [process.env.PRIVATE_KEY],
      gasPrice: 1000000000 // 1 gwei in ulydd
    }
  },
  solidity: "0.8.20"
};

# Deploy
npx hardhat run scripts/deploy.js --network libyachain
```

### Deploy with Foundry

```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Create project
forge init my-project
cd my-project

# Deploy
forge create --rpc-url https://evm.libyachain.net \
    --private-key $PRIVATE_KEY \
    --constructor-args "Hello" \
    src/MyContract.sol:MyContract
```

## Example Contracts

### Hello World

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract HelloLibya {
    string public message = "Welcome to LibyaChain!";

    function setMessage(string memory _message) public {
        message = _message;
    }

    function getMessage() public view returns (string memory) {
        return message;
    }
}
```

### ERC20 Token

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LibyanToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("Libyan Token", "LBT") {
        _mint(msg.sender, initialSupply);
    }
}
```

### Multi-Currency Payment

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IBank {
    function balanceOf(address account, string memory denom) external view returns (uint256);
    function transfer(address to, uint256 amount, string memory denom) external returns (bool);
}

contract MultiCurrencyPayment {
    IBank public bank = IBank(0x0000000000000000000000000000000000000001);

    // Accept payment in LYDD, LYDC, or UCBL
    function pay(string memory currency, uint256 amount) public {
        require(
            keccak256(bytes(currency)) == keccak256("ulydd") ||
            keccak256(bytes(currency)) == keccak256("ulydc") ||
            keccak256(bytes(currency)) == keccak256("uucbl"),
            "Currency not supported"
        );

        require(bank.transfer(address(this), amount, currency), "Transfer failed");

        // Process payment logic here
    }
}
```

### Cross-Chain Bridge Contract

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IBridge {
    function deposit(string memory destChain, address destAddress, uint256 amount) external payable;
    function withdraw(string memory sourceChain, bytes memory proof) external;
}

contract CrossChainDApp {
    IBridge public bridge = IBridge(0x0000000000000000000000000000000000000002);

    function bridgeToEthereum(address ethAddress, uint256 amount) public payable {
        bridge.deposit{value: amount}("ethereum", ethAddress, amount);
    }

    function bridgeFromEthereum(bytes memory proof) public {
        bridge.withdraw("ethereum", proof);
    }
}
```

## Precompiled Contracts

LibyaChain provides custom precompiled contracts at fixed addresses:

| Address | Contract | Description |
|---------|----------|-------------|
| `0x0000...0001` | Bank | Access native tokens (LYDD, LYDC, UCBL) |
| `0x0000...0002` | Bridge | Cross-chain transfers |
| `0x0000...0003` | Staking | Delegate to validators |
| `0x0000...0004` | Governance | Create/vote on proposals |
| `0x0000...0005` | Privacy | Shield/unshield transactions |
| `0x0000...0006` | IBC | IBC transfers |

### Using Precompiles

```solidity
// Bank Precompile
interface IBank {
    function balanceOf(address account, string memory denom) external view returns (uint256);
    function transfer(address to, uint256 amount, string memory denom) external returns (bool);
    function allowance(address owner, address spender, string memory denom) external view returns (uint256);
    function approve(address spender, uint256 amount, string memory denom) external returns (bool);
}

// Staking Precompile
interface IStaking {
    function delegate(address validator, uint256 amount) external returns (bool);
    function undelegate(address validator, uint256 amount) external returns (bool);
    function rewards(address delegator) external view returns (uint256);
    function claimRewards() external returns (uint256);
}

// Privacy Precompile
interface IPrivacy {
    function shield(uint256 amount, string memory denom) external returns (bytes32 commitment);
    function unshield(bytes memory proof, address to, uint256 amount) external returns (bool);
}
```

## Gas & Fees

### Gas Price

Gas prices in LibyaChain can be paid in any native currency:

```javascript
// Using ethers.js
const tx = await contract.myFunction({
  gasPrice: ethers.utils.parseUnits("1", "gwei"), // 1 gwei in ulydd
  gasLimit: 200000
});

// Or use EIP-1559
const tx = await contract.myFunction({
  maxFeePerGas: ethers.utils.parseUnits("2", "gwei"),
  maxPriorityFeePerGas: ethers.utils.parseUnits("1", "gwei"),
  gasLimit: 200000
});
```

### Fee Currencies

You can pay fees in LYDD, LYDC, or UCBL:

```bash
# Set fee currency in MetaMask transaction
# Or in Hardhat:
const tx = await contract.myFunction({
  gasPrice: 1000000000, // 1 gwei
  feeCurrency: "ulydd"  // or "ulydc" or "uucbl"
});
```

## Development Tools

### Hardhat

```bash
npm install --save-dev @nomiclabs/hardhat-ethers ethers

# hardhat.config.js
require("@nomiclabs/hardhat-ethers");

module.exports = {
  solidity: "0.8.20",
  networks: {
    libyachain: {
      url: "https://evm.libyachain.net",
      chainId: 10100,
      accounts: {
        mnemonic: process.env.MNEMONIC
      }
    }
  }
};

# Deploy
npx hardhat run scripts/deploy.js --network libyachain

# Verify
npx hardhat verify --network libyachain <contract-address> <constructor-args>
```

### Truffle

```bash
npm install -g truffle

# truffle-config.js
module.exports = {
  networks: {
    libyachain: {
      provider: () => new HDWalletProvider(
        process.env.MNEMONIC,
        "https://evm.libyachain.net"
      ),
      network_id: 10100,
      gas: 8000000,
      gasPrice: 1000000000
    }
  },
  compilers: {
    solc: {
      version: "0.8.20"
    }
  }
};

# Deploy
truffle migrate --network libyachain
```

### Web3.js

```javascript
const Web3 = require('web3');
const web3 = new Web3('https://evm.libyachain.net');

// Get balance
const balance = await web3.eth.getBalance(address);

// Send transaction
const tx = await web3.eth.sendTransaction({
  from: from Address,
  to: toAddress,
  value: web3.utils.toWei('1', 'ether'),
  gas: 21000,
  gasPrice: '1000000000'
});

// Interact with contract
const contract = new web3.eth.Contract(abi, contractAddress);
const result = await contract.methods.myFunction().call();
```

### Ethers.js

```javascript
const ethers = require('ethers');

// Connect to LibyaChain
const provider = new ethers.providers.JsonRpcProvider(
  'https://evm.libyachain.net'
);

// Create wallet
const wallet = new ethers.Wallet(privateKey, provider);

// Deploy contract
const factory = new ethers.ContractFactory(abi, bytecode, wallet);
const contract = await factory.deploy(...constructorArgs);
await contract.deployed();

// Interact with contract
const tx = await contract.myFunction(arg1, arg2);
await tx.wait();
```

## Testing

### Local Development

```bash
# Start local EVM node
libyachaind start --evm.enable

# EVM endpoint: http://localhost:8545
# WebSocket: ws://localhost:8546

# Use in tests
const provider = new ethers.providers.JsonRpcProvider(
  'http://localhost:8545'
);
```

### Hardhat Tests

```javascript
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("MyContract", function () {
  it("Should deploy and interact", async function () {
    const [owner] = await ethers.getSigners();

    const Contract = await ethers.getContractFactory("MyContract");
    const contract = await Contract.deploy();
    await contract.deployed();

    expect(await contract.owner()).to.equal(owner.address);
  });
});
```

## Performance

### Benchmarks

| Metric | LibyaChain | Ethereum | BSC |
|--------|------------|----------|-----|
| Block Time | 1-2s | 12s | 3s |
| TPS | 1000+ | 15-30 | 100+ |
| Finality | 2s | 12 min | 60s |
| Gas Price | 1 gwei | 20+ gwei | 5 gwei |

### Optimizations

- Use `view` and `pure` functions when possible
- Batch transactions
- Optimize storage usage
- Use events for off-chain data
- Consider L2 patterns if needed

## Security

### Best Practices

1. **Audit Contracts**: Get professional audits
2. **Use OpenZeppelin**: Battle-tested libraries
3. **Test Thoroughly**: Unit and integration tests
4. **Handle Reentrancy**: Use ReentrancyGuard
5. **Check Overflows**: Solidity 0.8.x has built-in checks
6. **Validate Inputs**: Always sanitize user inputs

### Example: Secure Contract

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract SecureVault is ReentrancyGuard, Ownable, Pausable {
    mapping(address => uint256) public balances;

    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);

    function deposit() public payable whenNotPaused {
        require(msg.value > 0, "Amount must be > 0");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public nonReentrant whenNotPaused {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        emit Withdrawal(msg.sender, amount);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}
```

## Debugging

### Console Logs

```solidity
import "hardhat/console.sol";

contract Debug {
    function myFunction(uint256 x) public {
        console.log("x is", x);
        // ...
    }
}
```

### Tenderly Integration

```bash
# Install Tenderly CLI
npm install -g @tenderly/cli

# Login
tenderly login

# Push contracts
tenderly push --networks libyachain

# Monitor transactions
tenderly monitoring --network libyachain
```

## Ecosystem

### DeFi

- **DEX**: Uniswap V2/V3 forks
- **Lending**: Aave, Compound forks
- **Stablecoins**: Algorithmic and collateralized
- **Yield Farming**: Various strategies

### NFTs

- **Marketplaces**: OpenSea-compatible
- **Collections**: ERC721, ERC1155
- **Metaverse**: Virtual worlds

### Gaming

- **Game Assets**: NFT-based items
- **P2E**: Play-to-earn mechanics
- **On-chain Logic**: Smart contract games

## Migration from Ethereum

### Steps

1. **Test Compatibility**: Deploy on testnet
2. **Update Chain ID**: Change to 10100
3. **Adjust Gas**: Optimize for lower costs
4. **Bridge Tokens**: Use native bridges
5. **Update Frontend**: Point to LibyaChain RPC

### Differences from Ethereum

- ✅ Faster finality (2s vs 12min)
- ✅ Lower fees (up to 99% cheaper)
- ✅ Multi-currency gas payments
- ✅ Native privacy features
- ✅ IBC interoperability
- ⚠️ Different chain ID (10100)
- ⚠️ Custom precompiles

## Resources

- **EVM Endpoint**: https://evm.libyachain.net
- **WebSocket**: wss://evm.libyachain.net
- **Explorer**: https://explorer.libyachain.net
- **Faucet**: https://faucet.libyachain.net
- **Contract Verification**: https://explorer.libyachain.net/verify
- **Precompile Docs**: https://docs.libyachain.net/precompiles

## Support

For EVM-related questions:
- Discord: #evm-support
- Telegram: @libyachain_evm
- Email: evm@libyachain.net

## Examples Repository

Find more examples at:
- https://github.com/skacaniku/libyachain-evm-examples

Including:
- DeFi protocols
- NFT contracts
- Gaming contracts
- DAO implementations
- Cross-chain bridges
- Privacy-enabled contracts
