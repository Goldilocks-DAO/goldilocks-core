// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20 ^0.8.4;
pragma abicoder v2;

// lib/solady/src/tokens/ERC20.sol

/// @notice Simple ERC20 + EIP-2612 implementation.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol)
///
/// @dev Note:
/// - The ERC20 standard allows minting and transferring to and from the zero address,
///   minting and transferring zero tokens, as well as self-approvals.
///   For performance, this implementation WILL NOT revert for such actions.
///   Please add any checks with overrides if desired.
/// - The `permit` function uses the ecrecover precompile (0x1).
///
/// If you are overriding:
/// - NEVER violate the ERC20 invariant:
///   the total sum of all balances must be equal to `totalSupply()`.
/// - Check that the overridden function is actually used in the function you want to
///   change the behavior of. Much of the code has been manually inlined for performance.
abstract contract ERC20 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The total supply has overflowed.
    error TotalSupplyOverflow();

    /// @dev The allowance has overflowed.
    error AllowanceOverflow();

    /// @dev The allowance has underflowed.
    error AllowanceUnderflow();

    /// @dev Insufficient balance.
    error InsufficientBalance();

    /// @dev Insufficient allowance.
    error InsufficientAllowance();

    /// @dev The permit is invalid.
    error InvalidPermit();

    /// @dev The permit has expired.
    error PermitExpired();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Emitted when `amount` tokens is transferred from `from` to `to`.
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @dev Emitted when `amount` tokens is approved by `owner` to be used by `spender`.
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /// @dev `keccak256(bytes("Transfer(address,address,uint256)"))`.
    uint256 private constant _TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    /// @dev `keccak256(bytes("Approval(address,address,uint256)"))`.
    uint256 private constant _APPROVAL_EVENT_SIGNATURE =
        0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The storage slot for the total supply.
    uint256 private constant _TOTAL_SUPPLY_SLOT = 0x05345cdf77eb68f44c;

    /// @dev The balance slot of `owner` is given by:
    /// ```
    ///     mstore(0x0c, _BALANCE_SLOT_SEED)
    ///     mstore(0x00, owner)
    ///     let balanceSlot := keccak256(0x0c, 0x20)
    /// ```
    uint256 private constant _BALANCE_SLOT_SEED = 0x87a211a2;

    /// @dev The allowance slot of (`owner`, `spender`) is given by:
    /// ```
    ///     mstore(0x20, spender)
    ///     mstore(0x0c, _ALLOWANCE_SLOT_SEED)
    ///     mstore(0x00, owner)
    ///     let allowanceSlot := keccak256(0x0c, 0x34)
    /// ```
    uint256 private constant _ALLOWANCE_SLOT_SEED = 0x7f5e9f20;

    /// @dev The nonce slot of `owner` is given by:
    /// ```
    ///     mstore(0x0c, _NONCES_SLOT_SEED)
    ///     mstore(0x00, owner)
    ///     let nonceSlot := keccak256(0x0c, 0x20)
    /// ```
    uint256 private constant _NONCES_SLOT_SEED = 0x38377508;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev `(_NONCES_SLOT_SEED << 16) | 0x1901`.
    uint256 private constant _NONCES_SLOT_SEED_WITH_SIGNATURE_PREFIX = 0x383775081901;

    /// @dev `keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")`.
    bytes32 private constant _DOMAIN_TYPEHASH =
        0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    /// @dev `keccak256("1")`.
    bytes32 private constant _VERSION_HASH =
        0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6;

    /// @dev `keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")`.
    bytes32 private constant _PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       ERC20 METADATA                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the name of the token.
    function name() public view virtual returns (string memory);

    /// @dev Returns the symbol of the token.
    function symbol() public view virtual returns (string memory);

    /// @dev Returns the decimals places of the token.
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           ERC20                            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the amount of tokens in existence.
    function totalSupply() public view virtual returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := sload(_TOTAL_SUPPLY_SLOT)
        }
    }

    /// @dev Returns the amount of tokens owned by `owner`.
    function balanceOf(address owner) public view virtual returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x0c, _BALANCE_SLOT_SEED)
            mstore(0x00, owner)
            result := sload(keccak256(0x0c, 0x20))
        }
    }

    /// @dev Returns the amount of tokens that `spender` can spend on behalf of `owner`.
    function allowance(address owner, address spender)
        public
        view
        virtual
        returns (uint256 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x20, spender)
            mstore(0x0c, _ALLOWANCE_SLOT_SEED)
            mstore(0x00, owner)
            result := sload(keccak256(0x0c, 0x34))
        }
    }

    /// @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
    ///
    /// Emits a {Approval} event.
    function approve(address spender, uint256 amount) public virtual returns (bool) {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the allowance slot and store the amount.
            mstore(0x20, spender)
            mstore(0x0c, _ALLOWANCE_SLOT_SEED)
            mstore(0x00, caller())
            sstore(keccak256(0x0c, 0x34), amount)
            // Emit the {Approval} event.
            mstore(0x00, amount)
            log3(0x00, 0x20, _APPROVAL_EVENT_SIGNATURE, caller(), shr(96, mload(0x2c)))
        }
        return true;
    }

    /// @dev Transfer `amount` tokens from the caller to `to`.
    ///
    /// Requirements:
    /// - `from` must at least have `amount`.
    ///
    /// Emits a {Transfer} event.
    function transfer(address to, uint256 amount) public virtual returns (bool) {
        _beforeTokenTransfer(msg.sender, to, amount);
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the balance slot and load its value.
            mstore(0x0c, _BALANCE_SLOT_SEED)
            mstore(0x00, caller())
            let fromBalanceSlot := keccak256(0x0c, 0x20)
            let fromBalance := sload(fromBalanceSlot)
            // Revert if insufficient balance.
            if gt(amount, fromBalance) {
                mstore(0x00, 0xf4d678b8) // `InsufficientBalance()`.
                revert(0x1c, 0x04)
            }
            // Subtract and store the updated balance.
            sstore(fromBalanceSlot, sub(fromBalance, amount))
            // Compute the balance slot of `to`.
            mstore(0x00, to)
            let toBalanceSlot := keccak256(0x0c, 0x20)
            // Add and store the updated balance of `to`.
            // Will not overflow because the sum of all user balances
            // cannot exceed the maximum uint256 value.
            sstore(toBalanceSlot, add(sload(toBalanceSlot), amount))
            // Emit the {Transfer} event.
            mstore(0x20, amount)
            log3(0x20, 0x20, _TRANSFER_EVENT_SIGNATURE, caller(), shr(96, mload(0x0c)))
        }
        _afterTokenTransfer(msg.sender, to, amount);
        return true;
    }

    /// @dev Transfers `amount` tokens from `from` to `to`.
    ///
    /// Note: Does not update the allowance if it is the maximum uint256 value.
    ///
    /// Requirements:
    /// - `from` must at least have `amount`.
    /// - The caller must have at least `amount` of allowance to transfer the tokens of `from`.
    ///
    /// Emits a {Transfer} event.
    function transferFrom(address from, address to, uint256 amount) public virtual returns (bool) {
        _beforeTokenTransfer(from, to, amount);
        /// @solidity memory-safe-assembly
        assembly {
            let from_ := shl(96, from)
            // Compute the allowance slot and load its value.
            mstore(0x20, caller())
            mstore(0x0c, or(from_, _ALLOWANCE_SLOT_SEED))
            let allowanceSlot := keccak256(0x0c, 0x34)
            let allowance_ := sload(allowanceSlot)
            // If the allowance is not the maximum uint256 value.
            if add(allowance_, 1) {
                // Revert if the amount to be transferred exceeds the allowance.
                if gt(amount, allowance_) {
                    mstore(0x00, 0x13be252b) // `InsufficientAllowance()`.
                    revert(0x1c, 0x04)
                }
                // Subtract and store the updated allowance.
                sstore(allowanceSlot, sub(allowance_, amount))
            }
            // Compute the balance slot and load its value.
            mstore(0x0c, or(from_, _BALANCE_SLOT_SEED))
            let fromBalanceSlot := keccak256(0x0c, 0x20)
            let fromBalance := sload(fromBalanceSlot)
            // Revert if insufficient balance.
            if gt(amount, fromBalance) {
                mstore(0x00, 0xf4d678b8) // `InsufficientBalance()`.
                revert(0x1c, 0x04)
            }
            // Subtract and store the updated balance.
            sstore(fromBalanceSlot, sub(fromBalance, amount))
            // Compute the balance slot of `to`.
            mstore(0x00, to)
            let toBalanceSlot := keccak256(0x0c, 0x20)
            // Add and store the updated balance of `to`.
            // Will not overflow because the sum of all user balances
            // cannot exceed the maximum uint256 value.
            sstore(toBalanceSlot, add(sload(toBalanceSlot), amount))
            // Emit the {Transfer} event.
            mstore(0x20, amount)
            log3(0x20, 0x20, _TRANSFER_EVENT_SIGNATURE, shr(96, from_), shr(96, mload(0x0c)))
        }
        _afterTokenTransfer(from, to, amount);
        return true;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          EIP-2612                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev For more performance, override to return the constant value
    /// of `keccak256(bytes(name()))` if `name()` will never change.
    function _constantNameHash() internal view virtual returns (bytes32 result) {}

    /// @dev Returns the current nonce for `owner`.
    /// This value is used to compute the signature for EIP-2612 permit.
    function nonces(address owner) public view virtual returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the nonce slot and load its value.
            mstore(0x0c, _NONCES_SLOT_SEED)
            mstore(0x00, owner)
            result := sload(keccak256(0x0c, 0x20))
        }
    }

    /// @dev Sets `value` as the allowance of `spender` over the tokens of `owner`,
    /// authorized by a signed approval by `owner`.
    ///
    /// Emits a {Approval} event.
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        bytes32 nameHash = _constantNameHash();
        //  We simply calculate it on-the-fly to allow for cases where the `name` may change.
        if (nameHash == bytes32(0)) nameHash = keccak256(bytes(name()));
        /// @solidity memory-safe-assembly
        assembly {
            // Revert if the block timestamp is greater than `deadline`.
            if gt(timestamp(), deadline) {
                mstore(0x00, 0x1a15a3cc) // `PermitExpired()`.
                revert(0x1c, 0x04)
            }
            let m := mload(0x40) // Grab the free memory pointer.
            // Clean the upper 96 bits.
            owner := shr(96, shl(96, owner))
            spender := shr(96, shl(96, spender))
            // Compute the nonce slot and load its value.
            mstore(0x0e, _NONCES_SLOT_SEED_WITH_SIGNATURE_PREFIX)
            mstore(0x00, owner)
            let nonceSlot := keccak256(0x0c, 0x20)
            let nonceValue := sload(nonceSlot)
            // Prepare the domain separator.
            mstore(m, _DOMAIN_TYPEHASH)
            mstore(add(m, 0x20), nameHash)
            mstore(add(m, 0x40), _VERSION_HASH)
            mstore(add(m, 0x60), chainid())
            mstore(add(m, 0x80), address())
            mstore(0x2e, keccak256(m, 0xa0))
            // Prepare the struct hash.
            mstore(m, _PERMIT_TYPEHASH)
            mstore(add(m, 0x20), owner)
            mstore(add(m, 0x40), spender)
            mstore(add(m, 0x60), value)
            mstore(add(m, 0x80), nonceValue)
            mstore(add(m, 0xa0), deadline)
            mstore(0x4e, keccak256(m, 0xc0))
            // Prepare the ecrecover calldata.
            mstore(0x00, keccak256(0x2c, 0x42))
            mstore(0x20, and(0xff, v))
            mstore(0x40, r)
            mstore(0x60, s)
            let t := staticcall(gas(), 1, 0, 0x80, 0x20, 0x20)
            // If the ecrecover fails, the returndatasize will be 0x00,
            // `owner` will be checked if it equals the hash at 0x00,
            // which evaluates to false (i.e. 0), and we will revert.
            // If the ecrecover succeeds, the returndatasize will be 0x20,
            // `owner` will be compared against the returned address at 0x20.
            if iszero(eq(mload(returndatasize()), owner)) {
                mstore(0x00, 0xddafbaef) // `InvalidPermit()`.
                revert(0x1c, 0x04)
            }
            // Increment and store the updated nonce.
            sstore(nonceSlot, add(nonceValue, t)) // `t` is 1 if ecrecover succeeds.
            // Compute the allowance slot and store the value.
            // The `owner` is already at slot 0x20.
            mstore(0x40, or(shl(160, _ALLOWANCE_SLOT_SEED), spender))
            sstore(keccak256(0x2c, 0x34), value)
            // Emit the {Approval} event.
            log3(add(m, 0x60), 0x20, _APPROVAL_EVENT_SIGNATURE, owner, spender)
            mstore(0x40, m) // Restore the free memory pointer.
            mstore(0x60, 0) // Restore the zero pointer.
        }
    }

    /// @dev Returns the EIP-712 domain separator for the EIP-2612 permit.
    function DOMAIN_SEPARATOR() public view virtual returns (bytes32 result) {
        bytes32 nameHash = _constantNameHash();
        //  We simply calculate it on-the-fly to allow for cases where the `name` may change.
        if (nameHash == bytes32(0)) nameHash = keccak256(bytes(name()));
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Grab the free memory pointer.
            mstore(m, _DOMAIN_TYPEHASH)
            mstore(add(m, 0x20), nameHash)
            mstore(add(m, 0x40), _VERSION_HASH)
            mstore(add(m, 0x60), chainid())
            mstore(add(m, 0x80), address())
            result := keccak256(m, 0xa0)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  INTERNAL MINT FUNCTIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Mints `amount` tokens to `to`, increasing the total supply.
    ///
    /// Emits a {Transfer} event.
    function _mint(address to, uint256 amount) internal virtual {
        _beforeTokenTransfer(address(0), to, amount);
        /// @solidity memory-safe-assembly
        assembly {
            let totalSupplyBefore := sload(_TOTAL_SUPPLY_SLOT)
            let totalSupplyAfter := add(totalSupplyBefore, amount)
            // Revert if the total supply overflows.
            if lt(totalSupplyAfter, totalSupplyBefore) {
                mstore(0x00, 0xe5cfe957) // `TotalSupplyOverflow()`.
                revert(0x1c, 0x04)
            }
            // Store the updated total supply.
            sstore(_TOTAL_SUPPLY_SLOT, totalSupplyAfter)
            // Compute the balance slot and load its value.
            mstore(0x0c, _BALANCE_SLOT_SEED)
            mstore(0x00, to)
            let toBalanceSlot := keccak256(0x0c, 0x20)
            // Add and store the updated balance.
            sstore(toBalanceSlot, add(sload(toBalanceSlot), amount))
            // Emit the {Transfer} event.
            mstore(0x20, amount)
            log3(0x20, 0x20, _TRANSFER_EVENT_SIGNATURE, 0, shr(96, mload(0x0c)))
        }
        _afterTokenTransfer(address(0), to, amount);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  INTERNAL BURN FUNCTIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Burns `amount` tokens from `from`, reducing the total supply.
    ///
    /// Emits a {Transfer} event.
    function _burn(address from, uint256 amount) internal virtual {
        _beforeTokenTransfer(from, address(0), amount);
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the balance slot and load its value.
            mstore(0x0c, _BALANCE_SLOT_SEED)
            mstore(0x00, from)
            let fromBalanceSlot := keccak256(0x0c, 0x20)
            let fromBalance := sload(fromBalanceSlot)
            // Revert if insufficient balance.
            if gt(amount, fromBalance) {
                mstore(0x00, 0xf4d678b8) // `InsufficientBalance()`.
                revert(0x1c, 0x04)
            }
            // Subtract and store the updated balance.
            sstore(fromBalanceSlot, sub(fromBalance, amount))
            // Subtract and store the updated total supply.
            sstore(_TOTAL_SUPPLY_SLOT, sub(sload(_TOTAL_SUPPLY_SLOT), amount))
            // Emit the {Transfer} event.
            mstore(0x00, amount)
            log3(0x00, 0x20, _TRANSFER_EVENT_SIGNATURE, shr(96, shl(96, from)), 0)
        }
        _afterTokenTransfer(from, address(0), amount);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                INTERNAL TRANSFER FUNCTIONS                 */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Moves `amount` of tokens from `from` to `to`.
    function _transfer(address from, address to, uint256 amount) internal virtual {
        _beforeTokenTransfer(from, to, amount);
        /// @solidity memory-safe-assembly
        assembly {
            let from_ := shl(96, from)
            // Compute the balance slot and load its value.
            mstore(0x0c, or(from_, _BALANCE_SLOT_SEED))
            let fromBalanceSlot := keccak256(0x0c, 0x20)
            let fromBalance := sload(fromBalanceSlot)
            // Revert if insufficient balance.
            if gt(amount, fromBalance) {
                mstore(0x00, 0xf4d678b8) // `InsufficientBalance()`.
                revert(0x1c, 0x04)
            }
            // Subtract and store the updated balance.
            sstore(fromBalanceSlot, sub(fromBalance, amount))
            // Compute the balance slot of `to`.
            mstore(0x00, to)
            let toBalanceSlot := keccak256(0x0c, 0x20)
            // Add and store the updated balance of `to`.
            // Will not overflow because the sum of all user balances
            // cannot exceed the maximum uint256 value.
            sstore(toBalanceSlot, add(sload(toBalanceSlot), amount))
            // Emit the {Transfer} event.
            mstore(0x20, amount)
            log3(0x20, 0x20, _TRANSFER_EVENT_SIGNATURE, shr(96, from_), shr(96, mload(0x0c)))
        }
        _afterTokenTransfer(from, to, amount);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                INTERNAL ALLOWANCE FUNCTIONS                */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Updates the allowance of `owner` for `spender` based on spent `amount`.
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the allowance slot and load its value.
            mstore(0x20, spender)
            mstore(0x0c, _ALLOWANCE_SLOT_SEED)
            mstore(0x00, owner)
            let allowanceSlot := keccak256(0x0c, 0x34)
            let allowance_ := sload(allowanceSlot)
            // If the allowance is not the maximum uint256 value.
            if add(allowance_, 1) {
                // Revert if the amount to be transferred exceeds the allowance.
                if gt(amount, allowance_) {
                    mstore(0x00, 0x13be252b) // `InsufficientAllowance()`.
                    revert(0x1c, 0x04)
                }
                // Subtract and store the updated allowance.
                sstore(allowanceSlot, sub(allowance_, amount))
            }
        }
    }

    /// @dev Sets `amount` as the allowance of `spender` over the tokens of `owner`.
    ///
    /// Emits a {Approval} event.
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            let owner_ := shl(96, owner)
            // Compute the allowance slot and store the amount.
            mstore(0x20, spender)
            mstore(0x0c, or(owner_, _ALLOWANCE_SLOT_SEED))
            sstore(keccak256(0x0c, 0x34), amount)
            // Emit the {Approval} event.
            mstore(0x00, amount)
            log3(0x00, 0x20, _APPROVAL_EVENT_SIGNATURE, shr(96, owner_), shr(96, mload(0x2c)))
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     HOOKS TO OVERRIDE                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Hook that is called before any transfer of tokens.
    /// This includes minting and burning.
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /// @dev Hook that is called after any transfer of tokens.
    /// This includes minting and burning.
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// lib/solady/src/utils/FixedPointMathLib.sol

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
library FixedPointMathLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The operation failed, as the output exceeds the maximum value of uint256.
    error ExpOverflow();

    /// @dev The operation failed, as the output exceeds the maximum value of uint256.
    error FactorialOverflow();

    /// @dev The operation failed, due to an overflow.
    error RPowOverflow();

    /// @dev The mantissa is too big to fit.
    error MantissaOverflow();

    /// @dev The operation failed, due to an multiplication overflow.
    error MulWadFailed();

    /// @dev The operation failed, either due to a
    /// multiplication overflow, or a division by a zero.
    error DivWadFailed();

    /// @dev The multiply-divide operation failed, either due to a
    /// multiplication overflow, or a division by a zero.
    error MulDivFailed();

    /// @dev The division failed, as the denominator is zero.
    error DivFailed();

    /// @dev The full precision multiply-divide operation failed, either due
    /// to the result being larger than 256 bits, or a division by a zero.
    error FullMulDivFailed();

    /// @dev The output is undefined, as the input is less-than-or-equal to zero.
    error LnWadUndefined();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The scalar of ETH and most ERC20s.
    uint256 internal constant WAD = 1e18;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*              SIMPLIFIED FIXED POINT OPERATIONS             */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Equivalent to `(x * y) / WAD` rounded down.
    function mulWad(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y == 0 || x <= type(uint256).max / y)`.
            if mul(y, gt(x, div(not(0), y))) {
                mstore(0x00, 0xbac65e5b) // `MulWadFailed()`.
                revert(0x1c, 0x04)
            }
            z := div(mul(x, y), WAD)
        }
    }

    /// @dev Equivalent to `(x * y) / WAD` rounded up.
    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y == 0 || x <= type(uint256).max / y)`.
            if mul(y, gt(x, div(not(0), y))) {
                mstore(0x00, 0xbac65e5b) // `MulWadFailed()`.
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(mul(x, y), WAD))), div(mul(x, y), WAD))
        }
    }

    /// @dev Equivalent to `(x * WAD) / y` rounded down.
    function divWad(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y != 0 && (WAD == 0 || x <= type(uint256).max / WAD))`.
            if iszero(mul(y, iszero(mul(WAD, gt(x, div(not(0), WAD)))))) {
                mstore(0x00, 0x7c5f487d) // `DivWadFailed()`.
                revert(0x1c, 0x04)
            }
            z := div(mul(x, WAD), y)
        }
    }

    /// @dev Equivalent to `(x * WAD) / y` rounded up.
    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y != 0 && (WAD == 0 || x <= type(uint256).max / WAD))`.
            if iszero(mul(y, iszero(mul(WAD, gt(x, div(not(0), WAD)))))) {
                mstore(0x00, 0x7c5f487d) // `DivWadFailed()`.
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(mul(x, WAD), y))), div(mul(x, WAD), y))
        }
    }

    /// @dev Equivalent to `x` to the power of `y`.
    /// because `x ** y = (e ** ln(x)) ** y = e ** (ln(x) * y)`.
    function powWad(int256 x, int256 y) internal pure returns (int256) {
        // Using `ln(x)` means `x` must be greater than 0.
        return expWad((lnWad(x) * y) / int256(WAD));
    }

    /// @dev Returns `exp(x)`, denominated in `WAD`.
    function expWad(int256 x) internal pure returns (int256 r) {
        unchecked {
            // When the result is < 0.5 we return zero. This happens when
            // x <= floor(log(0.5e18) * 1e18) ~ -42e18
            if (x <= -42139678854452767551) return r;

            /// @solidity memory-safe-assembly
            assembly {
                // When the result is > (2**255 - 1) / 1e18 we can not represent it as an
                // int. This happens when x >= floor(log((2**255 - 1) / 1e18) * 1e18) ~ 135.
                if iszero(slt(x, 135305999368893231589)) {
                    mstore(0x00, 0xa37bfec9) // `ExpOverflow()`.
                    revert(0x1c, 0x04)
                }
            }

            // x is now in the range (-42, 136) * 1e18. Convert to (-42, 136) * 2**96
            // for more intermediate precision and a binary basis. This base conversion
            // is a multiplication by 1e18 / 2**96 = 5**18 / 2**78.
            x = (x << 78) / 5 ** 18;

            // Reduce range of x to (-½ ln 2, ½ ln 2) * 2**96 by factoring out powers
            // of two such that exp(x) = exp(x') * 2**k, where k is an integer.
            // Solving this gives k = round(x / log(2)) and x' = x - k * log(2).
            int256 k = ((x << 96) / 54916777467707473351141471128 + 2 ** 95) >> 96;
            x = x - k * 54916777467707473351141471128;

            // k is in the range [-61, 195].

            // Evaluate using a (6, 7)-term rational approximation.
            // p is made monic, we'll multiply by a scale factor later.
            int256 y = x + 1346386616545796478920950773328;
            y = ((y * x) >> 96) + 57155421227552351082224309758442;
            int256 p = y + x - 94201549194550492254356042504812;
            p = ((p * y) >> 96) + 28719021644029726153956944680412240;
            p = p * x + (4385272521454847904659076985693276 << 96);

            // We leave p in 2**192 basis so we don't need to scale it back up for the division.
            int256 q = x - 2855989394907223263936484059900;
            q = ((q * x) >> 96) + 50020603652535783019961831881945;
            q = ((q * x) >> 96) - 533845033583426703283633433725380;
            q = ((q * x) >> 96) + 3604857256930695427073651918091429;
            q = ((q * x) >> 96) - 14423608567350463180887372962807573;
            q = ((q * x) >> 96) + 26449188498355588339934803723976023;

            /// @solidity memory-safe-assembly
            assembly {
                // Div in assembly because solidity adds a zero check despite the unchecked.
                // The q polynomial won't have zeros in the domain as all its roots are complex.
                // No scaling is necessary because p is already 2**96 too large.
                r := sdiv(p, q)
            }

            // r should be in the range (0.09, 0.25) * 2**96.

            // We now need to multiply r by:
            // * the scale factor s = ~6.031367120.
            // * the 2**k factor from the range reduction.
            // * the 1e18 / 2**96 factor for base conversion.
            // We do this all at once, with an intermediate result in 2**213
            // basis, so the final right shift is always by a positive amount.
            r = int256(
                (uint256(r) * 3822833074963236453042738258902158003155416615667) >> uint256(195 - k)
            );
        }
    }

    /// @dev Returns `ln(x)`, denominated in `WAD`.
    function lnWad(int256 x) internal pure returns (int256 r) {
        unchecked {
            /// @solidity memory-safe-assembly
            assembly {
                if iszero(sgt(x, 0)) {
                    mstore(0x00, 0x1615e638) // `LnWadUndefined()`.
                    revert(0x1c, 0x04)
                }
            }

            // We want to convert x from 10**18 fixed point to 2**96 fixed point.
            // We do this by multiplying by 2**96 / 10**18. But since
            // ln(x * C) = ln(x) + ln(C), we can simply do nothing here
            // and add ln(2**96 / 10**18) at the end.

            // Compute k = log2(x) - 96, t = 159 - k = 255 - log2(x) = 255 ^ log2(x).
            int256 t;
            /// @solidity memory-safe-assembly
            assembly {
                t := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
                t := or(t, shl(6, lt(0xffffffffffffffff, shr(t, x))))
                t := or(t, shl(5, lt(0xffffffff, shr(t, x))))
                t := or(t, shl(4, lt(0xffff, shr(t, x))))
                t := or(t, shl(3, lt(0xff, shr(t, x))))
                // forgefmt: disable-next-item
                t := xor(t, byte(and(0x1f, shr(shr(t, x), 0x8421084210842108cc6318c6db6d54be)),
                    0xf8f9f9faf9fdfafbf9fdfcfdfafbfcfef9fafdfafcfcfbfefafafcfbffffffff))
            }

            // Reduce range of x to (1, 2) * 2**96
            // ln(2^k * x) = k * ln(2) + ln(x)
            x = int256(uint256(x << uint256(t)) >> 159);

            // Evaluate using a (8, 8)-term rational approximation.
            // p is made monic, we will multiply by a scale factor later.
            int256 p = x + 3273285459638523848632254066296;
            p = ((p * x) >> 96) + 24828157081833163892658089445524;
            p = ((p * x) >> 96) + 43456485725739037958740375743393;
            p = ((p * x) >> 96) - 11111509109440967052023855526967;
            p = ((p * x) >> 96) - 45023709667254063763336534515857;
            p = ((p * x) >> 96) - 14706773417378608786704636184526;
            p = p * x - (795164235651350426258249787498 << 96);

            // We leave p in 2**192 basis so we don't need to scale it back up for the division.
            // q is monic by convention.
            int256 q = x + 5573035233440673466300451813936;
            q = ((q * x) >> 96) + 71694874799317883764090561454958;
            q = ((q * x) >> 96) + 283447036172924575727196451306956;
            q = ((q * x) >> 96) + 401686690394027663651624208769553;
            q = ((q * x) >> 96) + 204048457590392012362485061816622;
            q = ((q * x) >> 96) + 31853899698501571402653359427138;
            q = ((q * x) >> 96) + 909429971244387300277376558375;
            /// @solidity memory-safe-assembly
            assembly {
                // Div in assembly because solidity adds a zero check despite the unchecked.
                // The q polynomial is known not to have zeros in the domain.
                // No scaling required because p is already 2**96 too large.
                r := sdiv(p, q)
            }

            // r is in the range (0, 0.125) * 2**96

            // Finalization, we need to:
            // * multiply by the scale factor s = 5.549…
            // * add ln(2**96 / 10**18)
            // * add k * ln(2)
            // * multiply by 10**18 / 2**96 = 5**18 >> 78

            // mul s * 5e18 * 2**96, base is now 5**18 * 2**192
            r *= 1677202110996718588342820967067443963516166;
            // add ln(2) * k * 5e18 * 2**192
            r += 16597577552685614221487285958193947469193820559219878177908093499208371 * (159 - t);
            // add ln(2**96 / 10**18) * 5e18 * 2**192
            r += 600920179829731861736702779321621459595472258049074101567377883020018308;
            // base conversion: mul 2**18 / 2**192
            r >>= 174;
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  GENERAL NUMBER UTILITIES                  */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Calculates `floor(a * b / d)` with full precision.
    /// Throws if result overflows a uint256 or when `d` is zero.
    /// Credit to Remco Bloemen under MIT license: https://2π.com/21/muldiv
    function fullMulDiv(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            for {} 1 {} {
                // 512-bit multiply `[p1 p0] = x * y`.
                // Compute the product mod `2**256` and mod `2**256 - 1`
                // then use the Chinese Remainder Theorem to reconstruct
                // the 512 bit result. The result is stored in two 256
                // variables such that `product = p1 * 2**256 + p0`.

                // Least significant 256 bits of the product.
                let p0 := mul(x, y)
                let mm := mulmod(x, y, not(0))
                // Most significant 256 bits of the product.
                let p1 := sub(mm, add(p0, lt(mm, p0)))

                // Handle non-overflow cases, 256 by 256 division.
                if iszero(p1) {
                    if iszero(d) {
                        mstore(0x00, 0xae47f702) // `FullMulDivFailed()`.
                        revert(0x1c, 0x04)
                    }
                    result := div(p0, d)
                    break
                }

                // Make sure the result is less than `2**256`. Also prevents `d == 0`.
                if iszero(gt(d, p1)) {
                    mstore(0x00, 0xae47f702) // `FullMulDivFailed()`.
                    revert(0x1c, 0x04)
                }

                /*------------------- 512 by 256 division --------------------*/

                // Make division exact by subtracting the remainder from `[p1 p0]`.
                // Compute remainder using mulmod.
                let r := mulmod(x, y, d)
                // `t` is the least significant bit of `d`.
                // Always greater or equal to 1.
                let t := and(d, sub(0, d))
                // Divide `d` by `t`, which is a power of two.
                d := div(d, t)
                // Invert `d mod 2**256`
                // Now that `d` is an odd number, it has an inverse
                // modulo `2**256` such that `d * inv = 1 mod 2**256`.
                // Compute the inverse by starting with a seed that is correct
                // correct for four bits. That is, `d * inv = 1 mod 2**4`.
                let inv := xor(mul(3, d), 2)
                // Now use Newton-Raphson iteration to improve the precision.
                // Thanks to Hensel's lifting lemma, this also works in modular
                // arithmetic, doubling the correct bits in each step.
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**8
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**16
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**32
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**64
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**128
                result :=
                    mul(
                        // Divide [p1 p0] by the factors of two.
                        // Shift in bits from `p1` into `p0`. For this we need
                        // to flip `t` such that it is `2**256 / t`.
                        or(mul(sub(p1, gt(r, p0)), add(div(sub(0, t), t), 1)), div(sub(p0, r), t)),
                        // inverse mod 2**256
                        mul(inv, sub(2, mul(d, inv)))
                    )
                break
            }
        }
    }

    /// @dev Calculates `floor(x * y / d)` with full precision, rounded up.
    /// Throws if result overflows a uint256 or when `d` is zero.
    /// Credit to Uniswap-v3-core under MIT license:
    /// https://github.com/Uniswap/v3-core/blob/contracts/libraries/FullMath.sol
    function fullMulDivUp(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 result) {
        result = fullMulDiv(x, y, d);
        /// @solidity memory-safe-assembly
        assembly {
            if mulmod(x, y, d) {
                result := add(result, 1)
                if iszero(result) {
                    mstore(0x00, 0xae47f702) // `FullMulDivFailed()`.
                    revert(0x1c, 0x04)
                }
            }
        }
    }

    /// @dev Returns `floor(x * y / d)`.
    /// Reverts if `x * y` overflows, or `d` is zero.
    function mulDiv(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(d != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(d, iszero(mul(y, gt(x, div(not(0), y)))))) {
                mstore(0x00, 0xad251c27) // `MulDivFailed()`.
                revert(0x1c, 0x04)
            }
            z := div(mul(x, y), d)
        }
    }

    /// @dev Returns `ceil(x * y / d)`.
    /// Reverts if `x * y` overflows, or `d` is zero.
    function mulDivUp(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(d != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(d, iszero(mul(y, gt(x, div(not(0), y)))))) {
                mstore(0x00, 0xad251c27) // `MulDivFailed()`.
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(mul(x, y), d))), div(mul(x, y), d))
        }
    }

    /// @dev Returns `ceil(x / d)`.
    /// Reverts if `d` is zero.
    function divUp(uint256 x, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(d) {
                mstore(0x00, 0x65244e4e) // `DivFailed()`.
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(x, d))), div(x, d))
        }
    }

    /// @dev Returns `max(0, x - y)`.
    function zeroFloorSub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := mul(gt(x, y), sub(x, y))
        }
    }

    /// @dev Exponentiate `x` to `y` by squaring, denominated in base `b`.
    /// Reverts if the computation overflows.
    function rpow(uint256 x, uint256 y, uint256 b) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := mul(b, iszero(y)) // `0 ** 0 = 1`. Otherwise, `0 ** n = 0`.
            if x {
                z := xor(b, mul(xor(b, x), and(y, 1))) // `z = isEven(y) ? scale : x`
                let half := shr(1, b) // Divide `b` by 2.
                // Divide `y` by 2 every iteration.
                for { y := shr(1, y) } y { y := shr(1, y) } {
                    let xx := mul(x, x) // Store x squared.
                    let xxRound := add(xx, half) // Round to the nearest number.
                    // Revert if `xx + half` overflowed, or if `x ** 2` overflows.
                    if or(lt(xxRound, xx), shr(128, x)) {
                        mstore(0x00, 0x49f7642b) // `RPowOverflow()`.
                        revert(0x1c, 0x04)
                    }
                    x := div(xxRound, b) // Set `x` to scaled `xxRound`.
                    // If `y` is odd:
                    if and(y, 1) {
                        let zx := mul(z, x) // Compute `z * x`.
                        let zxRound := add(zx, half) // Round to the nearest number.
                        // If `z * x` overflowed or `zx + half` overflowed:
                        if or(xor(div(zx, x), z), lt(zxRound, zx)) {
                            // Revert if `x` is non-zero.
                            if iszero(iszero(x)) {
                                mstore(0x00, 0x49f7642b) // `RPowOverflow()`.
                                revert(0x1c, 0x04)
                            }
                        }
                        z := div(zxRound, b) // Return properly scaled `zxRound`.
                    }
                }
            }
        }
    }

    /// @dev Returns the square root of `x`.
    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // `floor(sqrt(2**15)) = 181`. `sqrt(2**15) - 181 = 2.84`.
            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // Let `y = x / 2**r`. We check `y >= 2**(k + 8)`
            // but shift right by `k` bits to ensure that if `x >= 256`, then `y >= 256`.
            let r := shl(7, lt(0xffffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffffff, shr(r, x))))
            z := shl(shr(1, r), z)

            // Goal was to get `z*z*y` within a small factor of `x`. More iterations could
            // get y in a tighter range. Currently, we will have y in `[256, 256*(2**16))`.
            // We ensured `y >= 256` so that the relative difference between `y` and `y+1` is small.
            // That's not possible if `x < 256` but we can just verify those cases exhaustively.

            // Now, `z*z*y <= x < z*z*(y+1)`, and `y <= 2**(16+8)`, and either `y >= 256`, or `x < 256`.
            // Correctness can be checked exhaustively for `x < 256`, so we assume `y >= 256`.
            // Then `z*sqrt(y)` is within `sqrt(257)/sqrt(256)` of `sqrt(x)`, or about 20bps.

            // For `s` in the range `[1/256, 256]`, the estimate `f(s) = (181/1024) * (s+1)`
            // is in the range `(1/2.84 * sqrt(s), 2.84 * sqrt(s))`,
            // with largest error when `s = 1` and when `s = 256` or `1/256`.

            // Since `y` is in `[256, 256*(2**16))`, let `a = y/65536`, so that `a` is in `[1/256, 256)`.
            // Then we can estimate `sqrt(y)` using
            // `sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2**18`.

            // There is no overflow risk here since `y < 2**136` after the first branch above.
            z := shr(18, mul(z, add(shr(r, x), 65536))) // A `mul()` is saved from starting `z` at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If `x+1` is a perfect square, the Babylonian method cycles between
            // `floor(sqrt(x))` and `ceil(sqrt(x))`. This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            z := sub(z, lt(div(x, z), z))
        }
    }

    /// @dev Returns the cube root of `x`.
    /// Credit to bout3fiddy and pcaversaccio under AGPLv3 license:
    /// https://github.com/pcaversaccio/snekmate/blob/main/src/utils/Math.vy
    function cbrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffff, shr(r, x))))
            r := or(r, shl(3, lt(0xff, shr(r, x))))

            z := div(shl(div(r, 3), shl(lt(0xf, shr(r, x)), 0xf)), xor(7, mod(r, 3)))

            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)

            z := sub(z, lt(div(x, mul(z, z)), z))
        }
    }

    /// @dev Returns the square root of `x`, denominated in `WAD`.
    function sqrtWad(uint256 x) internal pure returns (uint256 z) {
        unchecked {
            z = 10 ** 9;
            if (x <= type(uint256).max / 10 ** 36 - 1) {
                x *= 10 ** 18;
                z = 1;
            }
            z *= sqrt(x);
        }
    }

    /// @dev Returns the cube root of `x`, denominated in `WAD`.
    function cbrtWad(uint256 x) internal pure returns (uint256 z) {
        unchecked {
            z = 10 ** 12;
            if (x <= (type(uint256).max / 10 ** 36) * 10 ** 18 - 1) {
                if (x >= type(uint256).max / 10 ** 36) {
                    x *= 10 ** 18;
                    z = 10 ** 6;
                } else {
                    x *= 10 ** 36;
                    z = 1;
                }
            }
            z *= cbrt(x);
        }
    }

    /// @dev Returns the factorial of `x`.
    function factorial(uint256 x) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(lt(x, 58)) {
                mstore(0x00, 0xaba0f2a2) // `FactorialOverflow()`.
                revert(0x1c, 0x04)
            }
            for { result := 1 } x { x := sub(x, 1) } { result := mul(result, x) }
        }
    }

    /// @dev Returns the log2 of `x`.
    /// Equivalent to computing the index of the most significant bit (MSB) of `x`.
    /// Returns 0 if `x` is zero.
    function log2(uint256 x) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffff, shr(r, x))))
            r := or(r, shl(3, lt(0xff, shr(r, x))))
            // forgefmt: disable-next-item
            r := or(r, byte(and(0x1f, shr(shr(r, x), 0x8421084210842108cc6318c6db6d54be)),
                0x0706060506020504060203020504030106050205030304010505030400000000))
        }
    }

    /// @dev Returns the log2 of `x`, rounded up.
    /// Returns 0 if `x` is zero.
    function log2Up(uint256 x) internal pure returns (uint256 r) {
        r = log2(x);
        /// @solidity memory-safe-assembly
        assembly {
            r := add(r, lt(shl(r, 1), x))
        }
    }

    /// @dev Returns the log10 of `x`.
    /// Returns 0 if `x` is zero.
    function log10(uint256 x) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(lt(x, 100000000000000000000000000000000000000)) {
                x := div(x, 100000000000000000000000000000000000000)
                r := 38
            }
            if iszero(lt(x, 100000000000000000000)) {
                x := div(x, 100000000000000000000)
                r := add(r, 20)
            }
            if iszero(lt(x, 10000000000)) {
                x := div(x, 10000000000)
                r := add(r, 10)
            }
            if iszero(lt(x, 100000)) {
                x := div(x, 100000)
                r := add(r, 5)
            }
            r := add(r, add(gt(x, 9), add(gt(x, 99), add(gt(x, 999), gt(x, 9999)))))
        }
    }

    /// @dev Returns the log10 of `x`, rounded up.
    /// Returns 0 if `x` is zero.
    function log10Up(uint256 x) internal pure returns (uint256 r) {
        r = log10(x);
        /// @solidity memory-safe-assembly
        assembly {
            r := add(r, lt(exp(10, r), x))
        }
    }

    /// @dev Returns the log256 of `x`.
    /// Returns 0 if `x` is zero.
    function log256(uint256 x) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffff, shr(r, x))))
            r := or(shr(3, r), lt(0xff, shr(r, x)))
        }
    }

    /// @dev Returns the log256 of `x`, rounded up.
    /// Returns 0 if `x` is zero.
    function log256Up(uint256 x) internal pure returns (uint256 r) {
        r = log256(x);
        /// @solidity memory-safe-assembly
        assembly {
            r := add(r, lt(shl(shl(3, r), 1), x))
        }
    }

    /// @dev Returns the scientific notation format `mantissa * 10 ** exponent` of `x`.
    /// Useful for compressing prices (e.g. using 25 bit mantissa and 7 bit exponent).
    function sci(uint256 x) internal pure returns (uint256 mantissa, uint256 exponent) {
        /// @solidity memory-safe-assembly
        assembly {
            mantissa := x
            if mantissa {
                if iszero(mod(mantissa, 1000000000000000000000000000000000)) {
                    mantissa := div(mantissa, 1000000000000000000000000000000000)
                    exponent := 33
                }
                if iszero(mod(mantissa, 10000000000000000000)) {
                    mantissa := div(mantissa, 10000000000000000000)
                    exponent := add(exponent, 19)
                }
                if iszero(mod(mantissa, 1000000000000)) {
                    mantissa := div(mantissa, 1000000000000)
                    exponent := add(exponent, 12)
                }
                if iszero(mod(mantissa, 1000000)) {
                    mantissa := div(mantissa, 1000000)
                    exponent := add(exponent, 6)
                }
                if iszero(mod(mantissa, 10000)) {
                    mantissa := div(mantissa, 10000)
                    exponent := add(exponent, 4)
                }
                if iszero(mod(mantissa, 100)) {
                    mantissa := div(mantissa, 100)
                    exponent := add(exponent, 2)
                }
                if iszero(mod(mantissa, 10)) {
                    mantissa := div(mantissa, 10)
                    exponent := add(exponent, 1)
                }
            }
        }
    }

    /// @dev Convenience function for packing `x` into a smaller number using `sci`.
    /// The `mantissa` will be in bits [7..255] (the upper 249 bits).
    /// The `exponent` will be in bits [0..6] (the lower 7 bits).
    /// Use `SafeCastLib` to safely ensure that the `packed` number is small
    /// enough to fit in the desired unsigned integer type:
    /// ```
    ///     uint32 packed = SafeCastLib.toUint32(FixedPointMathLib.packSci(777 ether));
    /// ```
    function packSci(uint256 x) internal pure returns (uint256 packed) {
        (x, packed) = sci(x); // Reuse for `mantissa` and `exponent`.
        /// @solidity memory-safe-assembly
        assembly {
            if shr(249, x) {
                mstore(0x00, 0xce30380c) // `MantissaOverflow()`.
                revert(0x1c, 0x04)
            }
            packed := or(shl(7, x), packed)
        }
    }

    /// @dev Convenience function for unpacking a packed number from `packSci`.
    function unpackSci(uint256 packed) internal pure returns (uint256 unpacked) {
        unchecked {
            unpacked = (packed >> 7) * 10 ** (packed & 0x7f);
        }
    }

    /// @dev Returns the average of `x` and `y`.
    function avg(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = (x & y) + ((x ^ y) >> 1);
        }
    }

    /// @dev Returns the average of `x` and `y`.
    function avg(int256 x, int256 y) internal pure returns (int256 z) {
        unchecked {
            z = (x >> 1) + (y >> 1) + (((x & 1) + (y & 1)) >> 1);
        }
    }

    /// @dev Returns the absolute value of `x`.
    function abs(int256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(sub(0, shr(255, x)), add(sub(0, shr(255, x)), x))
        }
    }

    /// @dev Returns the absolute distance between `x` and `y`.
    function dist(int256 x, int256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(mul(xor(sub(y, x), sub(x, y)), sgt(x, y)), sub(y, x))
        }
    }

    /// @dev Returns the minimum of `x` and `y`.
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), lt(y, x)))
        }
    }

    /// @dev Returns the minimum of `x` and `y`.
    function min(int256 x, int256 y) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), slt(y, x)))
        }
    }

    /// @dev Returns the maximum of `x` and `y`.
    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), gt(y, x)))
        }
    }

    /// @dev Returns the maximum of `x` and `y`.
    function max(int256 x, int256 y) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), sgt(y, x)))
        }
    }

    /// @dev Returns `x`, bounded to `minValue` and `maxValue`.
    function clamp(uint256 x, uint256 minValue, uint256 maxValue)
        internal
        pure
        returns (uint256 z)
    {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, minValue), gt(minValue, x)))
            z := xor(z, mul(xor(z, maxValue), lt(maxValue, z)))
        }
    }

    /// @dev Returns `x`, bounded to `minValue` and `maxValue`.
    function clamp(int256 x, int256 minValue, int256 maxValue) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, minValue), sgt(minValue, x)))
            z := xor(z, mul(xor(z, maxValue), slt(maxValue, z)))
        }
    }

    /// @dev Returns greatest common divisor of `x` and `y`.
    function gcd(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            for { z := x } y {} {
                let t := y
                y := mod(z, y)
                z := t
            }
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   RAW NUMBER OPERATIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns `x + y`, without checking for overflow.
    function rawAdd(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = x + y;
        }
    }

    /// @dev Returns `x + y`, without checking for overflow.
    function rawAdd(int256 x, int256 y) internal pure returns (int256 z) {
        unchecked {
            z = x + y;
        }
    }

    /// @dev Returns `x - y`, without checking for underflow.
    function rawSub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = x - y;
        }
    }

    /// @dev Returns `x - y`, without checking for underflow.
    function rawSub(int256 x, int256 y) internal pure returns (int256 z) {
        unchecked {
            z = x - y;
        }
    }

    /// @dev Returns `x * y`, without checking for overflow.
    function rawMul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = x * y;
        }
    }

    /// @dev Returns `x * y`, without checking for overflow.
    function rawMul(int256 x, int256 y) internal pure returns (int256 z) {
        unchecked {
            z = x * y;
        }
    }

    /// @dev Returns `x / y`, returning 0 if `y` is zero.
    function rawDiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := div(x, y)
        }
    }

    /// @dev Returns `x / y`, returning 0 if `y` is zero.
    function rawSDiv(int256 x, int256 y) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := sdiv(x, y)
        }
    }

    /// @dev Returns `x % y`, returning 0 if `y` is zero.
    function rawMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := mod(x, y)
        }
    }

    /// @dev Returns `x % y`, returning 0 if `y` is zero.
    function rawSMod(int256 x, int256 y) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := smod(x, y)
        }
    }

    /// @dev Returns `(x + y) % d`, return 0 if `d` if zero.
    function rawAddMod(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := addmod(x, y, d)
        }
    }

    /// @dev Returns `(x * y) % d`, return 0 if `d` if zero.
    function rawMulMod(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := mulmod(x, y, d)
        }
    }
}

