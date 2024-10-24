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
import { FixedPointMathLib } from "../../../lib/solady/src/utils/FixedPointMathLib.sol";
import { SafeTransferLib } from "../../../lib/solady/src/utils/SafeTransferLib.sol";
import { Goldivault } from "./Goldivault.sol";
import { OwnershipToken } from "./OwnershipToken.sol";
import { YieldToken } from "./YieldToken.sol";


contract WeethGoldivault is Goldivault {

  constructor(
    address _ot,
    address _yt,
    address _multisig,
    address _timelock,
    address _depositToken,
    address _depositVault,
    address _ibgt,
    address _ibgtVault
  ) Goldivault(
    _ot,
    _yt,
    _multisig,
    _timelock,
    _depositToken,
    _depositVault,
    _ibgt,
    _ibgtVault
  ) {}

  error SpentTooMuch();

  function _vaultDeposit(uint256 amount) internal override {}
  function _unstakeDepositToken(uint256 amount) internal override {}
  function _concludeVaultRewards() internal override {}
  function _compoundVaultRewards() internal override {}

  /// @notice Buys YT using the vault and kodiak pool
  /// @param ytAmount Amount of YT for user to buy
  /// @param dtAmountMax Maximum amount of deposit token that user wishes to pay
  function buyYT (uint256 ytAmount, uint256 dtAmountMax) external {
    // require(startingBalance >= _depositAmount);
    uint256 startingBalance = ERC20(depositToken).balanceOf(msg.sender);
    uint256 remainingTime = block.timestamp > endTime ? 0 : endTime - block.timestamp;
    uint256 ratio = FixedPointMathLib.divWad(remainingTime, duration);
    uint256 remainingYt = ytAmount;
    uint256 spentDt = startingBalance - ERC20(depositToken).balanceOf(msg.sender);
    while (remainingYt > 0) {
      if(spentDt > dtAmountMax) revert SpentTooMuch();
      if (remainingYt >= FixedPointMathLib.mulWad((dtAmountMax - spentDt), ratio)) {
        _vaultDeposit(dtAmountMax - spentDt); 
        //sell the OT's acquired  
        //exact amount in = dtAmountMax - spentDt, minimum amount out = 0.1 -- doesn't matter if there's too much slippage here because will rever on line 18 later
        // kodiakOTPool.sell(ot, dtAmountMax - spentDt);
        remainingYt -= FixedPointMathLib.mulWad((dtAmountMax - spentDt), ratio);
        spentDt = startingBalance - ERC20(depositToken).balanceOf(msg.sender);
      }
      else {
        _vaultDeposit(remainingYt/ratio);
        //sell the OT's acquired
        //exact amount in = dtAmountMax - spentDt, minimum amount out = 0.1 -- doesn't matter if there's too much slippage here because will rever on line 18 later
        // kodiakOTPool.sell(ot, remainingYt/ratio);
        remainingYt = 0;
        spentDt = startingBalance - ERC20(depositToken).balanceOf(msg.sender);
        uint256 fee = spentDt * earlyWithdrawalFee / 1000;
        if(spentDt + fee > dtAmountMax) revert SpentTooMuch();
        SafeTransferLib.safeTransferFrom(depositToken, msg.sender, multisig, fee);
      }
    }
  }

  /// @notice Sells YT using the vault and kodiak pool
  /// @param ytAmount Amount of YT for user to sell
  /// @param dtAmountMin Minimum amount of deposit token that user wishes to receive
  function sellYT (uint256 ytAmount, uint256 dtAmountMin) external {
    // require(ERC20(depositToken).balanceOf(msg.sender) > ytAmount);
    uint256 startingBalance = ERC20(depositToken).balanceOf(msg.sender);
    uint256 remainingTime = block.timestamp > endTime ? 0 : endTime - block.timestamp;
    uint256 ratio = FixedPointMathLib.divWad(remainingTime, duration);
    OwnershipToken(ot).mintOT(msg.sender, FixedPointMathLib.divWad(ytAmount, ratio));
    _redeemOwnership(FixedPointMathLib.divWad(ytAmount, ratio)); 
    //Buy back the amount of minted OT's from the LP (specify that ytAmount/ratio is the exact amount of OT to be bought, it can't be less)
    //exact amount out = ytAmount/ratio, max amount in = ytAmount/ratio (because OT should always trade at a discount to deposit token)
    // kodiakOTPool.buy(ot, ytAmount/ratio);
    OwnershipToken(ot).burnOT(msg.sender, FixedPointMathLib.divWad(ytAmount, ratio));
    uint256 dtAmount = ERC20(depositToken).balanceOf(msg.sender) - startingBalance;
    uint256 fee = earlyWithdrawalFee * dtAmount / 1000;
    if(ERC20(depositToken).balanceOf(msg.sender) - startingBalance - fee < dtAmountMin) revert SpentTooMuch();
    SafeTransferLib.safeTransferFrom(depositToken, msg.sender, multisig, fee);
  }

  function _redeemOwnership(uint256 amount) internal {
    if(amount == 0) revert InvalidRedemption();
    uint256 remainingTime = block.timestamp > endTime ? 0 : endTime - block.timestamp;
    uint256 timeshare = FixedPointMathLib.divWad(remainingTime, duration);
    OwnershipToken(ot).burnOT(msg.sender, amount);
    YieldToken(yt).burnYT(msg.sender, FixedPointMathLib.mulWad(amount, timeshare));
    _unstakeDepositToken(amount);
    depositTokenAmount -= amount;
    uint256 _fee = earlyWithdrawalFee;
    if(remainingTime > 0) {
      uint256 fee = amount * _fee / 1000;
      SafeTransferLib.safeTransfer(depositToken, msg.sender, amount - fee);
      SafeTransferLib.safeTransfer(depositToken, multisig, fee);
      emit OwnershipTokenRedemption(msg.sender, amount - fee);
    }
    else {
      SafeTransferLib.safeTransfer(depositToken, msg.sender, amount);
      emit OwnershipTokenRedemption(msg.sender, amount);
    }
  }
}