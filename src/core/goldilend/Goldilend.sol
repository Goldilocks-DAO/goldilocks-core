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
/// @notice Bong Bear (and rebase) Fixed Term NFT Lending
contract Goldilend is IGoldilend, ERC20, IERC721Receiver {


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                      STATE VARIABLES                       */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    

  /// @notice Address of Goldilocked
  address public immutable goldilocked;

  /// @notice Address of iBGT
  address public immutable ibgt;

  /// @notice Address of iBGT vault
  address public immutable ibgtVault;

  /// @notice Address of multisig
  address public immutable multisig;

  /// @notice Address of Timelock
  address public immutable timelock;

  /// @notice Address of APDAO
  address public immutable apdao;

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

  /// @notice Rate at which interest rate increases
  uint256 public slope;

  /// @notice Minimum loan duration
  uint256 public minDuration;

  /// @notice Maximum loan duration
  uint256 public maxDuration;

  /// @notice Duration to lock partner NFT for boost
  uint256 public boostLockDuration;

  /// @notice Portion of interest payments to multisig
  uint256 public multisigClaims;

  /// @notice Portion of interest payments to apdao
  uint256 public apdaoClaims;

  /// @notice Share of interest payments to multisig
  uint256 public multisigShare;

  /// @notice Share of interest payments to apdao
  uint256 public apdaoShare;

  /// @notice Annual emission rate of Porridge
  uint256 public annualPrgEmissions;
  
  /// @notice Total staked GiBGT
  uint256 public totalStakedGiBGT;

  /// @notice Addresses of reward tokens from iBGT staking
  address[] public rewardTokens;

  /// @notice Boolean value if borrowing is active
  bool public borrowingActive;

  /// @notice Maps user to boost
  mapping(address => Boost) public boosts;

  /// @notice Maps user to loans
  // mapping(address => Loan[]) public loans;
  mapping(address => mapping(uint256 => Loan)) public loans;

  /// @notice Id of loan for a user
  uint256 public userLoanId;

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
  /// @param _apdao Address of APDAO
  /// @param _ibgt Address of iBGT
  /// @param _ibgtVault Address of iBGTVault
  /// @param _rewardTokens Reward tokens from iBGT staking
  constructor(
    address _goldilocked,
    address _timelock,
    address _multisig,
    address _apdao,
    address _ibgt, 
    address _ibgtVault,
    address[] memory _rewardTokens
  ) {
    goldilocked = _goldilocked;
    multisig = _multisig;
    timelock = _timelock;
    apdao = _apdao;
    ibgt = _ibgt;
    ibgtVault = _ibgtVault;
    deployTime = block.timestamp;
    for(uint8 i; i < _rewardTokens.length; ++i) {
      rewardTokens.push(_rewardTokens[i]);
      lastRewardUpdateTime[rewardTokens[i]] = block.timestamp;
    }
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
  function lookupLoan(address user, uint256 _userLoanId) external view returns (Loan memory) {
    return loans[user][_userLoanId];
  }

  /// @inheritdoc IGoldilend
  function lookupBoost(address user) external view returns (Boost memory) {
    return boosts[user];
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
    SafeTransferLib.safeTransferFrom(ibgt, msg.sender, address(this), amount);
    _refreshiBGT(amount);
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
      uint256 discount = 500;
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
    userLoanId++;
    Loan memory loan = Loan({
      collateralNFTs: collateralNFTs,
      collateralNFTIds: collateralNFTIds,
      borrowedAmount: borrowAmount + interest,
      interest: interest,
      duration: duration,
      endDate: block.timestamp + duration,
      loanId: userLoanId,
      liquidated: false
    });
    loans[msg.sender][userLoanId] = loan;
    IERC721(collateralNFT).safeTransferFrom(msg.sender, address(this), collateralNFTId);
    iBGTVault(ibgtVault).withdraw(borrowAmount);
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
    uint256 debt = outstandingDebt;
    if(borrowAmount > _calculateFairValue(collateralNFTs) || borrowAmount > poolSize - debt) revert BorrowLimitExceeded();
    uint256 interest = _calculateInterest(borrowAmount, debt, duration);
    Boost memory userBoost = boosts[msg.sender];
    if(userBoost.expiry > block.timestamp + duration) {
      uint256 discount = 500;
      if(userBoost.boostMagnitude < discount) {
        discount = 1000 - userBoost.boostMagnitude;
      }
      interest = interest * discount / 1000;
    }
    outstandingDebt += borrowAmount;
    userLoanId++;
    Loan memory loan = Loan({
      collateralNFTs: collateralNFTs,
      collateralNFTIds: collateralNFTIds,
      borrowedAmount: borrowAmount + interest,
      interest: interest,
      duration: duration,
      endDate: block.timestamp + duration,
      loanId: userLoanId,
      liquidated: false
    });
    loans[msg.sender][userLoanId] = loan;
    for(uint256 i; i < collateralNFTs.length; i++) {
      IERC721(collateralNFTs[i]).safeTransferFrom(msg.sender, address(this), collateralNFTIds[i]);
    }
    iBGTVault(ibgtVault).withdraw(borrowAmount);
    SafeTransferLib.safeTransfer(ibgt, msg.sender, borrowAmount);
    emit Borrow(msg.sender, borrowAmount);
  }

  /// @inheritdoc IGoldilend
  function repay(uint256 repayAmount, uint256 _userLoanId) external {
    Loan memory userLoan = loans[msg.sender][_userLoanId];
    if(userLoan.borrowedAmount < repayAmount) revert ExcessiveRepay();
    if(block.timestamp > userLoan.endDate) revert LoanExpired();
    uint256 interestLoanRatio = FixedPointMathLib.divWad(userLoan.interest, userLoan.borrowedAmount);
    uint256 interest = FixedPointMathLib.mulWadUp(repayAmount, interestLoanRatio);
    outstandingDebt -= repayAmount - interest > outstandingDebt ? outstandingDebt : repayAmount - interest;
    loans[msg.sender][_userLoanId].borrowedAmount -= repayAmount;
    loans[msg.sender][_userLoanId].interest -= interest;
    poolSize += interest * (1000 - (multisigShare + apdaoShare)) / 1000;
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
  function liquidate(address user, uint256 _userLoanId) external {
    Loan memory userLoan = loans[user][_userLoanId];
    if(block.timestamp < userLoan.endDate || userLoan.liquidated || userLoan.borrowedAmount == 0) revert Unliquidatable();
    loans[user][_userLoanId].liquidated = true;
    loans[user][_userLoanId].borrowedAmount = 0;
    outstandingDebt -=  userLoan.borrowedAmount - userLoan.interest > outstandingDebt ? outstandingDebt : userLoan.borrowedAmount - userLoan.interest;
    if(msg.sender != multisig || block.timestamp < userLoan.endDate + 5 days) {
      poolSize += userLoan.interest * (1000 - (multisigShare + apdaoShare)) / 1000;
      _updateInterestClaims(userLoan.interest);
      SafeTransferLib.safeTransferFrom(ibgt, msg.sender, address(this), userLoan.borrowedAmount);
      _refreshiBGT(userLoan.borrowedAmount);
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
      uint256 prgBoost = userBoost.boostMagnitude < 500 ? userBoost.boostMagnitude : 500;
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
    return claimablePrgPerGiBGTStored + FixedPointMathLib.mulWad(FixedPointMathLib.divWad(block.timestamp - lastPrgUpdateTime, 365 days), annualPrgEmissions);
  }

  /// @notice Calculates claimable reward token per GiBGT
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
  ) internal view returns (uint256) {
    uint256 rate = protocolInterestRate;
    uint256 ratio = FixedPointMathLib.divWad(debt + borrowAmount, poolSize) + 5e17;
    uint256 interestRate = rate + FixedPointMathLib.mulWad(FixedPointMathLib.mulWad(slope, rate), FixedPointMathLib.mulWad(ratio, FixedPointMathLib.divWad(duration, 365 days)));
    uint256 interestAdjusted = FixedPointMathLib.mulWad(FixedPointMathLib.mulWad(interestRate, borrowAmount), FixedPointMathLib.divWad(duration, 365 days));
    return interestAdjusted / 100;
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
        expiry: block.timestamp + boostLockDuration,
        boostMagnitude: magnitude
      });
    }
    else {
      address[] storage nfts = userBoost.partnerNFTs;
      uint256[] storage ids = userBoost.partnerNFTIds;
      for(uint256 i = 0; i < nfts.length; i++) {
        magnitude += partnerNFTBoosts[nfts[i]];
      }
      magnitude += partnerNFTBoosts[partnerNFT];
      nfts.push(partnerNFT);
      ids.push(partnerNFTId);
      newUserBoost = Boost({
        partnerNFTs: nfts,
        partnerNFTIds: ids,
        expiry: block.timestamp + boostLockDuration,
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
        expiry: block.timestamp + boostLockDuration,
        boostMagnitude: magnitude
      });
    }
    else {
      address[] storage nfts = userBoost.partnerNFTs;
      uint256[] storage ids = userBoost.partnerNFTIds;
      for(uint256 i = 0; i < nfts.length; i++) {
        magnitude += partnerNFTBoosts[nfts[i]];
      }
      for(uint256 i = 0; i < partnerNFTs.length; i++) {
        magnitude += partnerNFTBoosts[partnerNFTs[i]];
        nfts.push(partnerNFTs[i]);
        ids.push(partnerNFTIds[i]);
      }
      newUserBoost = Boost({
        partnerNFTs: nfts,
        partnerNFTIds: ids,
        expiry: block.timestamp + boostLockDuration,
        boostMagnitude: magnitude
      });
    }
  }

  /// @notice Update internal variables tracking amount of interest for multisig and apdao
  /// @dev Multisig can claim 4.5% and apdao can claim 0.5% of interest paid
  /// @param interest Interest paid during repayment
  function _updateInterestClaims(uint256 interest) internal {
    multisigClaims += interest * multisigShare / 1000;
    apdaoClaims += interest * apdaoShare / 1000;
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
  function changeShareRates(uint256 _multisigShare, uint256 _apdaoShare) external {
    if(msg.sender != timelock) revert NotTimelock();
    multisigShare = _multisigShare;
    apdaoShare = _apdaoShare;
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
    annualPrgEmissions = newPrgEmissions;
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
    iBGTVault(ibgtVault).withdraw(interestClaim);
    SafeTransferLib.safeTransfer(ibgt, multisig, interestClaim);
  }

  /// @inheritdoc IGoldilend
  function apdaoInterestClaim() external {
    if(msg.sender != apdao) revert NotAPDAO();
    uint256 interestClaim = apdaoClaims;
    apdaoClaims = 0;
    iBGTVault(ibgtVault).withdraw(interestClaim);
    SafeTransferLib.safeTransfer(ibgt, apdao, interestClaim);
  }

  /// @inheritdoc IGoldilend
  function initializeParameters(
    uint256 _multisigShare,
    uint256 _apdaoShare,
    uint256 _minDuration,
    uint256 _maxDuration,
    uint256 _startingPoolSize,
    uint256 _protocolInterestRate,
    uint256 _slope,
    uint256 _annualPrgEmissions,
    uint256 _boostLockDuration
  ) external {
    if(msg.sender != multisig) revert NotMultisig();
    multisigShare = _multisigShare;
    apdaoShare = _apdaoShare;
    minDuration = _minDuration;
    maxDuration = _maxDuration;
    poolSize = _startingPoolSize;
    protocolInterestRate = _protocolInterestRate;
    slope = _slope;
    annualPrgEmissions = _annualPrgEmissions;
    boostLockDuration = _boostLockDuration;
  }

  /// @inheritdoc IGoldilend
  function initializeBeras(
    uint256 _totalValuation,
    address[] calldata _nfts,
    uint256[] calldata _nftFairValues
  ) external {
    if(msg.sender != multisig) revert NotMultisig();
    totalValuation = _totalValuation;
    for(uint256 i; i < _nftFairValues.length; i++) {
      nftFairValues[_nfts[i]] = _nftFairValues[i];
    }
    borrowingActive = true;
  }

  /// @inheritdoc IGoldilend
  function initializePartners(
    address[] memory _partnerNFTs, 
    uint8[] memory _partnerNFTBoosts
  ) external {
    if(msg.sender != multisig) revert NotMultisig();
    for(uint8 i; i < _partnerNFTs.length; i++) {
      partnerNFTBoosts[_partnerNFTs[i]] = _partnerNFTBoosts[i];
    }
  }

  /// @inheritdoc IGoldilend
  function adjustBoosts(
    address[] memory _partnerNFTs, 
    uint8[] memory _partnerNFTBoosts,
    uint256 _boostLockDuration
  ) external {
    if(msg.sender != timelock) revert NotTimelock();
    for(uint8 i; i < _partnerNFTs.length; i++) {
      partnerNFTBoosts[_partnerNFTs[i]] = _partnerNFTBoosts[i];
    }
    boostLockDuration = _boostLockDuration;
  }

  /// @inheritdoc IGoldilend
  function sunsetProtocol() external {
    if(msg.sender != timelock) revert NotTimelock();
    iBGTVault(ibgtVault).withdraw(poolSize - outstandingDebt);
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