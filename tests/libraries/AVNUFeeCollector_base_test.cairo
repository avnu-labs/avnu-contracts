%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256
from src.libraries.AVNUFeeCollector_base import AVNUFeeCollector
from src.libraries.structs.Route import Route

@external
func __setup__{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
    let owner = 0x1234;
    let fee_type = 0x0;
    let fee_amount = 0x5;
    AVNUFeeCollector.initialize(owner, fee_type, fee_amount);
    %{ context.token_address = deploy_contract("./tests/mocks/MockToken.cairo").contract_address %}
    return ();
}

@external
func test__feeInfo__should_return_fee_info{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    // When
    let (is_active, fee_type, fee_amount) = AVNUFeeCollector.feeInfo();

    // Then
    assert is_active = 0x0;
    assert fee_type = 0x0;
    assert fee_amount = 0x5;
    return ();
}

@external
func test__setActive__should_set_active{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    // When
    AVNUFeeCollector.setActive(0x1);

    // Then
    let (is_active, fee_type, fee_amount) = AVNUFeeCollector.feeInfo();
    assert is_active = 0x1;
    return ();
}

@external
func test__update__should_update_fee_type_and_fee_amount{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    // When
    AVNUFeeCollector.update(0x1, 0x10);

    // Then
    let (is_active, fee_type, fee_amount) = AVNUFeeCollector.feeInfo();
    assert fee_type = 0x1;
    assert fee_amount = 0x10;
    return ();
}

@external
func test__update__should_fail_when_invalid_fee_type{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    // When & Then
    %{ expect_revert(error_message="AVNUFeeCollector: Fee type not exist") %}
    AVNUFeeCollector.update(0x5, 0x10);
    return ();
}

@external
func test__update__should_fail_when_invalid_fee_amount{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    // When & Then
    %{ expect_revert(error_message="AVNUFeeCollector: Fee amount have to be > 0") %}
    AVNUFeeCollector.update(0x1, 0x0);
    return ();
}

@external
func test__withdraw__should_transfer_balance{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    // Given
    tempvar token_address;
    %{ ids.token_address = context.token_address %}
    %{ start_prank(123) %}
    %{ mock_call(context.token_address, "balanceOf", [1,0]) %}
    %{ transfer_called = expect_call(context.token_address, "transfer", [123,1,0]) %}

    // When
    AVNUFeeCollector.withdraw(token_address);

    // Then
    %{ transfer_called() %}
    return ();
}
