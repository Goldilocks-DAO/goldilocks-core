//SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/// @title IBeraBondGoldilend
interface IBeraBondGoldilend {

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

  struct Bid {
    address loanOriginator;
    uint256 loanId;
    address bidder;
    uint256 bidAmount;
  }

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                           ERRORS                           */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  error NotMultisig();
  error NotActive();
  error InvalidDuration();
  error InvalidLoanAmount();
  error InvalidCollateral();
  error BorrowLimitExceeded();
  error MaxUtilizationExceeded();
  error LoanExpired();
  error Unliquidatable();
  error AlreadyInitialized();
  error InvalidAmount();
  error TransferFailed();
  error InvalidRenew();
  error MoreThanMaxInterest();
  error OverPayment();
  error InvalidRepay();
  error AuctionEnded();
  error AuctionNotEnded();
  error InsufficientBid();
  error NotHighestBid();

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                           EVENTS                           */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  event Deposit(address indexed user, uint256 amount);
  event Withdraw(address indexed user, uint256 amount);
  event Borrow(address indexed user, uint256 loanID, uint256 borrowAmount, uint256 interestAmount, uint256 expiration, address collateral, uint256 collateralID);
  event Renew(address indexed user, uint256 loanId, uint256 newBorrowAmount, uint256 newInterest, uint256 newDuration);
  event Repay(address indexed user, uint256 userLoanId, uint256 amount);
  event Liquidation(address indexed borrower, address indexed liquidator, uint256 amount, uint256 loanId);
  event BidPlaced(address indexed loanOriginator, uint256 loanId, address bidder, uint256 bidAmount);
  event AuctionClosed(address indexed loanOriginator, uint256 loanId, address winner, uint256 winningBidAmount, bool multsigWon);
  event NewProtocolInterestRate(uint256 newProtocolInterestRate);
  event NewDurations(uint256 newMinDuration, uint256 newMaxDuration);
  event NewSlope(uint256 newSlope);
  event NewMaxUtilization(uint256 newMaxUtilization);
  event NewLTV(uint256 newLTV);
  event NewBorrowingActive(bool newBorrowingActive);

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                      EXTERNAL FUNCTIONS                    */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /// @notice Deposits BERA and mints Goldilend Debt Asset
  function deposit() external payable;

  /// @notice Withdraws BERA and burns Goldilend Debt Asset
  /// @param amount Amount of goldilend debt asset to burn
  function withdraw(uint256 amount) external;

  /// @notice Borrows BERA against value of BeraBond
  /// @param borrowAmount Amount of BERA to borrow
  /// @param maxInterest Maximum amount of interest paid by user
  /// @param duration Duration of loan
  /// @param collateralNFT BeraBond to use as collateral
  /// @param collateralNFTId Token Id of BeraBond to use as collateral
  function borrow(
    uint256 borrowAmount,
    uint256 maxInterest,
    uint256 duration,
    address collateralNFT,
    uint256 collateralNFTId
  ) external payable;

  /// @notice Renews loan with new expiry
  /// @param userLoanId Loan to be renewed
  /// @param newDuration New duration of the loan
  /// @param newBorrowAmount Amount of additional BERA to be borrowed
  /// @param maxInterest Maximum amount of interest paid by user
  function renew(
    uint256 userLoanId,
    uint256 newDuration,
    uint256 newBorrowAmount,
    uint256 maxInterest
  ) external payable;

  /// @notice Repays loan with BERA
  /// @param userLoanId ID of loan to repay
  function repay(uint256 userLoanId) external payable;

  /// @notice Places a bid for a liquidatable loan auction
  /// @param loanOriginator Originator of the liquidatable loan
  /// @param loanId ID of the liquidatable loan
  function placeBid(
    address loanOriginator,
    uint256 loanId
  ) external payable;

  /// @notice Close the liquidation auction
  /// @dev This function will process even if the receiver will revert on receiving the native asset, BERA
  /// @param loanOriginator Originator of the liquidatable loan
  /// @param loanId ID of the liquidatable loan
  function closeAuction(address loanOriginator, uint256 loanId) external;

  /// @notice Claims BGT rewards from BeraBond NFT
  /// @param beraBondID ID of the BeraBond to claim yield from
  /// @param rewardContracts Addresses of BGT reward vaults to claim from
  function claimYield(uint256 beraBondID, address[] memory rewardContracts) external;

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                       VIEW FUNCTIONS                       */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /// @notice Returns info on a user loan
  function getUserLoan(address user, uint256 userLoanId) external view returns (Loan memory);

  /// @notice Returns interest on single NFT loan
  function calculateInterest(
    uint256 borrowAmount,
    uint256 duration,
    address collateralNFT,
    uint256 collateralNFTId
  ) external view returns (uint256);

  /// @notice Returns the BGT balance of the token bound account
  /// @param nft Address of the token bound account
  /// @param tokenId ID of the token bound account
  /// @return BGT balance of TBA
  function getTBABGTBalance(address nft, uint256 tokenId) external view returns (uint256);

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                    PERMISSIONED FUNCTIONS                  */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /// @notice Allows multisig to adjust the protocol lending parameters
  /// @dev Callable only by multisig
  /// @param _protocolInterestRate New interest rate
  /// @param _minDuration New minimum duration
  /// @param _maxDuration New maximum duration
  /// @param _renewMinDuration New minimum renew duration
  /// @param _renewMaxDuration New maximum renew duration
  /// @param _slope New slope
  /// @param _maxUtilization New Max Utilization
  /// @param _LTV Maximum Loan to Value ratio
  function changeLendingParams(
    uint256 _protocolInterestRate,
    uint256 _minDuration,
    uint256 _maxDuration,
    uint256 _renewMinDuration,
    uint256 _renewMaxDuration,
    uint256 _slope,
    uint256 _maxUtilization,
    uint256 _LTV
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
  /// @param _renewMinDuration Minimum renew duration
  /// @param _renewMaxDuration Maximum renew duration
  /// @param _slope Initial rate at which interest rate increases
  /// @param _maxUtilization Maximum amount of protocol debt based on pool size
  /// @param _LTV Maximum Loan to Value ratio
  function initializeParameters(
    uint256 _protocolInterestRate,
    uint256 _minDuration,
    uint256 _maxDuration,
    uint256 _renewMinDuration,
    uint256 _renewMaxDuration,
    uint256 _slope,
    uint256 _maxUtilization,
    uint256 _LTV
  ) external;

  /// @notice Allows multisig to recover tokens to distribute potential airdrops to borrowers
  /// @dev Callable only by multisig
  /// @param token Address of token to recover
  function recoverTokens(address token) external;

  /// @notice Allows multisig to withdraw surplus winning bids from liquidatable loan auctions
  /// @dev Callable only by multisig
  function withdrawSurplus() external;

  /// @notice Manages the delegation of the token bound account to a delegatee
  /// @param nft Address of BeraBond
  /// @param tokenId Token ID of BeraBond
  /// @param delegatee Address to be delegated to
  /// @param permissions Permissions to give to the delegatee
  function manageDelegation(
    address nft,
    uint256 tokenId,
    address delegatee,
    uint256 permissions
  ) external;

}