// src/interfaces/IGoldivault4626.sol

/// @title IGoldivault4626
interface IGoldivault4626 {

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                           EVENTS                           */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  event Deposit(address indexed user, uint256 amount);
  event OwnershipTokenRedemption(address indexed user, uint256 amount);
  event YTBuy(address indexed user, uint256 boughtYt, uint256 spentDt);
  event YTSell(address indexed user, uint256 soldYt, uint256 receivedDt);
  event YTStake(address indexed user, uint256 amount);
  event YTUnstake(address indexed user, uint256 amount);
  event Claim(address indexed user, uint256 amount);

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                           ERRORS                           */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  error NotMultisig();
  error DelayTooShort();
  error InvalidRedemption();
  error InvalidDeposit();
  error AlreadyConcluded();
  error SpentTooMuch();
  error ReceivedTooMuch();
  error ReceivedTooLitte();
  error FlashLoanFailed();
  error InvalidTrade();
  error InvalidUnstake();
  error NegativeYield();

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                    EXTERNAL FUNCTIONS                      */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /// @notice Deposits tokens into vault to receive ownership and yield tokens
  /// @param amount Amount of tokens to deposit
  function deposit(uint256 amount) external;

  /// @notice Withdraws tokens from the vault 
  /// @param amount Amount of ownership tokens to redeem
  function redeemOwnership(uint256 amount) external;

