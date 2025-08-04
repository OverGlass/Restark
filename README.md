# Restarke

An automated smart contract for Starknet that handles the complete workflow of claiming staking rewards and automatically restaking them to compound returns.

## Overview

Restarke is a Cairo smart contract that automates the following workflow:

1. **Claim rewards** from the Starknet staking contract
2. **Approve** the claimed STARK tokens to the staking contract
3. **Increase stake** by restaking all claimed rewards

This eliminates the need for manual intervention and ensures your staking rewards are continuously compounded.

## Features

- ✅ **Automated Restaking**: Single function call to execute the entire claim → approve → restake workflow
- ✅ **Upgradeable**: Built with OpenZeppelin's upgradeable pattern for future improvements
- ✅ **Access Control**: Owner-only functions for configuration updates and emergency withdrawals
- ✅ **Event Logging**: Detailed events for tracking all restaking operations
- ✅ **Emergency Recovery**: Ability to withdraw tokens sent to the contract by mistake
- ✅ **Configurable**: Update staking contract, token, and staker addresses without redeployment

## Contract Addresses

The contract interacts with the following Starknet mainnet contracts:

- **Staking Contract**: `0x00ca1702e64c81d9a07b86bd2c540188d92a2c73cf5cc0e508d949015e7e84a7`
- **STARK Token**: `0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d`
- **Default Staker Address**: `0x03912BF7ee089d66bf3D1e25Af6b7458bdb4e4A17DbAd357CBcFD544830F79ea`

## Installation

### Prerequisites

- [Scarb](https://docs.swmansion.com/scarb/) - Cairo package manager
- [Starkli](https://github.com/xJonathanLEI/starkli) - Starknet CLI tool
- Node.js (optional, for automation scripts)

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
    0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d \
    0x03912BF7ee089d66bf3D1e25Af6b7458bdb4e4A17DbAd357CBcFD544830F79ea
```

## Usage

### Execute Auto-Restake

To execute the complete restaking workflow:

```bash
starkli invoke \
    --rpc https://starknet-mainnet.public.blastapi.io \
    --account <YOUR_ACCOUNT_FILE> \
    --keystore <YOUR_KEYSTORE_FILE> \
    <CONTRACT_ADDRESS> \
    execute_auto_restake
```

This single call will:

1. Claim all pending rewards for the configured staker address
2. Check the STARK token balance received
3. Approve the staking contract to spend the tokens
4. Increase the stake with the full amount

### View Configuration

To check the current contract configuration:

```bash
starkli call \
    --rpc https://starknet-mainnet.public.blastapi.io \
    <CONTRACT_ADDRESS> \
    get_config
```

Returns: `(staking_contract, stark_token, staker_address)`

### Update Configuration (Owner Only)

To update the contract addresses:

```bash
starkli invoke \
    --rpc https://starknet-mainnet.public.blastapi.io \
    --account <OWNER_ACCOUNT_FILE> \
    --keystore <OWNER_KEYSTORE_FILE> \
    <CONTRACT_ADDRESS> \
    update_contracts \
    <NEW_STAKING_CONTRACT> \
    <NEW_STARK_TOKEN> \
    <NEW_STAKER_ADDRESS>
```

### Emergency Withdrawal (Owner Only)

To withdraw tokens sent to the contract by mistake:

```bash
starkli invoke \
    --rpc https://starknet-mainnet.public.blastapi.io \
    --account <OWNER_ACCOUNT_FILE> \
    --keystore <OWNER_KEYSTORE_FILE> \
    <CONTRACT_ADDRESS> \
    emergency_withdraw \
    <TOKEN_ADDRESS> \
    <RECIPIENT_ADDRESS> \
    <AMOUNT>
```

## Automation

### Option 1: Cron Job

Create a script to call `execute_auto_restake` periodically:

```bash
#!/bin/bash
# restake.sh
starkli invoke \
    --rpc https://starknet-mainnet.public.blastapi.io \
    --account ~/.starkli/account.json \
    --keystore ~/.starkli/keystore.json \
    <CONTRACT_ADDRESS> \
    execute_auto_restake
```

Add to crontab (daily at 2 AM):

```bash
0 2 * * * /path/to/restake.sh >> /var/log/restake.log 2>&1
```

### Option 2: Keeper Bot

A Node.js keeper bot example is provided in the `keeper` directory for more sophisticated automation with error handling and monitoring.

## Security Considerations

1. **Access Control**: Only the owner can update configurations and perform emergency withdrawals
2. **Upgradeable**: The contract can be upgraded by the owner to fix bugs or add features
3. **No Token Storage**: The contract immediately restakes any tokens it receives
4. **Event Logging**: All operations emit events for transparency and monitoring

## Events

### AutoRestakeExecuted

Emitted when the auto-restake workflow completes successfully:

- `executor`: Address that called the function
- `rewards_claimed`: Amount of STARK tokens claimed
- `amount_restaked`: Amount of STARK tokens restaked
- `timestamp`: Block timestamp

### ContractsUpdated

Emitted when contract addresses are updated:

- `staking_contract`: New staking contract address
- `stark_token`: New STARK token address
- `staker_address`: New staker address

## Testing

Run the test suite:

```bash
cd contracts
scarb test
```

## Gas Optimization

The contract is optimized for gas efficiency:

- Single transaction for the entire workflow
- Minimal storage operations
- Direct contract calls without intermediate transfers

## Future Improvements

- [ ] Support for multiple staker addresses
- [ ] Configurable restaking thresholds
- [ ] Integration with keeper networks
- [ ] Advanced compounding strategies
- [ ] Multi-signature support for owner actions

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Disclaimer

This smart contract is provided as-is. Users should audit the code and understand the risks before using it with real funds. The authors are not responsible for any losses incurred through the use of this contract.
