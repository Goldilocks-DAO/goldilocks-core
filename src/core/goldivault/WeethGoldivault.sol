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
// ===================================== WeethGoldivault ========================================
// ==============================================================================================


import { ERC20 } from "../../../lib/solady/src/tokens/ERC20.sol";
import { IV3SwapRouter } from "../../interfaces/IV3SwapRouter.sol";
import { FixedPointMathLib } from "../../../lib/solady/src/utils/FixedPointMathLib.sol";
import { SafeTransferLib } from "../../../lib/solady/src/utils/SafeTransferLib.sol";
import { Goldivault } from "./Goldivault.sol";
import { OwnershipToken } from "./OwnershipToken.sol";
import { YieldToken } from "./YieldToken.sol";


contract WeethGoldivault is Goldivault {

  address router;
  uint256 tradeFee;
  error SpentTooMuch();
  error ReceivedTooLitte();
  error FlashLoanFailed();

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
    ERC20(_ot).approve(router, type(uint256).max);
    ERC20(_depositToken).approve(router, type(uint256).max);
  }

/// @notice Buys YT using the vault and kodiak pool
  /// @param ytAmount Amount of YT for user to buy
  /// @param dtAmountMax Maximum amount of deposit token that user wishes to pay
  /// @param otPriceMin Minimum price received per OT
  function buyYT (uint256 ytAmount, uint256 dtAmountMax, uint256 otPriceMin) external returns (uint256){
    uint256 remainingTime = block.timestamp > endTime ? 0 : endTime - block.timestamp;
    uint256 ratio = FixedPointMathLib.divWad(remainingTime, duration);
    uint256 startingBalance = ERC20(depositToken).balanceOf(msg.sender);
    uint256 dtNeeded = dtAmountMax > FixedPointMathLib.divWad(ytAmount, ratio) ? 0 : FixedPointMathLib.divWad(ytAmount, ratio) -  dtAmountMax;
    if(dtNeeded == 0) dtAmountMax = FixedPointMathLib.divWad(ytAmount, ratio);
    if(ERC20(depositToken).balanceOf(address(this)) < dtNeeded) revert FlashLoanFailed();
    if(dtNeeded > 0) SafeTransferLib.safeTransfer(depositToken, msg.sender, dtNeeded);
    _deposit(dtAmountMax + dtNeeded);
    SafeTransferLib.safeTransferFrom(ot, msg.sender, address(this), dtAmountMax + dtNeeded);
    IV3SwapRouter.ExactInputSingleParams memory params = IV3SwapRouter.ExactInputSingleParams({
      tokenIn: ot,
      tokenOut: depositToken,
      fee: 3000,
      recipient: msg.sender,
      amountIn: dtAmountMax + dtNeeded,
      amountOutMinimum: FixedPointMathLib.mulWad(otPriceMin, dtNeeded + dtAmountMax),
      sqrtPriceLimitX96: 0
    });
    IV3SwapRouter(router).exactInputSingle(params);
    if(dtNeeded > 0) SafeTransferLib.safeTransferFrom(depositToken, msg.sender, address(this), dtNeeded);
    uint256 fee = tradeFee * (startingBalance - ERC20(depositToken).balanceOf(msg.sender)) / 1000;
    if(startingBalance - ERC20(depositToken).balanceOf(msg.sender) - fee > dtAmountMax) revert SpentTooMuch();
    SafeTransferLib.safeTransferFrom(depositToken, msg.sender, multisig, fee);
    return(startingBalance - ERC20(depositToken).balanceOf(msg.sender) - fee);
    //add event
  }
  
/// @notice Sells YT using the vault and kodiak pool
  /// @param ytAmount Amount of YT for user to sell
  /// @param dtAmountMin Minimum amount of deposit token that user wishes to receive
  /// @param otPriceMax Maximum price user wishes to pay per OT
  function sellYT (uint256 ytAmount, uint256 dtAmountMin, uint256 otPriceMax) external returns(uint256) {
    uint256 remainingTime = block.timestamp > endTime ? 0 : endTime - block.timestamp;
    uint256 ratio = FixedPointMathLib.divWad(remainingTime, duration);
    uint256 startingBalance = ERC20(depositToken).balanceOf(msg.sender);
    uint256 startingVaultBalance = ERC20(depositToken).balanceOf(address(this));
    OwnershipToken(ot).mintOT(msg.sender, FixedPointMathLib.divWad(ytAmount, ratio));
    _redeemOwnership(FixedPointMathLib.divWad(ytAmount, ratio));
    IV3SwapRouter.ExactOutputSingleParams memory params = IV3SwapRouter.ExactOutputSingleParams({
      tokenIn: depositToken,
      tokenOut: ot,
      fee: 3000,
      recipient: msg.sender,
      amountOut: FixedPointMathLib.divWad(ytAmount, ratio),
      amountInMaximum: FixedPointMathLib.mulWad(FixedPointMathLib.divWad(ytAmount, ratio), otPriceMax),
      sqrtPriceLimitX96: 0
    });
    IV3SwapRouter(router).exactOutputSingle(params);
    OwnershipToken(ot).burnOT(msg.sender, FixedPointMathLib.divWad(ytAmount, ratio));
    uint256 vaultSpend = ERC20(depositToken).balanceOf(address(this)) - startingVaultBalance;
    SafeTransferLib.safeTransferFrom(depositToken, msg.sender, address(this), vaultSpend);
    uint256 dtAmount = ERC20(depositToken).balanceOf(msg.sender) - startingBalance;
    uint256 fee = tradeFee * dtAmount / 1000;
    if(dtAmount - fee < dtAmountMin) revert ReceivedTooLitte();
    SafeTransferLib.safeTransferFrom(depositToken, msg.sender, multisig, fee);
    return(dtAmount - fee);
    //add event
  }

  /// @notice Internal deposit function for buy and sell functions
  function _deposit(uint256 amount) internal {
    uint256 remainingTime = block.timestamp > endTime ? 0 : endTime - block.timestamp;
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
  function _redeemOwnership(uint256 amount) internal {
    if(amount == 0) revert InvalidRedemption();
    uint256 remainingTime = block.timestamp > endTime ? 0 : endTime - block.timestamp;
    uint256 timeshare = FixedPointMathLib.divWad(remainingTime, duration);
    OwnershipToken(ot).burnOT(msg.sender, amount);
    YieldToken(yt).burnYT(msg.sender, FixedPointMathLib.mulWad(amount, timeshare));
    _unstakeDepositToken(amount);
    depositTokenAmount -= amount;
    SafeTransferLib.safeTransfer(depositToken, msg.sender, amount);
    emit OwnershipTokenRedemption(msg.sender, amount);
  }

}
