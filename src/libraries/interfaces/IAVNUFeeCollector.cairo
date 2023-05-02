%lang starknet

@contract_interface
namespace IAVNUFeeCollector {
    func feeInfo() -> (is_active: felt, fee_type: felt, fee_amount: felt) {
    }

    func withdraw(token: felt) {
    }

    func update(new_fee_type: felt, new_fee_amount: felt) {
    }

    func setActive(is_active: felt) {
    }
}