  /// @notice Buys YT using the vault and kodiak pool
  /// @dev These parameters cannot be 0
  /// @param ytAmount Amount of YT for user to buy
  /// @param dtAmountMax Maximum amount of deposit token that user wishes to pay
  /// @param amountOutMin Minimum amount of tokens to receive out from the kodiak pool swap
  function buyYT (uint256 ytAmount, uint256 dtAmountMax, uint256 amountOutMin) external;

  /// @notice Sells YT using the vault and kodiak pool
  /// @dev These parameters cannot be 0
  /// @param ytAmount Amount of YT for user to sell
  /// @param dtAmountMin Minimum amount of deposit token that user wishes to receive
  /// @param amountInMax Maximum amount of tokens to spend from the kodiak pool swap
  function sellYT (uint256 ytAmount, uint256 dtAmountMin, uint256 amountInMax) external;

  /// @notice Stakes YT
  /// @param amount Amount of YT for user to stake
  function stakeYT(uint256 amount) external;

  /// @notice Unstakes YT
  /// @param amount Amount of YT for user to unstake
  function unstakeYT(uint256 amount) external;

  /// @notice Claims rewards for YT stakers
  function claim() external;

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                 EXTERNAL VIEW FUNCTIONS                    */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /// @notice Returns the amount of underlying claimable by a YT staker
  /// @param user Address of the YT staker
  function userClaimableUnderlying(address user) external view returns (uint256);

}

