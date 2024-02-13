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
// ======================================== Goldivaults =========================================
// ==============================================================================================


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
    uint256 _fee,
    uint256 _delay,
    uint256 _duration,
    address _ot,
    address _yt,
    address _depositAsset,
    address _yieldAsset,
    address _vault,
    address _ibgtvault,
    address _ired,
    address _treasury
  ) Goldivault(
    _fee,
    _delay,
    _duration,
    _ot,
    _yt,
    _depositAsset,
    _yieldAsset,
    _vault,
    _ibgtvault,
    _ired,
    _treasury
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
    uint256 ibgtrewards = ERC20(yieldAsset).balanceOf(address(this));
    iBGTVault(ibgtvault).stake(ibgtrewards);
  }

}