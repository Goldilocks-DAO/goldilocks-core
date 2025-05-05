//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title IGoldilend
interface IGoldilend {

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                          STRUCT                            */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  struct Loan {
    address[] collateralNFTs;
    uint256[] collateralNFTIds;
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
  error NotTimelock();
  error NotActive();
  error ArrayMismatch();
  error InvalidDuration();
  error InvalidLoanAmount();
  error InvalidCollateral();
  error BorrowLimitExceeded();
  error LoanNotFound();
  error LoanExpired();
  error Unliquidatable();
  error TooManyLoans();
  error AlreadyInitialized();

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                           EVENTS                           */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  event PorridgeLock(address indexed user, uint256 amount);
  event PorridgeUnlock(address indexed user, uint256 amount);
  event Borrow(address indexed user, uint256 loanID, uint256 borrowAmount, uint256 interestAmount, uint256 expiration, address collateral, uint256 collateralID);
  event Repay(address indexed user, uint256 amount);
  event Liquidation(address indexed borrower, address indexed liquidator, uint256 amount);
  event NewProtocolInterestRate(uint256 newProtocolInterestRate);
  event NewSlope(uint256 newSlope);
  event NewDurations(uint256 newMinDuration, uint256 newMaxDuration);
  event NewBorrowingActive(bool newBorrowingActive);

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                      EXTERNAL FUNCTIONS                    */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
  
  /// @notice Locks PRG and mints GPRG
  /// @param amount Amount of PRG to lock
  function lock(uint256 amount) external;

  /// @notice Unlocks PRG and burns GPRG
  /// @param amount Amount of PRG to unlock
  function unlock(uint256 amount) external;

  /// @notice Borrows iBGT against value of NFT
  /// @param borrowAmount Amount of iBGT to borrow
  /// @param duration Duration of loan
  /// @param collateralNFT NFT collection to use as collateral
  /// @param collateralNFTId Token Id of NFT to use as collateral
  function borrow(
    uint256 borrowAmount,
    uint256 duration,
    address collateralNFT,
    uint256 collateralNFTId
  ) external;

  /// @notice Repays loan of iBGT
  /// @param repayAmount Amount of iBGT to repay
  /// @param userLoanId ID of loan to repay
  function repay(uint256 repayAmount, uint256 userLoanId) external;

  /// @notice Liquidates overdue loans by paying iiBGT to purchase collateral
  /// @param user Owner of loan to be liquidated
  /// @param userLoanId Loan to be liquidated
  function liquidate(address user, uint256 userLoanId) external;

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                       VIEW FUNCTIONS                       */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /// @notice Returns details of all loans originated from user
  /// @param user Address of user for query
  function lookupLoans(address user) external view returns (Loan[] memory userLoans);

  /// @notice Returns details of a specific loan
  /// @param user Address of user for query
  /// @param userLoanId Id of loan
  function lookupLoan(address user, uint256 userLoanId) external view returns (Loan memory);

  /// @notice Returns current GPRG ratio
  function getGPRGRatio() external view returns (uint256);

  /// @notice Returns interest on single NFT loan
  function calculateInterest(
    uint256 borrowAmount,
    uint256 duration,
    address collateralNFT
  ) external view returns (uint256);

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

  /// @notice Allows the DAO to adjust the interest rate for the protocol
  /// @dev Callable only by Timelock
  /// @param _protocolInterestRate New interest rate
  function changeProtocolInterestRate(uint256 _protocolInterestRate) external;

  /// @notice Allows the DAO to adjust the degree of the protocol interest rate
  /// @dev Callable only by Timelock
  /// @param _slope New slope
  function changeSlope(uint256 _slope) external;

  /// @notice Allows the DAO to adjust the min and max duration of loans
  /// @dev Callable only by Timelock
  /// @param _minDuration New minimum duration
  /// @param _maxDuration New maximum duration
  function changeDurations(uint256 _minDuration, uint256 _maxDuration) external;

  /// @notice Allows multisig to activate or inactivate the protocol
  /// @dev Callable only by multisig
  /// @param _borrowingActive Value that activates or inactivates
  function changeBorrowingActive(bool _borrowingActive) external;

  /// @notice Allows multisig to initialize the protocol parameters
  /// @dev Callable only by multisig
  /// @param _minDuration Minimum loan duration
  /// @param _maxDuration Maximum loan duration
  /// @param _protocolInterestRate Initial interest rate of protocol
  /// @param _slope Initial rate at which interest rate increases
  function initializeParameters(
    uint256 _minDuration,
    uint256 _maxDuration,
    uint256 _protocolInterestRate,
    uint256 _slope
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

}