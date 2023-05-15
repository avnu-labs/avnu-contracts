%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256
from src.libraries.AVNUExchange_base import AVNUExchange
from src.libraries.structs.Route import Route

@external
func __setup__{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    let fee_collector_address = 0x1234;
    AVNUExchange.initialize(fee_collector_address);
    tempvar adapter_class_hash;
    %{
        context.adapter_class_hash = declare("./tests/mocks/MockSwapAdapter.cairo").class_hash
        ids.adapter_class_hash = context.adapter_class_hash
    %}
    AVNUExchange.setAdapterClassHash(0x12, adapter_class_hash);
    AVNUExchange.setAdapterClassHash(0x11, adapter_class_hash);
    return ();
}

@external
func test__getAdapterClassHash__should_return_adapter_hash{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    // Given
    tempvar expected_hash;
    %{ ids.expected_hash = context.adapter_class_hash %}

    // When
    let (result) = AVNUExchange.getAdapterClassHash(0x12);

    // Then
    assert result = expected_hash;
    return ();
}

@external
func test__setAdapterClassHash__should_set_adapter_hash{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    // When
    AVNUExchange.setAdapterClassHash(0x13, 0x1234);

    // Then
    let (hash) = AVNUExchange.getAdapterClassHash(0x13);
    assert hash = 0x1234;
    return ();
}

@external
func test__getFeeCollectorAddress__should_return_fee_collector_address{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    // When
    let (result) = AVNUExchange.getFeeCollectorAddress();

    // Then
    assert result = 0x1234;
    return ();
}

@external
func test__setFeeCollectorAddress__should_set_fee_collector_address{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    // When
    AVNUExchange.setFeeCollectorAddress(0x1);

    // Then
    let (address) = AVNUExchange.getFeeCollectorAddress();
    assert address = 0x1;
    return ();
}

@external
func test__multi_route_swap__should_call_swap{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*
}() {
    // Given
    alloc_locals;
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
    %{ mock_call(0x1234, "feeInfo", [0, 0, 0]) %}

    // When
    let (result) = AVNUExchange.multi_route_swap(
        token_from_address,
        token_from_amount,
        token_to_address,
        token_to_min_amount,
        0x1,
        0,
        0,
        routes,
        1,
    );

    // Then
    assert result = TRUE;
    return ();
}

@external
func test__multi_route_swap__should_fail_insufficient_tokens_received{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*
}() {
    // Given
    alloc_locals;
    let token_from_address = 0x1;
    let token_from_amount = Uint256(10, 0);
    let token_to_address = 0x2;
    let token_to_min_amount = Uint256(9, 0);
    let (routes: Route*) = alloc();
    assert routes[0] = Route(token_from=0x1, token_to=0x2, exchange_address=0x12, percent=100);
    %{ mock_call(0x1, "balanceOf", [10,0]) %}
    %{ mock_call(0x2, "balanceOf", [2,0]) %}
    %{ mock_call(0x1, "transferFrom", [1]) %}
    %{ mock_call(0x1234, "feeInfo", [0, 0, 0]) %}

    // When & Then
    %{ expect_revert(error_message="Insufficient tokens received") %}
    AVNUExchange.multi_route_swap(
        token_from_address,
        token_from_amount,
        token_to_address,
        token_to_min_amount,
        0x1,
        0,
        0,
        routes,
        1,
    );
    return ();
}

@external
func test__apply_routes__should_call_swap{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    // Given
    alloc_locals;
    let (routes: Route*) = alloc();
    assert routes[0] = Route(token_from=0x1, token_to=0x2, exchange_address=0x12, percent=100);
    assert routes[1] = Route(token_from=0x2, token_to=0x3, exchange_address=0x12, percent=33);
    assert routes[2] = Route(token_from=0x2, token_to=0x3, exchange_address=0x11, percent=50);
    assert routes[3] = Route(token_from=0x2, token_to=0x4, exchange_address=0x12, percent=100);
    assert routes[4] = Route(token_from=0x3, token_to=0x5, exchange_address=0x12, percent=100);
    assert routes[5] = Route(token_from=0x4, token_to=0x5, exchange_address=0x12, percent=100);
    %{ mock_call(0x1, "balanceOf", [10,0]) %}
    %{ mock_call(0x2, "balanceOf", [10,0]) %}
    %{ mock_call(0x3, "balanceOf", [10,0]) %}
    %{ mock_call(0x4, "balanceOf", [10,0]) %}

    // When
    let (result) = AVNUExchange._apply_routes(routes, 6);
    // %{ assert_swap_1_called() %}

    // Then
    assert result = 0;
    return ();
}

