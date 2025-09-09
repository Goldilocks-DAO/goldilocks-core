//SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/// @title IRebaseGoldilend
interface IRebaseGoldilend {

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
    bool repaid;
    bool liquidated;
  }

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                           ERRORS                           */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  error NotMultisig();
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
  error InvalidRenew();
  error LessThanMinOut();
  error Dilution();

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                           EVENTS                           */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  event Deposit(address indexed user, uint256 amount, uint256 mintAmount);
  event Withdraw(address indexed user, uint256 amount, uint256 burnAmount);
  event Borrow(address indexed user, uint256 loanID, uint256 borrowAmount, uint256 interestAmount, uint256 expiration, address collateral, uint256 collateralID);
  event Renew(address indexed user, uint256 loanId, uint256 newBorrowAmount, uint256 newInterest, uint256 newDuration);
  event Repay(address indexed user, uint256 userLoanId, uint256 amount);
  event Liquidation(address indexed borrower, address indexed liquidator, uint256 amount, uint256 loanId);
  event NewProtocolInterestRate(uint256 newProtocolInterestRate);
  event NewDurations(uint256 newMinDuration, uint256 newMaxDuration);
  event NewSlope(uint256 newSlope);
  event NewMaxUtilization(uint256 newMaxUtilization);
  event NewBorrowingActive(bool newBorrowingActive);

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                      EXTERNAL FUNCTIONS                    */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /// @notice Deposits debt asset and mints Goldilend Debt Asset
  /// @param amount Amount of debt asset to deposit
  function deposit(uint256 amount) external;

  /// @notice Withdraws debt asset and burns Goldilend Debt Asset
  /// @param amount Amount of goldilend debt asset to burn
  function withdraw(uint256 amount) external;

  /// @notice Borrows HONEY against value of Rebase Bera
  /// @param borrowAmount Amount of HONEY to borrow
  /// @param minOut Minimum amount of HONEY to send to user
  /// @param duration Duration of loan
  /// @param collateralNFT Rebase Bera to use as collateral
  /// @param collateralNFTId Token Id of Rebase Bera to use as collateral
  function borrow(
    uint256 borrowAmount,
    uint256 minOut,
    uint256 duration,
    address collateralNFT,
    uint256 collateralNFTId
  ) external;

  /// @notice Renews loan with new expiry
  /// @param userLoanId Loan to be renewed
  /// @param newDuration New duration of the loan
  /// @param newBorrowAmount Amount of additional debt asset to be borrowed
  /// @param minOut Minimum amount of HONEY to send to user
  function renew(
    uint256 userLoanId,
    uint256 newDuration,
    uint256 newBorrowAmount,
    uint256 minOut
  ) external;

  /// @notice Repays loan of debt asset
  /// @param repayAmount Amount of debt asset to repay
  /// @param userLoanId ID of loan to repay
  function repay(uint256 repayAmount, uint256 userLoanId) external;

  /// @notice Liquidates overdue loans by paying debt asset to purchase collateral
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

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                    PERMISSIONED FUNCTIONS                  */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /// @notice Allows multisig to adjust the protocol lending parameters
  /// @dev Callable only by multisig
  /// @param _protocolInterestRate New interest rate
  /// @param _minDuration New minimum duration
  /// @param _maxDuration New maximum duration
  /// @param _slope New slope
  /// @param _maxUtilization New Max Utilization
  function changeLendingParams(
    uint256 _protocolInterestRate,
    uint256 _minDuration,
    uint256 _maxDuration,
    uint256 _slope,
    uint256 _maxUtilization
  ) external;

  /// @notice Allows multisig to activate or inactivate the protocol
  /// @dev Callable only by multisig
  /// @param _borrowingActive Value that activates or inactivates
  function changeBorrowingActive(bool _borrowingActive) external;

  /// @notice Allows multisig to initialize the protocol parameters
  /// @dev Callable only by multisig
  /// @param _protocolInterestRate Initial interest rate of protocol
  /// @param _minDuration Minimum loan duration
  /// @param _maxDuration Maximum loan duration
  /// @param _slope Initial rate at which interest rate increases
  /// @param _maxUtilization Maximum amount of protocol debt based on pool size
  function initializeParameters(
    uint256 _protocolInterestRate,
    uint256 _minDuration,
    uint256 _maxDuration,
    uint256 _slope,
    uint256 _maxUtilization
  ) external;

  /// @notice Allows multisig to recover tokens to distribute potential airdrops to borrowers
  /// @dev Callable only by multisig
  /// @param token Address of token to recover
  function recoverTokens(address token) external;

  /// @notice Allows multisig to increase backing of Goldilend Debt Asset by sending debt asset
  /// @dev Callable only by multisig
  /// @param amount Amount of debt asset to send
  function increaseglDebtAssetBacking(uint256 amount) external;

  /// @notice Allows multisig to adjust the valuation of the NFTs to borrow against
  /// @dev Callable only by multisig
  /// @param _nfts NFTs that are able to be borrowed against
  /// @param _nftFairValues Percentage each NFT is valued as a porportion of the total valuation
  function changeValue(
    address[] calldata _nfts,
    uint256[] calldata _nftFairValues
  ) external;

  /// @notice Allows multisig to initalize bera nft fair values
  /// @dev Callable only by multisig
  /// @param _nfts Bera nft addresses
  /// @param _nftFairValues Bera nft fair values
  function initializeBeras(
    address[] calldata _nfts,
    uint256[] calldata _nftFairValues
  ) external;

}