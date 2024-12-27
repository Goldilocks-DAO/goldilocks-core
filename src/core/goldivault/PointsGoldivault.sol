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
// ==================================== PointsGoldivault ========================================
// ==============================================================================================


import { ERC20 } from "../../../lib/solady/src/tokens/ERC20.sol";
import { IV3SwapRouter } from "../../interfaces/IV3SwapRouter.sol";
import { FixedPointMathLib } from "../../../lib/solady/src/utils/FixedPointMathLib.sol";
import { SafeTransferLib } from "../../../lib/solady/src/utils/SafeTransferLib.sol";
import { Goldivault } from "./Goldivault.sol";
import { OwnershipToken } from "./OwnershipToken.sol";
import { YieldToken } from "./YieldToken.sol";


contract PointsGoldivault is Goldivault {

  address router;
  uint256 tradeFee;
  error SpentTooMuch();
  error ReceivedTooMuch();
  error ReceivedTooLitte();
  error FlashLoanFailed();
  error InvalidTrade();
  event YTBuy(address indexed user, uint256 boughtYt, uint256 spentDt);
  event YTSell(address indexed user, uint256 soldYt, uint256 receivedDt);

  constructor(
    address _ot,
    address _yt,
    address _multisig,
    address _timelock,
    address _depositToken,
    address _depositVault,
    address _ibgt,
    address _ibgtVault,
    address _router,
    uint256 _tradeFee
  ) Goldivault(
    _ot,
    _yt,
    _multisig,
    _timelock,
    _depositToken,
    _depositVault,
    _ibgt,
    _ibgtVault
  ) {
    router = _router;
    tradeFee = _tradeFee;
  }

  /// @notice Buys YT using the vault and kodiak pool
  /// @param ytAmount Amount of YT for user to buy
  /// @param dtAmountMax Maximum amount of deposit token that user wishes to pay
  /// @param amountOutMin Minimum amount of tokens to receive out from the kodiak pool swap
  function buyYT (uint256 ytAmount, uint256 dtAmountMax, uint256 amountOutMin) external nonReentrant {
    if(ytAmount == 0 || dtAmountMax == 0 || amountOutMin == 0) revert InvalidTrade();
    uint256 remainingTime = block.timestamp > endTime ? 0 : endTime - block.timestamp;
    if(remainingTime == 0) revert AlreadyConcluded();
    uint256 timeshare = FixedPointMathLib.divWad(remainingTime, duration);
    uint256 startingBalance = ERC20(depositToken).balanceOf(msg.sender);
    uint256 dtNeeded = dtAmountMax > FixedPointMathLib.divWad(ytAmount, timeshare) ? 0 : FixedPointMathLib.divWad(ytAmount, timeshare) - dtAmountMax;
    uint256 depositAmount = dtAmountMax + dtNeeded;
    if(dtNeeded == 0) dtAmountMax = FixedPointMathLib.divWad(ytAmount, timeshare);
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
  /// @param ytAmount Amount of YT for user to sell
  /// @param dtAmountMin Minimum amount of deposit token that user wishes to receive
  /// @param amountInMax Maximum amount of tokens to spend from the kodiak pool swap
  function sellYT (uint256 ytAmount, uint256 dtAmountMin, uint256 amountInMax) external nonReentrant {
    if(ytAmount == 0 || dtAmountMin == 0 || amountInMax == 0) revert InvalidTrade();
    uint256 remainingTime = block.timestamp > endTime ? 0 : endTime - block.timestamp;
    if(remainingTime == 0) revert AlreadyConcluded();
    uint256 timeshare = FixedPointMathLib.divWad(remainingTime, duration);
    uint256 startingBalance = ERC20(depositToken).balanceOf(msg.sender);
    uint256 otAmount = FixedPointMathLib.divWad(ytAmount, timeshare);
    _redeemOwnership(otAmount, ytAmount);
    uint256 startingVaultBalance = ERC20(depositToken).balanceOf(address(this));
    ERC20(depositToken).approve(router, type(uint256).max);
    IV3SwapRouter.ExactOutputSingleParams memory params = IV3SwapRouter.ExactOutputSingleParams({
      tokenIn: depositToken,
      tokenOut: ot,
      fee: 500,
      recipient: address(this),
      amountOut: otAmount,
      amountInMaximum: amountInMax,
      sqrtPriceLimitX96: 0
    });
    IV3SwapRouter(router).exactOutputSingle(params);
    ERC20(depositToken).approve(router, 0);
    OwnershipToken(ot).burnOT(address(this), otAmount);
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

  /// @notice Internal deposit function for buy and sell functions
  function _deposit(uint256 amount) internal {
    uint256 remainingTime = endTime - block.timestamp;
    if(remainingTime < depositWindow) revert InsufficientTime();
    uint256 timeshare = FixedPointMathLib.divWad(remainingTime, duration);
    SafeTransferLib.safeTransferFrom(depositToken, msg.sender, address(this), amount);
    _vaultDeposit(amount);
    depositTokenAmount += amount;
    OwnershipToken(ot).mintOT(msg.sender, amount);
    YieldToken(yt).mintYT(msg.sender, FixedPointMathLib.mulWad(amount, timeshare));
    emit Deposit(msg.sender, amount);
  }

  /// @notice Internal redeem function for buy and sell functions
  function _redeemOwnership(uint256 amount, uint256 burnAmount) internal {
    if(amount == 0) revert InvalidRedemption();
    YieldToken(yt).burnYT(msg.sender, burnAmount);
    _unstakeDepositToken(amount);
    depositTokenAmount -= amount;
    SafeTransferLib.safeTransfer(depositToken, msg.sender, amount);
    emit OwnershipTokenRedemption(msg.sender, amount);
  }

}