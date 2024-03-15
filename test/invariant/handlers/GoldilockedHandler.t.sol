//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../../lib/forge-std/src/Test.sol";
import { Goldilocked } from "../../../src/core/goldiswap/Goldilocked.sol";
import { Goldiswap } from "../../../src/core/goldiswap/Goldiswap.sol";

contract GoldilockedHandler is Test {

  Goldilocked public goldilocked;
  Goldiswap public goldiswap;

  uint256 public locksMintAmount = 100_000_000e18;

  uint256 public ghost_stakeSum;
  uint256 public ghost_unstakeSum;

  constructor(Goldilocked _goldilocked, Goldiswap _goldiswap) {
    goldilocked = _goldilocked;
    goldiswap = _goldiswap;
    deal(address(goldiswap), address(this), locksMintAmount);
    goldiswap.approve(address(goldilocked), locksMintAmount);
  }

  function stake(uint256 amount) public {
    amount = bound(amount, 0, goldiswap.balanceOf(address(this)));
    goldilocked.stake(amount);
    ghost_stakeSum += amount;
  }

  function unstake(uint256 amount) public {
    amount = bound(amount, 0, goldilocked.stakedLocks(address(this)));
    goldilocked.unstake(amount);
    ghost_unstakeSum += amount;
  }
}