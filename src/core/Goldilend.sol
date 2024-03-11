//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


// |============================================================================================|
// |    ______      _____    __      _____    __   __       _____     _____   __  __   ______   |
// |   /_/\___\    ) ___ (  /\_\    /\ __/\  /\_\ /\_\     ) ___ (   /\ __/\ /\_\\  /\/ ____/\  |
// |   ) ) ___/   / /\_/\ \( ( (    ) )  \ \ \/_/( ( (    / /\_/\ \  ) )__\/( ( (/ / /) ) __\/  |
// |  /_/ /  ___ / /_/ (_\ \\ \_\  / / /\ \ \ /\_\\ \_\  / /_/ (_\ \/ / /    \ \_ / /  \ \ \    |
// |  \ \ \_/\__\\ \ )_/ / // / /__\ \ \/ / // / // / /__\ \ )_/ / /\ \ \_   / /  \ \  _\ \ \   |
// |   )_)  \/ _/ \ \/_\/ /( (_____() )__/ /( (_(( (_____(\ \/_\/ /  ) )__/\( (_(\ \ \)____) )  |
// |   \_\____/    )_____(  \/_____/\/___\/  \/_/ \/_____/ )_____(   \/___\/ \/_//__\/\____\/   |
// |                                                                                            |
// |============================================================================================|
// ==============================================================================================
// ======================================== Goldilend ===========================================
// ==============================================================================================


import { FixedPointMathLib } from "../../lib/solady/src/utils/FixedPointMathLib.sol";
import { SafeTransferLib } from "../../lib/solady/src/utils/SafeTransferLib.sol";
import { Goldilocked } from "./Goldilocked.sol";
import { ERC20 } from "../../lib/solady/src/tokens/ERC20.sol";
import { IERC20 } from "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "../../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import { IERC721Receiver } from "../../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import { iBGTVault } from "../mock/iBGTVault.sol";


