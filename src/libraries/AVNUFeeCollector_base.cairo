%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.starknet.common.syscalls import get_contract_address, get_caller_address
from starkware.cairo.common.math import assert_not_zero, assert_le
from openzeppelin.security.initializable.library import Initializable
from openzeppelin.token.erc20.IERC20 import IERC20

//
// Storage
//

@storage_var
func FeeActive() -> (is_active: felt) {
}

// 0 = Percent
// 1 = Fixed
@storage_var
func FeeType() -> (fee_type: felt) {
}

// Amount of fee taken, depends on the fee type
// Percent = BPS
// Fixed = USD * 1000
@storage_var
func FeeAmount() -> (fee_amount: felt) {
}

namespace AVNUFeeCollector {
    func initialize{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        owner: felt, fee_type: felt, fee_amount: felt
    ) {
        Initializable.initialize();
        update(fee_type, fee_amount);
        return ();
    }

    func withdraw{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(token: felt) {
        let (contract_address) = get_contract_address();
        let (caller_address) = get_caller_address();
        let (balance) = IERC20.balanceOf(token, contract_address);
        IERC20.transfer(token, caller_address, balance);
        return ();
    }

    func update{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        new_fee_type: felt, new_fee_amount: felt
    ) {
        with_attr error_message("AVNUFeeCollector: Fee type not exist") {
            // Only 0 & 1 are valid fee types
            assert_le(new_fee_type, 1);
        }
        // If you want no fees, deactivate it
        with_attr error_message("AVNUFeeCollector: Fee amount have to be > 0") {
            assert_not_zero(new_fee_amount);
        }
        FeeType.write(new_fee_type);
        FeeAmount.write(new_fee_amount);
        return ();
    }

    func feeInfo{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
        is_active: felt, fee_type: felt, fee_amount: felt
    ) {
        let (is_active) = FeeActive.read();
        let (fee_type) = FeeType.read();
        let (fee_amount) = FeeAmount.read();
        return (is_active=is_active, fee_type=fee_type, fee_amount=fee_amount);
    }

    func setActive{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        is_active: felt
    ) {
        FeeActive.write(is_active);
        return ();
    }
}
