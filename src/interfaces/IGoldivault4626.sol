//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

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