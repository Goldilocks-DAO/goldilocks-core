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
// =============================== InfraredBexLPGoldivault ======================================
// ==============================================================================================


import { SafeTransferLib } from "../../../lib/solady/src/utils/SafeTransferLib.sol";
import { ERC20 } from "../../../lib/solady/src/tokens/ERC20.sol";
import { Goldivault } from "../../core/goldivault/Goldivault.sol";
import { iBGTVault } from "../../mock/iBGTVault.sol";
import { BexLPVault } from "../../mock/BexLPVault.sol";


contract InfraredBexLPGoldivault is Goldivault {


  /// @notice Constructor of this contract
  constructor(
    address _ot,
    address _yt,
    address _multisig,
    address _timelock
  ) Goldivault(
    _ot,
    _yt,
    _multisig,
    _timelock
  ) {}

  function _vaultDeposit(uint256 amount) internal override {
    BexLPVault(depositVault).stake(amount);
  }

  function _unstakeDepositToken(uint256 amount) internal override {
    BexLPVault(depositVault).withdraw(amount);
  }

  function _concludeVaultRewards() internal override {
    BexLPVault(depositVault).exit();
    iBGTVault(ibgtVault).exit();
  }

  function _compoundVaultRewards() internal override {
    BexLPVault(depositVault).getReward();
    iBGTVault(ibgtVault).getReward();
    uint256 ibgtrewards = ERC20(ibgt).balanceOf(address(this));
    uint256 yieldTokensLength = yieldTokens.length;
    for(uint8 i; i < yieldTokensLength; ++i) {
      SafeTransferLib.safeTransfer(yieldTokens[i], multisig, ERC20(yieldTokens[i]).balanceOf(address(this)) * yieldFee / 100);
    }
    iBGTVault(ibgtVault).stake(ibgtrewards);
  }

}