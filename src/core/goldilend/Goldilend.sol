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


import { FixedPointMathLib } from "../../../lib/solady/src/utils/FixedPointMathLib.sol";
import { SafeTransferLib } from "../../../lib/solady/src/utils/SafeTransferLib.sol";
import { ERC20 } from "../../../lib/solady/src/tokens/ERC20.sol";
import { IERC721 } from "../../../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import { IERC721Receiver } from "../../../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import { IGoldilend } from "../../interfaces/IGoldilend.sol";
import { IGoldilocked } from "../../interfaces/IGoldilocked.sol";
import { iBGTVault } from "../../mock/iBGTVault.sol";


/// @title Goldilend
/// @notice Berachain NFT Lending
contract Goldilend is IGoldilend, ERC20, IERC721Receiver {


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                      STATE VARIABLES                       */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    

  /// @notice Address of Goldilocked
  address public immutable goldilocked;

  /// @notice Address of honeyjar
  address public immutable hj;

  /// @notice Address of iBGT
  address public immutable ibgt;

  /// @notice Address of iBGT vault
  address public immutable ibgtVault;

  /// @notice Address of multisig
  address public immutable multisig;

  /// @notice Address of Timelock
  address public immutable timelock;

  /// @notice Timestamp of contract deployment
  uint256 public deployTime;

  /// @notice Total valuation of NFTs available for loan origination
  uint256 public totalValuation;

  /// @notice Interest rate of protocol
  uint256 public protocolInterestRate;

  /// @notice Outstanding debt of all unpaid loans
  uint256 public outstandingDebt;

  /// @notice Size of lending pool
  uint256 public poolSize;
  
  /// @notice Amount of porridge emitted per staked GiBGT annually
  uint256 public porridgeMultiple;

  /// @notice Rate at which interest rate increases
  uint256 public slope;

  /// @notice Minimum loan duration
  uint256 public minDuration;

  /// @notice Maximum loan duration
  uint256 public maxDuration;

  /// @notice Portion of interest payments to multisig
  uint256 public multisigClaims;

  /// @notice Portion of interest payments to honeyjar
  uint256 public honeyjarClaims;

  /// @notice Share of interest payments to multisig
  uint256 public multisigShare;

  /// @notice Share of interest payments ot honeyjar
  uint256 public honeyjarShare;

  /// @notice Annual emission rate of Porridge
  uint256 public ANNUAL_PORRIDGE_EMISSIONS;
  
  /// @notice Total staked GiBGT
  uint256 public totalStakedGiBGT;

  /// @notice Addresses of reward tokens from iBGT staking
  address[] public rewardTokens;

  /// @notice Boolean value if borrowing is active
  bool public borrowingActive;

  /// @notice Maps user to boost
  mapping(address => Boost) public boosts;

  /// @notice Maps user to loans
  mapping(address => Loan[]) public loans;

  /// @notice Maps user to amount staked GiBGT
  mapping(address => uint256) public stakedGiBGT;

  /// @notice Claimble Porridge per GiBGT staked
  uint256 public claimablePrgPerGiBGTStored;

  /// @notice Timestamp of last update of claimable Porridge reward
  uint256 public lastPrgUpdateTime;

  /// @notice Maps user to amount of claimable Porridge
  mapping(address => uint256) public claimablePrg;

  /// @notice Maps user to amount of Porridge reward debt
  mapping(address => uint256) public prgPerTokenDebt;

  /// @notice Maps reward token to claimable reward token per GiBGT staked
  mapping(address => uint256) public claimableRewardsPerGiBGTStored;
  
  /// @notice Maps reward token to last update of claimable reward
  mapping(address => uint256) public lastRewardUpdateTime;

  /// @notice Maps reward token to amount of outstanding rewards
  mapping(address => uint256) public outstandingRewardsPerReward;

  /// @notice Maps user to reward token to amount of claimable rewards
  mapping(address => mapping(address => uint256)) public claimableRewards;

  /// @notice Maps user to reward token to amount of reward debt
  mapping(address => mapping(address => uint256)) public rewardPerTokenDebt;

  /// @notice Maps partner NFT to boost magnitude
  mapping(address => uint8) public partnerNFTBoosts;

  /// @notice Maps NFT to fair value
  mapping(address => uint256) public nftFairValues;


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                         CONSTRUCTOR                        */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
  

  /// @notice Constructor of this contract
  /// @param _goldilocked Address of Goldilocked
  /// @param _multisig Address of the multisig
  /// @param _timelock Address of the multisig
  /// @param _hj Address of Honeyjar
  /// @param _ibgt Address of iBGT
  /// @param _ibgtVault Address of iBGTVault
  /// @param _partnerNFTs Partnership NFTs
  /// @param _partnerNFTBoosts Partnership NFTs Boosts
  /// @param _rewardTokens Reward tokens from iBGT staking
  constructor(
    address _goldilocked,
    address _timelock,
    address _multisig,
    address _hj,
    address _ibgt, 
    address _ibgtVault,
    address[] memory _partnerNFTs, 
    uint8[] memory _partnerNFTBoosts,
    address[] memory _rewardTokens
  ) {
    goldilocked = _goldilocked;
    multisig = _multisig;
    timelock = _timelock;
    hj = _hj;
    ibgt = _ibgt;
    ibgtVault = _ibgtVault;
    deployTime = block.timestamp;
    for(uint8 i; i < _partnerNFTs.length; i++) {
      partnerNFTBoosts[_partnerNFTs[i]] = _partnerNFTBoosts[i];
    }
    for(uint8 i; i < _rewardTokens.length; ++i) {
      rewardTokens.push(_rewardTokens[i]);
      lastRewardUpdateTime[rewardTokens[i]] = block.timestamp;
    }
    ANNUAL_PORRIDGE_EMISSIONS = 5e17;
  }

  /// @notice Returns the name of GiBGT token
  function name() public pure override returns (string memory) {
    return "GiBGT";
  }

  /// @notice Returns the symbol of GiBGT token
  function symbol() public pure override returns (string memory) {
    return "GiBGT";
  }


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                       VIEW FUNCTIONS                       */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @inheritdoc IGoldilend
  function lookupLoans(address user) external view returns (Loan[] memory userLoans) {
    userLoans = loans[user];
  }

  /// @inheritdoc IGoldilend
  function lookupLoan(address user, uint256 userLoanId) external view returns (Loan memory loan) {
    (loan, ) = _lookupLoan(user, userLoanId);
  }

  /// @inheritdoc IGoldilend
  function lookupBoost(address user) external view returns (Boost memory userBoost) {
    userBoost = boosts[user];
  }

  /// @inheritdoc IGoldilend
  function userClaimablePrg(address user) external view returns (uint256) {
    return _calculateClaimablePrg(user);
  }

  /// @inheritdoc IGoldilend
  function getGiBGTRatio() external view returns (uint256) {
    uint256 supply = totalSupply();
    uint256 _poolSize = poolSize;
    return _GiBGTRatio(supply, _poolSize);
  }

  /// @inheritdoc IGoldilend
  function getFairValues(address[] calldata collateralNFTs) external view returns (uint256) {
    return _calculateFairValue(collateralNFTs);
  }


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                      EXTERNAL FUNCTIONS                    */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @inheritdoc IGoldilend
  function boost(
    address partnerNFT,
    uint256 partnerNFTId
  ) external {    
    if(partnerNFTBoosts[partnerNFT] == 0) revert InvalidBoostNFT();
    boosts[msg.sender] = _buildBoost(partnerNFT, partnerNFTId);
    IERC721(partnerNFT).safeTransferFrom(msg.sender, address(this), partnerNFTId);
  }

  /// @inheritdoc IGoldilend
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

  /// @inheritdoc IGoldilend
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

  /// @inheritdoc IGoldilend
  function lock(uint256 amount) external {
    uint256 mintAmount = _GiBGTMintAmount(amount);
    poolSize += amount;
    _refreshiBGT(amount);
    SafeTransferLib.safeTransferFrom(ibgt, msg.sender, address(this), amount);
    _mint(msg.sender, mintAmount);
    emit iBGTLock(msg.sender, amount);
  }

  /// @inheritdoc IGoldilend
  function stake(uint256 amount) external {
    _updateClaimablePrg(msg.sender);
    _updateClaimableRewards(msg.sender);
    stakedGiBGT[msg.sender] += amount;
    totalStakedGiBGT += amount;
    SafeTransferLib.safeTransferFrom(address(this), msg.sender, address(this), amount);
    emit GiBGTStake(msg.sender, amount);
  }

  /// @inheritdoc IGoldilend
  function unstake(uint256 amount) external {
    if(amount > stakedGiBGT[msg.sender]) revert InvalidUnstake();
    _updateClaimablePrg(msg.sender);
    _updateClaimableRewards(msg.sender);
    stakedGiBGT[msg.sender] -= amount;
    totalStakedGiBGT -= amount;
    SafeTransferLib.safeTransfer(address(this), msg.sender, amount);
    emit GiBGTUnstake(msg.sender, amount);
  }

  /// @inheritdoc IGoldilend
  function claim() external {
    _updateClaimablePrg(msg.sender);
    _updateClaimableRewards(msg.sender);
    _claimPrg(msg.sender, claimablePrg[msg.sender]);
    _claimRewards(msg.sender);
  }

  /// @inheritdoc IGoldilend
  function updateClaimableRewards() external {
    _updateClaimableRewards(address(0));
  }

  /// @inheritdoc IGoldilend
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

  /// @inheritdoc IGoldilend
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

  /// @inheritdoc IGoldilend
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

  /// @inheritdoc IGoldilend
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
  /*                   INTERNAL VIEW FUNCTIONS                  */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @notice Calculates claimable Porridge
  /// @param user Address to calculate claimable Porridge for
  function _calculateClaimablePrg(address user) internal view returns (uint256) {
    uint256 claimable = FixedPointMathLib.mulWad(stakedGiBGT[user], _claimablePrgPerGiBGT() - prgPerTokenDebt[user]) + claimablePrg[user];
    Boost memory userBoost = boosts[user];
    if(userBoost.expiry > block.timestamp) {
      uint256 prgBoost = userBoost.boostMagnitude < 50 ? userBoost.boostMagnitude : 50;
      return claimable * (1000 + prgBoost) / 1000;
    }
    return claimable;
  }

  /// @notice Calculates claimable rewards
  /// @param user Address to calculate claimable rewards for
  function _calculateClaimableRewards(address user, address rewardToken, uint256 outstandingRewards) internal view returns (uint256) {
    return FixedPointMathLib.mulWad(stakedGiBGT[user], _claimableRewardPerGiBGT(rewardToken, outstandingRewards) - rewardPerTokenDebt[user][rewardToken]) + claimableRewards[user][rewardToken];
  }

  /// @notice Calculates claimable Porridge per GiBGT
  function _claimablePrgPerGiBGT() internal view returns (uint256) {
    if(block.timestamp - lastPrgUpdateTime == 0) {
      return claimablePrgPerGiBGTStored;
    }
    return claimablePrgPerGiBGTStored + FixedPointMathLib.mulWad(FixedPointMathLib.divWad(block.timestamp - lastPrgUpdateTime, 365 days), ANNUAL_PORRIDGE_EMISSIONS);
  }

  /// @notice Calculates claimable Porridge per GiBGT
  /// @param rewardToken Token to calculate claimable reward
  function _claimableRewardPerGiBGT(address rewardToken, uint256 outstandingRewards) internal view returns (uint256) {
    if(block.timestamp - lastRewardUpdateTime[rewardToken] == 0 || outstandingRewards == 0 || totalStakedGiBGT == 0) {
      return claimableRewardsPerGiBGTStored[rewardToken];
    }
    return claimableRewardsPerGiBGTStored[rewardToken] + FixedPointMathLib.divWad(outstandingRewards, totalStakedGiBGT);
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

  /// @notice Calculates the amount of GiBGT to mint
  /// @param lockAmount Amount of iBGT to lock
  /// @return mintAmount Total supply of GiBGT divided by the lending pool size multiplied by lockAmount
  function _GiBGTMintAmount(uint256 lockAmount) internal view returns (uint256) {
    uint256 supply = totalSupply();
    uint256 _poolSize = poolSize;
    return _poolSize > 0 && supply > 0 ? FixedPointMathLib.mulWad(lockAmount, _GiBGTRatio(supply, _poolSize)) : lockAmount;
  }

  /// @notice Calculates the current $GiBGT ratio
  /// @return gibgtRatio Total supply of $GiBGT divided by the lending pool size
  function _GiBGTRatio(uint256 supply, uint256 _poolSize) internal pure returns (uint256) {
    return FixedPointMathLib.divWad(supply, _poolSize);
  }


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                      INTERNAL FUNCTIONS                    */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @notice Updates claimable Porridge for user that is staking, unstaking, or claiming
  /// @param user Address to update claimable Porridge for
  function _updateClaimablePrg(address user) internal {
    claimablePrgPerGiBGTStored = _claimablePrgPerGiBGT();
    lastPrgUpdateTime = block.timestamp;
    if(user != address(0)) {
      claimablePrg[user] = _calculateClaimablePrg(user);
      prgPerTokenDebt[user] = claimablePrgPerGiBGTStored;
    }
  }

  /// @notice Updates claimable rewards for user that is locking or claiming
  /// @param user Address to update claimable rewards for
  function _updateClaimableRewards(address user) internal {
    uint256 rewardTokensLength = rewardTokens.length;
    for(uint8 i; i < rewardTokensLength; ++i) {
      outstandingRewardsPerReward[rewardTokens[i]] = ERC20(rewardTokens[i]).balanceOf(address(this));
    }
    iBGTVault(ibgtVault).getReward();
    for(uint8 i; i < rewardTokensLength; ++i) {
      address rewardToken = rewardTokens[i];
      uint256 outstandingRewards = ERC20(rewardToken).balanceOf(address(this)) - outstandingRewardsPerReward[rewardToken];
      claimableRewardsPerGiBGTStored[rewardToken] = _claimableRewardPerGiBGT(rewardToken, outstandingRewards);
      lastRewardUpdateTime[rewardToken] = block.timestamp;
      if(user != address(0)) {
        claimableRewards[user][rewardToken] = _calculateClaimableRewards(user, rewardToken, outstandingRewards);
        rewardPerTokenDebt[user][rewardToken] = claimableRewardsPerGiBGTStored[rewardToken];
      }
    }
  }

  /// @notice Mints claimable Porridge
  /// @param claimer User that is claiming Porridge
  /// @param claimable Amount of Porridge to be claimed
  function _claimPrg(address claimer, uint256 claimable) internal {
    if(claimable > 0) {
      claimablePrg[claimer] = 0;
      IGoldilocked(goldilocked).goldilendMint(claimer, claimable);
      emit Claim(claimer, claimable);
    }
  }

  /// @notice Calculates and distributes rewards
  /// @param claimer User that is claiming rewards
  function _claimRewards(address claimer) internal {
    uint256 rewardTokensLength = rewardTokens.length;
    for(uint8 i; i < rewardTokensLength; ++i) {
      address rewardToken = rewardTokens[i];
      uint256 reward = claimableRewards[claimer][rewardToken];
      if(reward > 0) {
        claimableRewards[claimer][rewardToken] = 0;
        SafeTransferLib.safeTransfer(rewardToken, claimer, reward);
      }
    }
  }

  /// @notice Stakes iBGT in Infrared vault
  /// @dev Claims existing vault rewards and updates poolSize
  /// @param ibgtAmount Amount of iBGT to stake
  function _refreshiBGT(uint256 ibgtAmount) internal {
    ERC20(ibgt).approve(ibgtVault, ibgtAmount);
    iBGTVault(ibgtVault).stake(ibgtAmount);
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


  /// @inheritdoc IGoldilend
    function changeValue(
    address[] calldata _nfts,
    uint256[] calldata _nftFairValues,
    uint256 _totalValuation
  ) external {
    if(msg.sender != timelock) revert NotTimelock();
    for(uint256 i; i < _nftFairValues.length; i++) {
      nftFairValues[_nfts[i]] = _nftFairValues[i];
    }
    totalValuation = _totalValuation;
  } 

  /// @inheritdoc IGoldilend
  function changeProtocolInterestRate(uint256 _protocolInterestRate) external {
    if(msg.sender != timelock) revert NotTimelock();
    protocolInterestRate = _protocolInterestRate;
  }

  /// @inheritdoc IGoldilend
  function changeShareRates(uint256 _multisigShare, uint256 _honeyjarShare) external {
    if(msg.sender != timelock) revert NotTimelock();
    multisigShare = _multisigShare;
    honeyjarShare = _honeyjarShare;
  }

  /// @inheritdoc IGoldilend
  function changeSlope(uint256 _slope) external {
    if(msg.sender != timelock) revert NotTimelock();
    slope = _slope;
  }

  /// @inheritdoc IGoldilend
  function changeDurations(uint256 _minDuration, uint256 _maxDuration) external {
    if(msg.sender != timelock) revert NotTimelock();
    minDuration = _minDuration;
    maxDuration = _maxDuration;
  }

  /// @inheritdoc IGoldilend
  function changePrgEmissions(uint256 newPrgEmissions) external {
    if(msg.sender != timelock) revert NotTimelock();
    _updateClaimablePrg(address(0));
    ANNUAL_PORRIDGE_EMISSIONS = newPrgEmissions;
  }

  /// @inheritdoc IGoldilend
  function addRewardTokens(address[] calldata _rewardTokens) external {
    if(msg.sender != multisig) revert NotMultisig();
    for(uint8 i; i < _rewardTokens.length; ++i) {
      rewardTokens.push(_rewardTokens[i]);
      lastRewardUpdateTime[rewardTokens[i]] = block.timestamp;
    }
  }

  /// @inheritdoc IGoldilend
  function changeBorrowingActive(bool _borrowingActive) external {
    if(msg.sender != multisig) revert NotMultisig();
    borrowingActive = _borrowingActive;
  }

  /// @inheritdoc IGoldilend
  function multisigInterestClaim() external {
    if(msg.sender != multisig) revert NotMultisig();
    uint256 interestClaim = multisigClaims;
    multisigClaims = 0;
    SafeTransferLib.safeTransfer(ibgt, multisig, interestClaim);
  }

  /// @inheritdoc IGoldilend
  function honeyjarInterestClaim() external {
    if(msg.sender != hj) revert NotHoneyjar();
    uint256 interestClaim = honeyjarClaims;
    honeyjarClaims = 0;
    SafeTransferLib.safeTransfer(ibgt, hj, interestClaim);
  }

  /// @inheritdoc IGoldilend
  function initializeProtocol(
    address[] calldata _nfts,
    uint256[] calldata _nftFairValues,
    uint256 _totalValuation,
    uint256 _multisigShare,
    uint256 _honeyjarShare,
    uint256 _minDuration,
    uint256 _maxDuration,
    uint256 _startingPoolSize
  ) external {
    if(msg.sender != multisig) revert NotMultisig();
    for(uint256 i; i < _nftFairValues.length; i++) {
      nftFairValues[_nfts[i]] = _nftFairValues[i];
    }
    totalValuation = _totalValuation;
    multisigShare = _multisigShare;
    honeyjarShare = _honeyjarShare;
    minDuration = _minDuration;
    maxDuration = _maxDuration;
    poolSize = _startingPoolSize;
    protocolInterestRate = 1e17;
    porridgeMultiple = 1e13;
    slope = 10;
    borrowingActive = true;
  }

  /// @inheritdoc IGoldilend
  function sunsetProtocol() external {
    if(msg.sender != timelock) revert NotTimelock();
    SafeTransferLib.safeTransfer(ibgt, multisig, poolSize - outstandingDebt);
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