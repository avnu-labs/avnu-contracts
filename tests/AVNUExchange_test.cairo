%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256
from openzeppelin.upgrades.library import Proxy
from src.libraries.AVNUExchange_base import AVNUExchange
from src.libraries.structs.Route import Route

@contract_interface
namespace IAVNUExchange {
    func initializer(owner: felt, fee_collector_address: felt) {
    }

    func getName() -> (name: felt) {
    }

    func getAdapterClassHash(exchange_address: felt) -> (adapter_class_hash: felt) {
    }

    func getFeeCollectorAddress() -> (fee_collector_address: felt) {
    }

    func multi_route_swap(
        token_from_address: felt,
        token_from_amount: Uint256,
        token_to_address: felt,
        token_to_amount: Uint256,
        token_to_min_amount: Uint256,
        beneficiary: felt,
        integrator_fee_amount_bps: felt,
        integrator_fee_recipient: felt,
        routes_len: felt,
        routes: Route*,
    ) -> (success: felt) {
    }

    func setAdapterClassHash(exchange_address: felt, adapter_class_hash: felt) {
    }

    func setFeeCollectorAddress(new_fee_collector_address: felt) {
    }
}

@view
func __setup__{syscall_ptr: felt*, range_check_ptr}() {
    tempvar contract_address;
    tempvar adapter_class_hash;
    let owner = 0x0123;
    %{
        context.contract_address = deploy_contract("./src/AVNUExchange.cairo").contract_address
        ids.contract_address = context.contract_address
        context.adapter_class_hash = declare("./src/adapters/JediSwapAdapter.cairo").class_hash
        ids.adapter_class_hash = context.adapter_class_hash
        context.owner = ids.owner
    %}
    let fee_collector_address = 0x01234;
    IAVNUExchange.initializer(contract_address, owner, fee_collector_address);
    %{ stop_prank_callable = start_prank(ids.owner, target_contract_address=ids.contract_address) %}
    IAVNUExchange.setAdapterClassHash(contract_address, 0x12, adapter_class_hash);
    IAVNUExchange.setAdapterClassHash(contract_address, 0x13, adapter_class_hash);
    IAVNUExchange.setAdapterClassHash(contract_address, 0x14, adapter_class_hash);
    IAVNUExchange.setAdapterClassHash(contract_address, 0x15, adapter_class_hash);
    %{ stop_prank_callable() %}
    return ();
}

@view
func test__get_name__should_return_name{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    // Given
    tempvar contract_address;
    %{ ids.contract_address = context.contract_address %}

    // When
    let (result) = IAVNUExchange.getName(contract_address);

    // Then
    assert result = 'AVNU_Exchange';
    return ();
}

@view
func test__getAdapterClassHash__should_return_adapter_hash{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    // Given
    tempvar contract_address;
    tempvar expected_hash;
    %{ ids.contract_address = context.contract_address %}
    %{ ids.expected_hash = context.adapter_class_hash %}

    // When
    let (result) = IAVNUExchange.getAdapterClassHash(contract_address, 0x12);

    // Then
    assert result = expected_hash;
    return ();
}

@external
func test__setAdapterClassHash__should_set_adapter_hash{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    // Given
    tempvar contract_address;
    %{ ids.contract_address = context.contract_address %}
    %{ start_prank(context.owner, target_contract_address=ids.contract_address) %}

    // When
    IAVNUExchange.setAdapterClassHash(contract_address, 0x16, 0x1234);

    // Then
    let (hash) = IAVNUExchange.getAdapterClassHash(contract_address, 0x16);
    assert hash = 0x1234;
    return ();
}

@external
func test__setAdapterClassHash__should_fail_when_caller_is_not_the_owner{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    // Given
    tempvar contract_address;
    %{ ids.contract_address = context.contract_address %}

    // When & Then
    %{ expect_revert(error_message="Ownable: caller is not the owner") %}
    IAVNUExchange.setAdapterClassHash(contract_address, 0x13, 0x1234);
    return ();
}

