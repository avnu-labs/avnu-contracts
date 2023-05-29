%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256
from openzeppelin.upgrades.library import Proxy
from src.libraries.AVNUExchange_base import AVNUExchange
from src.libraries.structs.Route import Route

@contract_interface
namespace IAVNUFeeCollector {
    func initializer(owner: felt, fee_type: felt, fee_amount: felt) {
    }

    func feeInfo() -> (is_active: felt, fee_type: felt, fee_amount: felt) {
    }

    func withdraw(token: felt) {
    }

    func update(new_fee_type: felt, new_fee_amount: felt) {
    }

    func setActive(is_active: felt) {
    }
}

@view
func __setup__{syscall_ptr: felt*, range_check_ptr}() {
    let owner = 0x1234;
    let fee_type = 0x0;
    let fee_amount = 0x5;
    tempvar contract_address;
    let owner = 0x0123;
    %{
        context.contract_address = deploy_contract("./src/AVNUFeeCollector.cairo").contract_address
        ids.contract_address = context.contract_address
        context.adapter_class_hash = declare("./tests/mocks/MockSwapAdapter.cairo").class_hash
        context.owner = ids.owner
    %}
    IAVNUFeeCollector.initializer(contract_address, owner, fee_type, fee_amount);
    %{ context.token_address = deploy_contract("./tests/mocks/MockToken.cairo").contract_address %}
    return ();
}

@external
func test__feeInfo__should_return_fee_info{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    // Given
    tempvar contract_address;
    %{ ids.contract_address = context.contract_address %}

    // When
    let (is_active, fee_type, fee_amount) = IAVNUFeeCollector.feeInfo(contract_address);

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
    // Given
    tempvar contract_address;
    %{ ids.contract_address = context.contract_address %}
    %{ start_prank(context.owner, target_contract_address=ids.contract_address) %}

    // When
    IAVNUFeeCollector.setActive(contract_address, 0x1);

    // Then
    let (is_active, fee_type, fee_amount) = IAVNUFeeCollector.feeInfo(contract_address);
    assert is_active = 0x1;
    return ();
}

@external
func test__setActive__should_fail_when_caller_is_not_the_owner{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    // Given
    tempvar contract_address;
    %{ ids.contract_address = context.contract_address %}

    // When & Then
    %{ expect_revert(error_message="Ownable: caller is not the owner") %}
    IAVNUFeeCollector.setActive(contract_address, 0x1);
    return ();
}

@external
func test__update__should_update_fee_type_and_fee_amount{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    // Given
    tempvar contract_address;
    %{ ids.contract_address = context.contract_address %}
    %{ start_prank(context.owner, target_contract_address=ids.contract_address) %}

    // When
    IAVNUFeeCollector.update(contract_address, 0x1, 0x10);

    // Then
    let (is_active, fee_type, fee_amount) = IAVNUFeeCollector.feeInfo(contract_address);
    assert fee_type = 0x1;
    assert fee_amount = 0x10;
    return ();
}

@external
func test__update__should_fail_when_caller_is_not_the_owner{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    // Given
    tempvar contract_address;
    %{ ids.contract_address = context.contract_address %}

    // When & Then
    %{ expect_revert(error_message="Ownable: caller is not the owner") %}
    IAVNUFeeCollector.update(contract_address, 0x1, 0x10);
    return ();
}

@external
func test__withdraw__should_transfer_balance{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    // Given
    tempvar contract_address;
    %{ ids.contract_address = context.contract_address %}
    tempvar token_address;
    %{ ids.token_address = context.token_address %}
    %{ start_prank(context.owner, target_contract_address=ids.contract_address) %}
    %{ mock_call(context.token_address, "balanceOf", [1,0]) %}
    %{ transfer_called = expect_call(context.token_address, "transfer", [context.owner,1,0]) %}

    // When
    IAVNUFeeCollector.withdraw(contract_address, token_address);

    // Then
    %{ transfer_called() %}
    return ();
}

@external
func test__withdraw__should_fail_when_caller_is_not_the_owner{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
}() {
    // Given
    tempvar contract_address;
    tempvar token_address;
    %{ ids.contract_address = context.contract_address %}
    %{ ids.token_address = context.token_address %}

    // When & Then
    %{ expect_revert(error_message="Ownable: caller is not the owner") %}
    IAVNUFeeCollector.withdraw(contract_address, token_address);
    return ();
}
