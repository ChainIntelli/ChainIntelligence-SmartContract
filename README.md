# ChainIntelligence Smart Contract

On-chain check-in functionality built with Foundry. Uses UUPS upgradeable proxy pattern with OpenZeppelin contracts.

## Overview

This project implements a secure, upgradeable check-in smart contract for EVM-compatible chains. Users can perform daily check-ins through their wallets, with all records stored on-chain.

### Features

- **UUPS Upgradeable**: Proxy pattern for seamless contract upgrades
- **Security**: ReentrancyGuard, Pausable, same-block replay protection
- **On-chain Records**: All check-ins recorded via events for off-chain analysis
- **Gas Efficient**: Optimized storage layout for minimal gas consumption

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)

## Quick Start

```bash
# Install dependencies
forge install

# Build
make build

# Run tests
make test

# Run all tests with gas report
make test-all
```

## Project Structure

```
├── src/
│   ├── CheckIn.sol              # Main contract (UUPS upgradeable)
│   └── interfaces/
│       └── ICheckIn.sol         # Interface definition
├── test/
│   ├── CheckIn.t.sol            # Unit tests
│   ├── CheckIn.upgrade.t.sol    # Upgrade tests
│   └── CheckIn.gas.t.sol        # Gas benchmarks
├── script/
│   ├── Deploy.s.sol             # Deployment script
│   ├── Upgrade.s.sol            # Upgrade script
│   └── create-keystore.sh       # Keystore creation utility
├── Makefile                     # Build & test commands
└── foundry.toml                 # Foundry configuration
```

## Deployment

### Create Keystore

```bash
make create-keystore
```

### Deploy to BSC Testnet

```bash
make deploy-bsc-test
```

### Upgrade Contract

```bash
PROXY_ADDRESS=<deployed_proxy> make upgrade-bsc-test
```

## License

MIT
