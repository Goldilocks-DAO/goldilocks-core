//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { BaseHandler } from "../../base/BaseHandler.t.sol";
import { SafeTransferLib } from "../../../lib/solady/src/utils/SafeTransferLib.sol";
import { RebaseGoldilend } from "../../../src/core/goldilend/RebaseGoldilend.sol";
import { GoldilendDebtAsset } from "../../../src/core/goldilend/GoldilendDebtAsset.sol";
import { Honey } from "../../../src/mock/Honey.sol";

contract RebaseGoldilendHandler is BaseHandler {

  RebaseGoldilend public rebasegoldilend;
  GoldilendDebtAsset public glhoney;
  Honey public honey;

  uint256 public ghost_depositSum;
  uint256 public ghost_withdrawSum;
  uint256 public ghost_zeroWithdraws;

  constructor(address _rebaseproxy, GoldilendDebtAsset _glhoney, Honey _honey) {
    rebasegoldilend = RebaseGoldilend(_rebaseproxy);
    glhoney = _glhoney;
    honey = _honey;
    deal(address(honey), address(this), 100_000e18);
  }

  function deposit(uint256 amount) public createActor countCall("deposit") {
    amount = bound(amount, 0, honey.balanceOf(address(this)));

    sendHoney(currentActor, amount);
    vm.startPrank(currentActor);
    honey.approve(address(rebasegoldilend), amount);
    rebasegoldilend.deposit(amount);
    vm.stopPrank();

    ghost_depositSum += amount;
  }

  function withdraw(uint256 actorSeed, uint256 amount) public useActor(actorSeed) countCall("withdraw") {
    amount = bound(amount, 0, glhoney.balanceOf(currentActor));
    if(amount == 0) ghost_zeroWithdraws++;

    vm.startPrank(currentActor);
    rebasegoldilend.withdraw(amount);
    vm.stopPrank();

    ghost_withdrawSum += amount;
  }

  function approve(
    uint256 actorSeed,
    uint256 spenderSeed,
    uint256 amount
  ) public useActor(actorSeed) countCall("approve") {
    address spender = randomActor(spenderSeed);

    vm.prank(currentActor);
    glhoney.approve(spender, amount);
  }

  function transfer(
    uint256 actorSeed,
    uint256 toSeed,
    uint256 amount
  ) public useActor(actorSeed) countCall("transfer") {
    address to = randomActor(toSeed);
    amount = bound(amount, 0, glhoney.balanceOf(currentActor));

    vm.prank(currentActor);
    glhoney.transfer(to, amount);
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

    amount = bound(amount, 0, glhoney.balanceOf(from));

    if(_approve) {
      vm.prank(from);
      glhoney.approve(currentActor, amount);
    }
    else {
      amount = bound(amount, 0, glhoney.allowance(currentActor, from));
    }  

    vm.prank(currentActor);
    glhoney.transferFrom(from, to, amount);
  }

  function sendHoney(address actor, uint256 amount) internal {
    SafeTransferLib.safeTransfer(address(honey), actor, amount);
  }

}