@external
func test__getFeeCollectorAddress__should_return_fee_collector_address{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    // Given
    tempvar contract_address;
    %{ ids.contract_address = context.contract_address %}

    // When
    let (result) = IAVNUExchange.getFeeCollectorAddress(contract_address);

    // Then
    assert result = 0x01234;
    return ();
}

@external
func test__setFeeCollectorAddress__should_return_fee_collector_address{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    // Given
    tempvar contract_address;
    %{ ids.contract_address = context.contract_address %}
    %{ start_prank(context.owner, target_contract_address=ids.contract_address) %}

    // When
    IAVNUExchange.setFeeCollectorAddress(contract_address, 0x1);

    // Then
    let (address) = IAVNUExchange.getFeeCollectorAddress(contract_address);
    assert address = 0x1;
    return ();
}

@external
func test__setFeeCollectorAddress__should_fail_when_caller_is_not_the_owner{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    // Given
    tempvar contract_address;
    %{ ids.contract_address = context.contract_address %}

    // When & Then
    %{ expect_revert(error_message="Ownable: caller is not the owner") %}
    IAVNUExchange.setFeeCollectorAddress(contract_address, 0x1);
    return ();
}

@view
func test__multi_route_swap__should_succeed__when_1_route{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    // Given
    alloc_locals;
    tempvar contract_address;
    %{ ids.contract_address = context.contract_address %}
    let token_from_address = 0x1;
    let token_from_amount = Uint256(10, 0);
    let token_to_address = 0x2;
    let token_to_min_amount = Uint256(9, 0);
    let (routes: Route*) = alloc();
    assert routes[0] = Route(token_from=0x1, token_to=0x2, exchange_address=0x12, percent=100);
    %{ mock_call(0x1, "balanceOf", [0,0]) %}
    %{ mock_call(0x2, "balanceOf", [10,0]) %}
    %{ mock_call(0x1, "transferFrom", [1]) %}
    %{ mock_call(0x2, "transfer", [1]) %}
    %{ mock_call(0x1, "approve", [1]) %}
    %{ mock_call(0x12, "swap_exact_tokens_for_tokens", [1, 1, 0]) %}
    let fee_collector_address = 0x01234;
    %{ mock_call(0x1234, "feeInfo", [0, 0, 0]) %}
    %{ stop_prank_callable = start_prank(0x1, target_contract_address=ids.contract_address) %}

    // When
    let (result) = IAVNUExchange.multi_route_swap(
        contract_address,
        token_from_address,
        token_from_amount,
        token_to_address,
        token_to_min_amount,
        token_to_min_amount,
        0x1,
        0,
        0,
        1,
        routes,
    );

    // Then
    assert result = TRUE;
    return ();
}

@view
func test__multi_route_swap__should_succeed__when_2_routes{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    // Given
    alloc_locals;
    tempvar contract_address;
    %{ ids.contract_address = context.contract_address %}
    let token_from_address = 0x1;
    let token_from_amount = Uint256(10, 0);
    let token_to_address = 0x3;
    let token_to_min_amount = Uint256(9, 0);
    let (routes: Route*) = alloc();
    assert routes[0] = Route(token_from=0x1, token_to=0x2, exchange_address=0x12, percent=100);
    assert routes[1] = Route(token_from=0x2, token_to=0x3, exchange_address=0x12, percent=100);
    %{ mock_call(0x1, "balanceOf", [0,0]) %}
    %{ mock_call(0x2, "balanceOf", [0,0]) %}
    %{ mock_call(0x3, "balanceOf", [10,0]) %}
    %{ mock_call(0x1, "transferFrom", [1]) %}
    %{ mock_call(0x3, "transfer", [1]) %}
    %{ mock_call(0x1, "approve", [1]) %}
    %{ mock_call(0x2, "approve", [1]) %}
    %{ mock_call(0x12, "swap_exact_tokens_for_tokens", [1, 1, 0]) %}
    let fee_collector_address = 0x01234;
    %{ mock_call(0x1234, "feeInfo", [0, 0, 0]) %}
    %{ stop_prank_callable = start_prank(0x1, target_contract_address=ids.contract_address) %}

    // When
    let (result) = IAVNUExchange.multi_route_swap(
        contract_address,
        token_from_address,
        token_from_amount,
        token_to_address,
        token_to_min_amount,
        token_to_min_amount,
        0x1,
        0,
        0,
        2,
        routes,
    );

    // Then
    assert result = TRUE;
    return ();
}

