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
// ================================= HoneyWethLPGoldivault ======================================
// ==============================================================================================


import { SafeTransferLib } from "../../lib/solady/src/utils/SafeTransferLib.sol";
import { ERC20 } from "../../lib/solady/src/tokens/ERC20.sol";
import { Goldivault } from "../core/Goldivault.sol";


contract HoneyWethLPVault {
  function stake(uint256 amount) external {}
  function getReward() external {}
  function withdraw(uint256 amount) external {}
  function exit() external {}
}

contract InfraredBGTVault {
  function stake(uint256 amount) external {}
  function getReward() external {}
  function withdraw(uint256 amount) external {}
  function exit() external {}
}

contract BexLPGoldivault is Goldivault {

  constructor(
    address _ot,
    address _yt,
    address _depositToken,
    address _depositVault,
    address _ibgt,
    address _ibgtVault,
    address _ired,
    address _iredVault,
    address _multisig,
    address[] memory _yieldTokens
  ) Goldivault(
    _ot,
    _yt,
    _depositToken,
    _depositVault,
    _ibgt,
    _ibgtVault,
    _ired,
    _iredVault,
    _multisig,
    _yieldTokens
  ) {}

  function _vaultDeposit(uint256 amount) internal override {
    HoneyWethLPVault(depositVault).stake(amount);
  }

  function _unstakeDepositToken(uint256 amount) internal override {
    HoneyWethLPVault(depositVault).withdraw(amount);
  }

  function _concludeVaultRewards() internal override {
    HoneyWethLPVault(depositVault).exit();
    InfraredBGTVault(ibgtVault).exit();
  }

  function _compoundVaultRewards() internal override {
    HoneyWethLPVault(depositVault).getReward();
    InfraredBGTVault(ibgtVault).getReward();
    uint256 ibgtrewards = ERC20(ibgt).balanceOf(address(this));
    uint256 yieldTokensLength = yieldTokens.length;
    for(uint8 i; i < yieldTokensLength; ++i) {
      SafeTransferLib.safeTransfer(yieldTokens[i], multisig, (ERC20(yieldTokens[i]).balanceOf(address(this)) / 100) * yieldFee);
    }
    InfraredBGTVault(ibgtVault).stake(ibgtrewards);
  }

}