// src/interfaces/IUniswapV3SwapCallback.sol

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
  /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
  /// @dev In the implementation you must pay the pool tokens owed for the swap.
  /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
  /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
  /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
  /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
  /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
  /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
  /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
  function uniswapV3SwapCallback(
    int256 amount0Delta,
    int256 amount1Delta,
    bytes calldata data
  ) external;
}

// lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol

// OpenZeppelin Contracts (last updated v5.0.0) (utils/ReentrancyGuard.sol)

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}

// lib/solady/src/utils/SafeTransferLib.sol

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
///
/// @dev Note:
/// - For ETH transfers, please use `forceSafeTransferETH` for DoS protection.
/// - For ERC20s, this implementation won't check that a token has code,
///   responsibility is delegated to the caller.
library SafeTransferLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The ETH transfer has failed.
    error ETHTransferFailed();

    /// @dev The ERC20 `transferFrom` has failed.
    error TransferFromFailed();

    /// @dev The ERC20 `transfer` has failed.
    error TransferFailed();

    /// @dev The ERC20 `approve` has failed.
    error ApproveFailed();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Suggested gas stipend for contract receiving ETH that disallows any storage writes.
    uint256 internal constant GAS_STIPEND_NO_STORAGE_WRITES = 2300;

    /// @dev Suggested gas stipend for contract receiving ETH to perform a few
    /// storage reads and writes, but low enough to prevent griefing.
    uint256 internal constant GAS_STIPEND_NO_GRIEF = 100000;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       ETH OPERATIONS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // If the ETH transfer MUST succeed with a reasonable gas budget, use the force variants.
    //
    // The regular variants:
    // - Forwards all remaining gas to the target.
    // - Reverts if the target reverts.
    // - Reverts if the current contract has insufficient balance.
    //
    // The force variants:
    // - Forwards with an optional gas stipend
    //   (defaults to `GAS_STIPEND_NO_GRIEF`, which is sufficient for most cases).
    // - If the target reverts, or if the gas stipend is exhausted,
    //   creates a temporary contract to force send the ETH via `SELFDESTRUCT`.
    //   Future compatible with `SENDALL`: https://eips.ethereum.org/EIPS/eip-4758.
    // - Reverts if the current contract has insufficient balance.
    //
    // The try variants:
    // - Forwards with a mandatory gas stipend.
    // - Instead of reverting, returns whether the transfer succeeded.

    /// @dev Sends `amount` (in wei) ETH to `to`.
    function safeTransferETH(address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(call(gas(), to, amount, codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, 0xb12d13eb) // `ETHTransferFailed()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Sends all the ETH in the current contract to `to`.
    function safeTransferAllETH(address to) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // Transfer all the ETH and check if it succeeded or not.
            if iszero(call(gas(), to, selfbalance(), codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, 0xb12d13eb) // `ETHTransferFailed()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Force sends `amount` (in wei) ETH to `to`, with a `gasStipend`.
    function forceSafeTransferETH(address to, uint256 amount, uint256 gasStipend) internal {
        /// @solidity memory-safe-assembly
        assembly {
            if lt(selfbalance(), amount) {
                mstore(0x00, 0xb12d13eb) // `ETHTransferFailed()`.
                revert(0x1c, 0x04)
            }
            if iszero(call(gasStipend, to, amount, codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                if iszero(create(amount, 0x0b, 0x16)) { revert(codesize(), codesize()) } // For gas estimation.
            }
        }
    }

    /// @dev Force sends all the ETH in the current contract to `to`, with a `gasStipend`.
    function forceSafeTransferAllETH(address to, uint256 gasStipend) internal {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(call(gasStipend, to, selfbalance(), codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                if iszero(create(selfbalance(), 0x0b, 0x16)) { revert(codesize(), codesize()) } // For gas estimation.
            }
        }
    }

    /// @dev Force sends `amount` (in wei) ETH to `to`, with `GAS_STIPEND_NO_GRIEF`.
    function forceSafeTransferETH(address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            if lt(selfbalance(), amount) {
                mstore(0x00, 0xb12d13eb) // `ETHTransferFailed()`.
                revert(0x1c, 0x04)
            }
            if iszero(call(GAS_STIPEND_NO_GRIEF, to, amount, codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                if iszero(create(amount, 0x0b, 0x16)) { revert(codesize(), codesize()) } // For gas estimation.
            }
        }
    }

    /// @dev Force sends all the ETH in the current contract to `to`, with `GAS_STIPEND_NO_GRIEF`.
    function forceSafeTransferAllETH(address to) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // forgefmt: disable-next-item
            if iszero(call(GAS_STIPEND_NO_GRIEF, to, selfbalance(), codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                if iszero(create(selfbalance(), 0x0b, 0x16)) { revert(codesize(), codesize()) } // For gas estimation.
            }
        }
    }

    /// @dev Sends `amount` (in wei) ETH to `to`, with a `gasStipend`.
    function trySafeTransferETH(address to, uint256 amount, uint256 gasStipend)
        internal
        returns (bool success)
    {
        /// @solidity memory-safe-assembly
        assembly {
            success := call(gasStipend, to, amount, codesize(), 0x00, codesize(), 0x00)
        }
    }

    /// @dev Sends all the ETH in the current contract to `to`, with a `gasStipend`.
    function trySafeTransferAllETH(address to, uint256 gasStipend)
        internal
        returns (bool success)
    {
        /// @solidity memory-safe-assembly
        assembly {
            success := call(gasStipend, to, selfbalance(), codesize(), 0x00, codesize(), 0x00)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      ERC20 OPERATIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Sends `amount` of ERC20 `token` from `from` to `to`.
    /// Reverts upon failure.
    ///
    /// The `from` account must have at least `amount` approved for
    /// the current contract to manage.
    function safeTransferFrom(address token, address from, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x60, amount) // Store the `amount` argument.
            mstore(0x40, to) // Store the `to` argument.
            mstore(0x2c, shl(96, from)) // Store the `from` argument.
            mstore(0x0c, 0x23b872dd000000000000000000000000) // `transferFrom(address,address,uint256)`.
            // Perform the transfer, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                mstore(0x00, 0x7939f424) // `TransferFromFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Sends all of ERC20 `token` from `from` to `to`.
    /// Reverts upon failure.
    ///
    /// The `from` account must have their entire balance approved for
    /// the current contract to manage.
    function safeTransferAllFrom(address token, address from, address to)
        internal
        returns (uint256 amount)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x40, to) // Store the `to` argument.
            mstore(0x2c, shl(96, from)) // Store the `from` argument.
            mstore(0x0c, 0x70a08231000000000000000000000000) // `balanceOf(address)`.
            // Read the balance, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                    staticcall(gas(), token, 0x1c, 0x24, 0x60, 0x20)
                )
            ) {
                mstore(0x00, 0x7939f424) // `TransferFromFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x00, 0x23b872dd) // `transferFrom(address,address,uint256)`.
            amount := mload(0x60) // The `amount` is already at 0x60. We'll need to return it.
            // Perform the transfer, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                mstore(0x00, 0x7939f424) // `TransferFromFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Sends `amount` of ERC20 `token` from the current contract to `to`.
    /// Reverts upon failure.
    function safeTransfer(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, amount) // Store the `amount` argument.
            mstore(0x00, 0xa9059cbb000000000000000000000000) // `transfer(address,uint256)`.
            // Perform the transfer, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                mstore(0x00, 0x90b8ec18) // `TransferFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x34, 0) // Restore the part of the free memory pointer that was overwritten.
        }
    }

    /// @dev Sends all of ERC20 `token` from the current contract to `to`.
    /// Reverts upon failure.
    function safeTransferAll(address token, address to) internal returns (uint256 amount) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0x70a08231) // Store the function selector of `balanceOf(address)`.
            mstore(0x20, address()) // Store the address of the current contract.
            // Read the balance, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                    staticcall(gas(), token, 0x1c, 0x24, 0x34, 0x20)
                )
            ) {
                mstore(0x00, 0x90b8ec18) // `TransferFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x14, to) // Store the `to` argument.
            amount := mload(0x34) // The `amount` is already at 0x34. We'll need to return it.
            mstore(0x00, 0xa9059cbb000000000000000000000000) // `transfer(address,uint256)`.
            // Perform the transfer, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                mstore(0x00, 0x90b8ec18) // `TransferFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x34, 0) // Restore the part of the free memory pointer that was overwritten.
        }
    }

    /// @dev Sets `amount` of ERC20 `token` for `to` to manage on behalf of the current contract.
    /// Reverts upon failure.
    function safeApprove(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, amount) // Store the `amount` argument.
            mstore(0x00, 0x095ea7b3000000000000000000000000) // `approve(address,uint256)`.
            // Perform the approval, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                mstore(0x00, 0x3e3f8f73) // `ApproveFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x34, 0) // Restore the part of the free memory pointer that was overwritten.
        }
    }

    /// @dev Sets `amount` of ERC20 `token` for `to` to manage on behalf of the current contract.
    /// If the initial attempt to approve fails, attempts to reset the approved amount to zero,
    /// then retries the approval again (some tokens, e.g. USDT, requires this).
    /// Reverts upon failure.
    function safeApproveWithRetry(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, amount) // Store the `amount` argument.
            mstore(0x00, 0x095ea7b3000000000000000000000000) // `approve(address,uint256)`.
            // Perform the approval, retrying upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                mstore(0x34, 0) // Store 0 for the `amount`.
                mstore(0x00, 0x095ea7b3000000000000000000000000) // `approve(address,uint256)`.
                pop(call(gas(), token, 0, 0x10, 0x44, codesize(), 0x00)) // Reset the approval.
                mstore(0x34, amount) // Store back the original `amount`.
                // Retry the approval, reverting upon failure.
                if iszero(
                    and(
                        or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                        call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                    )
                ) {
                    mstore(0x00, 0x3e3f8f73) // `ApproveFailed()`.
                    revert(0x1c, 0x04)
                }
            }
            mstore(0x34, 0) // Restore the part of the free memory pointer that was overwritten.
        }
    }

    /// @dev Returns the amount of ERC20 `token` owned by `account`.
    /// Returns zero if the `token` does not exist.
    function balanceOf(address token, address account) internal view returns (uint256 amount) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, account) // Store the `account` argument.
            mstore(0x00, 0x70a08231000000000000000000000000) // `balanceOf(address)`.
            amount :=
                mul(
                    mload(0x20),
                    and( // The arguments of `and` are evaluated from right to left.
                        gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                        staticcall(gas(), token, 0x10, 0x24, 0x20, 0x20)
                    )
                )
        }
    }
}

