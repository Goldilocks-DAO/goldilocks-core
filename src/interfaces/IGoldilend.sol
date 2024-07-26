//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title IGoldilend
interface IGoldilend {

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                          STRUCTS                           */
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

  struct Boost {
    address[] partnerNFTs;
    uint256[] partnerNFTIds;
    uint256 boostMagnitude;
    uint256 expiry;
  }

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                           ERRORS                           */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  error NotMultisig();
  error NotTimelock();
  error NotAPDAO();
  error NotActive();
  error ArrayMismatch();
  error InvalidBoost();
  error InvalidBoostNFT();
  error BoostNotExpired();
  error InvalidUnstake();
  error InvalidDuration();
  error InvalidLoanAmount();
  error InvalidCollateral();
  error BorrowLimitExceeded();
  error LoanNotFound();
  error LoanExpired();
  error Unliquidatable();
  error TooManyTokens();
  error AlreadyInitialized();

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                           EVENTS                           */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  event iBGTLock(address indexed user, uint256 amount);
  event GiBGTStake(address indexed user, uint256 amount);
  event GiBGTUnstake(address indexed user, uint256 amount);
  event Claim(address indexed user, uint256 amount);
  event Borrow(address indexed user, uint256 amount);
  event Repay(address indexed user, uint256 amount);
  event Liquidation(address indexed borrower, address indexed liquidator, uint256 amount);
  event NewTotalValuation(uint256 newTotalValuation);
  event NewProtocolInterestRate(uint256 newProtocolInterestRate);
  event NewShareRates(uint256 newMultisigShare, uint256 newApdaoShare);
  event NewSlope(uint256 newSlope);
  event NewDurations(uint256 newMinDuration, uint256 newMaxDuration);
  event NewPrgEmissions(uint256 newPrgEmissions);
  event NewRewardTokens(address[] newRewardTokens);
  event NewBorrowingActive(bool newBorrowingActive);
  event MultisigInterestClaim(uint256 interestClaim);
  event ApdaoInterestClaim(uint256 interestClaim);
  event NewBoosts(address[] newPartnerNFTs, uint8[] newPartnerNFTsBoosts, uint256 newBoostLockDuration);
  event SunsetProtocol(uint256 sunsetAmount);
  event DonateiBGT(uint256 donatedAmount);

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                      EXTERNAL FUNCTIONS                    */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /// @notice Locks partner NFT to receive boost on staking yield and discounted borrowing rates
  /// @param partnerNFT NFT address to transfer to this contract
  /// @param partnerNFTId Token ID of NFT to be transferred
  function boost(
    address partnerNFT,
    uint256 partnerNFTId
  ) external;

  /// @notice Locks partner NFTs to receive boost on staking yield and discounted borrowing rates
  /// @param partnerNFTs Array of NFT addresses to transfer to this contract
  /// @param partnerNFTIds Array of token IDs for NFTs to be transferred
  function boost(
    address[] calldata partnerNFTs, 
    uint256[] calldata partnerNFTIds
  ) external;

  /// @notice Claims NFTs from expired boosts
  function withdrawBoost() external;
  
  /// @notice Locks iBGT and mints GiBGT
  /// @param amount Amount of iBGT to lock
  function lock(uint256 amount) external;

  /// @notice Stakes GiBGT
  /// @param amount Amount of GiBGT to stake
  function stake(uint256 amount) external;

  /// @notice Unstakes GiBGT
  /// @param amount Amount of GiBGT to unstake
  function unstake(uint256 amount) external;

  /// @notice Claims GiBGT and iBGT staking rewards
  function claim() external;

  /// @notice Updates claimable rewards from iBGT staking
  function updateClaimableRewards() external;

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
  
  /// @notice Returns details of a boost
  /// @param user Address of user for query
  function lookupBoost(address user) external view returns (Boost memory);

  /// @notice Returns claimable Porridge of GiBGT staker
  /// @param user Address of user for query
  function userClaimablePrg(address user) external view returns (uint256);

  /// @notice Returns current GiBGT ratio
  function getGiBGTRatio() external view returns (uint256);

