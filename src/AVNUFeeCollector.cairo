%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from openzeppelin.access.ownable.library import Ownable
from openzeppelin.upgrades.library import Proxy
from src.libraries.AVNUFeeCollector_base import AVNUFeeCollector

//
// Constructor
//
@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, fee_type: felt, fee_amount: felt
) {
    AVNUFeeCollector.initialize(owner, fee_type, fee_amount);
    Proxy.initializer(owner);
    Ownable.initializer(owner);
    return ();
}

@view
func feeInfo{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    is_active: felt, fee_type: felt, fee_amount: felt
) {
    let (is_active, fee_type, fee_amount) = AVNUFeeCollector.feeInfo();
    return (is_active=is_active, fee_type=fee_type, fee_amount=fee_amount);
}

@external
func withdraw{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(token: felt) {
    Ownable.assert_only_owner();
    AVNUFeeCollector.withdraw(token);
    return ();
}

@external
func update{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    new_fee_type: felt, new_fee_amount: felt
) {
    Ownable.assert_only_owner();
    AVNUFeeCollector.update(new_fee_type, new_fee_amount);
    return ();
}

@external
func setActive{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(is_active: felt) {
    Ownable.assert_only_owner();
    AVNUFeeCollector.setActive(is_active);
    return ();
}