// src/interfaces/IV3SwapRouter.sol

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface IV3SwapRouter is IUniswapV3SwapCallback {

  struct ExactInputSingleParams {
    address tokenIn;
    address tokenOut;
    uint24 fee;
    address recipient;
    uint256 amountIn;
    uint256 amountOutMinimum;
    uint160 sqrtPriceLimitX96;
  }

  /// @notice Swaps `amountIn` of one token for as much as possible of another token
  /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
  /// and swap the entire amount, enabling contracts to send tokens before calling this function.
  /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
  /// @return amountOut The amount of the received token
  function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

  struct ExactInputParams {
    bytes path;
    address recipient;
    uint256 amountIn;
    uint256 amountOutMinimum;
  }

  /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
  /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
  /// and swap the entire amount, enabling contracts to send tokens before calling this function.
  /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
  /// @return amountOut The amount of the received token
  function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

  struct ExactOutputSingleParams {
    address tokenIn;
    address tokenOut;
    uint24 fee;
    address recipient;
    uint256 amountOut;
    uint256 amountInMaximum;
    uint160 sqrtPriceLimitX96;
  }

  /// @notice Swaps as little as possible of one token for `amountOut` of another token
  /// that may remain in the router after the swap.
  /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
  /// @return amountIn The amount of the input token
  function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

  struct ExactOutputParams {
    bytes path;
    address recipient;
    uint256 amountOut;
    uint256 amountInMaximum;
  }

  /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
  /// that may remain in the router after the swap.
  /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
  /// @return amountIn The amount of the input token
  function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// src/core/goldivault/OwnershipToken.sol

// |============================================================================================|
// |    ______      _____    __      _____    __   __       _____     _____   __  __   ______   |
// |   /_/\___\    ) ___ (  /\_\    /\ __/\  /\_\ /\_\     ) ___ (   /\ __/\ /\_\\  /\/ ____/\  |
// |   ) ) ___/   / /\_/\ \( ( (    ) )  \ \ \/_/( ( (    / /\_/\ \  ) )__\/( ( (/ / /) ) __\/  |
// |  /_/ /  ___ / /_/ (_\ \\ \_\  / / /\ \ \ /\_\\ \_\  / /_/ (_\ \/ / /    \ \_ / /  \ \ \    |
// |  \ \ \_/\__\\ \ )_/ / // / /__\ \ \/ / // / // / /__\ \ )_/ / /\ \ \_   / /  \ \  _\ \ \   |
// |   )_)  \/ _/ \ \/_\/ /( (_____() )__/ /( (_(( (_____(\ \/_\/ /  ) )__/\( (_(\ \ \)____) )  |
// |   \_\____/    )_____(  \/_____/\/___\/  \/_/ \/_____/ )_____(   \/___\/ \/_//__\/\____\/   |
// |                                                                                            |
// |============================================================================================|
// ==============================================================================================
// ====================================== OwnershipToken ========================================
// ==============================================================================================

/// @title OwnershipToken
/// @notice Tokenized ownership token for use in Goldivaults
abstract contract OwnershipToken is ERC20 {

  string private tokenName;
  string private tokenSymbol;

  address public immutable vault;

  error NotVault();

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                         CONSTRUCTOR                        */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
  

  /// @notice Constructor of this contract
  /// @param _tokenName Name of token
  /// @param _tokenSymbol Symbol of token
  /// @param _vault Address of Goldivault
  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    address _vault
  ) {
    tokenName = _tokenName;
    tokenSymbol = _tokenSymbol;
    vault = _vault;
  }

  /// @notice Returns the name of ownership token
  function name() public view override returns (string memory) {
    return tokenName;
  }

  /// @notice Returns the symbol of ownership token
  function symbol() public view override returns (string memory) {
    return tokenSymbol;
  }

  /// @notice Mints ownership tokens
  /// @dev Callable only by Goldivault
  /// @param to Address to mint to
  /// @param amount Amount of ownership tokens to mint
  function mintOT(address to, uint256 amount) external {
    if(msg.sender != vault) revert NotVault();
    _mint(to, amount);
  }

  /// @notice Burns ownership tokens
  /// @dev Callable only by Goldivault
  /// @param from Address to burn from
  /// @param amount Amount of ownership tokens to burn
  function burnOT(address from, uint256 amount) external {
    if(msg.sender != vault) revert NotVault();
    _burn(from, amount);
  }

}

