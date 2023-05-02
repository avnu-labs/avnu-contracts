%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.uint256 import Uint256

@external
func swapExactTokensForTokensSimple(
    amount_in: Uint256,
    amount_out_min: Uint256,
    token_from: felt,
    token_to: felt,
    to: felt,
    deadline: felt,
) -> (amounts_len: felt, amounts: Uint256*) {
    let (amounts: Uint256*) = alloc();
    assert amounts[0] = Uint256(1, 0);
    return (1, amounts);
}
