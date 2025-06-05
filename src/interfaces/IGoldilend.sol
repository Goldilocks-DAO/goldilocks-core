//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title IGoldilend
interface IGoldilend {

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                          STRUCT                            */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  struct Loan {
    address collateralNFT;
    uint256 collateralNFTId;
    uint256 borrowedAmount;
    uint256 interest;
    uint256 duration;
    uint256 endDate;
    uint256 loanId;
    bool liquidated;
  }

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                           ERRORS                           */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  error NotMultisig();
  error NotAPDAO();
  error NotTimelock();
  error NotActive();
  error ArrayMismatch();
  error InvalidDuration();
  error InvalidLoanAmount();
  error InvalidCollateral();
  error BorrowLimitExceeded();
  error MaxUtilizationExceeded();
  error LoanExpired();
  error Unliquidatable();
  error AlreadyInitialized();

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                           EVENTS                           */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  event WBERALock(address indexed user, uint256 amount);
  event WBERAUnlock(address indexed user, uint256 amount);
  event Borrow(address indexed user, uint256 loanID, uint256 borrowAmount, uint256 interestAmount, uint256 expiration, address collateral, uint256 collateralID);
  event Repay(address indexed user, uint256 amount);
  event Liquidation(address indexed borrower, address indexed liquidator, uint256 amount, uint256 loanId);
  event NewProtocolInterestRate(uint256 newProtocolInterestRate);
  event NewShareRates(uint256 newMultisigShare, uint256 newApdaoShare);
  event NewSlope(uint256 newSlope);
  event NewDurations(uint256 newMinDuration, uint256 newMaxDuration);
  event NewBorrowingActive(bool newBorrowingActive);
  event MultisigInterestClaim(uint256 interestClaim);
  event ApdaoInterestClaim(uint256 interestClaim);

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                      EXTERNAL FUNCTIONS                    */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
  
  /// @notice Locks WBERA and mints glWBERA
  /// @param amount Amount of WBERA to lock
  function lock(uint256 amount) external;

  /// @notice Unlocks WBERA and burns glWBERA
  /// @param amount Amount of WBERA to unlock
  function unlock(uint256 amount) external;

  /// @notice Borrows WBERA against value of NFT
  /// @param borrowAmount Amount of WBERA to borrow
  /// @param duration Duration of loan
  /// @param collateralNFT NFT collection to use as collateral
  /// @param collateralNFTId Token Id of NFT to use as collateral
  function borrow(
    uint256 borrowAmount,
    uint256 duration,
    address collateralNFT,
    uint256 collateralNFTId
  ) external;

  /// @notice Borrows WBERA against value of the BeraBond NFT
  /// @param borrowAmount Amount of WBERA to borrow
  /// @param collateralNFT Berabond NFT to use as collateral
  /// @param collateralNFTId Token Id of NFT to use as collateral
  function berabondBorrow(
    uint256 borrowAmount,
    address collateralNFT,
    uint256 collateralNFTId
  ) external;

  /// @notice Repays loan of WBERA
  /// @param repayAmount Amount of WBERA to repay
  /// @param userLoanId ID of loan to repay
  function repay(uint256 repayAmount, uint256 userLoanId) external;

  /// @notice Liquidates overdue loans by paying WBERA to purchase collateral
  /// @param user Owner of loan to be liquidated
  /// @param userLoanId Loan to be liquidated
  function liquidate(address user, uint256 userLoanId) external;

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                       VIEW FUNCTIONS                       */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /// @notice Returns info on a user loan
  function getUserLoan(address user, uint256 userLoanId) external view returns (Loan memory);

  /// @notice Returns interest on single NFT loan
  function calculateInterest(
    uint256 borrowAmount,
    uint256 duration,
    address collateralNFT
  ) external view returns (uint256);

  /// @notice Returns BGT balance of the token bound account
  function getTBABGTBalance(address nft, uint256 tokenId) external view returns (uint256);

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                    PERMISSIONED FUNCTIONS                  */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /// @notice Allows multisig to adjust the valuation of the NFTs to borrow against
  /// @dev Callable only by multisig
  /// @param _nfts NFTs that are able to be borrowed against
  /// @param _nftFairValues Percentage each NFT is valued as a porportion of the total valuation
    function changeValue(
    address[] calldata _nfts,
    uint256[] calldata _nftFairValues
  ) external;

  /// @notice Allows the DAO to adjust the protocol lending parameters
  /// @dev Callable only by Timelock
  /// @param _protocolInterestRate New interest rate
  /// @param _multisigShare New share for multisig
  /// @param _apdaoShare New share for apdao
  /// @param _slope New slope
  /// @param _minDuration New minimum duration
  /// @param _maxDuration New maximum duration
  function changeLendingParams(
    uint256 _protocolInterestRate,
    uint256 _multisigShare,
    uint256 _apdaoShare,
    uint256 _slope,
    uint256 _minDuration,
    uint256 _maxDuration
  ) external;

  /// @notice Allows multisig to activate or inactivate the protocol
  /// @dev Callable only by multisig
  /// @param _borrowingActive Value that activates or inactivates
  function changeBorrowingActive(bool _borrowingActive) external;

  /// @notice Allows multisig to claim interest
  /// @dev Callable only by multisig
  /// @dev 4.5% of all protocol interest
  function multisigInterestClaim() external;

  /// @notice Allows APDAO to claim interest
  /// @dev Callable only by APDAO
  /// @dev 0.5% of all protocol interest
  function apdaoInterestClaim() external;

  /// @notice Allows multisig to initialize the protocol parameters
  /// @dev Callable only by multisig
  /// @param _multisigShare Share of interest payments to multisig
  /// @param _apdaoShare of interest payments to apdao
  /// @param _minDuration Minimum loan duration
  /// @param _maxDuration Maximum loan duration
  /// @param _protocolInterestRate Initial interest rate of protocol
  /// @param _slope Initial rate at which interest rate increases
  function initializeParameters(
    uint256 _multisigShare,
    uint256 _apdaoShare,
    uint256 _minDuration,
    uint256 _maxDuration,
    uint256 _protocolInterestRate,
    uint256 _slope,
    uint256 _maxUtilization
  ) external;

  /// @notice Allows multisig to initalize bera nft fair values
  /// @dev Callable only by multisig
  /// @param _nfts Bera nft addresses
  /// @param _nftFairValues Bera nft fair values
  function initializeBeras(
    address[] calldata _nfts,
    uint256[] calldata _nftFairValues
  ) external;

  /// @notice Allows multisig to recover tokens to distribute potential airdrops to borrowers
  /// @dev Callable only by multisig
  /// @param token Address of token to recover
  function recoverTokens(address token) external;

  /// @notice Allows multisig to increase backing of glWBERA by sending WBERA
  /// @dev Callable only by multisig
  /// @param amount Amount of WBERA to send
  function increaseglWBERABacking(uint256 amount) external;

  /// @notice Allows multisig to manage the delegation of the BeraBond NFT
  /// @dev Callable only by multisig
  function manageDelegation(
    address nft,
    uint256 tokenId,
    address delegatee,
    uint256 permissions
  ) external;

}