@external
func test__apply_routes__should_fail_when_exchange_is_unknown{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    // Given
    alloc_locals;
    let (routes: Route*) = alloc();
    assert routes[0] = Route(token_from=0x1, token_to=0x2, exchange_address=0x1, percent=100);
    %{ mock_call(0x1, "balanceOf", [10,0]) %}

    // When & Then
    %{ expect_revert(error_message="Unknown exchange") %}
    let (result) = AVNUExchange._apply_routes(routes, 1);
    return ();
}

@external
func test__assert_no_lost_tokens__should_verify_each_token_balances{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    // Given
    alloc_locals;
    let (routes: Route*) = alloc();
    assert routes[0] = Route(token_from=0x1, token_to=0x2, exchange_address=0x12, percent=100);
    assert routes[1] = Route(token_from=0x2, token_to=0x3, exchange_address=0x12, percent=33);
    assert routes[2] = Route(token_from=0x2, token_to=0x3, exchange_address=0x11, percent=50);
    assert routes[3] = Route(token_from=0x2, token_to=0x4, exchange_address=0x12, percent=100);
    assert routes[4] = Route(token_from=0x3, token_to=0x5, exchange_address=0x12, percent=100);
    assert routes[5] = Route(token_from=0x4, token_to=0x5, exchange_address=0x12, percent=100);
    %{ mock_call(0x1, "balanceOf", [0,0]) %}
    %{ mock_call(0x2, "balanceOf", [0,0]) %}
    %{ mock_call(0x3, "balanceOf", [0,0]) %}
    %{ mock_call(0x4, "balanceOf", [0,0]) %}

    // When & Then
    AVNUExchange._assert_no_lost_tokens(routes, 6, 0x5);
    return ();
}

@external
func test__assert_no_lost_tokens__should_not_fail_when_token_to_is_token_from{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    // Given
    alloc_locals;
    let (routes: Route*) = alloc();
    assert routes[0] = Route(token_from=0x1, token_to=0x2, exchange_address=0x12, percent=100);
    assert routes[1] = Route(token_from=0x2, token_to=0x3, exchange_address=0x12, percent=33);
    assert routes[2] = Route(token_from=0x2, token_to=0x3, exchange_address=0x11, percent=50);
    assert routes[3] = Route(token_from=0x2, token_to=0x4, exchange_address=0x12, percent=100);
    assert routes[4] = Route(token_from=0x3, token_to=0x1, exchange_address=0x12, percent=100);
    assert routes[5] = Route(token_from=0x4, token_to=0x1, exchange_address=0x12, percent=100);
    %{ mock_call(0x1, "balanceOf", [10,0]) %}
    %{ mock_call(0x2, "balanceOf", [0,0]) %}
    %{ mock_call(0x3, "balanceOf", [0,0]) %}
    %{ mock_call(0x4, "balanceOf", [0,0]) %}

    // When & Then
    AVNUExchange._assert_no_lost_tokens(routes, 6, 0x1);
    return ();
}

