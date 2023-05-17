# AVNU Contracts

This repository contains the contracts used by [AVNU](https://www.avnu.fi/). You can test them by using our [testnet](https://app.avnu.fi/).

If you want to learn more about AVNU, and how we are able to provide the best execution on Starknet, you can visit our [documentation](https://doc.avnu.fi/).

## Structure

- **AVNUExchange**: Handles the swap. It contains all the routing logic
- **AVNUFeeCollector**: Manages fees and collects them
- **AVNUProxy**: Allows to upgrade contracts

AVNUExchange uses **Adapter**s to call each AMM. 
These adapters are declared on Starknet and then called using library calls.
A mapping of "AMM Router address" to "Adapter class hash" is stored inside the AVNUExchange contract.

## AVNUExchange contract

Here is the interface of the contract: 

```
@contract_interface
namespace IAVNUExchange {
    func initializer(owner: felt, fee_collector_address: felt) {
    }

    func getName() -> (name: felt) {
    }

    func getAdapterClassHash(exchange_address: felt) -> (adapter_class_hash: felt) {
    }

    func getFeeCollectorAddress() -> (fee_collector_address: felt) {
    }

    func multi_route_swap(
        token_from_address: felt,
        token_from_amount: Uint256,
        token_to_address: felt,
        token_to_min_amount: Uint256,
        integrator_fee_amount_bps: felt,
        integrator_fee_recipient: felt,
        routes_len: felt,
        routes: Route*,
    ) -> (success: felt) {
    }

    func setAdapterClassHash(exchange_address: felt, adapter_class_hash: felt) {
    }

    func setFeeCollectorAddress(new_fee_collector_address: felt) {
    }
}
```

## Getting Started

This repository is using [Protostar](https://docs.swmansion.com/protostar/) to install, test, build contracts

```shell
# Install the dependencies
protostar install

# Run the tests
protostar test-cairo0

# Build contracts
protostar build-cairo0
```
