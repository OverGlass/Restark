# Restarke

An automated smart contract for Starknet that enables any staker to claim and restake their rewards in a single transaction.

## Overview

Restarke is a permissionless Cairo smart contract that automates the staking rewards compounding workflow. Any node runner or staker can use this single deployed contract to:

1. **Claim rewards** from the Starknet staking contract
2. **Approve** the claimed STARK tokens to the staking contract
3. **Increase stake** by restaking all claimed rewards

All in one transaction, for any staker address!

## Features

- ✅ **Permissionless**: Any staker can use the same deployed contract
- ✅ **Self-Service**: Connect wallet and restake with one click
- ✅ **Batch Operations**: Restake for multiple addresses in one transaction
- ✅ **Automated Restaking**: Single function call for the entire workflow
- ✅ **Upgradeable**: Built with OpenZeppelin's upgradeable pattern
- ✅ **Access Control**: Owner-only functions for contract management
- ✅ **Event Logging**: Detailed events for tracking all operations
- ✅ **Emergency Recovery**: Ability to withdraw tokens sent by mistake

## Contract Addresses

The contract interacts with the following Starknet mainnet contracts:

- **Staking Contract**: `0x00ca1702e64c81d9a07b86bd2c540188d92a2c73cf5cc0e508d949015e7e84a7`
- **STARK Token**: `0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d`

## Installation

### Prerequisites

- [Scarb](https://docs.swmansion.com/scarb/) - Cairo package manager
- [Starkli](https://github.com/xJonathanLEI/starkli) - Starknet CLI tool
- Node.js (optional, for automation scripts or dapp)

### Setup

1. Clone the repository:

```bash
git clone https://github.com/yourusername/restarke.git
cd restarke
```

2. Build the contract:

```bash
cd contracts
scarb build
```

## Deployment

### Using the deployment script:

```bash
cd scripts
chmod +x deploy.sh

# Deploy to mainnet with account file
./deploy.sh --network mainnet --account ~/.starkli/account.json --private-key $PRIVATE_KEY

# Deploy to testnet
./deploy.sh --network testnet --account ~/.starkli/account.json --private-key $PRIVATE_KEY
```

### Manual deployment:

```bash
starkli deploy \
    --rpc https://starknet-mainnet.public.blastapi.io \
    --account <YOUR_ACCOUNT_FILE> \
    --keystore <YOUR_KEYSTORE_FILE> \
    ./target/dev/restarke_Restarke.sierra.json \
    <OWNER_ADDRESS> \
    0x00ca1702e64c81d9a07b86bd2c540188d92a2c73cf5cc0e508d949015e7e84a7 \
    0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
```

## Usage

### For Dapp Users (Coming Soon)

Simply:

1. Connect your Starknet wallet
2. Click "Restake Rewards"
3. Approve the transaction
4. Done! Your rewards are claimed and restaked

### For Developers

#### Restake for Your Own Address

```bash
starkli invoke \
    --rpc https://starknet-mainnet.public.blastapi.io \
    --account <YOUR_ACCOUNT_FILE> \
    --keystore <YOUR_KEYSTORE_FILE> \
    <CONTRACT_ADDRESS> \
    execute_auto_restake_self
```

#### Restake for a Specific Address

```bash
starkli invoke \
    --rpc https://starknet-mainnet.public.blastapi.io \
    --account <YOUR_ACCOUNT_FILE> \
    --keystore <YOUR_KEYSTORE_FILE> \
    <CONTRACT_ADDRESS> \
    execute_auto_restake \
    <STAKER_ADDRESS>
```

#### Batch Restake for Multiple Addresses

```bash
starkli invoke \
    --rpc https://starknet-mainnet.public.blastapi.io \
    --account <YOUR_ACCOUNT_FILE> \
    --keystore <YOUR_KEYSTORE_FILE> \
    <CONTRACT_ADDRESS> \
    execute_auto_restake_batch \
    [<STAKER_ADDRESS_1>, <STAKER_ADDRESS_2>, <STAKER_ADDRESS_3>]
```

### View Configuration

```bash
starkli call \
    --rpc https://starknet-mainnet.public.blastapi.io \
    <CONTRACT_ADDRESS> \
    get_config
```

Returns: `(staking_contract, stark_token)`

### Update Configuration (Owner Only)

```bash
starkli invoke \
    --rpc https://starknet-mainnet.public.blastapi.io \
    --account <OWNER_ACCOUNT_FILE> \
    --keystore <OWNER_KEYSTORE_FILE> \
    <CONTRACT_ADDRESS> \
    update_contracts \
    <NEW_STAKING_CONTRACT> \
    <NEW_STARK_TOKEN>
```

## Frontend Integration

### Example using starknet.js:

```javascript
import { Contract, Provider, Account } from "starknet";

// Connect to Starknet
const provider = new Provider({ sequencer: { network: "mainnet-alpha" } });

// User connects their wallet (e.g., using get-starknet)
const account = await connect();

// Initialize Restarke contract
const restarkeContract = new Contract(
  restarkeAbi,
  RESTARKE_CONTRACT_ADDRESS,
  provider,
);

// Connect contract to user's account
restarkeContract.connect(account);

// Execute restake for connected wallet
async function restakeRewards() {
  try {
    const tx = await restarkeContract.execute_auto_restake_self();
    await provider.waitForTransaction(tx.transaction_hash);
    console.log("Restaking successful!");
  } catch (error) {
    console.error("Restaking failed:", error);
  }
}
```

## Automation

### For Individual Stakers

Create a simple cron job:

```bash
#!/bin/bash
# restake.sh
starkli invoke \
    --rpc https://starknet-mainnet.public.blastapi.io \
    --account ~/.starkli/account.json \
    --keystore ~/.starkli/keystore.json \
    <CONTRACT_ADDRESS> \
    execute_auto_restake_self
```

### For Service Providers

Use the keeper bot in the `keeper` directory to automate restaking for multiple addresses.

## Security Considerations

1. **Permissionless Design**: Anyone can call the restake functions - no trust required
2. **No Fund Custody**: The contract never holds funds, only forwards them
3. **Access Control**: Only the owner can update contract configurations
4. **Event Transparency**: All operations emit detailed events
5. **Upgradeable**: Can be improved without redeployment

## Events

### AutoRestakeExecuted

Emitted when restaking completes successfully:

- `staker_address`: Address whose rewards were restaked
- `executor`: Address that called the function
- `rewards_claimed`: Amount of STARK tokens claimed
- `amount_restaked`: Amount of STARK tokens restaked
- `timestamp`: Block timestamp

### ContractsUpdated

Emitted when contract addresses are updated:

- `staking_contract`: New staking contract address
- `stark_token`: New STARK token address

## Gas Optimization

The contract is optimized for efficiency:

- Single transaction for the entire workflow
- Minimal storage operations
- Direct contract calls without intermediate transfers
- Batch operations for multiple addresses

## Roadmap

- [x] Core restaking functionality
- [x] Permissionless design for any staker
- [x] Batch operations support
- [ ] Web dapp with wallet connection
- [ ] Mobile app support
- [ ] Analytics dashboard
- [ ] Integration with keeper networks
- [ ] Multi-protocol support

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Disclaimer

This smart contract is provided as-is. Users should audit the code and understand the risks before using it with real funds. The authors are not responsible for any losses incurred through the use of this contract.
