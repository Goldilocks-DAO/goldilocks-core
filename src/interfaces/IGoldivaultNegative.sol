//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title IGoldivaultNegative
interface IGoldivaultNegative {

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                           EVENTS                           */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  event Deposit(address indexed user, uint256 amount);
  event OwnershipTokenRedemption(address indexed user, uint256 amount);
  event YieldTokenRedemption(address indexed user, uint256 amount);
  event Conclude(uint256 timestamp);
  event Renew(uint256 newStartTime, uint256 newEndTime);
  event NewYieldTokens(address[] newYieldTokens);
  event NewNegativeProtocolParameters(uint256 newYieldFee, uint256 newDelay, uint256 newDepositWindow);

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                           ERRORS                           */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  error InsufficientTime();
  error InvalidRedemption();
  error InvalidDeposit();
  error NotExpired();
  error NotConcluded();
  error NotMultisig();
  error NotTimelock();
  error AlreadyConcluded();
  error ExcessiveRedeem();
  error TooManyTokens();
  error SameYieldToken();
  error AlreadyInitialized();
  error UnclearRenewState();

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
  /// @param _yieldFee New vault fee
  /// @param _delay New vault delay
  /// @param _depositWindow New deposit window
  function changeProtocolParameters(
    uint256 _yieldFee,
    uint256 _delay,
    uint256 _depositWindow
  ) external;

  /// @notice Allows the multisig to initialize the protocol
  /// @dev Callable only by multisig
  /// @param _yieldFee Fee charged for yield
  /// @param _delay Delay period after vault concludes before redemption is allowed
  /// @param _duration Duration of vault
  /// @param _depositWindow Amount of time before deposits are closed
  /// @param _yieldTokens Addresses of yield tokens
  function initializeProtocol(
    uint256 _yieldFee,
    uint256 _delay,
    uint256 _duration,
    uint256 _depositWindow,
    address[] memory _yieldTokens
  ) external;

}