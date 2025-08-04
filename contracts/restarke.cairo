// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts for Cairo ^0.14.0

#[starknet::contract]
mod Restarke {
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::upgrades::interface::IUpgradeable;
    use openzeppelin::upgrades::UpgradeableComponent;
    use starknet::{ContractAddress, get_caller_address, get_contract_address};
    use starknet::syscalls::call_contract_syscall;
    use core::num::traits::Zero;

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

    // Ownable Mixin
    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    // Upgradeable
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        staking_contract: ContractAddress,
        stark_token: ContractAddress,
        staker_address: ContractAddress,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
        AutoRestakeExecuted: AutoRestakeExecuted,
        ContractsUpdated: ContractsUpdated,
    }

    #[derive(Drop, starknet::Event)]
    struct AutoRestakeExecuted {
        #[key]
        executor: ContractAddress,
        rewards_claimed: u256,
        amount_restaked: u256,
        timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct ContractsUpdated {
        staking_contract: ContractAddress,
        stark_token: ContractAddress,
        staker_address: ContractAddress,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        owner: ContractAddress,
        staking_contract: ContractAddress,
        stark_token: ContractAddress,
        staker_address: ContractAddress
    ) {
        self.ownable.initializer(owner);
        self.staking_contract.write(staking_contract);
        self.stark_token.write(stark_token);
        self.staker_address.write(staker_address);
    }

    #[abi(embed_v0)]
    impl Restarke of super::IRestarke<ContractState> {
        /// Execute the full auto-restake workflow:
        /// 1. Claim rewards from staking contract
        /// 2. Approve STARK tokens to staking contract
        /// 3. Increase stake with claimed rewards
        fn execute_auto_restake(ref self: ContractState) -> u256 {
            // Get contract addresses
            let staking_contract = self.staking_contract.read();
            let stark_token = self.stark_token.read();
            let staker_address = self.staker_address.read();

            // Step 1: Claim rewards
            // Call claim_rewards(staker_address) on staking contract
            let mut claim_calldata = array![];
            Serde::serialize(@staker_address, ref claim_calldata);

            let claim_result = call_contract_syscall(
                staking_contract,
                selector!("claim_rewards"),
                claim_calldata.span()
            ).unwrap();

            // Step 2: Check balance of STARK tokens received
            let mut balance_calldata = array![];
            Serde::serialize(@get_contract_address(), ref balance_calldata);

            let balance_result = call_contract_syscall(
                stark_token,
                selector!("balanceOf"),
                balance_calldata.span()
            ).unwrap();

            let mut balance: u256 = Zero::zero();
            if !balance_result.is_empty() {
                balance = Serde::<u256>::deserialize(ref balance_result).unwrap();
            }

            // Only proceed if we have balance to restake
            if balance > 0 {
                // Step 3: Approve staking contract to spend our STARK tokens
                let mut approve_calldata = array![];
                Serde::serialize(@staking_contract, ref approve_calldata);
                Serde::serialize(@balance, ref approve_calldata);

                call_contract_syscall(
                    stark_token,
                    selector!("approve"),
                    approve_calldata.span()
                ).unwrap();

                // Step 4: Increase stake with the full balance
                let mut stake_calldata = array![];
                Serde::serialize(@staker_address, ref stake_calldata);
                Serde::serialize(@balance, ref stake_calldata);

                call_contract_syscall(
                    staking_contract,
                    selector!("increase_stake"),
                    stake_calldata.span()
                ).unwrap();

                // Emit event
                self.emit(
                    AutoRestakeExecuted {
                        executor: get_caller_address(),
                        rewards_claimed: balance,
                        amount_restaked: balance,
                        timestamp: starknet::get_block_timestamp(),
                    }
                );
            }

            balance
        }

        /// Update contract addresses (only owner)
        fn update_contracts(
            ref self: ContractState,
            staking_contract: ContractAddress,
            stark_token: ContractAddress,
            staker_address: ContractAddress
        ) {
            self.ownable.assert_only_owner();

            self.staking_contract.write(staking_contract);
            self.stark_token.write(stark_token);
            self.staker_address.write(staker_address);

            self.emit(
                ContractsUpdated {
                    staking_contract,
                    stark_token,
                    staker_address,
                }
            );
        }

        /// Get current configuration
        fn get_config(self: @ContractState) -> (ContractAddress, ContractAddress, ContractAddress) {
            (
                self.staking_contract.read(),
                self.stark_token.read(),
                self.staker_address.read()
            )
        }

        /// Emergency withdrawal of any tokens sent to this contract by mistake
        fn emergency_withdraw(
            ref self: ContractState,
            token: ContractAddress,
            recipient: ContractAddress,
            amount: u256
        ) {
            self.ownable.assert_only_owner();

            let mut transfer_calldata = array![];
            Serde::serialize(@recipient, ref transfer_calldata);
            Serde::serialize(@amount, ref transfer_calldata);

            call_contract_syscall(
                token,
                selector!("transfer"),
                transfer_calldata.span()
            ).unwrap();
        }
    }

    #[abi(embed_v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: starknet::ClassHash) {
            self.ownable.assert_only_owner();
            self.upgradeable.upgrade(new_class_hash);
        }
    }
}

#[starknet::interface]
trait IRestarke<TContractState> {
    fn execute_auto_restake(ref self: TContractState) -> u256;
    fn update_contracts(
        ref self: TContractState,
        staking_contract: ContractAddress,
        stark_token: ContractAddress,
        staker_address: ContractAddress
    );
    fn get_config(self: @TContractState) -> (ContractAddress, ContractAddress, ContractAddress);
    fn emergency_withdraw(
        ref self: TContractState,
        token: ContractAddress,
        recipient: ContractAddress,
        amount: u256
    );
}
