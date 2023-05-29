%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_block_timestamp
from openzeppelin.token.erc20.IERC20 import IERC20

// This contract implements ISwapAdapter

@contract_interface
namespace ISithSwapRouter {
    func swapExactTokensForTokensSimple(
        amount_in: Uint256,
        amount_out_min: Uint256,
        token_from: felt,
        token_to: felt,
        to: felt,
        deadline: felt,
    ) -> (amounts_len: felt, amounts: Uint256*) {
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

    // Init deadline
    let (block_timestamp) = get_block_timestamp();
    let deadline = block_timestamp + 1000;

    IERC20.approve(token_from_address, exchange_address, token_from_amount);
    ISithSwapRouter.swapExactTokensForTokensSimple(
        exchange_address,
        token_from_amount,
        token_to_min_amount,
        token_from_address,
        token_to_address,
        to,
        deadline,
    );
    return ();
}
