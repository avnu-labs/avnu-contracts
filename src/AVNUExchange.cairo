%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256
from openzeppelin.access.ownable.library import Ownable
from openzeppelin.upgrades.library import Proxy
from src.libraries.AVNUExchange_base import AVNUExchange
from src.libraries.structs.Route import Route

//
// Initializer
//
@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, fee_collector_address: felt
) {
    AVNUExchange.initialize(fee_collector_address);
    Proxy.initializer(owner);
    Ownable.initializer(owner);
    return ();
}

//
// Getters
//

@view
func getName{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (name: felt) {
    let name = 'AVNU_Exchange';
    return (name,);
}

@view
func getAdapterClassHash{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    exchange_address: felt
) -> (adapter_class_hash: felt) {
    let (adapter_class_hash) = AVNUExchange.getAdapterClassHash(exchange_address);
    return (adapter_class_hash,);
}

@view
func getFeeCollectorAddress{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    fee_collector_address: felt
) {
    let (fee_collector_address) = AVNUExchange.getFeeCollectorAddress();
    return (fee_collector_address,);
}

//
// Setters
//
@external
func multi_route_swap{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(
    token_from_address: felt,
    token_from_amount: Uint256,
    token_to_address: felt,
    token_to_min_amount: Uint256,
    integrator_fee_amount_bps: felt,
    integrator_fee_recipient: felt,
    routes_len: felt,
    routes: Route*,
) -> (success: felt) {
    let (success) = AVNUExchange.multi_route_swap(
        token_from_address,
        token_from_amount,
        token_to_address,
        token_to_min_amount,
        integrator_fee_amount_bps,
        integrator_fee_recipient,
        routes,
        routes_len,
    );
    return (success,);
}

@external
func setAdapterClassHash{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    exchange_address: felt, adapter_class_hash: felt
) {
    Ownable.assert_only_owner();
    AVNUExchange.setAdapterClassHash(exchange_address, adapter_class_hash);
    return ();
}

@external
func setFeeCollectorAddress{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    new_fee_collector_address: felt
) {
    Ownable.assert_only_owner();
    AVNUExchange.setFeeCollectorAddress(new_fee_collector_address);
    return ();
}
