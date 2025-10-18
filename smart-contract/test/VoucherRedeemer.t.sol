// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../contracts/VoucherRedeemer.sol";

contract VoucherRedeemerTest is Test {
    VoucherRedeemer public voucherRedeemer;

    address creator = address(0x1);
    address redeemer = address(0x2);
    address other = address(0x3);

    uint256 constant AMOUNT = 0.001 ether;
    uint64 constant EXPIRY_DURATION = 86400; // 24 hours

    function setUp() public {
        voucherRedeemer = new VoucherRedeemer();

        // Fund test accounts
        vm.deal(creator, 10 ether);
        vm.deal(redeemer, 10 ether);
        vm.deal(other, 10 ether);
    }

    // ============================================
    // CREATE VOUCHER TESTS
    // ============================================

    function test_CreateVoucher() public {
        bytes32 secret = bytes32(uint256(123456));
        bytes32 h = keccak256(abi.encodePacked(secret));
        uint64 expiry = uint64(block.timestamp + EXPIRY_DURATION);

        vm.prank(creator);
        voucherRedeemer.createVoucher{value: AMOUNT}(
            h,
            address(0),
            AMOUNT,
            expiry
        );

        (address vCreator, address token, uint256 amount, uint64 vExpiry, bool redeemed) =
            voucherRedeemer.getVoucher(h);

        assertEq(vCreator, creator);
        assertEq(token, address(0));
        assertEq(amount, AMOUNT);
        assertEq(vExpiry, expiry);
        assertFalse(redeemed);
        assertTrue(voucherRedeemer.isVoucherValid(h));
    }

    function test_CreateVoucher_RevertIfAmountZero() public {
        bytes32 h = keccak256(abi.encodePacked("secret"));
        uint64 expiry = uint64(block.timestamp + EXPIRY_DURATION);

        vm.prank(creator);
        vm.expectRevert(VoucherRedeemer.InvalidAmount.selector);
        voucherRedeemer.createVoucher{value: 0}(
            h,
            address(0),
            0,
            expiry
        );
    }

    function test_CreateVoucher_RevertIfExpiryPast() public {
        bytes32 h = keccak256(abi.encodePacked("secret"));
        // Set expiry to current timestamp (not in future)
        uint64 expiry = uint64(block.timestamp);

        vm.prank(creator);
        vm.expectRevert(VoucherRedeemer.InvalidExpiry.selector);
        voucherRedeemer.createVoucher{value: AMOUNT}(
            h,
            address(0),
            AMOUNT,
            expiry
        );
    }

    function test_CreateVoucher_RevertIfAlreadyExists() public {
        bytes32 h = keccak256(abi.encodePacked("secret"));
        uint64 expiry = uint64(block.timestamp + EXPIRY_DURATION);

        vm.startPrank(creator);
        voucherRedeemer.createVoucher{value: AMOUNT}(
            h,
            address(0),
            AMOUNT,
            expiry
        );

        vm.expectRevert(VoucherRedeemer.VoucherAlreadyExists.selector);
        voucherRedeemer.createVoucher{value: AMOUNT}(
            h,
            address(0),
            AMOUNT,
            expiry
        );
        vm.stopPrank();
    }

    function test_CreateVoucher_RevertIfValueMismatch() public {
        bytes32 h = keccak256(abi.encodePacked("secret"));
        uint64 expiry = uint64(block.timestamp + EXPIRY_DURATION);

        vm.prank(creator);
        vm.expectRevert(VoucherRedeemer.InvalidAmount.selector);
        voucherRedeemer.createVoucher{value: AMOUNT + 1}(
            h,
            address(0),
            AMOUNT,
            expiry
        );
    }

    // ============================================
    // REDEEM TESTS
    // ============================================

    function test_Redeem() public {
        bytes memory secret = abi.encodePacked(bytes32(uint256(123456)));
        bytes32 h = keccak256(secret);
        uint64 expiry = uint64(block.timestamp + EXPIRY_DURATION);

        // Create voucher
        vm.prank(creator);
        voucherRedeemer.createVoucher{value: AMOUNT}(
            h,
            address(0),
            AMOUNT,
            expiry
        );

        // Redeem
        uint256 balanceBefore = redeemer.balance;
        vm.prank(redeemer);
        voucherRedeemer.redeem(secret);

        uint256 balanceAfter = redeemer.balance;
        assertEq(balanceAfter - balanceBefore, AMOUNT);

        // Check voucher is marked as redeemed
        (,,,, bool redeemed) = voucherRedeemer.getVoucher(h);
        assertTrue(redeemed);
        assertFalse(voucherRedeemer.isVoucherValid(h));
    }

    function test_Redeem_RevertIfWrongSecret() public {
        bytes memory secret = abi.encodePacked(bytes32(uint256(123456)));
        bytes32 h = keccak256(secret);
        uint64 expiry = uint64(block.timestamp + EXPIRY_DURATION);

        // Create voucher
        vm.prank(creator);
        voucherRedeemer.createVoucher{value: AMOUNT}(
            h,
            address(0),
            AMOUNT,
            expiry
        );

        // Try to redeem with wrong secret
        bytes memory wrongSecret = abi.encodePacked(bytes32(uint256(999999)));
        vm.prank(redeemer);
        vm.expectRevert(VoucherRedeemer.VoucherNotFound.selector);
        voucherRedeemer.redeem(wrongSecret);
    }

    function test_Redeem_RevertIfAlreadyRedeemed() public {
        bytes memory secret = abi.encodePacked(bytes32(uint256(123456)));
        bytes32 h = keccak256(secret);
        uint64 expiry = uint64(block.timestamp + EXPIRY_DURATION);

        // Create voucher
        vm.prank(creator);
        voucherRedeemer.createVoucher{value: AMOUNT}(
            h,
            address(0),
            AMOUNT,
            expiry
        );

        // First redeem
        vm.prank(redeemer);
        voucherRedeemer.redeem(secret);

        // Try to redeem again
        vm.prank(other);
        vm.expectRevert(VoucherRedeemer.VoucherAlreadyRedeemed.selector);
        voucherRedeemer.redeem(secret);
    }

    function test_Redeem_RevertIfExpired() public {
        bytes memory secret = abi.encodePacked(bytes32(uint256(123456)));
        bytes32 h = keccak256(secret);
        uint64 expiry = uint64(block.timestamp + EXPIRY_DURATION);

        // Create voucher
        vm.prank(creator);
        voucherRedeemer.createVoucher{value: AMOUNT}(
            h,
            address(0),
            AMOUNT,
            expiry
        );

        // Fast forward past expiry
        vm.warp(expiry + 1);

        // Try to redeem
        vm.prank(redeemer);
        vm.expectRevert(VoucherRedeemer.VoucherExpired.selector);
        voucherRedeemer.redeem(secret);
    }

    // ============================================
    // REFUND TESTS
    // ============================================

    function test_Refund() public {
        bytes32 h = keccak256(abi.encodePacked("secret"));
        uint64 expiry = uint64(block.timestamp + EXPIRY_DURATION);

        // Create voucher
        vm.prank(creator);
        voucherRedeemer.createVoucher{value: AMOUNT}(
            h,
            address(0),
            AMOUNT,
            expiry
        );

        // Fast forward past expiry
        vm.warp(expiry + 1);

        // Refund
        uint256 balanceBefore = creator.balance;
        vm.prank(creator);
        voucherRedeemer.refund(h);

        uint256 balanceAfter = creator.balance;
        assertEq(balanceAfter - balanceBefore, AMOUNT);

        // Check voucher is marked as redeemed
        (,,,, bool redeemed) = voucherRedeemer.getVoucher(h);
        assertTrue(redeemed);
    }

    function test_Refund_RevertIfNotExpired() public {
        bytes32 h = keccak256(abi.encodePacked("secret"));
        uint64 expiry = uint64(block.timestamp + EXPIRY_DURATION);

        // Create voucher
        vm.prank(creator);
        voucherRedeemer.createVoucher{value: AMOUNT}(
            h,
            address(0),
            AMOUNT,
            expiry
        );

        // Try to refund before expiry
        vm.prank(creator);
        vm.expectRevert(VoucherRedeemer.VoucherNotExpired.selector);
        voucherRedeemer.refund(h);
    }

    function test_Refund_RevertIfNotCreator() public {
        bytes32 h = keccak256(abi.encodePacked("secret"));
        uint64 expiry = uint64(block.timestamp + EXPIRY_DURATION);

        // Create voucher
        vm.prank(creator);
        voucherRedeemer.createVoucher{value: AMOUNT}(
            h,
            address(0),
            AMOUNT,
            expiry
        );

        // Fast forward past expiry
        vm.warp(expiry + 1);

        // Try to refund as non-creator
        vm.prank(other);
        vm.expectRevert(VoucherRedeemer.OnlyCreator.selector);
        voucherRedeemer.refund(h);
    }

    function test_Refund_RevertIfAlreadyRedeemed() public {
        bytes memory secret = abi.encodePacked(bytes32(uint256(123456)));
        bytes32 h = keccak256(secret);
        uint64 expiry = uint64(block.timestamp + EXPIRY_DURATION);

        // Create voucher
        vm.prank(creator);
        voucherRedeemer.createVoucher{value: AMOUNT}(
            h,
            address(0),
            AMOUNT,
            expiry
        );

        // Redeem before expiry
        vm.prank(redeemer);
        voucherRedeemer.redeem(secret);

        // Fast forward past expiry
        vm.warp(expiry + 1);

        // Try to refund
        vm.prank(creator);
        vm.expectRevert(VoucherRedeemer.VoucherAlreadyRedeemed.selector);
        voucherRedeemer.refund(h);
    }

    // ============================================
    // FUZZ TESTS
    // ============================================

    function testFuzz_CreateAndRedeem(uint256 secretNum, uint96 amount) public {
        vm.assume(amount > 0);
        vm.assume(amount <= 1 ether); // Reasonable limit

        bytes memory secret = abi.encodePacked(bytes32(secretNum));
        bytes32 h = keccak256(secret);
        uint64 expiry = uint64(block.timestamp + EXPIRY_DURATION);

        // Create voucher
        vm.prank(creator);
        voucherRedeemer.createVoucher{value: amount}(
            h,
            address(0),
            amount,
            expiry
        );

        // Redeem
        uint256 balanceBefore = redeemer.balance;
        vm.prank(redeemer);
        voucherRedeemer.redeem(secret);

        uint256 balanceAfter = redeemer.balance;
        assertEq(balanceAfter - balanceBefore, amount);
    }
}
