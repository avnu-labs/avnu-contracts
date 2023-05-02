%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.math_cmp import is_not_zero
from starkware.cairo.common.bitwise import bitwise_and
from starkware.cairo.common.uint256 import Uint256, uint256_le, uint256_eq
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address
from openzeppelin.security.initializable.library import Initializable
from openzeppelin.security.safemath.library import SafeUint256
from openzeppelin.token.erc20.IERC20 import IERC20
from src.libraries.structs.Route import Route
from src.libraries.interfaces.ISwapAdapter import ISwapAdapter
from src.libraries.interfaces.IAVNUFeeCollector import IAVNUFeeCollector

//
// Events
//
@event
func Swap(
    taker_address: felt, sell_address: felt, sell_amount: felt, buy_address: felt, buy_amount: felt
) {
}

//
// Storage
//
@storage_var
func AdapterClassHash(exchange_address) -> (adapter_class_hash: felt) {
}

@storage_var
func FeeCollectorAddress() -> (fee_collector_address: felt) {
}

namespace AVNUExchange {
    func initialize{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        fee_collector_address: felt
    ) {
        Initializable.initialize();
        setFeeCollectorAddress(fee_collector_address);
        return ();
    }

    func getAdapterClassHash{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        exchange_address: felt
    ) -> (adapter_class_hash: felt) {
        let (adapter_class_hash) = AdapterClassHash.read(exchange_address);
        return (adapter_class_hash,);
    }

    func getFeeCollectorAddress{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        ) -> (fee_collector_address: felt) {
        let (fee_collector_address) = FeeCollectorAddress.read();
        return (fee_collector_address,);
    }

    func setAdapterClassHash{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        exchange_address: felt, adapter_class_hash: felt
    ) {
        AdapterClassHash.write(exchange_address, adapter_class_hash);
        return ();
    }

    func setFeeCollectorAddress{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        new_fee_collector_address: felt
    ) {
        with_attr error_message("AVNUExchange: Fee collector address cannot be 0") {
            assert_not_zero(new_fee_collector_address);
        }
        FeeCollectorAddress.write(new_fee_collector_address);
        return ();
    }

    func multi_route_swap{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
        bitwise_ptr: BitwiseBuiltin*,
    }(
        token_from_address: felt,
        token_from_amount: Uint256,
        token_to_address: felt,
        token_to_min_amount: Uint256,
        integrator_fee_amount_bps: felt,
        integrator_fee_recipient: felt,
        routes: Route*,
        routes_len: felt,
    ) -> (success: felt) {
        alloc_locals;

        let (caller_address) = get_caller_address();
        let (contract_address) = get_contract_address();

        // Transfer tokens to contract
        IERC20.transferFrom(
            token_from_address, caller_address, contract_address, token_from_amount
        );

        // Collect fees
        _collect_fees(
            token_from_amount.low,
            token_from_address,
            integrator_fee_amount_bps,
            integrator_fee_recipient,
            0,
        );

        // Swap
        _apply_routes(&routes[0], routes_len);

        // Retrieve amount of token to received
        let (received_token_to) = IERC20.balanceOf(token_to_address, contract_address);

        // Check if received amount if higher than min amount
        with_attr error_message("Insufficient tokens received") {
            let (sufficient: felt) = uint256_le(token_to_min_amount, received_token_to);
            assert sufficient = TRUE;
        }

        // Check no remaining tokens
        _assert_no_lost_tokens(routes, routes_len, token_to_address);

        // Transfer tokens to user
        IERC20.transfer(token_to_address, caller_address, received_token_to);

        // Emit event
        Swap.emit(
            caller_address,
            token_from_address,
            token_from_amount.low,
            token_to_address,
            received_token_to.low,
        );

        return (TRUE,);
    }

    func _apply_routes{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        routes: Route*, routes_len: felt
    ) -> (routes_len: felt) {
        alloc_locals;
        if (routes_len == 0) {
            return (routes_len,);
        }
        let route: Route = routes[0];
        let (contract_address) = get_contract_address();

        // Calculating tokens to be passed to the exchange
        // percentage should be 2 for 2%
        let (token_from_balance) = IERC20.balanceOf(route.token_from, contract_address);
        let (big_amount: Uint256) = SafeUint256.mul(token_from_balance, Uint256(route.percent, 0));
        let (token_from_amount: Uint256, rem: Uint256) = SafeUint256.div_rem(
            big_amount, Uint256(100, 0)
        );

        // Get adapter class hash
        let (adapter_class_hash) = AdapterClassHash.read(route.exchange_address);
        with_attr error_message("Unknown exchange") {
            assert_not_zero(adapter_class_hash);
        }

        ISwapAdapter.library_call_swap(
            adapter_class_hash,
            route.exchange_address,
            route.token_from,
            token_from_amount,
            route.token_to,
            Uint256(0, 0),
            contract_address,
        );

        return _apply_routes(&routes[1], routes_len - 1);
    }

