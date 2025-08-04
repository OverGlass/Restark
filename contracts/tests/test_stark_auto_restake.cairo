use starknet::{ContractAddress, contract_address_const, get_block_timestamp};
use starknet::testing::{set_caller_address, set_contract_address, set_block_timestamp};
use snforge_std::{declare, ContractClassTrait, start_prank, stop_prank, CheatTarget};
use openzeppelin::access::ownable::interface::{IOwnableDispatcher, IOwnableDispatcherTrait};
use openzeppelin::upgrades::interface::{IUpgradeableDispatcher, IUpgradeableDispatcherTrait};

use restake::interfaces::{IStarkAutoRestakeDispatcher, IStarkAutoRestakeDispatcherTrait};

// Test constants
fn OWNER() -> ContractAddress {
    contract_address_const::<'OWNER'>()
}

fn USER() -> ContractAddress {
    contract_address_const::<'USER'>()
}

fn STAKING_CONTRACT() -> ContractAddress {
    contract_address_const::<0x00ca1702e64c81d9a07b86bd2c540188d92a2c73cf5cc0e508d949015e7e84a7>()
}

fn STARK_TOKEN() -> ContractAddress {
    contract_address_const::<0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d>()
}

fn STAKER_ADDRESS() -> ContractAddress {
    contract_address_const::<0x03912BF7ee089d66bf3D1e25Af6b7458bdb4e4A17DbAd357CBcFD544830F79ea>()
}

fn ZERO_ADDRESS() -> ContractAddress {
    contract_address_const::<0>()
}

// Deploy helper
fn deploy_contract() -> ContractAddress {
    let contract = declare("StarkAutoRestake");
    let mut constructor_args = array![
        OWNER().into(),
        STAKING_CONTRACT().into(),
        STARK_TOKEN().into(),
        STAKER_ADDRESS().into()
    ];
    contract.deploy(@constructor_args).unwrap()
}

#[test]
fn test_constructor() {
    let contract_address = deploy_contract();
    let dispatcher = IStarkAutoRestakeDispatcher { contract_address };

    // Check initial configuration
    let (staking, token, staker) = dispatcher.get_config();
    assert(staking == STAKING_CONTRACT(), 'Wrong staking contract');
    assert(token == STARK_TOKEN(), 'Wrong STARK token');
    assert(staker == STAKER_ADDRESS(), 'Wrong staker address');

    // Check owner
    let ownable = IOwnableDispatcher { contract_address };
    assert(ownable.owner() == OWNER(), 'Wrong owner');
}

#[test]
fn test_update_contracts() {
    let contract_address = deploy_contract();
    let dispatcher = IStarkAutoRestakeDispatcher { contract_address };

    // New addresses
    let new_staking = contract_address_const::<'NEW_STAKING'>();
    let new_token = contract_address_const::<'NEW_TOKEN'>();
    let new_staker = contract_address_const::<'NEW_STAKER'>();

    // Update as owner
    start_prank(CheatTarget::One(contract_address), OWNER());
    dispatcher.update_contracts(new_staking, new_token, new_staker);
    stop_prank(CheatTarget::One(contract_address));

    // Verify update
    let (staking, token, staker) = dispatcher.get_config();
    assert(staking == new_staking, 'Staking not updated');
    assert(token == new_token, 'Token not updated');
    assert(staker == new_staker, 'Staker not updated');
}

#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_update_contracts_unauthorized() {
    let contract_address = deploy_contract();
    let dispatcher = IStarkAutoRestakeDispatcher { contract_address };

    // Try to update as non-owner
    start_prank(CheatTarget::One(contract_address), USER());
    dispatcher.update_contracts(STAKING_CONTRACT(), STARK_TOKEN(), STAKER_ADDRESS());
    stop_prank(CheatTarget::One(contract_address));
}

#[test]
fn test_emergency_withdraw() {
    let contract_address = deploy_contract();
    let dispatcher = IStarkAutoRestakeDispatcher { contract_address };

    // Mock token for testing
    let mock_token = contract_address_const::<'MOCK_TOKEN'>();
    let recipient = contract_address_const::<'RECIPIENT'>();
    let amount: u256 = 1000000000000000000; // 1 token

    // Execute emergency withdrawal as owner
    start_prank(CheatTarget::One(contract_address), OWNER());
    dispatcher.emergency_withdraw(mock_token, recipient, amount);
    stop_prank(CheatTarget::One(contract_address));

    // In a real test, we would verify the token was transferred
    // For now, just verify the function executes without panic
}

#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_emergency_withdraw_unauthorized() {
    let contract_address = deploy_contract();
    let dispatcher = IStarkAutoRestakeDispatcher { contract_address };

    let mock_token = contract_address_const::<'MOCK_TOKEN'>();
    let recipient = contract_address_const::<'RECIPIENT'>();
    let amount: u256 = 1000000000000000000;

    // Try to withdraw as non-owner
    start_prank(CheatTarget::One(contract_address), USER());
    dispatcher.emergency_withdraw(mock_token, recipient, amount);
    stop_prank(CheatTarget::One(contract_address));
}

#[test]
fn test_execute_auto_restake_no_rewards() {
    let contract_address = deploy_contract();
    let dispatcher = IStarkAutoRestakeDispatcher { contract_address };

    // Execute auto-restake (will return 0 if no rewards)
    let amount = dispatcher.execute_auto_restake();
    assert(amount == 0, 'Should return 0 for no rewards');
}

#[test]
fn test_upgrade() {
    let contract_address = deploy_contract();
    let upgradeable = IUpgradeableDispatcher { contract_address };

    // Mock new implementation
    let new_class_hash = declare("StarkAutoRestake").class_hash;

    // Upgrade as owner
    start_prank(CheatTarget::One(contract_address), OWNER());
    upgradeable.upgrade(new_class_hash);
    stop_prank(CheatTarget::One(contract_address));

    // Contract should still be functional after upgrade
    let dispatcher = IStarkAutoRestakeDispatcher { contract_address };
    let (staking, token, staker) = dispatcher.get_config();
    assert(staking == STAKING_CONTRACT(), 'Config lost after upgrade');
}

#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_upgrade_unauthorized() {
    let contract_address = deploy_contract();
    let upgradeable = IUpgradeableDispatcher { contract_address };

    let new_class_hash = declare("StarkAutoRestake").class_hash;

    // Try to upgrade as non-owner
    start_prank(CheatTarget::One(contract_address), USER());
    upgradeable.upgrade(new_class_hash);
    stop_prank(CheatTarget::One(contract_address));
}

// Integration test placeholder
// In a real environment, you would:
// 1. Deploy mock ERC20 and staking contracts
// 2. Mint tokens to the staking contract
// 3. Set up rewards for the staker
// 4. Execute auto-restake and verify the flow
#[test]
fn test_integration_auto_restake_flow() {
    // This test would require mock contracts for full integration testing
    // For now, we just verify the contract deploys and basic functions work
    let contract_address = deploy_contract();
    let dispatcher = IStarkAutoRestakeDispatcher { contract_address };

    // Verify we can call execute_auto_restake without errors
    let result = dispatcher.execute_auto_restake();
    assert(result == 0, 'Should handle no rewards case');
}

// Event emission tests would go here
// These require additional testing infrastructure to capture and verify events
