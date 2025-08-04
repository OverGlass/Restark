#!/bin/bash

# Restarke Deployment Script
# This script deploys the Restarke contract to Starknet

# Exit on error
set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Contract addresses from your requirements
STAKING_CONTRACT="0x00ca1702e64c81d9a07b86bd2c540188d92a2c73cf5cc0e508d949015e7e84a7"
STARK_TOKEN="0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d"
STAKER_ADDRESS="0x03912BF7ee089d66bf3D1e25Af6b7458bdb4e4A17DbAd357CBcFD544830F79ea"

# Default values
NETWORK="mainnet"
ACCOUNT_FILE=""
PRIVATE_KEY=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --network)
            NETWORK="$2"
            shift 2
            ;;
        --account)
            ACCOUNT_FILE="$2"
            shift 2
            ;;
        --private-key)
            PRIVATE_KEY="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --network <network>       Network to deploy to (mainnet/testnet) [default: mainnet]"
            echo "  --account <file>          Path to account file"
            echo "  --private-key <key>       Private key for deployment"
            echo "  --help                    Show this help message"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Restarke Deployment Script${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if required tools are installed
command -v starkli >/dev/null 2>&1 || { echo -e "${RED}starkli is required but not installed. Aborting.${NC}" >&2; exit 1; }
command -v scarb >/dev/null 2>&1 || { echo -e "${RED}scarb is required but not installed. Aborting.${NC}" >&2; exit 1; }

# Build the contract
echo -e "${YELLOW}Building contract...${NC}"
cd ../contracts
scarb build

if [ $? -ne 0 ]; then
    echo -e "${RED}Build failed!${NC}"
    exit 1
fi

echo -e "${GREEN}Build successful!${NC}"

# Set RPC endpoint based on network
if [ "$NETWORK" == "mainnet" ]; then
    RPC_URL="https://starknet-mainnet.public.blastapi.io"
elif [ "$NETWORK" == "testnet" ]; then
    RPC_URL="https://starknet-sepolia.public.blastapi.io"
else
    echo -e "${RED}Invalid network: $NETWORK${NC}"
    exit 1
fi

# Deploy the contract
echo -e "${YELLOW}Deploying to $NETWORK...${NC}"
echo "Staking Contract: $STAKING_CONTRACT"
echo "STARK Token: $STARK_TOKEN"
echo "Staker Address: $STAKER_ADDRESS"
echo ""

# Get the owner address (deployer)
if [ -n "$ACCOUNT_FILE" ]; then
    OWNER_ADDRESS=$(starkli account fetch $ACCOUNT_FILE --output json | jq -r '.address')
else
    echo -e "${YELLOW}Enter the owner address (deployer):${NC}"
    read OWNER_ADDRESS
fi

# Prepare constructor arguments
CONSTRUCTOR_ARGS="$OWNER_ADDRESS $STAKING_CONTRACT $STARK_TOKEN $STAKER_ADDRESS"

# Deploy command
if [ -n "$ACCOUNT_FILE" ] && [ -n "$PRIVATE_KEY" ]; then
    DEPLOY_CMD="starkli deploy \
        --rpc $RPC_URL \
        --account $ACCOUNT_FILE \
        --private-key $PRIVATE_KEY \
        ./target/dev/restarke_Restarke.sierra.json \
        $CONSTRUCTOR_ARGS"
else
    echo -e "${YELLOW}Manual deployment required. Use the following command:${NC}"
    echo ""
    echo "starkli deploy \\"
    echo "    --rpc $RPC_URL \\"
    echo "    --account <YOUR_ACCOUNT_FILE> \\"
    echo "    --keystore <YOUR_KEYSTORE_FILE> \\"
    echo "    ./target/dev/restarke_Restarke.sierra.json \\"
    echo "    $CONSTRUCTOR_ARGS"
    echo ""
    exit 0
fi

# Execute deployment
echo -e "${YELLOW}Executing deployment...${NC}"
DEPLOY_OUTPUT=$($DEPLOY_CMD 2>&1)
DEPLOY_EXIT_CODE=$?

if [ $DEPLOY_EXIT_CODE -ne 0 ]; then
    echo -e "${RED}Deployment failed!${NC}"
    echo "$DEPLOY_OUTPUT"
    exit 1
fi

# Extract contract address from output
CONTRACT_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep -oP 'Contract deployed at: \K0x[a-fA-F0-9]+')

if [ -z "$CONTRACT_ADDRESS" ]; then
    echo -e "${RED}Failed to extract contract address from deployment output${NC}"
    echo "$DEPLOY_OUTPUT"
    exit 1
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment Successful!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "Contract Address: ${GREEN}$CONTRACT_ADDRESS${NC}"
echo ""
echo "Configuration:"
echo "  Owner: $OWNER_ADDRESS"
echo "  Staking Contract: $STAKING_CONTRACT"
echo "  STARK Token: $STARK_TOKEN"
echo "  Staker Address: $STAKER_ADDRESS"
echo ""

# Save deployment info
DEPLOYMENT_FILE="deployment_${NETWORK}_$(date +%Y%m%d_%H%M%S).json"
cat > $DEPLOYMENT_FILE << EOF
{
    "network": "$NETWORK",
    "contractAddress": "$CONTRACT_ADDRESS",
    "deploymentTime": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "configuration": {
        "owner": "$OWNER_ADDRESS",
        "stakingContract": "$STAKING_CONTRACT",
        "starkToken": "$STARK_TOKEN",
        "stakerAddress": "$STAKER_ADDRESS"
    }
}
EOF

echo -e "Deployment info saved to: ${GREEN}$DEPLOYMENT_FILE${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Verify the contract on Voyager"
echo "2. Test the execute_auto_restake function"
echo "3. Set up automation (cron job or keeper bot) to call execute_auto_restake periodically"
