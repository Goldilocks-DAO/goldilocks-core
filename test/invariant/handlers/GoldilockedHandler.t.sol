//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { BaseHandler } from "../../base/BaseHandler.t.sol";
import { SafeTransferLib } from "../../../lib/solady/src/utils/SafeTransferLib.sol";
import { Goldilocked } from "../../../src/core/goldiswap/Goldilocked.sol";
import { Goldiswap } from "../../../src/core/goldiswap/Goldiswap.sol";

contract GoldilockedHandler is BaseHandler {

  Goldilocked public goldilocked;
  Goldiswap public goldiswap;

  uint256 public ghost_stakeSum;
  uint256 public ghost_unstakeSum;
  uint256 public ghost_zeroUnstakes;

  constructor(Goldilocked _goldilocked, Goldiswap _goldiswap) {
    goldilocked = _goldilocked;
    goldiswap = _goldiswap;
    deal(address(goldiswap), address(this), locksMintAmount);
  }

  function stake(uint256 amount) public createActor countCall("stake") {
    amount = bound(amount, 0, goldiswap.balanceOf(address(this)));

    sendLocks(currentActor, amount);
    vm.startPrank(currentActor);
    goldiswap.approve(address(goldilocked), amount);
    goldilocked.stake(amount);
    vm.stopPrank();

    ghost_stakeSum += amount;
  }

  function unstake(uint256 actorSeed, uint256 amount) public useActor(actorSeed) countCall("unstake") {
    amount = bound(amount, 0, goldilocked.stakedLocks(currentActor));
    if(amount == 0) ghost_zeroUnstakes++;

    vm.startPrank(currentActor);
    goldilocked.unstake(amount);
    sendLocks(address(this), amount);
    vm.stopPrank();

    ghost_unstakeSum += amount;
  }
  
  function approve(
    uint256 actorSeed,
    uint256 spenderSeed,
    uint256 amount
  ) public useActor(actorSeed) countCall("approve") {
    address spender = randomActor(spenderSeed);

    vm.prank(currentActor);
    goldilocked.approve(spender, amount);
  }

  function transfer(
    uint256 actorSeed,
    uint256 toSeed,
    uint256 amount
  ) public useActor(actorSeed) countCall("transfer") {
    address to = randomActor(toSeed);
    amount = bound(amount, 0, goldilocked.balanceOf(currentActor));

    vm.prank(currentActor);
    goldilocked.transfer(to, amount);
  }

  function transferFrom(
    uint256 actorSeed,
    uint256 fromSeed,
    uint256 toSeed,
    bool _approve,
    uint256 amount
  ) public useActor(actorSeed) countCall("transferFrom")
  {
    address from = randomActor(fromSeed);
    address to = randomActor(toSeed);

    amount = bound(amount, 0, goldilocked.balanceOf(from));

    if(_approve) {
      vm.prank(from);
      goldilocked.approve(currentActor, amount);
    }
    else {
      amount = bound(amount, 0, goldilocked.allowance(currentActor, from));
    }  

    vm.prank(currentActor);
    goldilocked.transferFrom(from, to, amount);
  }

  function sendLocks(address actor, uint256 amount) internal {
    SafeTransferLib.safeTransfer(address(goldiswap), actor, amount);
  }

}