@external
func test__assert_no_lost_tokens__should_fail_when_contract_has_intermediary_some_tokens{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    // Given
    alloc_locals;
    let (routes: Route*) = alloc();
    assert routes[0] = Route(token_from=0x1, token_to=0x2, exchange_address=0x12, percent=100);
    assert routes[1] = Route(token_from=0x2, token_to=0x3, exchange_address=0x12, percent=33);
    assert routes[2] = Route(token_from=0x2, token_to=0x3, exchange_address=0x11, percent=50);
    assert routes[3] = Route(token_from=0x2, token_to=0x4, exchange_address=0x12, percent=50);
    assert routes[4] = Route(token_from=0x3, token_to=0x5, exchange_address=0x12, percent=100);
    assert routes[5] = Route(token_from=0x4, token_to=0x5, exchange_address=0x12, percent=100);
    %{ mock_call(0x1, "balanceOf", [0,0]) %}
    %{ mock_call(0x2, "balanceOf", [2,0]) %}
    %{ mock_call(0x3, "balanceOf", [0,0]) %}
    %{ mock_call(0x4, "balanceOf", [0,0]) %}

    // When & Then
    %{ expect_revert(error_message="Invalid routes percentages") %}
    AVNUExchange._assert_no_lost_tokens(routes, 6, 0x5);
    return ();
}

@external
func test__collect_avnu_fees_bps__should_not_collect_avnu_fees_when_not_active{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*
}() {
    // Given
    let amount = 1000;
    // 3%
    let fees_bps = 30;
    let token_from_address = 0x1;

    %{ mock_call(0x1, "balanceOf", [1000,0]) %}
    %{ mock_call(0x1, "transfer", [1]) %}
    %{ mock_call(0x1234, "feeInfo", [0,0,30]) %}

    // When
    let (amount_including_fees) = AVNUExchange._collect_fees(amount, token_from_address, 0, 0);

    // Then
    assert amount_including_fees = amount;
    return ();
}

@external
func test__collect_avnu_fees_bps__should_collect_avnu_fees_in_bps{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*
}() {
    // Given
    let amount = 1000;
    // 3%
    let fees_bps = 30;
    let token_from_address = 0x1;

    %{ mock_call(0x1, "balanceOf", [1000,0]) %}
    %{ mock_call(0x1, "transfer", [1]) %}
    %{ mock_call(0x1234, "feeInfo", [1,0,30]) %}

    // When
    let (amount_including_fees) = AVNUExchange._collect_fees(amount, token_from_address, 0, 0);

    // Then
    assert amount_including_fees = 997;
    return ();
}

@external
func test__collect_integrator_fees_bps__should_not_collect_integrator_fees_when_no_recipient{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*
}() {
    // Given
    let amount = 1000;
    // 3%
    let fees_bps = 30;
    let token_from_address = 0x1;

    %{ mock_call(0x1, "balanceOf", [1000,0]) %}
    %{ mock_call(0x1, "transfer", [1]) %}
    %{ mock_call(0x1234, "feeInfo", [0,0,0]) %}

    // When
    let (amount_including_fees) = AVNUExchange._collect_fees(
        amount, token_from_address, fees_bps, 0
    );

    // Then
    assert amount_including_fees = amount;
    return ();
}

@external
func test__collect_integrator_fees_bps__should_collect_integrator_fees_in_bps{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*
}() {
    // Given
    let amount = 1000;
    // 3%
    let fees_bps = 30;
    let integrator_fee_recipient = 0x2;
    let token_from_address = 0x1;

    %{ mock_call(0x1, "balanceOf", [1000,0]) %}
    %{ mock_call(0x1, "transfer", [1]) %}
    %{ mock_call(0x1234, "feeInfo", [0,0,0]) %}

    // When
    let (amount_including_fees) = AVNUExchange._collect_fees(
        amount, token_from_address, fees_bps, integrator_fee_recipient
    );

    // Then
    assert amount_including_fees = 997;
    return ();
}

@external
func test__collect_avnu_and_integrator_fees_bps__should_collect_avnu_and_integrator_fees_in_bps{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*
}() {
    // Given
    let amount = 1000;
    // 3%
    let fees_bps = 30;
    let integrator_fee_recipient = 0x2;
    let token_from_address = 0x1;

    %{ mock_call(0x1, "balanceOf", [1000,0]) %}
    %{ mock_call(0x1, "transfer", [1]) %}
    %{ mock_call(0x1234, "feeInfo", [1,0,30]) %}

    // When
    let (amount_including_fees) = AVNUExchange._collect_fees(
        amount, token_from_address, fees_bps, integrator_fee_recipient
    );

    // Then
    assert amount_including_fees = 994;
    return ();
}
