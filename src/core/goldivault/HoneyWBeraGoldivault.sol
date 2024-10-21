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
// ================================== HoneyWBeraGoldivault ======================================
// ==============================================================================================


import { ERC20 } from "../../../lib/solady/src/tokens/ERC20.sol";
import { SafeTransferLib } from "../../../lib/solady/src/utils/SafeTransferLib.sol";
import { Goldivault } from "./Goldivault.sol";
import { IiBGTVault } from "../../interfaces/IiBGTVault.sol";


contract HoneyWBeraGoldivault is Goldivault {

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

  function _vaultDeposit(uint256 amount) internal override {
    IiBGTVault(depositVault).stake(amount);
  }

  function _unstakeDepositToken(uint256 amount) internal override {
    IiBGTVault(depositVault).withdraw(amount);
  }

  function _concludeVaultRewards() internal override {
    IiBGTVault(depositVault).getReward();
    IiBGTVault(ibgtVault).getReward();
  }

  function _compoundVaultRewards() internal override {
    IiBGTVault(depositVault).getReward();
    IiBGTVault(ibgtVault).getReward();
    uint256 ibgtrewards = ERC20(ibgt).balanceOf(address(this));
    uint256 yieldTokensLength = yieldTokens.length;
    for(uint8 i; i < yieldTokensLength; ++i) {
      SafeTransferLib.safeTransfer(yieldTokens[i], multisig, ERC20(yieldTokens[i]).balanceOf(address(this)) * yieldFee / 1000);
    }
    IiBGTVault(ibgtVault).stake(ibgtrewards * (1000 - yieldFee) / 1000);
  }

}