%lang starknet

from starkware.cairo.common.uint256 import Uint256

@external
func swap(pool_id: felt, token_from_addr: felt, amount_from: Uint256, amount_to_min: Uint256) -> (
    amount_to: Uint256
) {
    return (Uint256(1, 0),);
}
