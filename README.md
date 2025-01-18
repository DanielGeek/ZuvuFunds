# ZuvuFunds Smart Contract Project

## Project Overview
ZuvuFunds is a smart contract implementation for Zuvu's decentralized ecosystem that handles governance functionality and automated transaction features. The project focuses on providing secure and efficient fund distribution mechanisms with delegated voting capabilities.

## Technical Specifications

### Core Features
1. Fund Distribution (`forward_funds`)
   - Token distribution based on predefined splits
   - Validation of distribution percentages
   - Secure transfer mechanisms
   
2. Governance System
   - Delegated voting mechanism
   - Median-weighted distribution
   - Proposal creation and execution
   
3. Security Features
   - Access control
   - Reentrancy protection
   - Input validation
   - Event emission for transparency

## Project Plan

### Phase 1: Smart Contract Development (2 hours)
- [x] Basic contract structure
- [x] Implementation of `forward_funds`
- [x] Basic testing setup
- [ ] Governance implementation
- [ ] Advanced security features

### Phase 2: Testing & Security (2 hours)
- [x] Unit tests for `forward_funds`
- [ ] Governance system tests
- [ ] Security feature tests
- [ ] Gas optimization
- [ ] Documentation

### Phase 3: Documentation & Deployment (1 hour)
- [ ] NatSpec documentation
- [ ] Deployment scripts
- [ ] User guide
- [ ] Technical documentation

## Technical Stack
- **Framework**: Foundry
- **Language**: Solidity ^0.8.0
- **Libraries**: 
  - OpenZeppelin Contracts (ERC20, Access Control)
  - Forge Standard Library (Testing)

## Development Setup

### Prerequisites
- Foundry toolkit
- Git
- Solidity compiler ^0.8.0

### Build & Test Instructions

```shell
# Install dependencies
forge install

# Build contracts
forge build

# Run tests
forge test

# Format code
forge fmt

# Check gas usage
forge snapshot
```

## Security Considerations
- Reentrancy protection
- Access control mechanisms
- Input validation
- Integer overflow protection (using Solidity ^0.8.0)
- Event emission for transparency

## Testing Strategy
1. Unit Tests
   - Individual function testing
   - Edge case validation
   - Access control verification

2. Integration Tests
   - End-to-end fund distribution
   - Governance system interaction
   - Token handling

## Foundry Framework

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

### Documentation

https://book.getfoundry.sh/

### Deploy

```shell
$ forge script script/Deploy.s.sol:DeployScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

## License
MIT