// src/core/goldivault/YieldToken.sol

// |============================================================================================|
// |    ______      _____    __      _____    __   __       _____     _____   __  __   ______   |
// |   /_/\___\    ) ___ (  /\_\    /\ __/\  /\_\ /\_\     ) ___ (   /\ __/\ /\_\\  /\/ ____/\  |
// |   ) ) ___/   / /\_/\ \( ( (    ) )  \ \ \/_/( ( (    / /\_/\ \  ) )__\/( ( (/ / /) ) __\/  |
// |  /_/ /  ___ / /_/ (_\ \\ \_\  / / /\ \ \ /\_\\ \_\  / /_/ (_\ \/ / /    \ \_ / /  \ \ \    |
// |  \ \ \_/\__\\ \ )_/ / // / /__\ \ \/ / // / // / /__\ \ )_/ / /\ \ \_   / /  \ \  _\ \ \   |
// |   )_)  \/ _/ \ \/_\/ /( (_____() )__/ /( (_(( (_____(\ \/_\/ /  ) )__/\( (_(\ \ \)____) )  |
// |   \_\____/    )_____(  \/_____/\/___\/  \/_/ \/_____/ )_____(   \/___\/ \/_//__\/\____\/   |
// |                                                                                            |
// |============================================================================================|
// ==============================================================================================
// ======================================== YieldToken ==========================================
// ==============================================================================================

/// @title YieldToken
/// @notice Tokenized yield token for use in Goldivaults
abstract contract YieldToken is ERC20 {

  string private tokenName;
  string private tokenSymbol;

  address public immutable vault;

  error NotVault();

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                         CONSTRUCTOR                        */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
  

  /// @notice Constructor of this contract
  /// @param _tokenName Name of token
  /// @param _tokenSymbol Symbol of token
  /// @param _vault Address of Goldivault
  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    address _vault
  ) {
    tokenName = _tokenName;
    tokenSymbol = _tokenSymbol;
    vault = _vault;
  }

  /// @notice Returns the name of yield token
  function name() public view override returns (string memory) {
    return tokenName;
  }

  /// @notice Returns the symbol of yield token
  function symbol() public view override returns (string memory) {
    return tokenSymbol;
  }

  /// @notice Mints yield tokens
  /// @dev Callable only by Goldivault
  /// @param to Address to mint to
  /// @param amount Amount of yield tokens to mint
  function mintYT(address to, uint256 amount) external {
    if(msg.sender != vault) revert NotVault();
    _mint(to, amount);
  }

  /// @notice Burns yield tokens
  /// @dev Callable only by Goldivault
  /// @param from Address to burn from
  /// @param amount Amount of yield tokens to burn
  function burnYT(address from, uint256 amount) external {
    if(msg.sender != vault) revert NotVault();
    _burn(from, amount);
  }

}

// lib/solady/src/tokens/ERC4626.sol

