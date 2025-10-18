// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title VoucherRedeemer
 * @notice Lock funds tied to keccak256(secret). Redeem with secret or refund after expiry.
 * @dev Used by TapCapsule for tap-to-redeem crypto vouchers
 */
contract VoucherRedeemer is ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ============================================
    // STATE
    // ============================================

    struct Voucher {
        address creator;      // Who created the voucher
        address token;        // Token address (address(0) = native ETH)
        uint256 amount;       // Amount locked
        uint64 expiry;        // Expiry timestamp
        bool redeemed;        // Whether it's been redeemed
    }

    // Hash of secret => Voucher
    mapping(bytes32 => Voucher) public vouchers;

    // ============================================
    // EVENTS
    // ============================================

    event VoucherCreated(
        bytes32 indexed h,
        address indexed creator,
        address token,
        uint256 amount,
        uint64 expiry
    );

    event VoucherRedeemed(
        bytes32 indexed h,
        address indexed redeemer
    );

    event VoucherRefunded(
        bytes32 indexed h
    );

    // ============================================
    // ERRORS
    // ============================================

    error InvalidAmount();
    error InvalidExpiry();
    error VoucherAlreadyExists();
    error VoucherNotFound();
    error VoucherAlreadyRedeemed();
    error VoucherExpired();
    error VoucherNotExpired();
    error InvalidSecret();
    error OnlyCreator();
    error TransferFailed();

    // ============================================
    // EXTERNAL FUNCTIONS
    // ============================================

    /**
     * @notice Create a voucher by locking funds under hash of secret
     * @param h keccak256(secret)
     * @param token Token address (address(0) for ETH)
     * @param amount Amount to lock
     * @param expiry Expiry timestamp
     */
    function createVoucher(
        bytes32 h,
        address token,
        uint256 amount,
        uint64 expiry
    ) external payable nonReentrant {
        // Validations
        if (amount == 0) revert InvalidAmount();
        if (expiry <= block.timestamp) revert InvalidExpiry();
        if (vouchers[h].creator != address(0)) revert VoucherAlreadyExists();

        // Handle payment
        if (token == address(0)) {
            // Native ETH
            if (msg.value != amount) revert InvalidAmount();
        } else {
            // ERC-20
            if (msg.value != 0) revert InvalidAmount();
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        }

        // Create voucher
        vouchers[h] = Voucher({
            creator: msg.sender,
            token: token,
            amount: amount,
            expiry: expiry,
            redeemed: false
        });

        emit VoucherCreated(h, msg.sender, token, amount, expiry);
    }

    /**
     * @notice Redeem voucher by providing the secret
     * @param secret The secret that hashes to the voucher's h
     */
    function redeem(bytes memory secret) external nonReentrant {
        bytes32 h = keccak256(secret);
        Voucher storage voucher = vouchers[h];

        // Validations
        if (voucher.creator == address(0)) revert VoucherNotFound();
        if (voucher.redeemed) revert VoucherAlreadyRedeemed();
        if (block.timestamp > voucher.expiry) revert VoucherExpired();

        // Mark as redeemed BEFORE transfer (CEI pattern)
        voucher.redeemed = true;

        // Transfer funds to redeemer
        _transferFunds(voucher.token, msg.sender, voucher.amount);

        emit VoucherRedeemed(h, msg.sender);
    }

    /**
     * @notice Refund voucher after expiry (only creator)
     * @param h Hash of the secret
     */
    function refund(bytes32 h) external nonReentrant {
        Voucher storage voucher = vouchers[h];

        // Validations
        if (voucher.creator == address(0)) revert VoucherNotFound();
        if (voucher.redeemed) revert VoucherAlreadyRedeemed();
        if (msg.sender != voucher.creator) revert OnlyCreator();
        if (block.timestamp <= voucher.expiry) revert VoucherNotExpired();

        // Mark as redeemed BEFORE transfer (CEI pattern)
        voucher.redeemed = true;

        // Transfer funds back to creator
        _transferFunds(voucher.token, voucher.creator, voucher.amount);

        emit VoucherRefunded(h);
    }

    // ============================================
    // INTERNAL FUNCTIONS
    // ============================================

    /**
     * @notice Internal function to transfer ETH or ERC-20
     * @param token Token address (address(0) for ETH)
     * @param to Recipient
     * @param amount Amount to transfer
     */
    function _transferFunds(
        address token,
        address to,
        uint256 amount
    ) internal {
        if (token == address(0)) {
            // Native ETH
            (bool success, ) = to.call{value: amount}("");
            if (!success) revert TransferFailed();
        } else {
            // ERC-20
            IERC20(token).safeTransfer(to, amount);
        }
    }

    // ============================================
    // VIEW FUNCTIONS
    // ============================================

    /**
     * @notice Check if a voucher is valid and active
     * @param h Hash of the secret
     * @return isValid True if voucher exists, not redeemed, and not expired
     */
    function isVoucherValid(bytes32 h) external view returns (bool isValid) {
        Voucher memory voucher = vouchers[h];
        return voucher.creator != address(0) &&
               !voucher.redeemed &&
               block.timestamp <= voucher.expiry;
    }

    /**
     * @notice Get voucher details
     * @param h Hash of the secret
     */
    function getVoucher(bytes32 h) external view returns (
        address creator,
        address token,
        uint256 amount,
        uint64 expiry,
        bool redeemed
    ) {
        Voucher memory voucher = vouchers[h];
        return (
            voucher.creator,
            voucher.token,
            voucher.amount,
            voucher.expiry,
            voucher.redeemed
        );
    }
}
