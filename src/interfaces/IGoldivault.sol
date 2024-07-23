//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title IGoldivault
interface IGoldivault {

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                           EVENTS                           */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  event Deposit(address indexed user, uint256 amount);
  event OwnershipTokenRedemption(address indexed user, uint256 amount);
  event YieldTokenRedemption(address indexed user, uint256 amount);
  event Conclude(uint256 timestamp);

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                           ERRORS                           */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  error InsufficientTime();
  error InvalidRedemption();
  error NotExpired();
  error NotConcluded();
  error NotMultisig();
  error NotTimelock();
  error AlreadyConcluded();
  error ExcessiveRedeem();
  error TooManyTokens();
  error AlreadyInitialized();

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                    EXTERNAL FUNCTIONS                      */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /// @notice Deposits tokens into vault to receive ownership and yield tokens
  /// @param amount Amount of tokens to deposit
  function deposit(uint256 amount) external;

  /// @notice Withdraws tokens from the vault 
  /// @param amount Amount of ownership tokens to redeem
  function redeemOwnership(uint256 amount) external;

  /// @notice Redeems yield tokens for share of yield accrued to vault
  /// @param amount Amount of yield tokens to redeem
  function redeemYield(uint256 amount) external;

  /// @notice Concludes vault at expiry
  function conclude() external;

  /// @notice Compounds yield from vault and restakes it
  function compound() external;

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                    PERMISSIONED FUNCTIONS                  */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /// @notice Renews concluded vault
  /// @dev Callable only by Timelock
  function renew() external;

  /// @notice Allows the multisig to add yield tokens to vault
  /// @dev Callable only by multisig
  /// @param _yieldTokens Tokens to add to yieldTokens array
  function addYieldTokens(address[] calldata _yieldTokens) external;

  /// @notice Allows DAO to set protocol parameters
  /// @dev Callable only by Timelock
  /// @param _earlyWithdrawalFee New early withdrawal fee
  /// @param _yieldFee New vault fee
  /// @param _delay New vault delay
  /// @param _duration New vault duration
  function changeProtocolParameters(
    uint256 _earlyWithdrawalFee,
    uint256 _yieldFee,
    uint256 _delay,
    uint256 _duration
  ) external;

  /// @notice Allows the multisig to initialize the protocol
  /// @dev Callable only by multisig
  /// @param _earlyWithdrawalFee Fee charged for early withdrawal
  /// @param _yieldFee Fee charged for yield
  /// @param _delay Delay period after vault concludes before redemption is allowed
  /// @param _duration Duration of vault
  function initializeProtocol(
    uint256 _earlyWithdrawalFee,
    uint256 _yieldFee,
    uint256 _delay,
    uint256 _duration,
    address[] memory _yieldTokens
  ) external;

}