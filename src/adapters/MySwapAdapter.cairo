%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_equal
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_contract_address
from openzeppelin.token.erc20.IERC20 import IERC20

// This contract implements ISwapAdapter

@contract_interface
namespace IMySwapRouter {
    func get_total_number_of_pools() -> (num: felt) {
    }

    func get_pool(pool_id: felt) -> (
        name: felt,
        token_a_address: felt,
        token_a_reserves: Uint256,
        token_b_address: felt,
        token_b_reserves: Uint256,
        fee_percentage: felt,
        cfmm_type: felt,
        liq_token: felt,
    ) {
    }

    func swap(
        pool_id: felt, token_from_addr: felt, amount_from: Uint256, amount_to_min: Uint256
    ) -> (amount_to: Uint256) {
    }
}

@external
func swap{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    exchange_address: felt,
    token_from_address: felt,
    token_from_amount: Uint256,
    token_to_address: felt,
    token_to_min_amount: Uint256,
    to: felt,
) {
    alloc_locals;

    // Get pool id
    let (num) = IMySwapRouter.get_total_number_of_pools(exchange_address);
    let (pool_id) = _get_pool_index(exchange_address, token_from_address, token_to_address, 1, num);

    let (contract_address) = get_contract_address();
    IERC20.approve(token_from_address, exchange_address, token_from_amount);
    IMySwapRouter.swap(
        exchange_address, pool_id, token_from_address, token_from_amount, token_to_min_amount
    );
    return ();
}

func _get_pool_index{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    exchange_address: felt,
    token_from_address: felt,
    token_to_address: felt,
    current_index: felt,
    max: felt,
) -> (pool_id: felt) {
    alloc_locals;
    with_attr error_message("Pool not found") {
        assert_not_equal(max + 1, current_index);
    }
    let (
        name,
        token_a_address,
        token_a_reserves,
        token_b_address,
        token_b_reserves,
        fee_percentage,
        cfmm_type,
        liq_token,
    ) = IMySwapRouter.get_pool(exchange_address, current_index);
    if (token_a_address == token_from_address) {
        if (token_b_address == token_to_address) {
            return (current_index,);
        }
    }
    if (token_a_address == token_to_address) {
        if (token_b_address == token_from_address) {
            return (current_index,);
        }
    }
    return _get_pool_index(
        exchange_address, token_from_address, token_to_address, current_index + 1, max
    );
}
