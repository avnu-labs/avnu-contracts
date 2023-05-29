%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace ISwapAdapter {
    func swap(
        exchange_address: felt,
        token_from_address: felt,
        token_from_amount: Uint256,
        token_to_address: felt,
        token_to_min_amount: Uint256,
        to: felt,
    ) {
    }
}