/// @title Goldilend
/// @notice Berachain NFT Lending
/// @author ampnoob
/// @author geeb
contract Goldilend is ERC20, IERC721Receiver {


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
  /*                      STATE VARIABLES                       */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    

  address public immutable goldilocked;
  address public immutable hj;
  address public immutable ibgt;
  address public immutable vault;
  address public multisig;

  mapping(address => Boost) public boosts;
  mapping(address => Loan[]) public loans;

  mapping(address => uint256) public stakedGiBGT;
  mapping(address => uint256) public claimablePrg;
  mapping(address => uint256) public prgPerTokenDebt;
  mapping(address => uint8) public partnerNFTBoosts;
  mapping(address => uint256) public nftFairValues;

  uint256 public deployTime;
  uint256 public totalValuation;
  uint256 public protocolInterestRate;
  uint256 public outstandingDebt;
  uint256 public poolSize;
  uint256 public porridgeMultiple;
  uint256 public slope;
  uint256 public minDuration;
  uint256 public maxDuration;
  uint256 public multisigClaims;
  uint256 public honeyjarClaims;
  uint256 public multisigShare;
  uint256 public honeyjarShare;
  uint256 public ANNUAL_PORRIDGE_EMISSIONS;
  uint256 public lastUpdateTime;
  uint256 public claimablePrgPerLocksStored;

  bool public borrowingActive;


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                         CONSTRUCTOR                        */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
  

  /// @notice Constructor of this contract
  /// @param _startingPoolSize Starting size of the lending pool
  /// @param _protocolInterestRate Interest rate of the protocol
  /// @param _porridgeMultiple Emissions rate of $PRG for $iBGT in lending pool
  /// @param _slope Degree of protocol interest rate
  /// @param _goldilocked Address of Goldilocked
  /// @param _multisig Address of the GoldilocksDAO multisig
  /// @param _hj Address of Honeyjar
  /// @param _ibgt Address of $iBGT
  /// @param _vault Address of iBGTVault
  /// @param _partnerNFTs Partnership NFTs
  /// @param _partnerNFTBoosts Partnership NFTs Boosts
  constructor(
    uint256 _startingPoolSize,
    uint256 _protocolInterestRate,
    uint256 _porridgeMultiple,
    uint256 _slope,
    address _goldilocked,
    address _multisig,
    address _hj,
    address _ibgt, 
    address _vault,
    address[] memory _partnerNFTs, 
    uint8[] memory _partnerNFTBoosts
  ) {
    ANNUAL_PORRIDGE_EMISSIONS = 5e17;
    poolSize = _startingPoolSize;
    protocolInterestRate = _protocolInterestRate;
    porridgeMultiple = _porridgeMultiple;
    slope = _slope;
    goldilocked = _goldilocked;
    multisig = _multisig;
    hj = _hj;
    ibgt = _ibgt;
    vault = _vault;
    deployTime = block.timestamp;
    for(uint8 i; i < _partnerNFTs.length; i++) {
      partnerNFTBoosts[_partnerNFTs[i]] = _partnerNFTBoosts[i];
    }
  }

  /// @notice Returns the name of the $GiBGT token
  function name() public pure override returns (string memory) {
    return "GiBGT Token";
  }

  /// @notice Returns the symbol of the $GiBGT token
  function symbol() public pure override returns (string memory) {
    return "GiBGT";
  }


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                           ERRORS                           */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  error NotMultisig();
  error NotHoneyjar();
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
  error ExcessiveRepay();
  error LoanNotFound();
  error LoanExpired();
  error Unliquidatable();


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                           EVENTS                           */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  event iBGTLock(address indexed user, uint256 amount);
  event GiBGTStake(address indexed user, uint256 amount);
  event Borrow(address indexed user, uint256 amount);
  event Repay(address indexed user, uint256 amount);
  event Liquidation(address indexed borrower, address indexed liquidator, uint256 amount);


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                       VIEW FUNCTIONS                       */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @notice Returns the details of all loans originated from user
  /// @param user Originator of loan
  function lookupLoans(address user) external view returns (Loan[] memory userLoans) {
    userLoans = loans[user];
  }

  /// @notice Returns the details of a specific loan
  /// @param user Originator of loan
  /// @param userLoanId Id of loan
  function lookupLoan(address user, uint256 userLoanId) external view returns (Loan memory loan) {
    (loan, ) = _lookupLoan(user, userLoanId);
  }
  
  /// @notice Returns the details of a boost
  /// @param user Owner of boost
  function lookupBoost(address user) external view returns (Boost memory userBoost) {
    userBoost = boosts[user];
  }

  // /// @notice Returns the claimable $PRG of $GiBGT staker
  // /// @param user $GiBGT staker
  function userClaimablePrg(address user) external view returns (uint256) {
    return _calculateClaimablePrg(user);
  }

  /// @notice Returns the current $GiBGT ratio
  function getGiBGTRatio() external view returns (uint256) {
    return _GiBGTRatio();
  }

  /// @notice Returns the fair value of NFTs
  function getFairValues(address[] calldata collateralNFTs) external view returns (uint256) {
    return _calculateFairValue(collateralNFTs);
  }


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                      EXTERNAL FUNCTIONS                    */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @notice Locks partner NFT to receive boost on staking yield and discounted borrowing rates
  /// @param partnerNFT NFT address to transfer to this contract
  /// @param partnerNFTId Token ID of NFT to be transferred
  function boost(
    address partnerNFT,
    uint256 partnerNFTId
  ) external {    
    if(partnerNFTBoosts[partnerNFT] == 0) revert InvalidBoostNFT();
    boosts[msg.sender] = _buildBoost(partnerNFT, partnerNFTId);
    IERC721(partnerNFT).safeTransferFrom(msg.sender, address(this), partnerNFTId);
  }


  /// @notice Locks partner NFTs to receive boost on staking yield and discounted borrowing rates
  /// @param partnerNFTs Array of NFT addresses to transfer to this contract
  /// @param partnerNFTIds Array of token IDs for NFTs to be transferred
  function boost(
    address[] calldata partnerNFTs, 
    uint256[] calldata partnerNFTIds
  ) external {
    for(uint256 i; i < partnerNFTs.length; i++) {
      if(partnerNFTBoosts[partnerNFTs[i]] == 0) revert InvalidBoostNFT();
    }
    if(partnerNFTs.length != partnerNFTIds.length) revert ArrayMismatch();
    boosts[msg.sender] = _buildBoost(partnerNFTs, partnerNFTIds);
    for(uint8 i; i < partnerNFTs.length; i++) {
      IERC721(partnerNFTs[i]).safeTransferFrom(msg.sender, address(this), partnerNFTIds[i]);
    }
  }

  /// @notice Claims NFTs from expired boosts
  function withdrawBoost() external {
    Boost memory userBoost = boosts[msg.sender];
    if(userBoost.expiry == 0) revert InvalidBoost();
    if(userBoost.expiry > block.timestamp) revert BoostNotExpired();
    address[] memory nfts;
    uint256[] memory ids;
    Boost memory newUserBoost = Boost({
      partnerNFTs: nfts,
      partnerNFTIds: ids,
      expiry: 0,
      boostMagnitude: 0
    });
    boosts[msg.sender] = newUserBoost;
    for(uint8 i; i < userBoost.partnerNFTs.length; i++) {
      IERC721(userBoost.partnerNFTs[i]).safeTransferFrom(address(this), msg.sender, userBoost.partnerNFTIds[i]);
    }
  }
  
  /// @notice Locks $iBGT and mints $GiBGT
  /// @param amount Amount of $iBGT to lock
  function lock(uint256 amount) external {
    poolSize += amount;
    _refreshiBGT(amount);
    SafeTransferLib.safeTransferFrom(ibgt, msg.sender, address(this), amount);
    _mint(msg.sender, _GiBGTMintAmount(amount));
    emit iBGTLock(msg.sender, amount);
  }

  /// @notice Stakes $GiBGT
  /// @param amount Amount of $GiBGT to stake
  function stake(uint256 amount) external {
    _updateClaimablePrg(msg.sender);
    stakedGiBGT[msg.sender] += amount;
    SafeTransferLib.safeTransferFrom(address(this), msg.sender, address(this), amount);
    emit GiBGTStake(msg.sender, amount);
  }

  /// @notice Unstakes $GiBGT
  /// @param amount Amount of $GiBGT to unstake
  function unstake(uint256 amount) external {
    if(amount > stakedGiBGT[msg.sender]) revert InvalidUnstake();
    _updateClaimablePrg(msg.sender);
    stakedGiBGT[msg.sender] -= amount;
    SafeTransferLib.safeTransfer(address(this), msg.sender, amount);
  }

  /// @notice Claims $GiBGT staking rewards
  function claim() external {
    _updateClaimablePrg(msg.sender);
    _claim(msg.sender, claimablePrg[msg.sender]);
  }

  /// @notice Borrows $iBGT against value of NFT
  /// @param borrowAmount Amount of $iBGT to borrow
  /// @param duration Duration of loan
  /// @param collateralNFT NFT collection to use as collateral
  /// @param collateralNFTId Token Id of NFT to use as collateral
  function borrow(
    uint256 borrowAmount,
    uint256 duration,
    address collateralNFT,
    uint256 collateralNFTId
  ) external {
    if(!borrowingActive) revert NotActive();
    if(duration < minDuration || duration > maxDuration) revert InvalidDuration();
    if(borrowAmount > poolSize / 10) revert InvalidLoanAmount();
    if(nftFairValues[collateralNFT] == 0) revert InvalidCollateral();
    uint256 fairValue = nftFairValues[collateralNFT] * totalValuation / 100;
    uint256 debt = outstandingDebt;
    if(borrowAmount > fairValue || borrowAmount > poolSize - debt) revert BorrowLimitExceeded();
    uint256 interest = _calculateInterest(borrowAmount, debt, duration);
    Boost memory userBoost = boosts[msg.sender];
    if(userBoost.expiry > block.timestamp + duration) {
      uint256 discount = 50;
      if(userBoost.boostMagnitude < discount) {
        discount = 1000 - userBoost.boostMagnitude;
      }
      interest = interest * discount / 1000;
    }
    outstandingDebt += borrowAmount;
    address[] memory collateralNFTs = new address[](1);
    collateralNFTs[0] = collateralNFT;
    uint256[] memory collateralNFTIds = new uint256[](1);
    collateralNFTIds[0] = collateralNFTId;
    Loan memory loan = Loan({
      collateralNFTs: collateralNFTs,
      collateralNFTIds: collateralNFTIds,
      borrowedAmount: borrowAmount + interest,
      interest: interest,
      duration: duration,
      endDate: block.timestamp + duration,
      loanId: loans[msg.sender].length + 1,
      liquidated: false
    });
    loans[msg.sender].push(loan);
    IERC721(collateralNFT).safeTransferFrom(msg.sender, address(this), collateralNFTId);
    SafeTransferLib.safeTransfer(ibgt, msg.sender, borrowAmount);
    emit Borrow(msg.sender, borrowAmount);
  }

  /// @notice Borrows $iBGT against value of NFTs
  /// @param borrowAmount Amount of $iBGT to borrow
  /// @param duration Duration of loan
  /// @param collateralNFTs NFT collections to use as collateral
  /// @param collateralNFTIds Token IDs of NFTs to use as collateral
  function borrow(
    uint256 borrowAmount, 
    uint256 duration, 
    address[] calldata collateralNFTs, 
    uint256[] calldata collateralNFTIds
  ) external {
    if(!borrowingActive) revert NotActive();
    for(uint256 i; i < collateralNFTs.length; i++) {
      if(nftFairValues[collateralNFTs[i]] == 0) revert InvalidCollateral();
    }
    if(duration < minDuration || duration > maxDuration) revert InvalidDuration();
    if(borrowAmount > poolSize / 10) revert InvalidLoanAmount();
    if(collateralNFTs.length != collateralNFTIds.length) revert ArrayMismatch();
    uint256 fairValue = _calculateFairValue(collateralNFTs);
    uint256 debt = outstandingDebt;
    if(borrowAmount > fairValue || borrowAmount > poolSize - debt) revert BorrowLimitExceeded();
    uint256 interest = _calculateInterest(borrowAmount, debt, duration);
    Boost memory userBoost = boosts[msg.sender];
    if(userBoost.expiry > block.timestamp + duration) {
      uint256 discount = 50;
      if(userBoost.boostMagnitude < discount) {
        discount = 1000 - userBoost.boostMagnitude;
      }
      interest = interest * discount / 1000;
    }
    outstandingDebt += borrowAmount;
    Loan memory loan = Loan({
      collateralNFTs: collateralNFTs,
      collateralNFTIds: collateralNFTIds,
      borrowedAmount: borrowAmount + interest,
      interest: interest,
      duration: duration,
      endDate: block.timestamp + duration,
      loanId: loans[msg.sender].length + 1,
      liquidated: false
    });
    loans[msg.sender].push(loan);
    for(uint256 i; i < collateralNFTs.length; i++) {
      IERC721(collateralNFTs[i]).safeTransferFrom(msg.sender, address(this), collateralNFTIds[i]);
    } 
    SafeTransferLib.safeTransfer(ibgt, msg.sender, borrowAmount);
    emit Borrow(msg.sender, borrowAmount);
  }

  /// @notice Repays loan of $iBGT
  /// @param repayAmount Amount of $iBGT to repay
  /// @param userLoanId ID of loan to repay
  function repay(uint256 repayAmount, uint256 userLoanId) external {
    (Loan memory userLoan, uint256 index) = _lookupLoan(msg.sender, userLoanId);
    if(userLoan.borrowedAmount < repayAmount) revert ExcessiveRepay();
    if(block.timestamp > userLoan.endDate) revert LoanExpired();
    uint256 interestLoanRatio = FixedPointMathLib.divWad(userLoan.interest, userLoan.borrowedAmount);
    uint256 interest = FixedPointMathLib.mulWadUp(repayAmount, interestLoanRatio);
    outstandingDebt -= repayAmount - interest;
    loans[msg.sender][index].borrowedAmount -= repayAmount;
    loans[msg.sender][index].interest -= interest;
    poolSize += userLoan.interest * (1000 - (multisigShare + honeyjarShare)) / 1000;
    _updateInterestClaims(interest);
    if(userLoan.borrowedAmount - repayAmount == 0) {
      for(uint256 i; i < userLoan.collateralNFTs.length; i++){
        IERC721(userLoan.collateralNFTs[i]).safeTransferFrom(address(this), msg.sender, userLoan.collateralNFTIds[i]);
      }
    }
    SafeTransferLib.safeTransferFrom(ibgt, msg.sender, address(this), repayAmount);
    _refreshiBGT(repayAmount);
    emit Repay(msg.sender, repayAmount);
  }

  /// @notice Liquidates overdue loans by paying $iBGT to purchase collateral
  /// @param user Owner of loan to be liquidated
  /// @param userLoanId Loan to be liquidated
  function liquidate(address user, uint256 userLoanId) external {
    (Loan memory userLoan, uint256 index) = _lookupLoan(user, userLoanId);
    if(block.timestamp < userLoan.endDate || userLoan.liquidated) revert Unliquidatable();
    loans[user][index].liquidated = true;
    loans[user][index].borrowedAmount = 0;
    outstandingDebt -= userLoan.borrowedAmount - userLoan.interest;
    if(msg.sender != multisig || block.timestamp < userLoan.endDate + 5 days) {
      poolSize += userLoan.interest * (1000 - (multisigShare + honeyjarShare)) / 1000;
      _updateInterestClaims(userLoan.interest);
      SafeTransferLib.safeTransferFrom(ibgt, msg.sender, address(this), userLoan.borrowedAmount);
    }
    else {
      poolSize -= userLoan.borrowedAmount - userLoan.interest;
    }
    for(uint256 i; i < userLoan.collateralNFTs.length; i++) {
      IERC721(userLoan.collateralNFTs[i]).safeTransferFrom(address(this), msg.sender, userLoan.collateralNFTIds[i]);
    }
    emit Liquidation(msg.sender, user, userLoan.borrowedAmount);
  }


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                      INTERNAL FUNCTIONS                    */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @notice Updates claimable $PRG for user that is staking, unstaking, or claiming
  /// @param user Address to update claimable $PRG for
  function _updateClaimablePrg(address user) internal {
    claimablePrgPerLocksStored = _claimablePrgPerGiBGT();
    lastUpdateTime = block.timestamp;
    if(user != address(0)) {
      claimablePrg[user] = _calculateClaimablePrg(user);
      prgPerTokenDebt[user] = claimablePrgPerLocksStored;
    }
  }

  /// @notice Calculates and distributes $PRG
  /// @param claimer User that is claiming $PRG
  /// @param claimable Amount of $PRG to be claimed
  function _claim(address claimer, uint256 claimable) internal {
    if(claimable > 0) {
      claimablePrg[claimer] = 0;
      Goldilocked(goldilocked).goldilendMint(claimer, claimable);
    }
  }

  /// @notice Calculates claimable $PRG
  /// @param user Address to calculate claimable $PRG for
  function _calculateClaimablePrg(address user) internal view returns (uint256) {
    uint256 claimable = FixedPointMathLib.mulWad(stakedGiBGT[user], _claimablePrgPerGiBGT() - prgPerTokenDebt[user]) + claimablePrg[user];
    Boost memory userBoost = boosts[user];
    if(userBoost.expiry > block.timestamp) {
      uint256 prgBoost = userBoost.boostMagnitude < 50 ? userBoost.boostMagnitude : 50;
      return claimable * (1000 + prgBoost) / 1000;
    }
    return claimable;
  }

  /// @notice Calculates claimable $PRG per $GiBGT
  function _claimablePrgPerGiBGT() internal view returns (uint256) {
    if(block.timestamp - lastUpdateTime == 0) {
      return claimablePrgPerLocksStored;
    }
    return claimablePrgPerLocksStored + FixedPointMathLib.mulWad(FixedPointMathLib.divWad(block.timestamp - lastUpdateTime, 365 days), ANNUAL_PORRIDGE_EMISSIONS);
  }

  /// @notice Calculates the fair value of NFTs being borrowed against
  /// @param collateralNFTs NFT collections to find value of
  /// @return fairValue Fair value of NFTs
  function _calculateFairValue(address[] calldata collateralNFTs) internal view returns (uint256 fairValue) {
    for(uint256 i; i < collateralNFTs.length; i++) {
      fairValue += totalValuation * nftFairValues[collateralNFTs[i]] / 100;
    }
  }

  /// @notice Caluclates the total interest due at repayment
  /// @param borrowAmount Amount to be borrowed
  /// @param debt Current amount of outstanding debt
  /// @return interest Total interest due at repayment
  function _calculateInterest(
    uint256 borrowAmount, 
    uint256 debt,
    uint256 duration
  ) internal view returns (uint256 interest) {
    uint256 rate = protocolInterestRate;
    uint256 ratio = FixedPointMathLib.divWad(debt + borrowAmount, poolSize) + 5e17;
    uint256 interestRate = rate + FixedPointMathLib.mulWad(slope * rate, FixedPointMathLib.mulWad(ratio, FixedPointMathLib.divWad(duration, 365 days)));
    uint256 interestAdjusted = FixedPointMathLib.mulWad(FixedPointMathLib.mulWad(interestRate, borrowAmount), FixedPointMathLib.divWad(duration, 365 days));
    interest = interestAdjusted / 100;
  }

  /// @notice Finds the loan by userId
  /// @param userLoanId Id of loan to be found
  function _lookupLoan(
    address user, 
    uint256 userLoanId
  ) internal view returns (Loan memory userLoan, uint256 index) {
    uint256 loanLength = loans[user].length;
    for(uint256 i; i < loanLength; i++) {
      if(loans[user][i].loanId == userLoanId) return (loans[user][i], i);
    }
    revert LoanNotFound();
  }

  /// @notice Stakes $iBGT in Infrared vault
  /// @dev Claims existing vault rewards and updates poolSize
  /// @param ibgtAmount Amount of $iBGT to stake
  function _refreshiBGT(uint256 ibgtAmount) internal {
    IERC20(ibgt).approve(vault, ibgtAmount);
    iBGTVault(vault).stake(ibgtAmount);
  }

  /// @notice Calculates the amount of $GiBGT to mint
  /// @param lockAmount Amount of $iBGT to lock
  /// @return mintAmount Total supply of $GiBGT divided by the lending pool size multiplied by lockAmount
  function _GiBGTMintAmount(uint256 lockAmount) internal view returns (uint256) {
    return poolSize > 0 ? FixedPointMathLib.mulWad(lockAmount, _GiBGTRatio()) : lockAmount;
  }

  /// @notice Calculates the current $GiBGT ratio
  /// @return gibgtRatio Total supply of $GiBGT divided by the lending pool size
  function _GiBGTRatio() internal view returns (uint256) {
    return FixedPointMathLib.divWad(totalSupply(), poolSize);
  }

  /// @notice Creates the struct containing the details of the boost
  /// @param partnerNFT NFT address to transfer to this contract
  /// @param partnerNFTId Token ID of NFT to be transferred
  function _buildBoost(
    address partnerNFT, 
    uint256 partnerNFTId
  ) internal returns (Boost memory newUserBoost) {
    uint256 magnitude;
    Boost storage userBoost = boosts[msg.sender];
    if(userBoost.expiry == 0) {
      magnitude = partnerNFTBoosts[partnerNFT];
      address[] memory nft = new address[](1);
      nft[0] = partnerNFT;
      uint256[] memory id = new uint256[](1);
      id[0] = partnerNFTId;
      newUserBoost = Boost({
        partnerNFTs: nft,
        partnerNFTIds: id,
        expiry: block.timestamp + 30 days,
        boostMagnitude: magnitude
      });
    }
    else {
      address[] storage nfts = userBoost.partnerNFTs;
      uint256[] storage ids = userBoost.partnerNFTIds;
      magnitude = userBoost.boostMagnitude;
      magnitude += partnerNFTBoosts[partnerNFT];
      nfts.push(partnerNFT);
      ids.push(partnerNFTId);
      newUserBoost = Boost({
        partnerNFTs: nfts,
        partnerNFTIds: ids,
        expiry: block.timestamp + 30 days,
        boostMagnitude: magnitude
      });
    }
  }

  /// @notice Creates the struct containing the details of the boost
  /// @param partnerNFTs Array of NFT addresses to transfer to this contract
  /// @param partnerNFTIds Array of token IDs for NFTs to be transferred
  function _buildBoost(
    address[] calldata partnerNFTs, 
    uint256[] calldata partnerNFTIds
  ) internal returns (Boost memory newUserBoost) {
    uint256 magnitude;
    Boost storage userBoost = boosts[msg.sender];
    if(userBoost.expiry == 0) {
      for(uint8 i; i < partnerNFTs.length; i++) {
        magnitude += partnerNFTBoosts[partnerNFTs[i]];
      }
      newUserBoost = Boost({
        partnerNFTs: partnerNFTs,
        partnerNFTIds: partnerNFTIds,
        expiry: block.timestamp + 30 days,
        boostMagnitude: magnitude
      });
    }
    else {
      address[] storage nfts = userBoost.partnerNFTs;
      uint256[] storage ids = userBoost.partnerNFTIds;
      magnitude = userBoost.boostMagnitude;
      for (uint256 i = 0; i < partnerNFTs.length; i++) {
        magnitude += partnerNFTBoosts[partnerNFTs[i]];
        nfts.push(partnerNFTs[i]);
        ids.push(partnerNFTIds[i]);
      }
      newUserBoost = Boost({
        partnerNFTs: nfts,
        partnerNFTIds: ids,
        expiry: block.timestamp + 30 days,
        boostMagnitude: magnitude
      });
    }
  }

  /// @notice Update internal variables tracking amount of interest for multisig and honeyjar
  /// @dev Multisig can claim 4.5% and honeyjar can claim 0.5% of interest paid
  /// @param interest Interest paid during repayment
  function _updateInterestClaims(uint256 interest) internal {
    multisigClaims += interest * multisigShare / 1000;
    honeyjarClaims += interest * honeyjarShare / 1000;
  }


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                    PERMISSIONED FUNCTIONS                  */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @notice Changes the address of the multisig address
  /// @dev Used after deployment by deployment address
  /// @param _multisig Address of the multisig
  function setMultisig(address _multisig) external {
    if(msg.sender != multisig) revert NotMultisig();
    multisig = _multisig;
  }

  /// @notice Allows the DAO to adjust the valuation of the NFTs to borrow against
  /// @param _totalValuation Total valuation of all NFTs able to be borrowed against
  /// @param _nfts NFTs that are able to be borrowed against
  /// @param _nftFairValues Percentage each NFT is valued as a porportion of the total valuation
    function setValue(
    uint256 _totalValuation,
    address[] calldata _nfts,
    uint256[] calldata _nftFairValues
  ) external {
    if(msg.sender != multisig) revert NotMultisig();
    totalValuation = _totalValuation;
    for(uint256 i; i < _nftFairValues.length; i++) {
      nftFairValues[_nfts[i]] = _nftFairValues[i];
    }
  } 

  /// @notice Allows the DAO to adjust the interest rate for the protocol
  /// @param _protocolInterestRate New interest rate
  function setProtocolInterestRate(uint256 _protocolInterestRate) external {
    if(msg.sender != multisig) revert NotMultisig();
    protocolInterestRate = _protocolInterestRate;
  }

  /// @notice Allows the DAO to adjust shares of interest payment
  /// @param _multisigShare New share for multisig
  /// @param _honeyjarShare New share for honeyjar
  function setShareRates(uint256 _multisigShare, uint256 _honeyjarShare) external {
    if(msg.sender != multisig) revert NotMultisig();
    multisigShare = _multisigShare;
    honeyjarShare = _honeyjarShare;
  }

  /// @notice Allows the DAO to withdraw $iBGT in case of emergency
  function emergencyWithdraw() external {
    if(msg.sender != multisig) revert NotMultisig();
    SafeTransferLib.safeTransfer(ibgt, multisig, poolSize - outstandingDebt);
  }

  /// @notice Allows the multisig to claim interest
  /// @dev 4.5% of all protocol interest
  function multisigInterestClaim() external {
    if(msg.sender != multisig) revert NotMultisig();
    uint256 interestClaim = multisigClaims;
    multisigClaims = 0;
    SafeTransferLib.safeTransfer(ibgt, multisig, interestClaim);
  }

  /// @notice Allows the honeyjar to claim interest
  /// @dev 0.5% of all protocol interest
  function honeyjarInterestClaim() external {
    if(msg.sender != hj) revert NotHoneyjar();
    uint256 interestClaim = honeyjarClaims;
    honeyjarClaims = 0;
    SafeTransferLib.safeTransfer(ibgt, hj, interestClaim);
  }

  /// @notice Allows the DAO to change the degree of the protocol interest rate
  /// @param _slope New slope
  function setSlope(uint256 _slope) external {
    if(msg.sender != multisig) revert NotMultisig();
    slope = _slope;
  }

  /// @notice Allows the DAO to adjust the min and max duration of loans
  /// @param _minDuration New minimum duration
  /// @param _maxDuration New maximum duration
  function setDurations(uint256 _minDuration, uint256 _maxDuration) external {
    if(msg.sender != multisig) revert NotMultisig();
    minDuration = _minDuration;
    maxDuration = _maxDuration;
  }

  /// @notice Allows the DAO to activate or inactivate the protocol
  /// @param _borrowingActive Value that activates or inactivates
  function setBorrowingActive(bool _borrowingActive) external {
    if(msg.sender != multisig) revert NotMultisig();
    borrowingActive = _borrowingActive;
  }

  /// @notice Allows the DAO to change $PRG emissions
  /// @param newPrgEmissions Sets the annual $PRG emission rate for $GiBGT staking
  function changePrgEmissions(uint256 newPrgEmissions) external {
    if(msg.sender != multisig) revert NotMultisig();
    _updateClaimablePrg(address(0));
    ANNUAL_PORRIDGE_EMISSIONS = newPrgEmissions;
  }


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                   IMPLEMENTATION FUNCTION                  */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) external virtual returns (bytes4) {
    return IERC721Receiver.onERC721Received.selector;
  }

}