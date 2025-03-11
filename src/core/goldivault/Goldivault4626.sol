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
// ===================================== Goldivault4626 =========================================
// ==============================================================================================


import { FixedPointMathLib } from "../../../lib/solady/src/utils/FixedPointMathLib.sol";
import { SafeTransferLib } from "../../../lib/solady/src/utils/SafeTransferLib.sol";
import { ReentrancyGuard } from "../../../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import { ERC20 } from "../../../lib/solady/src/tokens/ERC20.sol";
import { ERC4626 } from "../../../lib/solady/src/tokens/ERC4626.sol";
import { IV3SwapRouter } from "../../interfaces/IV3SwapRouter.sol";
import { IGoldivault4626 } from "../../interfaces/IGoldivault4626.sol";
import { OwnershipToken } from "./OwnershipToken.sol";
import { YieldToken } from "./YieldToken.sol";


/// @title Goldivaults
/// @notice Splits deposited assets into ownership tokens representing
/// deposited assets and yield tokens representing future yield of those assets
///This vault is for streaming the yield continuously to users. Staking mechanism for YT copied from Goldilend
contract Goldivault4626 is IGoldivault4626, ReentrancyGuard {


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                      STATE VARIABLES                       */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @notice Address of ownership token
  address public immutable ot;

  /// @notice Address of yield token
  address public immutable yt;

  /// @notice Address of deposit token
  address public immutable depositToken;
  
  /// @notice Address of erc4626 deposit vault
  address public immutable depositVault;

  /// @notice Address of multisig
  address public immutable multisig;

  /// @notice Address of Kodiak SwapRouter02
  address router;

  /// @notice YT trade fee
  uint256 tradeFee;

  /// @notice Timestamp of vault start time
  uint256 public startTime;

  /// @notice Timestamp of vault end time
  uint256 public endTime;

  /// @notice Amount of deposit token in vault
  uint256 public depositTokenAmount;

  /// @notice Decimals of underlying asset
  uint256 public tokenDecimals;

  /// @notice Claimable underlying per staked YT
  uint256 public claimableUnderlyingPerYTStored;

  /// @notice Assets/shares ratio at last claim update
  uint256 public lastRatio;

  /// @notice Amount of yield tokens staked in contract
  uint256 public totalYtStaked;

  /// @notice Amount of YT staked per user
  mapping(address => uint256) public ytStaked;

  /// @notice Maps user to amount of claimable Underlying
  mapping(address => uint256) public claimableUnderlying;

  /// @notice Maps user to amount of Underlying reward debt
  mapping(address => uint256) public underlyingPerTokenDebt;


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                          CONSTRUCTOR                       */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @notice Constructor of this contract
  /// @param _ot Address of ownership token
  /// @param _yt Address of yield token
  /// @param _multisig Address of multisig
  /// @param _depositToken Address of deposit token
  /// @param _depositVault Address of deposit token vault
  /// @param _tokenDecimals Decimals of underlying asset
  /// @param _duration Duration of vault
  constructor(
    address _ot,
    address _yt,
    address _multisig,
    address _depositToken,
    address _depositVault,
    uint256 _tokenDecimals,
    uint256 _duration
  ) {
    ot = _ot;
    yt = _yt;
    multisig = _multisig;
    depositToken = _depositToken;
    depositVault = _depositVault;
    tokenDecimals = _tokenDecimals;
    lastRatio = ERC4626(depositVault).convertToAssets(tokenDecimals);
    startTime = block.timestamp;
    endTime = block.timestamp + _duration;
  }


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                    EXTERNAL FUNCTIONS                      */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @inheritdoc IGoldivault4626
  function deposit(uint256 amount) external nonReentrant {
    if(amount == 0) revert InvalidDeposit();
    SafeTransferLib.safeTransferFrom(depositToken, msg.sender, address(this), amount);
    ERC4626(depositVault).deposit(amount, address(this));
    depositTokenAmount += amount;
    OwnershipToken(ot).mintOT(msg.sender, amount);
    YieldToken(yt).mintYT(msg.sender, amount);
    _updateClaimableUnderlying(msg.sender);
    _stakeYT(amount);
    emit Deposit(msg.sender, amount);
  }

  /// @inheritdoc IGoldivault4626
  function redeemOwnership(uint256 amount) external nonReentrant {
    if(amount == 0) revert InvalidRedemption();
    uint256 remainingTime = block.timestamp > endTime ? 0 : endTime - block.timestamp;
    _updateClaimableUnderlying(msg.sender);
    uint256 unstakableAmount = _unstakableYT(msg.sender, amount);
    _unstakeYT(unstakableAmount);
    OwnershipToken(ot).burnOT(msg.sender, amount);
    if(remainingTime > 0) {
      YieldToken(yt).burnYT(msg.sender, amount);
    }
    ERC4626(depositVault).withdraw(amount, address(this), address(this));
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
    // need to track change in share balance as well as change in asset balance
    uint256 startingShareBalance = ERC20(depositVault).balanceOf(msg.sender);
    uint256 dtNeeded = dtAmountMax > ytAmount ? 0 : ytAmount - dtAmountMax;
    uint256 depositAmount = dtAmountMax + dtNeeded;
    if(dtNeeded == 0) dtAmountMax = ytAmount;
    // because the contract holds shares, not assets, need to check there are enough shares
    if(ERC4626(depositVault).convertToAssets(ERC20(depositVault).balanceOf(address(this))) < dtNeeded) revert FlashLoanFailed();
    // because the contract holds shares, not assets, need to withdraw to the user rather than transfer
    if(dtNeeded > 0) ERC4626(depositVault).withdraw(dtNeeded, msg.sender, address(this));
    _deposit(depositAmount);
    SafeTransferLib.safeTransferFrom(ot, msg.sender, address(this), depositAmount);
    ERC20(ot).approve(router, type(uint256).max);
    IV3SwapRouter.ExactInputSingleParams memory params = IV3SwapRouter.ExactInputSingleParams({
      tokenIn: ot,
      tokenOut: depositVault,
      fee: 500,
      recipient: msg.sender,
      amountIn: depositAmount,
      amountOutMinimum: amountOutMin,
      sqrtPriceLimitX96: 0
    });
    IV3SwapRouter(router).exactInputSingle(params);
    ERC20(ot).approve(router, 0);
    // because user receives shares rather than assets from the LP, they need to convert back to assets here
    uint256 endingShareBalance = ERC20(depositVault).balanceOf(msg.sender);
    ERC4626(depositVault).redeem(endingShareBalance - startingShareBalance, msg.sender, msg.sender);
    if(dtNeeded > 0) SafeTransferLib.safeTransferFrom(depositToken, msg.sender, address(this), dtNeeded);
    // vault needs to redeposit the received assets
    ERC4626(depositVault).deposit(dtNeeded, address(this));
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
    // need to track change in share balance as well as change in asset balance
    uint256 startingShareBalance = ERC20(depositVault).balanceOf(msg.sender);
    _redeemOwnership(ytAmount);
    // since the contract holds shares, not assets, we should check balance of underlying assets
    uint256 startingVaultBalance = ERC4626(depositVault).convertToAssets(ERC20(depositVault).balanceOf(address(this)));
    ERC20(depositToken).approve(router, type(uint256).max);
    IV3SwapRouter.ExactOutputSingleParams memory params = IV3SwapRouter.ExactOutputSingleParams({
      tokenIn: depositVault,
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
    // do the same here again
    uint256 vaultSpend = startingVaultBalance - ERC4626(depositVault).convertToAssets(ERC20(depositVault).balanceOf(address(this)));
    // here the user needs to convert accrued shares to assets
    ERC4626(depositVault).redeem(ERC4626(depositVault).balanceOf(msg.sender) - startingShareBalance , msg.sender, msg.sender);
    SafeTransferLib.safeTransferFrom(depositToken, msg.sender, address(this), vaultSpend);
    // vault needs to redeposit the received assets
    ERC4626(depositVault).deposit(vaultSpend, address(this));
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
    _updateClaimableUnderlying(msg.sender);
    _stakeYT(amount);
  }

  /// @notice Unstakes YT
  function unstakeYT(uint256 amount) external {
    _updateClaimableUnderlying(msg.sender);
    uint256 unstakableAmount = _unstakableYT(msg.sender, amount);
    _unstakeYT(unstakableAmount);
  }

  /// @notice Claims rewards for YT stakers
  function claim() public nonReentrant {
    _updateClaimableUnderlying(msg.sender);
    _claim(msg.sender, claimableUnderlying[msg.sender]);
  }


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                 EXTERNAL VIEW FUNCTIONS                    */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  function userClaimableUnderlying(address user) external view returns (uint256) {
    return _calculateClaimableUnderlying(user);
  }


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                    INTERNAL FUNCTIONS                      */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @notice Updates claimable Underlying
  /// @param user Address of user
  function _updateClaimableUnderlying(address user) internal {
    claimableUnderlyingPerYTStored = _claimableUnderlyingPerYT();
    lastRatio = ERC4626(depositVault).convertToAssets(tokenDecimals);
    if(user != address(0)) {
      claimableUnderlying[user] = _calculateClaimableUnderlying(user);
      underlyingPerTokenDebt[user] = claimableUnderlyingPerYTStored;
    }
  }

  /// @notice Internal function for claiming underlying
  function _claim(address claimer, uint256 claimable) internal {
    if(claimable > 0) {
      claimableUnderlying[claimer] = 0;
      ERC4626(depositVault).withdraw(claimable, msg.sender, address(this));
      emit Claim(claimer, claimable);
    }
  }

  /// @notice Internal deposit function for buy and sell functions
  function _deposit(uint256 amount) internal {
    if(amount == 0) revert InvalidDeposit();
    SafeTransferLib.safeTransferFrom(depositToken, msg.sender, address(this), amount);
    ERC4626(depositVault).deposit(amount, address(this));
    depositTokenAmount += amount;
    OwnershipToken(ot).mintOT(msg.sender, amount);
    YieldToken(yt).mintYT(msg.sender, amount);
    _updateClaimableUnderlying(msg.sender);
    _stakeYT(amount);
    emit Deposit(msg.sender, amount);
  }

  /// @notice Internal redeem function for buy and sell functions
  function _redeemOwnership(uint256 amount) internal {
    if(amount == 0) revert InvalidRedemption();
    _updateClaimableUnderlying(msg.sender);
    uint256 unstakableAmount = _unstakableYT(msg.sender, amount);
    _unstakeYT(unstakableAmount);
    YieldToken(yt).burnYT(msg.sender, amount);
    ERC4626(depositVault).withdraw(amount, msg.sender, address(this));
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


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                   INTERNAL VIEW FUNCTIONS                  */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @notice Calculates claimable underlying
  function _calculateClaimableUnderlying(address user) internal view returns (uint256) {
    return FixedPointMathLib.mulWad(ytStaked[user], _claimableUnderlyingPerYT() - underlyingPerTokenDebt[user]) + claimableUnderlying[user];
  }

  /// @notice Calculates claimable underlying per YT
  function _claimableUnderlyingPerYT() internal view returns (uint256) {
    uint256 oldRatio = lastRatio;
    uint256 newRatio = ERC4626(depositVault).convertToAssets(tokenDecimals);
    uint256 ratioDiff = newRatio - oldRatio;
    if(ratioDiff == 0 || totalYtStaked == 0) {
      return claimableUnderlyingPerYTStored;
    }
    return claimableUnderlyingPerYTStored + FixedPointMathLib.divWad(ratioDiff, totalYtStaked);
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