@view
func test__multi_route_swap__should_succeed__when_10_routes{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    // Given
    alloc_locals;
    tempvar contract_address;
    %{ ids.contract_address = context.contract_address %}
    let token_from_address = 0x1;
    let token_from_amount = Uint256(10, 0);
    let token_to_address = 0x5;
    let token_to_min_amount = Uint256(9, 0);
    let (routes: Route*) = alloc();
    assert routes[0] = Route(token_from=0x1, token_to=0x2, exchange_address=0x12, percent=25);
    assert routes[1] = Route(token_from=0x2, token_to=0x3, exchange_address=0x12, percent=100);
    assert routes[2] = Route(token_from=0x3, token_to=0x4, exchange_address=0x12, percent=100);
    assert routes[3] = Route(token_from=0x4, token_to=0x5, exchange_address=0x12, percent=100);
    assert routes[4] = Route(token_from=0x1, token_to=0x2, exchange_address=0x13, percent=33);
    assert routes[5] = Route(token_from=0x2, token_to=0x3, exchange_address=0x13, percent=100);
    assert routes[6] = Route(token_from=0x3, token_to=0x4, exchange_address=0x13, percent=100);
    assert routes[7] = Route(token_from=0x4, token_to=0x5, exchange_address=0x13, percent=100);
    assert routes[8] = Route(token_from=0x1, token_to=0x5, exchange_address=0x14, percent=50);
    assert routes[9] = Route(token_from=0x1, token_to=0x5, exchange_address=0x15, percent=100);
    %{ mock_call(0x1, "balanceOf", [0,0]) %}
    %{ mock_call(0x2, "balanceOf", [0,0]) %}
    %{ mock_call(0x3, "balanceOf", [0,0]) %}
    %{ mock_call(0x4, "balanceOf", [0,0]) %}
    %{ mock_call(0x5, "balanceOf", [10,0]) %}
    %{ mock_call(0x1, "transferFrom", [1]) %}
    %{ mock_call(0x5, "transfer", [1]) %}
    %{ mock_call(0x1, "approve", [1]) %}
    %{ mock_call(0x2, "approve", [1]) %}
    %{ mock_call(0x3, "approve", [1]) %}
    %{ mock_call(0x4, "approve", [1]) %}
    %{ mock_call(0x5, "approve", [1]) %}
    %{ mock_call(0x12, "swap_exact_tokens_for_tokens", [1, 1, 0]) %}
    %{ mock_call(0x13, "swap_exact_tokens_for_tokens", [1, 1, 0]) %}
    %{ mock_call(0x14, "swap_exact_tokens_for_tokens", [1, 1, 0]) %}
    %{ mock_call(0x15, "swap_exact_tokens_for_tokens", [1, 1, 0]) %}
    let fee_collector_address = 0x01234;
    %{ mock_call(0x1234, "feeInfo", [0, 0, 0]) %}
    %{ stop_prank_callable = start_prank(0x1, target_contract_address=ids.contract_address) %}

    // When
    let (result) = IAVNUExchange.multi_route_swap(
        contract_address,
        token_from_address,
        token_from_amount,
        token_to_address,
        token_to_min_amount,
        token_to_min_amount,
        0x1,
        0,
        0,
        10,
        routes,
    );

    // Then
    assert result = TRUE;
    return ();
}