/// @notice Simple ERC4626 tokenized Vault implementation.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/tokens/ERC4626.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/mixins/ERC4626.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/ERC4626.sol)
abstract contract ERC4626 is ERC20 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The default underlying decimals.
    uint8 internal constant _DEFAULT_UNDERLYING_DECIMALS = 18;

    /// @dev The default decimals offset.
    uint8 internal constant _DEFAULT_DECIMALS_OFFSET = 0;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Cannot deposit more than the max limit.
    error DepositMoreThanMax();

    /// @dev Cannot mint more than the max limit.
    error MintMoreThanMax();

    /// @dev Cannot withdraw more than the max limit.
    error WithdrawMoreThanMax();

    /// @dev Cannot redeem more than the max limit.
    error RedeemMoreThanMax();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Emitted during a mint call or deposit call.
    event Deposit(address indexed by, address indexed owner, uint256 assets, uint256 shares);

    /// @dev Emitted during a withdraw call or redeem call.
    event Withdraw(
        address indexed by,
        address indexed to,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /// @dev `keccak256(bytes("Deposit(address,address,uint256,uint256)"))`.
    uint256 private constant _DEPOSIT_EVENT_SIGNATURE =
        0xdcbc1c05240f31ff3ad067ef1ee35ce4997762752e3a095284754544f4c709d7;

    /// @dev `keccak256(bytes("Withdraw(address,address,address,uint256,uint256)"))`.
    uint256 private constant _WITHDRAW_EVENT_SIGNATURE =
        0xfbde797d201c681b91056529119e0b02407c7bb96a4a2c75c01fc9667232c8db;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     ERC4626 CONSTANTS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev To be overridden to return the address of the underlying asset.
    ///
    /// - MUST be an ERC20 token contract.
    /// - MUST NOT revert.
    function asset() public view virtual returns (address);

    /// @dev To be overridden to return the number of decimals of the underlying asset.
    /// Default: 18.
    ///
    /// - MUST NOT revert.
    function _underlyingDecimals() internal view virtual returns (uint8) {
        return _DEFAULT_UNDERLYING_DECIMALS;
    }

    /// @dev Override to return a non-zero value to make the inflation attack even more unfeasible.
    /// Only used when {_useVirtualShares} returns true.
    /// Default: 0.
    ///
    /// - MUST NOT revert.
    function _decimalsOffset() internal view virtual returns (uint8) {
        return _DEFAULT_DECIMALS_OFFSET;
    }

    /// @dev Returns whether virtual shares will be used to mitigate the inflation attack.
    /// See: https://github.com/OpenZeppelin/openzeppelin-contracts/issues/3706
    /// Override to return true or false.
    /// Default: true.
    ///
    /// - MUST NOT revert.
    function _useVirtualShares() internal view virtual returns (bool) {
        return true;
    }

    /// @dev Returns the decimals places of the token.
    ///
    /// - MUST NOT revert.
    function decimals() public view virtual override(ERC20) returns (uint8) {
        if (!_useVirtualShares()) return _underlyingDecimals();
        return _underlyingDecimals() + _decimalsOffset();
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                ASSET DECIMALS GETTER HELPER                */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Helper function to get the decimals of the underlying asset.
    /// Useful for setting the return value of `_underlyingDecimals` during initialization.
    /// If the retrieval succeeds, `success` will be true, and `result` will hold the result.
    /// Otherwise, `success` will be false, and `result` will be zero.
    ///
    /// Example usage:
    /// ```
    /// (bool success, uint8 result) = _tryGetAssetDecimals(underlying);
    /// _decimals = success ? result : _DEFAULT_UNDERLYING_DECIMALS;
    /// ```
    function _tryGetAssetDecimals(address underlying)
        internal
        view
        returns (bool success, uint8 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Store the function selector of `decimals()`.
            mstore(0x00, 0x313ce567)
            // Arguments are evaluated last to first.
            success :=
                and(
                    // Returned value is less than 256, at left-padded to 32 bytes.
                    and(lt(mload(0x00), 0x100), gt(returndatasize(), 0x1f)),
                    // The staticcall succeeds.
                    staticcall(gas(), underlying, 0x1c, 0x04, 0x00, 0x20)
                )
            result := mul(mload(0x00), success)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      ACCOUNTING LOGIC                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the total amount of the underlying asset managed by the Vault.
    ///
    /// - SHOULD include any compounding that occurs from the yield.
    /// - MUST be inclusive of any fees that are charged against assets in the Vault.
    /// - MUST NOT revert.
    function totalAssets() public view virtual returns (uint256 assets) {
        assets = SafeTransferLib.balanceOf(asset(), address(this));
    }

    /// @dev Returns the amount of shares that the Vault will exchange for the amount of
    /// assets provided, in an ideal scenario where all conditions are met.
    ///
    /// - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
    /// - MUST NOT show any variations depending on the caller.
    /// - MUST NOT reflect slippage or other on-chain conditions, during the actual exchange.
    /// - MUST NOT revert.
    ///
    /// Note: This calculation MAY NOT reflect the "per-user" price-per-share, and instead
    /// should reflect the "average-user's" price-per-share, i.e. what the average user should
    /// expect to see when exchanging to and from.
    function convertToShares(uint256 assets) public view virtual returns (uint256 shares) {
        if (!_useVirtualShares()) {
            uint256 supply = totalSupply();
            return _eitherIsZero(assets, supply)
                ? _initialConvertToShares(assets)
                : FixedPointMathLib.fullMulDiv(assets, supply, totalAssets());
        }
        uint256 o = _decimalsOffset();
        if (o == 0) {
            return FixedPointMathLib.fullMulDiv(assets, totalSupply() + 1, _inc(totalAssets()));
        }
        return FixedPointMathLib.fullMulDiv(assets, totalSupply() + 10 ** o, _inc(totalAssets()));
    }

    /// @dev Returns the amount of assets that the Vault will exchange for the amount of
    /// shares provided, in an ideal scenario where all conditions are met.
    ///
    /// - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
    /// - MUST NOT show any variations depending on the caller.
    /// - MUST NOT reflect slippage or other on-chain conditions, during the actual exchange.
    /// - MUST NOT revert.
    ///
    /// Note: This calculation MAY NOT reflect the "per-user" price-per-share, and instead
    /// should reflect the "average-user's" price-per-share, i.e. what the average user should
    /// expect to see when exchanging to and from.
    function convertToAssets(uint256 shares) public view virtual returns (uint256 assets) {
        if (!_useVirtualShares()) {
            uint256 supply = totalSupply();
            return supply == 0
                ? _initialConvertToAssets(shares)
                : FixedPointMathLib.fullMulDiv(shares, totalAssets(), supply);
        }
        uint256 o = _decimalsOffset();
        if (o == 0) {
            return FixedPointMathLib.fullMulDiv(shares, totalAssets() + 1, _inc(totalSupply()));
        }
        return FixedPointMathLib.fullMulDiv(shares, totalAssets() + 1, totalSupply() + 10 ** o);
    }

    /// @dev Allows an on-chain or off-chain user to simulate the effects of their deposit
    /// at the current block, given current on-chain conditions.
    ///
    /// - MUST return as close to and no more than the exact amount of Vault shares that
    ///   will be minted in a deposit call in the same transaction, i.e. deposit should
    ///   return the same or more shares as `previewDeposit` if call in the same transaction.
    /// - MUST NOT account for deposit limits like those returned from `maxDeposit` and should
    ///   always act as if the deposit will be accepted, regardless of approvals, etc.
    /// - MUST be inclusive of deposit fees. Integrators should be aware of this.
    /// - MUST not revert.
    ///
    /// Note: Any unfavorable discrepancy between `convertToShares` and `previewDeposit` SHOULD
    /// be considered slippage in share price or some other type of condition, meaning
    /// the depositor will lose assets by depositing.
    function previewDeposit(uint256 assets) public view virtual returns (uint256 shares) {
        shares = convertToShares(assets);
    }

    /// @dev Allows an on-chain or off-chain user to simulate the effects of their mint
    /// at the current block, given current on-chain conditions.
    ///
    /// - MUST return as close to and no fewer than the exact amount of assets that
    ///   will be deposited in a mint call in the same transaction, i.e. mint should
    ///   return the same or fewer assets as `previewMint` if called in the same transaction.
    /// - MUST NOT account for mint limits like those returned from `maxMint` and should
    ///   always act as if the mint will be accepted, regardless of approvals, etc.
    /// - MUST be inclusive of deposit fees. Integrators should be aware of this.
    /// - MUST not revert.
    ///
    /// Note: Any unfavorable discrepancy between `convertToAssets` and `previewMint` SHOULD
    /// be considered slippage in share price or some other type of condition,
    /// meaning the depositor will lose assets by minting.
    function previewMint(uint256 shares) public view virtual returns (uint256 assets) {
        if (!_useVirtualShares()) {
            uint256 supply = totalSupply();
            return supply == 0
                ? _initialConvertToAssets(shares)
                : FixedPointMathLib.fullMulDivUp(shares, totalAssets(), supply);
        }
        uint256 o = _decimalsOffset();
        if (o == 0) {
            return FixedPointMathLib.fullMulDivUp(shares, totalAssets() + 1, _inc(totalSupply()));
        }
        return FixedPointMathLib.fullMulDivUp(shares, totalAssets() + 1, totalSupply() + 10 ** o);
    }

    /// @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal
    /// at the current block, given the current on-chain conditions.
    ///
    /// - MUST return as close to and no fewer than the exact amount of Vault shares that
    ///   will be burned in a withdraw call in the same transaction, i.e. withdraw should
    ///   return the same or fewer shares as `previewWithdraw` if call in the same transaction.
    /// - MUST NOT account for withdrawal limits like those returned from `maxWithdraw` and should
    ///   always act as if the withdrawal will be accepted, regardless of share balance, etc.
    /// - MUST be inclusive of withdrawal fees. Integrators should be aware of this.
    /// - MUST not revert.
    ///
    /// Note: Any unfavorable discrepancy between `convertToShares` and `previewWithdraw` SHOULD
    /// be considered slippage in share price or some other type of condition,
    /// meaning the depositor will lose assets by depositing.
    function previewWithdraw(uint256 assets) public view virtual returns (uint256 shares) {
        if (!_useVirtualShares()) {
            uint256 supply = totalSupply();
            return _eitherIsZero(assets, supply)
                ? _initialConvertToShares(assets)
                : FixedPointMathLib.fullMulDivUp(assets, supply, totalAssets());
        }
        uint256 o = _decimalsOffset();
        if (o == 0) {
            return FixedPointMathLib.fullMulDivUp(assets, totalSupply() + 1, _inc(totalAssets()));
        }
        return FixedPointMathLib.fullMulDivUp(assets, totalSupply() + 10 ** o, _inc(totalAssets()));
    }

    /// @dev Allows an on-chain or off-chain user to simulate the effects of their redemption
    /// at the current block, given current on-chain conditions.
    ///
    /// - MUST return as close to and no more than the exact amount of assets that
    ///   will be withdrawn in a redeem call in the same transaction, i.e. redeem should
    ///   return the same or more assets as `previewRedeem` if called in the same transaction.
    /// - MUST NOT account for redemption limits like those returned from `maxRedeem` and should
    ///   always act as if the redemption will be accepted, regardless of approvals, etc.
    /// - MUST be inclusive of withdrawal fees. Integrators should be aware of this.
    /// - MUST NOT revert.
    ///
    /// Note: Any unfavorable discrepancy between `convertToAssets` and `previewRedeem` SHOULD
    /// be considered slippage in share price or some other type of condition,
    /// meaning the depositor will lose assets by depositing.
    function previewRedeem(uint256 shares) public view virtual returns (uint256 assets) {
        assets = convertToAssets(shares);
    }

    /// @dev Private helper to return if either value is zero.
    function _eitherIsZero(uint256 a, uint256 b) private pure returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := or(iszero(a), iszero(b))
        }
    }

    /// @dev Private helper to return the value plus one.
    function _inc(uint256 x) private pure returns (uint256) {
        unchecked {
            return x + 1;
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*              DEPOSIT / WITHDRAWAL LIMIT LOGIC              */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the maximum amount of the underlying asset that can be deposited
    /// into the Vault for `to`, via a deposit call.
    ///
    /// - MUST return a limited value if `to` is subject to some deposit limit.
    /// - MUST return `2**256-1` if there is no maximum limit.
    /// - MUST NOT revert.
    function maxDeposit(address to) public view virtual returns (uint256 maxAssets) {
        to = to; // Silence unused variable warning.
        maxAssets = type(uint256).max;
    }

    /// @dev Returns the maximum amount of the Vault shares that can be minter for `to`,
    /// via a mint call.
    ///
    /// - MUST return a limited value if `to` is subject to some mint limit.
    /// - MUST return `2**256-1` if there is no maximum limit.
    /// - MUST NOT revert.
    function maxMint(address to) public view virtual returns (uint256 maxShares) {
        to = to; // Silence unused variable warning.
        maxShares = type(uint256).max;
    }

    /// @dev Returns the maximum amount of the underlying asset that can be withdrawn
    /// from the `owner`'s balance in the Vault, via a withdraw call.
    ///
    /// - MUST return a limited value if `owner` is subject to some withdrawal limit or timelock.
    /// - MUST NOT revert.
    function maxWithdraw(address owner) public view virtual returns (uint256 maxAssets) {
        maxAssets = convertToAssets(balanceOf(owner));
    }

    /// @dev Returns the maximum amount of Vault shares that can be redeemed
    /// from the `owner`'s balance in the Vault, via a redeem call.
    ///
    /// - MUST return a limited value if `owner` is subject to some withdrawal limit or timelock.
    /// - MUST return `balanceOf(owner)` otherwise.
    /// - MUST NOT revert.
    function maxRedeem(address owner) public view virtual returns (uint256 maxShares) {
        maxShares = balanceOf(owner);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                 DEPOSIT / WITHDRAWAL LOGIC                 */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Mints `shares` Vault shares to `to` by depositing exactly `assets`
    /// of underlying tokens.
    ///
    /// - MUST emit the {Deposit} event.
    /// - MAY support an additional flow in which the underlying tokens are owned by the Vault
    ///   contract before the deposit execution, and are accounted for during deposit.
    /// - MUST revert if all of `assets` cannot be deposited, such as due to deposit limit,
    ///   slippage, insufficient approval, etc.
    ///
    /// Note: Most implementations will require pre-approval of the Vault with the
    /// Vault's underlying `asset` token.
    function deposit(uint256 assets, address to) public virtual returns (uint256 shares) {
        if (assets > maxDeposit(to)) _revert(0xb3c61a83); // `DepositMoreThanMax()`.
        shares = previewDeposit(assets);
        _deposit(msg.sender, to, assets, shares);
    }

    /// @dev Mints exactly `shares` Vault shares to `to` by depositing `assets`
    /// of underlying tokens.
    ///
    /// - MUST emit the {Deposit} event.
    /// - MAY support an additional flow in which the underlying tokens are owned by the Vault
    ///   contract before the mint execution, and are accounted for during mint.
    /// - MUST revert if all of `shares` cannot be deposited, such as due to deposit limit,
    ///   slippage, insufficient approval, etc.
    ///
    /// Note: Most implementations will require pre-approval of the Vault with the
    /// Vault's underlying `asset` token.
    function mint(uint256 shares, address to) public virtual returns (uint256 assets) {
        if (shares > maxMint(to)) _revert(0x6a695959); // `MintMoreThanMax()`.
        assets = previewMint(shares);
        _deposit(msg.sender, to, assets, shares);
    }

    /// @dev Burns `shares` from `owner` and sends exactly `assets` of underlying tokens to `to`.
    ///
    /// - MUST emit the {Withdraw} event.
    /// - MAY support an additional flow in which the underlying tokens are owned by the Vault
    ///   contract before the withdraw execution, and are accounted for during withdraw.
    /// - MUST revert if all of `assets` cannot be withdrawn, such as due to withdrawal limit,
    ///   slippage, insufficient balance, etc.
    ///
    /// Note: Some implementations will require pre-requesting to the Vault before a withdrawal
    /// may be performed. Those methods should be performed separately.
    function withdraw(uint256 assets, address to, address owner)
        public
        virtual
        returns (uint256 shares)
    {
        if (assets > maxWithdraw(owner)) _revert(0x936941fc); // `WithdrawMoreThanMax()`.
        shares = previewWithdraw(assets);
        _withdraw(msg.sender, to, owner, assets, shares);
    }

    /// @dev Burns exactly `shares` from `owner` and sends `assets` of underlying tokens to `to`.
    ///
    /// - MUST emit the {Withdraw} event.
    /// - MAY support an additional flow in which the underlying tokens are owned by the Vault
    ///   contract before the redeem execution, and are accounted for during redeem.
    /// - MUST revert if all of shares cannot be redeemed, such as due to withdrawal limit,
    ///   slippage, insufficient balance, etc.
    ///
    /// Note: Some implementations will require pre-requesting to the Vault before a redeem
    /// may be performed. Those methods should be performed separately.
    function redeem(uint256 shares, address to, address owner)
        public
        virtual
        returns (uint256 assets)
    {
        if (shares > maxRedeem(owner)) _revert(0x4656425a); // `RedeemMoreThanMax()`.
        assets = previewRedeem(shares);
        _withdraw(msg.sender, to, owner, assets, shares);
    }

    /// @dev Internal helper for reverting efficiently.
    function _revert(uint256 s) private pure {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, s)
            revert(0x1c, 0x04)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      INTERNAL HELPERS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev For deposits and mints.
    ///
    /// Emits a {Deposit} event.
    function _deposit(address by, address to, uint256 assets, uint256 shares) internal virtual {
        SafeTransferLib.safeTransferFrom(asset(), by, address(this), assets);
        _mint(to, shares);
        /// @solidity memory-safe-assembly
        assembly {
            // Emit the {Deposit} event.
            mstore(0x00, assets)
            mstore(0x20, shares)
            let m := shr(96, not(0))
            log3(0x00, 0x40, _DEPOSIT_EVENT_SIGNATURE, and(m, by), and(m, to))
        }
        _afterDeposit(assets, shares);
    }

    /// @dev For withdrawals and redemptions.
    ///
    /// Emits a {Withdraw} event.
    function _withdraw(address by, address to, address owner, uint256 assets, uint256 shares)
        internal
        virtual
    {
        if (by != owner) _spendAllowance(owner, by, shares);
        _beforeWithdraw(assets, shares);
        _burn(owner, shares);
        SafeTransferLib.safeTransfer(asset(), to, assets);
        /// @solidity memory-safe-assembly
        assembly {
            // Emit the {Withdraw} event.
            mstore(0x00, assets)
            mstore(0x20, shares)
            let m := shr(96, not(0))
            log4(0x00, 0x40, _WITHDRAW_EVENT_SIGNATURE, and(m, by), and(m, to), and(m, owner))
        }
    }

    /// @dev Internal conversion function (from assets to shares) to apply when the Vault is empty.
    /// Only used when {_useVirtualShares} returns false.
    ///
    /// Note: Make sure to keep this function consistent with {_initialConvertToAssets}
    /// when overriding it.
    function _initialConvertToShares(uint256 assets)
        internal
        view
        virtual
        returns (uint256 shares)
    {
        shares = assets;
    }

    /// @dev Internal conversion function (from shares to assets) to apply when the Vault is empty.
    /// Only used when {_useVirtualShares} returns false.
    ///
    /// Note: Make sure to keep this function consistent with {_initialConvertToShares}
    /// when overriding it.
    function _initialConvertToAssets(uint256 shares)
        internal
        view
        virtual
        returns (uint256 assets)
    {
        assets = shares;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     HOOKS TO OVERRIDE                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Hook that is called before any withdrawal or redemption.
    function _beforeWithdraw(uint256 assets, uint256 shares) internal virtual {}

    /// @dev Hook that is called after any deposit or mint.
    function _afterDeposit(uint256 assets, uint256 shares) internal virtual {}
}

// src/core/goldivault/Goldivault4626.sol

// |============================================================================================|
// |    ______      _____    __      _____    __   __       _____     _____   __  __   ______   |
// |   /_/\___\    ) ___ (  /\_\    /\ __/\  /\_\ /\_\     ) ___ (   /\ __/\ /\_\\  /\/ ____/\  |
// |   ) ) ___/   / /\_/\ \( ( (    ) )  \ \ \/_/( ( (    / /\_/\ \  ) )__\/( ( (/ / /) ) __\/  |
// |  /_/ /  ___ / /_/ (_\ \\ \_\  / / /\ \ \ /\_\\ \_\  / /_/ (_\ \/ / /    \ \_ / /  \ \ \    |
// |  \ \ \_/\__\\ \ )_/ / // / /__\ \ \/ / // / // / /__\ \ )_/ / /\ \ \_   / /  \ \  _\ \ \   |
// |   )_)  \/ _/ \ \/_\/ /( (_____() )__/ /( (_(( (_____(\ \/_\/ /  ) )__/\( (_(\ \ \)____) )  |
// |   \_\____/    )_____(  \/_____/\/___\/  \/_/ \/_____/ )_____(   \/___\/ \/_//__\/\____\/   |
// |                                                                                            |
// |============================================================================================|
// ==============================================================================================
// ===================================== Goldivault4626 =========================================
// ==============================================================================================

/// @title Goldivault4626
/// @notice Splits deposited assets into ownership tokens representing
/// deposited assets and yield tokens representing future yield of those assets
/// This vault is for streaming the yield continuously to users. Staking mechanism for YT copied from Goldilend
contract Goldivault4626 is IGoldivault4626, ReentrancyGuard {

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                      STATE VARIABLES                       */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /// @notice Address of ownership token
  address public immutable ot;

  /// @notice Address of yield token
  address public immutable yt;

  /// @notice Address of deposit token
  address public immutable depositToken;
  
  /// @notice Address of erc4626 deposit vault
  address public immutable depositVault;

  /// @notice Address of multisig
  address public immutable multisig;

  /// @notice Address of Kodiak SwapRouter02
  address router;

  /// @notice YT trade fee
  uint256 tradeFee;

  /// @notice Fee charged for yield
  uint256 public yieldFee;

  /// @notice Timestamp of vault start time
  uint256 public startTime;

  /// @notice Timestamp of vault end time
  uint256 public endTime;

  /// @notice Amount of deposit token in vault
  uint256 public depositTokenAmount;

  /// @notice Defines the value of one token
  uint256 public inputRatioAmount;

  /// @notice Claimable underlying per staked YT
  uint256 public claimableUnderlyingPerYTStored;

  /// @notice Assets/shares ratio at last claim update
  uint256 public lastRatio;

  /// @notice Amount of yield tokens staked in contract
  uint256 public totalYtStaked;

  /// @notice Amount of YT staked per user
  mapping(address user => uint256 amount) public ytStaked;

  /// @notice Maps user to amount of claimable Underlying
  mapping(address user => uint256 amount) public claimableUnderlying;

  /// @notice Maps user to amount of Underlying reward debt
  mapping(address user => uint256 amount) public underlyingPerYTDebt;

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                          CONSTRUCTOR                       */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /// @notice Constructor of this contract
  /// @param _ot Address of ownership token
  /// @param _yt Address of yield token
  /// @param _multisig Address of multisig
  /// @param _depositToken Address of deposit token
  /// @param _depositVault Address of deposit token vault
  /// @param _router Address of Kodiak SwapRouter02
  /// @param _tradeFee Fee charged on YT trades
  /// @param _yieldFee Fee charged for yield
  /// @param _inputRatioAmount Defines the value of one token
  /// @param _duration Duration of vault
  constructor(
    address _ot,
    address _yt,
    address _multisig,
    address _depositToken,
    address _depositVault,
    address _router,
    uint256 _tradeFee,
    uint256 _yieldFee,
    uint256 _inputRatioAmount,
    uint256 _duration
  ) {
    ot = _ot;
    yt = _yt;
    multisig = _multisig;
    depositToken = _depositToken;
    depositVault = _depositVault;
    router = _router;
    tradeFee = _tradeFee;
    yieldFee = _yieldFee;
    inputRatioAmount = _inputRatioAmount;
    lastRatio = ERC4626(depositVault).convertToAssets(_inputRatioAmount);
    startTime = block.timestamp;
    endTime = block.timestamp + _duration;
  }

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                    EXTERNAL FUNCTIONS                      */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /// @inheritdoc IGoldivault4626
  function deposit(uint256 amount) external nonReentrant {
    if(amount == 0) revert InvalidDeposit();
    _updateClaimableUnderlying(msg.sender);
    SafeTransferLib.safeTransferFrom(depositToken, msg.sender, address(this), amount);
    ERC20(depositToken).approve(depositVault, amount);
    ERC4626(depositVault).deposit(amount, address(this));
    depositTokenAmount += amount;
    OwnershipToken(ot).mintOT(msg.sender, amount);
    YieldToken(yt).mintYT(msg.sender, amount);
    _stakeYT(amount);
    emit Deposit(msg.sender, amount);
  }

  /// @inheritdoc IGoldivault4626
  function redeemOwnership(uint256 amount) external nonReentrant {
    if(amount == 0) revert InvalidRedemption();
    uint256 remainingTime = block.timestamp > endTime ? 0 : endTime - block.timestamp;
    _updateClaimableUnderlying(msg.sender);
    OwnershipToken(ot).burnOT(msg.sender, amount);
    if(remainingTime > 0) {
      _unstakeYT(amount);
      YieldToken(yt).burnYT(msg.sender, amount);
    }
    ERC4626(depositVault).withdraw(amount, msg.sender, address(this));
    depositTokenAmount -= amount;
    emit OwnershipTokenRedemption(msg.sender, amount);
  }

  /// @inheritdoc IGoldivault4626
  function buyYT (uint256 ytAmount, uint256 dtAmountMax, uint256 amountOutMin) external nonReentrant {
    if(ytAmount == 0 || dtAmountMax == 0 || amountOutMin == 0) revert InvalidTrade();
    ERC4626 _depositVault = ERC4626(depositVault);
    uint256 remainingTime = block.timestamp > endTime ? 0 : endTime - block.timestamp;
    if(remainingTime == 0) revert AlreadyConcluded();
    uint256 startingBalance = ERC20(depositToken).balanceOf(msg.sender);
    uint256 dtNeeded = dtAmountMax > ytAmount ? 0 : ytAmount - dtAmountMax;
    uint256 depositAmount = dtAmountMax + dtNeeded;
    if(dtNeeded == 0) dtAmountMax = ytAmount;
    if(_depositVault.previewRedeem(ERC20(depositVault).balanceOf(address(this))) < dtNeeded) revert FlashLoanFailed();
    if(dtNeeded > 0) _depositVault.withdraw(dtNeeded, msg.sender, address(this));
    _deposit(depositAmount);
    uint256 startingShareBalance = ERC20(depositVault).balanceOf(address(this));
    ERC20(ot).approve(router, type(uint256).max);
    IV3SwapRouter.ExactInputSingleParams memory params = IV3SwapRouter.ExactInputSingleParams({
      tokenIn: ot,
      tokenOut: depositVault,
      fee: 500,
      recipient: address(this),
      amountIn: depositAmount,
      amountOutMinimum: amountOutMin,
      sqrtPriceLimitX96: 0
    });
    IV3SwapRouter(router).exactInputSingle(params);
    ERC20(ot).approve(router, 0);
    uint256 proceeds = ERC20(depositVault).balanceOf(address(this)) - startingShareBalance;
    if (dtNeeded == 0) {
      _depositVault.redeem(proceeds, msg.sender, address(this));
    } else {
      uint256 contractShares = _depositVault.convertToShares(dtNeeded);
      _depositVault.redeem(proceeds - contractShares, msg.sender, address(this));
    }
    uint256 endingBalance = ERC20(depositToken).balanceOf(msg.sender);
    if(endingBalance > startingBalance) revert ReceivedTooMuch();
    uint256 spentDt = startingBalance - endingBalance;
    uint256 fee = tradeFee * spentDt / 1000;
    if(spentDt + fee > dtAmountMax) revert SpentTooMuch();
    SafeTransferLib.safeTransferFrom(depositToken, msg.sender, multisig, fee);
    emit YTBuy(msg.sender, ytAmount, spentDt);
  }
  
  /// @inheritdoc IGoldivault4626
  function sellYT (uint256 ytAmount, uint256 dtAmountMin, uint256 amountInMax) external nonReentrant {
    if(ytAmount == 0 || dtAmountMin == 0 || amountInMax == 0) revert InvalidTrade();
    ERC20 _depositToken = ERC20(depositToken);
    ERC20 _shares = ERC20(depositVault);
    uint256 remainingTime = block.timestamp > endTime ? 0 : endTime - block.timestamp;
    if(remainingTime == 0) revert AlreadyConcluded();
    uint256 startingBalance = _depositToken.balanceOf(msg.sender);
    _redeemOwnership(ytAmount);
    uint256 startingVaultBalance = _shares.balanceOf(address(this));
    _shares.approve(router, type(uint256).max);
    IV3SwapRouter.ExactOutputSingleParams memory params = IV3SwapRouter.ExactOutputSingleParams({
      tokenIn: depositVault,
      tokenOut: ot,
      fee: 500,
      recipient: address(this),
      amountOut: ytAmount,
      amountInMaximum: amountInMax,
      sqrtPriceLimitX96: 0
    });
    IV3SwapRouter(router).exactOutputSingle(params);
    _shares.approve(router, 0);
    OwnershipToken(ot).burnOT(address(this), ytAmount);
    uint256 vaultSpend = startingVaultBalance - _shares.balanceOf(address(this));
    uint256 repayAmount = ERC4626(depositVault).previewMint(vaultSpend);
    SafeTransferLib.safeTransferFrom(depositToken, msg.sender, address(this), repayAmount);
    _depositToken.approve(depositVault, repayAmount);
    ERC4626(depositVault).deposit(repayAmount, address(this));
    uint256 endingBalance = _depositToken.balanceOf(msg.sender);
    if(endingBalance < startingBalance) revert ReceivedTooLitte(); 
    uint256 receivedDt = endingBalance - startingBalance;
    uint256 fee = tradeFee * receivedDt / 1000;
    if(receivedDt - fee < dtAmountMin) revert ReceivedTooLitte();
    SafeTransferLib.safeTransferFrom(depositToken, msg.sender, multisig, fee);
    emit YTSell(msg.sender, ytAmount, receivedDt - fee);
  }

  /// @inheritdoc IGoldivault4626
  function stakeYT(uint256 amount) external nonReentrant {
    _updateClaimableUnderlying(msg.sender);
    _stakeYT(amount);
  }

  /// @inheritdoc IGoldivault4626
  function unstakeYT(uint256 amount) external nonReentrant {
    _updateClaimableUnderlying(msg.sender);
    _unstakeYT(amount);
  }

  /// @inheritdoc IGoldivault4626
  function claim() external nonReentrant {
    _updateClaimableUnderlying(msg.sender);
    _claim(msg.sender, claimableUnderlying[msg.sender]);
  }

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                 EXTERNAL VIEW FUNCTIONS                    */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /// @inheritdoc IGoldivault4626
  function userClaimableUnderlying(address user) external view returns (uint256) {
    return _calculateClaimableUnderlying(user);
  }

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                    INTERNAL FUNCTIONS                      */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /// @notice Updates claimable Underlying
  /// @param user Address of user
  function _updateClaimableUnderlying(address user) internal {
    claimableUnderlyingPerYTStored = _claimableUnderlyingPerYT();
    lastRatio = ERC4626(depositVault).convertToAssets(inputRatioAmount);
    claimableUnderlying[user] = _calculateClaimableUnderlying(user);
    underlyingPerYTDebt[user] = claimableUnderlyingPerYTStored;
  }

  /// @notice Internal function for claiming underlying
  /// @param claimer Address of user claiming
  /// @param claimable Amount of underlying token to claim
  function _claim(address claimer, uint256 claimable) internal {
    if(claimable > 0) {
      claimableUnderlying[claimer] = 0;
      uint256 beforeBal = ERC20(depositToken).balanceOf(address(this));
      ERC4626(depositVault).withdraw(claimable, address(this), address(this));
      uint256 afterBal = ERC20(depositToken).balanceOf(address(this));
      uint256 fee = (afterBal - beforeBal) * yieldFee / 100;
      SafeTransferLib.safeTransfer(depositToken, msg.sender, (afterBal - beforeBal) - fee);
      SafeTransferLib.safeTransfer(depositToken, multisig, fee);
      emit Claim(claimer, claimable);
    }
  }

  /// @notice Internal deposit function for buy and sell functions
  /// @param amount Amount of DT to deposit into the underlying vault
  function _deposit(uint256 amount) internal {
    if(amount == 0) revert InvalidDeposit();
    _updateClaimableUnderlying(msg.sender);
    SafeTransferLib.safeTransferFrom(depositToken, msg.sender, address(this), amount);
    ERC20(depositToken).approve(depositVault, amount);
    ERC4626(depositVault).deposit(amount, address(this));
    depositTokenAmount += amount;
    OwnershipToken(ot).mintOT(address(this), amount);
    YieldToken(yt).mintYT(address(this), amount);
    ytStaked[msg.sender] += amount;
    totalYtStaked += amount;
    emit YTStake(msg.sender, amount);
    emit Deposit(msg.sender, amount);
  }

  /// @notice Internal redeem function for buy and sell functions
  /// @param amount Amount of OT to redeem
  function _redeemOwnership(uint256 amount) internal {
    if(amount == 0) revert InvalidRedemption();
    _updateClaimableUnderlying(msg.sender);
    _unstakeYT(amount);
    YieldToken(yt).burnYT(msg.sender, amount);
    ERC4626(depositVault).withdraw(amount, msg.sender, address(this));
    depositTokenAmount -= amount; 
    emit OwnershipTokenRedemption(msg.sender, amount);
  }

  /// @notice Stakes YT into contract
  /// @param amount Amount of YT to stake
  function _stakeYT(uint256 amount) internal {
    ytStaked[msg.sender] += amount;
    totalYtStaked += amount;
    SafeTransferLib.safeTransferFrom(yt, msg.sender, address(this), amount);
    emit YTStake(msg.sender, amount);
  }

  /// @notice Unstakes YT from contract
  /// @param amount Amount of YT to unstake
  function _unstakeYT(uint256 amount) internal {
    if(amount > ytStaked[msg.sender]) revert InvalidUnstake();
    ytStaked[msg.sender] -= amount;
    totalYtStaked -= amount;
    SafeTransferLib.safeTransfer(yt, msg.sender, amount);
    emit YTUnstake(msg.sender, amount);
  }

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                   INTERNAL VIEW FUNCTIONS                  */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /// @notice Calculates claimable underlying
  /// @param user Address of user to calculate the claimable for
  function _calculateClaimableUnderlying(address user) internal view returns (uint256) {
    return FixedPointMathLib.mulWad(ytStaked[user], _claimableUnderlyingPerYT() - underlyingPerYTDebt[user]) + claimableUnderlying[user];
  }

  /// @notice Calculates claimable underlying per YT
  /// @dev This function will revert if there is a loss in the underlying vault
  function _claimableUnderlyingPerYT() internal view returns (uint256) {
    uint256 oldRatio = lastRatio;
    uint256 newRatio = ERC4626(depositVault).convertToAssets(inputRatioAmount);
    if(newRatio < oldRatio) revert NegativeYield();
    uint256 ratioDiff = newRatio - oldRatio;
    if(ratioDiff == 0 || totalYtStaked == 0) {
      return claimableUnderlyingPerYTStored;
    }
    uint256 totalContractInterest = FixedPointMathLib.mulWad(ratioDiff, ERC20(depositVault).balanceOf(address(this)));
    return claimableUnderlyingPerYTStored + FixedPointMathLib.divWad(totalContractInterest, totalYtStaked);
  }

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                    PERMISSIONED FUNCTIONS                  */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  function recoverYield() external {
    if(msg.sender != multisig) revert NotMultisig();
    uint256 timeAfterMaturity = endTime > block.timestamp ? 0 : block.timestamp - endTime;
    if(timeAfterMaturity < 1 weeks) revert DelayTooShort();
    SafeTransferLib.safeTransfer(depositVault, multisig, ERC20(depositVault).balanceOf(address(this)));
  }

}
