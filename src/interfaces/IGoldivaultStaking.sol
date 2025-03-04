//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title IGoldivaultStaking
interface IGoldivaultStaking {

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                           EVENTS                           */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  event Deposit(address indexed user, uint256 amount);
  event OwnershipTokenRedemption(address indexed user, uint256 amount);
  event YieldTokenRedemption(address indexed user, uint256 amount);
  event NewProtocolParameters(uint256 newEarlyWithdrawalFee, uint256 newYieldFee, uint256 newDelay, uint256 newDepositWindow);
  event YTBuy(address indexed user, uint256 boughtYt, uint256 spentDt);
  event YTSell(address indexed user, uint256 soldYt, uint256 receivedDt);
  event YTStake(address indexed user, uint256 amount);
  event YTUnstake(address indexed user, uint256 amount);
  event Claim(address indexed user, uint256 amount);

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                           ERRORS                           */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  error InvalidRedemption();
  error InvalidDeposit();
  error NotMultisig();
  error AlreadyConcluded();
  error AlreadyInitialized();
  error SpentTooMuch();
  error ReceivedTooMuch();
  error ReceivedTooLitte();
  error FlashLoanFailed();
  error InvalidTrade();
  error InvalidUnstake();

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                    EXTERNAL FUNCTIONS                      */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /// @notice Deposits tokens into vault to receive ownership and yield tokens
  /// @param amount Amount of tokens to deposit
  function deposit(uint256 amount) external;

  /// @notice Withdraws tokens from the vault 
  /// @param amount Amount of ownership tokens to redeem
  function redeemOwnership(uint256 amount) external;

}