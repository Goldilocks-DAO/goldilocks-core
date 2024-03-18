//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../../lib/forge-std/src/Test.sol";
import { BaseHandler } from "../../base/BaseHandler.t.sol";
import { SafeTransferLib } from "../../../lib/solady/src/utils/SafeTransferLib.sol";
import { Goldilocked } from "../../../src/core/goldiswap/Goldilocked.sol";
import { Goldiswap } from "../../../src/core/goldiswap/Goldiswap.sol";
import { GovLocks } from "../../../src/core/goldigovernance/GovLocks.sol";

contract GovLocksHandler is BaseHandler {

  Goldilocked public goldilocked;
  Goldiswap public goldiswap;
  GovLocks public govlocks;

  uint256 public ghost_depositSum;
  uint256 public ghost_withdrawSum;
  uint256 public ghost_zeroWithdrawals;

  constructor(GovLocks _govlocks, Goldilocked _goldilocked, Goldiswap _goldiswap) {
    goldilocked = _goldilocked;
    goldiswap = _goldiswap;
    govlocks =_govlocks;
    deal(address(goldiswap), address(this), locksMintAmount);
    // goldiswap.approve(address(govlocks), type(uint256).max);
  }

  function deposit(uint256 amount) public createActor countCall("deposit") {
    amount = bound(amount, 0, goldiswap.balanceOf(address(this)));

    sendLocks(currentActor, amount);
    vm.startPrank(currentActor);
    goldiswap.approve(address(govlocks), amount);
    govlocks.deposit(amount);
    vm.stopPrank();

    ghost_depositSum += amount;
  }

  function withdraw(
    uint256 actorSeed,
    uint256 amount
  ) 
    public
    useActor(actorSeed)
    countCall("withdraw")
  {
    amount = bound(amount, 0, govlocks.balanceOf(currentActor));
    if(amount == 0) ghost_zeroWithdrawals++;

    vm.startPrank(currentActor);
    govlocks.withdraw(amount);
    sendLocks(address(this), amount);
    vm.stopPrank();

    ghost_withdrawSum += amount;
  }

  function delegate(
    uint256 actorSeed,
    address delegatee
  )
    public
    useActor(actorSeed)
    countCall("delegate")
  {
    vm.prank(currentActor);
    govlocks.delegate(delegatee);
  }

  function approve(
    uint256 actorSeed,
    uint256 spenderSeed,
    uint256 amount
  ) public useActor(actorSeed) countCall("approve") {
    address spender = randomActor(spenderSeed);

    vm.prank(currentActor);
    govlocks.approve(spender, amount);
  }

  function transfer(
    uint256 actorSeed,
    uint256 toSeed,
    uint256 amount
  ) public useActor(actorSeed) countCall("transfer") {
    address to = randomActor(toSeed);
    amount = bound(amount, 0, govlocks.balanceOf(currentActor));

    vm.prank(currentActor);
    govlocks.transfer(to, amount);
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

    amount = bound(amount, 0, govlocks.balanceOf(from));

    if(_approve) {
      vm.prank(from);
      govlocks.approve(currentActor, amount);
    }
    else {
      amount = bound(amount, 0, govlocks.allowance(currentActor, from));
    }  

    vm.prank(currentActor);
    govlocks.transferFrom(from, to, amount);
  }

  function sendLocks(address actor, uint256 amount) internal {
    SafeTransferLib.safeTransfer(address(goldiswap), actor, amount);
  }

  // function callSummary() external view {
  //   console.log("call summary:");
  //   console.log("-------------------");
  //   console.log("deposit", calls["deposit"]);
  //   console.log("withdraw", calls["withdraw"]);
  //   console.log("delegate", calls["delegate"]);
  //   console.log("-------------------");

  //   console.log("Zero withdrawals:", ghost_zeroWithdrawals);
  // }
}