    func _assert_no_lost_tokens{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        routes: Route*, routes_len: felt, last_token: felt
    ) -> (routes_len: felt) {
        alloc_locals;
        if (routes_len == 0) {
            return (routes_len,);
        }
        let (contract_address) = get_contract_address();
        let route: Route = routes[0];
        if (route.token_from != last_token) {
            let (balance) = IERC20.balanceOf(route.token_from, contract_address);
            with_attr error_message("Invalid routes percentages") {
                let (is_zero) = uint256_eq(Uint256(0, 0), balance);
                assert is_zero = TRUE;
            }
            tempvar range_check_ptr = range_check_ptr;
            tempvar syscall_ptr = syscall_ptr;
        } else {
            tempvar range_check_ptr = range_check_ptr;
            tempvar syscall_ptr = syscall_ptr;
        }
        return _assert_no_lost_tokens(&routes[1], routes_len - 1, last_token);
    }

    func _collect_fee_bps{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
        bitwise_ptr: BitwiseBuiltin*,
    }(
        amount: felt,
        token_address: felt,
        fee_amount_bps: felt,
        fee_recipient: felt,
        collect_from_address: felt,
        is_base_active: felt,
    ) -> (fees_collected: Uint256) {
        alloc_locals;

        let is_fee_amount_not_zero = is_not_zero(fee_amount_bps);
        let is_fee_recipient_not_zero = is_not_zero(fee_recipient);
        let (is_fee_active) = bitwise_and(is_fee_amount_not_zero, is_fee_recipient_not_zero);
        let (is_fee_active) = bitwise_and(is_fee_active, is_base_active);

        // Fee collector is active when recipient & amount are defined, don't throw exception for UX purpose
        // -> It's integrator work to defined it correctly
        let fees_amount = Uint256(0, 0);
        if (is_fee_active == TRUE) {
            // fee_amount in BPS
            let (big_amount: Uint256) = SafeUint256.mul(
                Uint256(amount, 0), Uint256(fee_amount_bps, 0)
            );
            let (fees_amount: Uint256, rem: Uint256) = SafeUint256.div_rem(
                big_amount, Uint256(10000, 0)
            );

            let collect_from_external = is_not_zero(collect_from_address);

            // Send fees to fee recipient
            if (collect_from_external == TRUE) {
                // Collect fees from external source (should be approved)
                IERC20.transferFrom(
                    token_address, collect_from_address, fee_recipient, fees_amount
                );
            } else {
                // Collect fees from contract
                IERC20.transfer(token_address, fee_recipient, fees_amount);
            }

            // see https://www.cairo-lang.org/docs/how_cairo_works/builtins.html?highlight=builtins#revoked-implicit-arguments
            tempvar range_check_ptr = range_check_ptr;
            tempvar syscall_ptr = syscall_ptr;
            tempvar fees_amount = fees_amount;
        } else {
            // see https://www.cairo-lang.org/docs/how_cairo_works/builtins.html?highlight=builtins#revoked-implicit-arguments
            tempvar range_check_ptr = range_check_ptr;
            tempvar syscall_ptr = syscall_ptr;
            tempvar fees_amount = fees_amount;
        }

        return (fees_collected=fees_amount);
    }

    func _collect_fees{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
        bitwise_ptr: BitwiseBuiltin*,
    }(
        amount: felt,
        token_address: felt,
        integrator_fee_amount_bps: felt,
        integrator_fee_recipient: felt,
        collect_from_address: felt,
    ) -> (amount_including_fees: felt) {
        alloc_locals;

        let (avnu_fee_collector_address) = FeeCollectorAddress.read();
        let (is_avnu_fee_active, fee_type, avnu_fee_amount_bps) = IAVNUFeeCollector.feeInfo(
            avnu_fee_collector_address
        );

        // ---------------- Integrator fees ---------------- //
        let (integrator_fees_collected) = _collect_fee_bps(
            amount,
            token_address,
            integrator_fee_amount_bps,
            integrator_fee_recipient,
            collect_from_address,
            TRUE,
        );

        // ---------------- AVNU fees ---------------- //
        // TODO check fee type of fees
        let (avnu_fees_collected) = _collect_fee_bps(
            amount,
            token_address,
            avnu_fee_amount_bps,
            avnu_fee_collector_address,
            collect_from_address,
            is_avnu_fee_active,
        );

        let (amount_including_fees_integrator: Uint256) = SafeUint256.sub_le(
            Uint256(amount, 0), integrator_fees_collected
        );
        let (amount_including_fees_full: Uint256) = SafeUint256.sub_le(
            amount_including_fees_integrator, avnu_fees_collected
        );
        return (amount_including_fees=amount_including_fees_full.low);
    }
}
