//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title IGoldilocked
interface IGoldilocked {

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                           EVENTS                           */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  event Stake(address indexed user, uint256 amount);
  event Unstake(address indexed user, uint256 amount);
  event Stir(address indexed user, uint256 amount);
  event Claim(address indexed user, uint256 amount);
  event Borrow(address indexed user, uint256 amount);
  event Repay(address indexed user, uint256 amount);

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                           ERRORS                           */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  error NotGoldilend();
  error NotTimelock();
  error NotMultisig();
  error NotVested();
  error Vesting();
  error InvalidUnstake();
  error LocksBorrowedAgainst();
  error InsufficientBorrowLimit();
  error ExcessiveRepay();

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                       VIEW FUNCTIONS                       */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /// @notice Returns amount of staked Locks
  /// @param user Address of user for query
  function userStakedLocks(address user) external view returns (uint256);

  /// @notice Returns amount of claimable Porridge
  /// @param user Address of user for query
  function userClaimablePrg(address user) external view returns (uint256);

  /// @notice Returns amount of locked Locks
  /// @param user Address of user for query
  function userLockedLocks(address user) external view returns (uint256);

  /// @notice Returns amount of borrowed Honey
  /// @param user Address of user for query
  function userBorrowedHoney(address user) external view returns (uint256);

  /// @notice Returns limit of borrowable Honey
  /// @param user Address of user for query
  function userBorrowLimit(address user) external view returns (uint256);

  /// @notice Returns amount of unvested Locks
  /// @param user Address of user for query
  function userVestingCheck(address user) external view returns (uint256);

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                    EXTERNAL FUNCTIONS                      */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /// @notice Stakes Locks and begins earning Porridge
  /// @param amount Amount of Locks to stake
  function stake(uint256 amount) external;

  /// @notice Unstakes Locks
  /// @param amount Amount of Locks to unstake
  function unstake(uint256 amount) external;

  /// @notice Burns Porridge to buy Locks at floor price
  /// @param amount Amount of Porridge to burn
  function stir(uint256 amount) external;

  /// @notice Claim Porridge rewards
  function claim() external;

  /// @notice Lends out Honey using staked Locks as collateral
  /// @dev borrow limit is Locks floor price * staked Locks - locked locks
  /// @param amount Amount of Honey to borrow
  function borrow(uint256 amount) external;

  /// @notice Repays Honey loans
  /// @param amount Amount of Honey to repay
  function repay(uint256 amount) external;

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                    PERMISSIONED FUNCTIONS                  */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /// @notice Mints Porridge to user who is staking GiBGT
  /// @dev Callable only by Goldilend
  /// @param to Recipient of minted Porridge
  /// @param amount Amount of minted Porridge
  function goldilendMint(address to, uint256 amount) external;

  /// @notice Allows the DAO to change Porridge emissions
  /// @dev Callable only by Timelock
  /// @param newPrgEmissions Sets the annual Porridge emission rate for Locks staking
  function changePrgEmissions(uint256 newPrgEmissions) external;

  /// @notice Allows the DAO to mint Porridge
  /// @dev Callable only by Timelock
  /// @param newPorridge Amount of Porridge to mint
  function mintPorridge(uint256 newPorridge) external;

  /// @notice Allows multisig to set Goldilend address
  /// @dev Callable only by multisig
  /// @param _goldilend Address of Goldilend
  function setGoldilendAddress(address _goldilend) external;

}