//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title IGoldiswap
interface IGoldiswap {

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                           EVENTS                           */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  event Buy(address indexed user, uint256 amount);
  event Sale(address indexed user, uint256 amount);
  event Redeem(address indexed user, uint256 amount);

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                           ERRORS                           */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  error NotGoldilocked();
  error NotMultisig();
  error NotTimelock();
  error ExcessiveSlippage();

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                       VIEW FUNCTIONS                       */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /// @notice Returns Locks floor price
  function floorPrice() external view returns (uint256);

  /// @notice Returns Locks market price
  function marketPrice() external view returns (uint256);

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                    EXTERNAL FUNCTIONS                      */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /// @notice Buys Locks with Honey
  /// @param amount Amount of Locks to buy
  /// @param maxAmount Maximum amount of Honey to spend
  function buy(uint256 amount, uint256 maxAmount) external;

  /// @notice Sells Locks for Honey
  /// @param amount Amount of Locks to sell
  /// @param minAmount Minimum amount of Honey to receive
  function sell(uint256 amount, uint256 minAmount) external;

  /// @notice Redeems Locks tokens for floor value
  /// @param amount Amount of Locks to redeem
  function redeem(uint256 amount) external;

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                   PERMISSIONED FUNCTIONS                   */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /// @notice Transfers Honey to user borrowing against locks
  /// @dev Callable only by Goldilocked
  /// @param to Address to transfer Honey to
  /// @param amount Amount of Honey to transfer
  /// @param fee Fee sent to treasury
  function borrowTransfer(address to, uint256 amount, uint256 fee) external;

  /// @notice Mints Locks tokens from Porridge token stirring
  /// @dev Callable only by Goldilocked
  /// @param to Recipient of minted Locks tokens
  /// @param amount Amount of minted Locks tokens
  function porridgeMint(address to, uint256 amount, uint256 cost) external;

  /// @notice Allows the DAO to inject liquidity into the contract
  /// @dev Callable only by Timelock
  /// @param fslLiq Liquidity added to FSL
  /// @param pslLiq Liquidity added to PSL
  function injectLiquidity(uint256 fslLiq, uint256 pslLiq) external;

}