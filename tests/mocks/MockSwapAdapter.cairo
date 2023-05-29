%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

@external
func swap{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    exchange_address: felt,
    token_from_address: felt,
    token_from_amount: Uint256,
    token_to_address: felt,
    token_to_min_amount: Uint256,
    to: felt,
) {
    // Uncomment to debug and run "protostar test --disable-hint-validation"
    // %{ print(f"Swap {ids.token_from_amount.low} tokens {ids.token_from_address} to tokens {ids.token_to_address} using exchange {ids.exchange_address}") %}
    return ();
}
