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
// ======================================= iBGTGoldivault =======================================
// ==============================================================================================


import { ERC20 } from "../../../lib/solady/src/tokens/ERC20.sol";
import { Goldivault } from "./Goldivault.sol";
import { IiBGTVault } from "../../interfaces/IiBGTVault.sol";


contract iBGTGoldivault is Goldivault {

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
    ERC20(depositToken).approve(depositVault, amount);
    IiBGTVault(depositVault).stake(amount);
  }

  function _unstakeDepositToken(uint256 amount) internal override {
    IiBGTVault(depositVault).withdraw(amount);
  }

  function _concludeVaultRewards() internal override {
    IiBGTVault(depositVault).getReward();
    uint256 stakedAmount = IiBGTVault(depositVault).balanceOf(address(this));
    IiBGTVault(depositVault).withdraw(stakedAmount);
  }

}