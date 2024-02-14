//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;


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
// ========================================= IBGTVault ==========================================
// ==============================================================================================


import { SafeTransferLib } from "../../lib/solady/src/utils/SafeTransferLib.sol";
import { ERC20 } from "../../lib/solady/src/tokens/ERC20.sol";
import { Goldivault } from "../core/Goldivault.sol";


contract iBGTVault {
  function stake(uint256 amount) external {}
  function getReward() external {}
  function withdraw(uint256 amount) external {}
  function exit() external {}
}

contract IBGTVault is Goldivault {

  constructor(
    address _ot,
    address _yt,
    address _depositAsset,
    address[] memory _yieldAssets,
    address _vault,
    address _ibgtvault,
    address _ired,
    address _multisig
  ) Goldivault(
    _ot,
    _yt,
    _depositAsset,
    _yieldAssets,
    _vault,
    _ibgtvault,
    _ired,
    _multisig
  ) {
    concluded = false;
    startTime = block.timestamp;
    endTime = block.timestamp + duration;
  }

  function _vaultDeposit(uint256 amount) internal override {
    iBGTVault(vault).stake(amount);
  }

  function _concludeVaultRewards() internal override {
    iBGTVault(vault).exit();
    iBGTVault(ibgtvault).exit();
  }

  function _compoundVaultRewards() internal override {
    iBGTVault(vault).getReward();
    iBGTVault(ibgtvault).getReward();
    uint256 yieldAssetsLength = yieldAssets.length;
    uint256 ibgtrewards = ERC20(depositAsset).balanceOf(address(this));
    iBGTVault(ibgtvault).stake(ibgtrewards);
    for(uint8 i; i < yieldAssetsLength; ++i) {
      SafeTransferLib.safeTransfer(yieldAssets[i], multisig, (ERC20(yieldAssets[i]).balanceOf(address(this)) / 100) * fee);
    }
  }

}