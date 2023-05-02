%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from src.adapters.MySwapAdapter import swap

@external
func __setup__{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    %{ context.exchange_address = deploy_contract("./tests/mocks/MockMySwap.cairo").contract_address %}
    %{ context.token_from_address = deploy_contract("./tests/mocks/MockToken.cairo").contract_address %}
    %{ context.token_to_address = deploy_contract("./tests/mocks/MockToken.cairo").contract_address %}
    return ();
}

@external
func test__swap__should_call_myswap{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    // Given
    tempvar exchange_address;
    tempvar token_from_address;
    tempvar token_to_address;
    %{ ids.exchange_address = context.exchange_address %}
    %{ ids.token_from_address = context.token_from_address %}
    %{ ids.token_to_address = context.token_to_address %}
    let token_from_amount = Uint256(1, 0);
    let token_to_min_amount = Uint256(2, 0);
    let to = 0x4;
    %{ approved_called = expect_call(ids.token_from_address, "approve", [ids.exchange_address, 1, 0]) %}
    %{ mock_call(ids.exchange_address, "get_total_number_of_pools", [1]) %}
    %{ mock_call(ids.exchange_address, "get_pool", [0, ids.token_from_address, 0,0,ids.token_to_address,0,0,0,0,0]) %}
    %{ swapExactTokensForTokens_called = expect_call(ids.exchange_address, "swap", [1, ids.token_from_address, 1, 0, 2, 0]) %}

    // When
    swap(
        exchange_address,
        token_from_address,
        token_from_amount,
        token_to_address,
        token_to_min_amount,
        to,
    );

    // Then
    %{ approved_called() %}
    %{ swapExactTokensForTokens_called() %}
    return ();
}