  /// @notice Returns interest on single NFT loan
  function calculateInterest(
    uint256 borrowAmount,
    uint256 duration,
    address collateralNFT
  ) external view returns (uint256);

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                    PERMISSIONED FUNCTIONS                  */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /// @notice Allows the DAO to adjust the valuation of the NFTs to borrow against
  /// @dev Callable only by Timelock
  /// @param _totalValuation Total valuation of all NFTs able to be borrowed against
  /// @param _nfts NFTs that are able to be borrowed against
  /// @param _nftFairValues Percentage each NFT is valued as a porportion of the total valuation
    function changeValue(
    address[] calldata _nfts,
    uint256[] calldata _nftFairValues,
    uint256 _totalValuation
  ) external;

  /// @notice Allows the DAO to adjust the interest rate for the protocol
  /// @dev Callable only by Timelock
  /// @param _protocolInterestRate New interest rate
  function changeProtocolInterestRate(uint256 _protocolInterestRate) external;

  /// @notice Allows the DAO to adjust shares of interest payment
  /// @dev Callable only by Timelock
  /// @param _multisigShare New share for multisig
  /// @param _apdaoShare New share for apdao
  function changeShareRates(uint256 _multisigShare, uint256 _apdaoShare) external;

  /// @notice Allows the DAO to adjust the degree of the protocol interest rate
  /// @dev Callable only by Timelock
  /// @param _slope New slope
  function changeSlope(uint256 _slope) external;

  /// @notice Allows the DAO to adjust the min and max duration of loans
  /// @dev Callable only by Timelock
  /// @param _minDuration New minimum duration
  /// @param _maxDuration New maximum duration
  function changeDurations(uint256 _minDuration, uint256 _maxDuration) external;

  /// @notice Allows the DAO to change $PRG emissions
  /// @dev Callable only by Timelock
  /// @param newPrgEmissions Sets the annual $PRG emission rate for $GiBGT staking
  function changePrgEmissions(uint256 newPrgEmissions) external;

  /// @notice Allows multisig to add yield tokens to Goldilend
  /// @dev Callable only by multisig
  /// @param _rewardTokens Tokens to add to yieldTokens array
  function addRewardTokens(address[] calldata _rewardTokens) external;

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
  /// @param _annualPrgEmissions Annual emissions rate of Porridge
  /// @param _boostLockDuration Duration to lock partner NFT for boost
  function initializeParameters(
    uint256 _multisigShare,
    uint256 _apdaoShare,
    uint256 _minDuration,
    uint256 _maxDuration,
    uint256 _protocolInterestRate,
    uint256 _slope,
    uint256 _annualPrgEmissions,
    uint256 _boostLockDuration
  ) external;

  /// @notice Allows multisig to initalize bera nft fair values
  /// @dev Callable only by multisig
  /// @param _nfts Bera nft addresses
  /// @param _nftFairValues Bera nft fair values
  /// @param _totalValuation Total valuation of Bera nft fair values
  function initializeBeras(
    uint256 _totalValuation,
    address[] calldata _nfts,
    uint256[] calldata _nftFairValues
  ) external;

  /// @notice Allows multisig to initialize partner nft boosts
  /// @dev Callable only by multisig
  /// @param _partnerNFTs Partnership NFTs
  /// @param _partnerNFTBoosts Partnership NFTs Boosts
  function initializePartners(
    address[] memory _partnerNFTs, 
    uint8[] memory _partnerNFTBoosts
  ) external;

  /// @notice Allows the DAO to adjust the partner boosts
  /// @dev Callable only by Timelock
  /// @param _partnerNFTs Partnership NFTs
  /// @param _partnerNFTBoosts Partnership NFTs Boosts
  /// @param _boostLockDuration Duration to lock partner NFT for boost
  function adjustBoosts(
    address[] memory _partnerNFTs, 
    uint8[] memory _partnerNFTBoosts,
    uint256 _boostLockDuration
  ) external;

  /// @notice Allows the DAO to sunset protocol
  /// @dev Callable only by Timelock
  function sunsetProtocol() external;

  /// @notice Allows multisig to send iBGT to compensate lenders for unliquidated loans
  /// @dev Callable only by multisig
  /// @param amount Amount of iBGT to donate
  function donateiBGT(uint256 amount) external;

}