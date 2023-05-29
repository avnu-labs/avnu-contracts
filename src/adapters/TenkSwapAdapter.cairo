%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_block_timestamp
from openzeppelin.token.erc20.IERC20 import IERC20

// This contract implements ISwapAdapter

@contract_interface
namespace Il0kRouter {
    func swapExactTokensForTokens(
        amountIn: Uint256,
        amountOutMin: Uint256,
        path_len: felt,
        path: felt*,
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

    // Init path
    let (path: felt*) = alloc();
    assert path[0] = token_from_address;
    assert path[1] = token_to_address;

    // Init deadline
    let (block_timestamp) = get_block_timestamp();
    let deadline = block_timestamp + 1000;

    IERC20.approve(token_from_address, exchange_address, token_from_amount);
    Il0kRouter.swapExactTokensForTokens(
        exchange_address, token_from_amount, token_to_min_amount, 2, path, to, deadline
    );
    return ();
}
