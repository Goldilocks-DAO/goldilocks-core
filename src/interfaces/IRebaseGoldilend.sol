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
  error NotTimelock();
  error ArrayMismatch();
  error InvalidDuration();
  error InvalidLoanAmount();
  error InvalidCollateral();
  error BorrowLimitExceeded();
  error MaxUtilizationExceeded();
  error MinUtilizationExceeded();
  error LoanExpired();
  error Unliquidatable();
  error AlreadyInitialized();
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
  /// @param maxInterest Maximum amount of interest paid by user
  /// @param duration Duration of loan
  /// @param collateralNFT Rebase Bera to use as collateral
  /// @param collateralNFTId Token Id of Rebase Bera to use as collateral
  function borrow(
    uint256 borrowAmount,
    uint256 maxInterest,
    uint256 duration,
    address collateralNFT,
    uint256 collateralNFTId
  ) external;

  /// @notice Renews loan with new expiry
  /// @param userLoanId Loan to be renewed
  /// @param newDuration New duration of the loan
  /// @param newBorrowAmount Amount of additional debt asset to be borrowed
  /// @param maxInterest Maximum amount of interest paid by user
  function renew(
    uint256 userLoanId,
    uint256 newDuration,
    uint256 newBorrowAmount,
    uint256 maxInterest
  ) external;

  /// @notice Repays loan of debt asset
  /// @param repayAmount Amount of debt asset to repay
  /// @param userLoanId ID of loan to repay
  function repay(uint256 repayAmount, uint256 userLoanId) external;

  /// @notice Places a bid for a liquidatable loan auction
  /// @param loanOriginator Originator of the liquidatable loan
  /// @param loanId ID of the liquidatable loan
  /// @param bidAmount Amount of debt asset to bid
  function placeBid(
    address loanOriginator,
    uint256 loanId,
    uint256 bidAmount
  ) external;

  /// @notice Close the liquidation auction
  /// @param loanOriginator Originator of the liquidatable loan
  /// @param loanId ID of the liquidatable loan
  function closeAuction(address loanOriginator, uint256 loanId) external;

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

  /// @notice Returns the fair value of a bera NFT based on unvested BERA tokens
  function calculateFairValue(address rebaseBera) external view returns (uint256);

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                    PERMISSIONED FUNCTIONS                  */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /// @notice Allows multisig to adjust the protocol lending parameters
  /// @dev Callable only by multisig
  /// @param _protocolInterestRate New interest rate
  /// @param _slope New slope
  /// @param _pythPriceFeed New pyth price feed address
  /// @param _beraPythPriceFeedId New bera pyth price feed id
  /// @param _interestPaymentPercentage New interest payment percentage
  /// @param _utilizationRatioMultiplier New utilization ratio multiplier
  /// @param _minUtilization Minimum utilization of protocol liquidity
  /// @param _liquidityThreshold Threshold of protocol liquidity to enfore minimum utilization
  function changeLendingParams(
    uint256 _protocolInterestRate,
    uint256 _slope,
    address _pythPriceFeed,
    bytes32 _beraPythPriceFeedId,
    uint256 _interestPaymentPercentage,
    uint256 _utilizationRatioMultiplier,
    uint256 _minUtilization,
    uint256 _liquidityThreshold
  ) external;

  /// @notice Allows timelock to adjust the protocol governance lending parameters
  /// @dev Callable only by timelock
  /// @param _minDuration New minimum duration
  /// @param _maxDuration New maximum duration
  /// @param _renewMinDuration New minimum renew duration
  /// @param _renewMaxDuration New maximum renew duration
  /// @param _maxUtilization New Max Utilization
  function changeGovParams(
    uint256 _minDuration,
    uint256 _maxDuration,
    uint256 _renewMinDuration,
    uint256 _renewMaxDuration,
    uint256 _maxUtilization
  ) external;

  /// @notice Allows multisig to initialize the protocol parameters
  /// @dev Callable only by multisig
  /// @param _minDuration Minimum loan duration
  /// @param _maxDuration Maximum loan duration
  /// @param _renewMinDuration Minimum renew duration
  /// @param _renewMaxDuration Maximum renew duration
  /// @param _maxUtilization Maximum amount of protocol debt based on pool size
  function initializeGovParams(
    uint256 _minDuration,
    uint256 _maxDuration,
    uint256 _renewMinDuration,
    uint256 _renewMaxDuration,
    uint256 _maxUtilization
  ) external;

  /// @notice Allows multisig to activate or inactivate the protocol
  /// @dev Callable only by multisig
  /// @param _borrowingActive Value that activates or inactivates
  function changeBorrowingActive(bool _borrowingActive) external;

  /// @notice Allows multisig to recover tokens to distribute potential airdrops to borrowers
  /// @dev Callable only by multisig
  /// @param token Address of token to recover
  function recoverTokens(address token) external;

  /// @notice Allows multisig to adjust the unvested bera valuation weights
  /// @dev Callable only by multisig
  /// @param _beras Rebase bera collection addresses that are able to be borrowed against
  /// @param _weights Percentage each bera is weighted as a porportion of the total unvested bera
  /// @param _streams Rebase bera streaming contract addresses
  function changeUnvestedWeights(
    address[] calldata _beras,
    uint256[] calldata _weights,
    address[] calldata _streams
  ) external;

  /// @notice Allows multisig to initalize unvested bera valuation weights
  /// @dev Callable only by multisig
  /// @param _beras Rebase bera addresses
  /// @param _weights Rebase bera unvested bera weights
  /// @param _streams Rebase bera streaming contract addresses
  function initializeBeras(
    address[] calldata _beras,
    uint256[] calldata _weights,
    address[] calldata _streams
  ) external;

  /// @notice Allows multisig to withdraw surplus winning bids from liquidatable loan auctions
  /// @dev Callable only by multisig
  function withdrawSurplus() external;

}