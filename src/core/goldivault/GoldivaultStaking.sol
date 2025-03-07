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
// =================================== GoldivaultStaking ========================================
// ==============================================================================================


import { FixedPointMathLib } from "../../../lib/solady/src/utils/FixedPointMathLib.sol";
import { SafeTransferLib } from "../../../lib/solady/src/utils/SafeTransferLib.sol";
import { ReentrancyGuard } from "../../../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import { ERC20 } from "../../../lib/solady/src/tokens/ERC20.sol";
import { IiBGTVault } from "../../interfaces/IiBGTVault.sol";
import { IV3SwapRouter } from "../../interfaces/IV3SwapRouter.sol";
import { IGoldivaultStaking } from "../../interfaces/IGoldivaultStaking.sol";
import { OwnershipToken } from "./OwnershipToken.sol";
import { YieldToken } from "./YieldToken.sol";


/// @title GoldivaultStaking
contract GoldivaultStaking is IGoldivaultStaking, ReentrancyGuard {


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                      STATE VARIABLES                       */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @notice Address of ownership token
  address public immutable ot;

  /// @notice Address of yield token
  address public immutable yt;

  /// @notice Address of deposit token
  address public immutable depositToken;

  /// @notice Address of deposit vault
  address public immutable depositVault;

  /// @notice Address of multisig
  address public immutable multisig;

  /// @notice Address of Kodiak SwapRouter02
  address public immutable router;

  /// @notice YT trade fee
  uint256 public immutable tradeFee;

  /// @notice Fee charged for yield
  uint256 public immutable yieldFee;

  /// @notice Timestamp of vault start time
  uint256 public startTime;

  /// @notice Timestamp of vault end time
  uint256 public endTime;

  /// @notice Amount of deposit token in vault
  uint256 public depositTokenAmount;

  /// @notice Amount of yield tokens staked in contract
  uint256 public totalYtStaked;

  /// @notice Previous claimable rewards per YT Staked
  mapping(address => uint256) public claimableRewardsPerYTStored;

  /// @notice block.timestamp at last reward update
  mapping(address => uint256) public lastRewardUpdateTime;

  /// @notice Amount of YT staked per user
  mapping(address => uint256) public ytStaked;

  /// @notice Maps user to reward token to amount of claimable rewards
  mapping(address => mapping(address => uint256)) public claimableRewards;

  /// @notice Maps user to reward token to amount of reward debt
  mapping(address => mapping(address => uint256)) public rewardPerTokenDebt;

  /// @notice Addresses of the reward tokens
  address[] public rewardTokens;


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                          CONSTRUCTOR                       */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @notice Constructor of this contract
  /// @param _ot Address of ownership token
  /// @param _yt Address of yield token
  /// @param _multisig Address of multisig
  /// @param _depositToken Address of deposit token
  /// @param _depositVault Address of deposit token vault
  /// @param _router Address of the Kodiak SwapRouter02
  /// @param _tradeFee Fee charged on YT trades
  /// @param _yieldFee Fee charged on yield claims
  /// @param _duration Duration of vault
  /// @param _rewardTokens Addresses of the reward tokens
  constructor(
    address _ot,
    address _yt,
    address _multisig,
    address _depositToken,
    address _depositVault,
    address _router,
    uint256 _tradeFee,
    uint256 _yieldFee,
    uint256 _duration,
    address[] memory _rewardTokens
  ) {
    ot = _ot;
    yt = _yt;
    multisig = _multisig;
    depositToken = _depositToken;
    depositVault = _depositVault;
    router = _router;
    tradeFee = _tradeFee;
    yieldFee = _yieldFee;
    startTime = block.timestamp;
    endTime = block.timestamp + _duration;
    uint256 rewardTokensLength = _rewardTokens.length;
    if(rewardTokensLength > 20) revert TooManyTokens();
    for(uint256 i; i < rewardTokensLength;) {
      rewardTokens.push(_rewardTokens[i]);
      lastRewardUpdateTime[_rewardTokens[i]] = block.timestamp;
      unchecked {
        ++i;
      }
    }
  }


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                    EXTERNAL FUNCTIONS                      */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @inheritdoc IGoldivaultStaking
  function deposit(uint256 amount) external nonReentrant {
    if(amount == 0) revert InvalidDeposit();
    SafeTransferLib.safeTransferFrom(depositToken, msg.sender, address(this), amount);
    _vaultDeposit(amount);
    depositTokenAmount += amount;
    OwnershipToken(ot).mintOT(msg.sender, amount);
    YieldToken(yt).mintYT(msg.sender, amount);
    _updateClaimableRewards(msg.sender);
    _stakeYT(amount);
    emit Deposit(msg.sender, amount);
  }

  /// @inheritdoc IGoldivaultStaking
  function redeemOwnership(uint256 amount) external nonReentrant {
    if(amount == 0) revert InvalidRedemption();
    uint256 remainingTime = block.timestamp > endTime ? 0 : endTime - block.timestamp;
    _updateClaimableRewards(msg.sender);
    uint256 unstakableAmount = _unstakableYT(msg.sender, amount);
    _unstakeYT(unstakableAmount);
    OwnershipToken(ot).burnOT(msg.sender, amount);
    if(remainingTime > 0) {
      YieldToken(yt).burnYT(msg.sender, amount);
    }
    _unstakeDepositToken(amount);
    depositTokenAmount -= amount;
    SafeTransferLib.safeTransfer(depositToken, msg.sender, amount);
    emit OwnershipTokenRedemption(msg.sender, amount);
  }

  /// @notice Buys YT using the vault and kodiak pool
  /// @dev These parameters cannot be 0
  /// @param ytAmount Amount of YT for user to buy
  /// @param dtAmountMax Maximum amount of deposit token that user wishes to pay
  /// @param amountOutMin Minimum amount of tokens to receive out from the kodiak pool swap
  function buyYT (uint256 ytAmount, uint256 dtAmountMax, uint256 amountOutMin) external nonReentrant {
    if(ytAmount == 0 || dtAmountMax == 0 || amountOutMin == 0) revert InvalidTrade();
    uint256 remainingTime = block.timestamp > endTime ? 0 : endTime - block.timestamp;
    if(remainingTime == 0) revert AlreadyConcluded();
    uint256 startingBalance = ERC20(depositToken).balanceOf(msg.sender);
    uint256 dtNeeded = dtAmountMax > ytAmount ? 0 : ytAmount - dtAmountMax;
    uint256 depositAmount = dtAmountMax + dtNeeded;
    if(dtNeeded == 0) dtAmountMax = ytAmount;
    if(ERC20(depositToken).balanceOf(address(this)) < dtNeeded) revert FlashLoanFailed();
    if(dtNeeded > 0) SafeTransferLib.safeTransfer(depositToken, msg.sender, dtNeeded);
    _deposit(depositAmount);
    SafeTransferLib.safeTransferFrom(ot, msg.sender, address(this), depositAmount);
    ERC20(ot).approve(router, type(uint256).max);
    IV3SwapRouter.ExactInputSingleParams memory params = IV3SwapRouter.ExactInputSingleParams({
      tokenIn: ot,
      tokenOut: depositToken,
      fee: 500,
      recipient: msg.sender,
      amountIn: depositAmount,
      amountOutMinimum: amountOutMin,
      sqrtPriceLimitX96: 0
    });
    IV3SwapRouter(router).exactInputSingle(params);
    ERC20(ot).approve(router, 0);
    if(dtNeeded > 0) SafeTransferLib.safeTransferFrom(depositToken, msg.sender, address(this), dtNeeded);
    uint256 endingBalance = ERC20(depositToken).balanceOf(msg.sender);
    if(endingBalance > startingBalance) revert ReceivedTooMuch();
    uint256 spentDt = startingBalance - endingBalance;
    uint256 fee = tradeFee * spentDt / 1000;
    if(spentDt + fee > dtAmountMax) revert SpentTooMuch();
    SafeTransferLib.safeTransferFrom(depositToken, msg.sender, multisig, fee);
    emit YTBuy(msg.sender, ytAmount, spentDt);
  }
  
  /// @notice Sells YT using the vault and kodiak pool
  /// @dev These parameters cannot be 0
  /// @param ytAmount Amount of YT for user to sell
  /// @param dtAmountMin Minimum amount of deposit token that user wishes to receive
  /// @param amountInMax Maximum amount of tokens to spend from the kodiak pool swap
  function sellYT (uint256 ytAmount, uint256 dtAmountMin, uint256 amountInMax) external nonReentrant {
    if(ytAmount == 0 || dtAmountMin == 0 || amountInMax == 0) revert InvalidTrade();
    uint256 remainingTime = block.timestamp > endTime ? 0 : endTime - block.timestamp;
    if(remainingTime == 0) revert AlreadyConcluded();
    uint256 startingBalance = ERC20(depositToken).balanceOf(msg.sender);
    _redeemOwnership(ytAmount);
    uint256 startingVaultBalance = ERC20(depositToken).balanceOf(address(this));
    ERC20(depositToken).approve(router, type(uint256).max);
    IV3SwapRouter.ExactOutputSingleParams memory params = IV3SwapRouter.ExactOutputSingleParams({
      tokenIn: depositToken,
      tokenOut: ot,
      fee: 500,
      recipient: address(this),
      amountOut: ytAmount,
      amountInMaximum: amountInMax,
      sqrtPriceLimitX96: 0
    });
    IV3SwapRouter(router).exactOutputSingle(params);
    ERC20(depositToken).approve(router, 0);
    OwnershipToken(ot).burnOT(address(this), ytAmount);
    uint256 vaultSpend = startingVaultBalance - ERC20(depositToken).balanceOf(address(this));
    SafeTransferLib.safeTransferFrom(depositToken, msg.sender, address(this), vaultSpend);
    uint256 endingBalance = ERC20(depositToken).balanceOf(msg.sender);
    if(endingBalance < startingBalance) revert ReceivedTooLitte(); 
    uint256 receivedDt = endingBalance - startingBalance;
    uint256 fee = tradeFee * receivedDt / 1000;
    if(receivedDt - fee < dtAmountMin) revert ReceivedTooLitte();
    SafeTransferLib.safeTransferFrom(depositToken, msg.sender, multisig, fee);
    emit YTSell(msg.sender, ytAmount, receivedDt - fee);
  }

  /// @notice Stakes YT
  function stakeYT(uint256 amount) external {
    _updateClaimableRewards(msg.sender);
    _stakeYT(amount);
  }

  /// @notice Unstakes YT
  function unstakeYT(uint256 amount) external {
    _updateClaimableRewards(msg.sender);
    uint256 unstakableAmount = _unstakableYT(msg.sender, amount);
    _unstakeYT(unstakableAmount);
  }

  /// @notice Claims rewards for YT stakers
  function claim() public nonReentrant {
    _updateClaimableRewards(msg.sender);
    _claim(msg.sender);
  }

  /// @notice Updates claimable rewards
  function _updateClaimableRewards() external {
    _updateClaimableRewards(address(0));
  }

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                    INTERNAL FUNCTIONS                      */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @notice Updates claimable rewards for user
  /// @param user Address of user to update claimable rewards for
  function _updateClaimableRewards(address user) internal {
    uint256 rewardTokensLength = rewardTokens.length;
    uint256[] memory outstandingRewardsPerReward = new uint256[](rewardTokensLength);
    for(uint256 i; i < rewardTokensLength;) {
      outstandingRewardsPerReward[i] = ERC20(rewardTokens[i]).balanceOf(address(this));
      unchecked {
        ++i;
      }
    }
    IiBGTVault(depositVault).getReward();
    for(uint256 i; i < rewardTokensLength;) {
      address rewardToken = rewardTokens[i];
      uint256 outstandingRewards = ERC20(rewardToken).balanceOf(address(this)) - outstandingRewardsPerReward[i];
      claimableRewardsPerYTStored[rewardToken] = _claimableRewardPerYT(rewardToken, outstandingRewards);
      lastRewardUpdateTime[rewardToken] = block.timestamp;
      if(user != address(0)) {
        claimableRewards[user][rewardToken] = _calculateClaimableRewards(user, rewardToken, outstandingRewards);
        rewardPerTokenDebt[user][rewardToken] = claimableRewardsPerYTStored[rewardToken];
      }
      unchecked {
        ++i;
      }
    }
  }

  /// @notice Internal function for claiming underlying
  function _claim(address claimer) internal {
    uint256 rewardTokensLength = rewardTokens.length;
    for(uint256 i; i < rewardTokensLength;) {
      address rewardToken = rewardTokens[i];
      uint256 reward = claimableRewards[claimer][rewardToken];
      if(reward > 0) {
        uint256 fee = yieldFee * reward / 1000;
        claimableRewards[claimer][rewardToken] = 0;
        SafeTransferLib.safeTransfer(rewardToken, claimer, reward - fee);
        SafeTransferLib.safeTransfer(rewardToken, multisig, fee);
      }
      unchecked {
        ++i;
      }
    }
  }

  /// @notice Internal deposit function for buy and sell functions
  function _deposit(uint256 amount) internal {
    if(amount == 0) revert InvalidDeposit();
    SafeTransferLib.safeTransferFrom(depositToken, msg.sender, address(this), amount);
    _vaultDeposit(amount);
    depositTokenAmount += amount;
    OwnershipToken(ot).mintOT(msg.sender, amount);
    YieldToken(yt).mintYT(msg.sender, amount);
    _updateClaimableRewards(msg.sender);
    _stakeYT(amount);
    emit Deposit(msg.sender, amount);
  }

  /// @notice Internal redeem function for buy and sell functions
  function _redeemOwnership(uint256 amount) internal {
    if(amount == 0) revert InvalidRedemption();
    _updateClaimableRewards(msg.sender);
    uint256 unstakableAmount = _unstakableYT(msg.sender, amount);
    _unstakeYT(unstakableAmount);
    YieldToken(yt).burnYT(msg.sender, amount);
    _unstakeDepositToken(amount);
    depositTokenAmount -= amount; 
    emit OwnershipTokenRedemption(msg.sender, amount);
  }

  /// @notice Stakes YT into contract
  function _stakeYT(uint256 amount) internal {
    ytStaked[msg.sender] += amount;
    totalYtStaked += amount;
    SafeTransferLib.safeTransferFrom(yt, msg.sender, address(this), amount);
    emit YTStake(msg.sender, amount);
  }

  /// @notice Unstakes YT from contract
  function _unstakeYT(uint256 amount) internal {
    if(amount > ytStaked[msg.sender]) revert InvalidUnstake();
    ytStaked[msg.sender] -= amount;
    totalYtStaked -= amount;
    SafeTransferLib.safeTransfer(yt, msg.sender, amount);
    emit YTUnstake(msg.sender, amount);
  }

  /// @notice Deposits into underlying vault
  function _vaultDeposit(uint256 amount) internal {
    ERC20(depositToken).approve(depositVault, amount);
    IiBGTVault(depositVault).stake(amount);
  }

  /// @notice Withdraws from underlying vault
  function _unstakeDepositToken(uint256 amount) internal {
    IiBGTVault(depositVault).withdraw(amount);
  }


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                   INTERNAL VIEW FUNCTIONS                  */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @notice Calculates claimable underlying
  function _calculateClaimableRewards(address user, address rewardToken, uint256 outstandingRewards) internal view returns (uint256) {
    return FixedPointMathLib.mulWad(ytStaked[user], _claimableRewardPerYT(rewardToken, outstandingRewards) - rewardPerTokenDebt[user][rewardToken]) + claimableRewards[user][rewardToken];
  }

  /// @notice Calculates claimable underlying per YT
  function _claimableRewardPerYT(address rewardToken, uint256 outstandingRewards) internal view returns (uint256) {
    if(block.timestamp - lastRewardUpdateTime[rewardToken] == 0 || outstandingRewards == 0 || totalYtStaked == 0) {
      return claimableRewardsPerYTStored[rewardToken];
    }
    return claimableRewardsPerYTStored[rewardToken] + FixedPointMathLib.divWad(outstandingRewards, totalYtStaked);
  }

  /// @notice Calculates if the user has unstaked YT
  function _unstakableYT(address user, uint256 unstakeAmount) internal view returns (uint256) {
    uint256 _ytStaked = ytStaked[user];
    if(_ytStaked == 0) {
      return 0;
    }
    else if(unstakeAmount > _ytStaked) {
      return unstakeAmount - _ytStaked;
    }
    else {
      return unstakeAmount;      
    }
  }

}