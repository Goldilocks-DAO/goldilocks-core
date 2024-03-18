//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { BaseHandler } from "../../base/BaseHandler.t.sol";
import { Goldilend } from "../../../src/core/goldilend/Goldilend.sol";

contract GoldilendHandler is BaseHandler {

  Goldilend public goldilend;

  constructor(Goldilend _goldilend) {
    goldilend = _goldilend;
  }

  function approve(
    uint256 actorSeed,
    uint256 spenderSeed,
    uint256 amount
  ) public useActor(actorSeed) countCall("approve") {
    address spender = randomActor(spenderSeed);

    vm.prank(currentActor);
    goldilend.approve(spender, amount);
  }

  function transfer(
    uint256 actorSeed,
    uint256 toSeed,
    uint256 amount
  ) public useActor(actorSeed) countCall("transfer") {
    address to = randomActor(toSeed);
    amount = bound(amount, 0, goldilend.balanceOf(currentActor));

    vm.prank(currentActor);
    goldilend.transfer(to, amount);
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

    amount = bound(amount, 0, goldilend.balanceOf(from));

    if(_approve) {
      vm.prank(from);
      goldilend.approve(currentActor, amount);
    }
    else {
      amount = bound(amount, 0, goldilend.allowance(currentActor, from));
    }  

    vm.prank(currentActor);
    goldilend.transferFrom(from, to, amount);
  }

}