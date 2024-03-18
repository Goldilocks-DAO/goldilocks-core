//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { BaseHandler } from "../../base/BaseHandler.t.sol";
import { FixedPointMathLib } from "../../../lib/solady/src/utils/FixedPointMathLib.sol";
import { SafeTransferLib } from "../../../lib/solady/src/utils/SafeTransferLib.sol";
import { Goldiswap } from "../../../src/core/goldiswap/Goldiswap.sol";
import { Honey } from "../../../src/mock/Honey.sol";

contract GoldiswapHandler is BaseHandler {

  Goldiswap public goldiswap;
  Honey public honey;

  constructor(Goldiswap _goldiswap, Honey _honey) {
    goldiswap = _goldiswap;
    honey = _honey;
    deal(address(honey), address(this), 100_000e18);
  }

  function buy(uint256 amount) public createActor countCall("buy") {
    amount = bound(amount, 0, 3_000_000e18);
    sendHoney(currentActor, 40_000e18);
    
    vm.startPrank(currentActor);
    honey.approve(address(goldiswap), type(uint256).max);
    goldiswap.buy(amount, type(uint256).max);
    sendHoney(address(this), honey.balanceOf(currentActor));
    vm.stopPrank();
  }

  function sell(uint256 actorSeed, uint256 amount) public useActor(actorSeed) countCall("sell") {
    amount = bound(amount, 0, goldiswap.balanceOf(currentActor));

    vm.prank(currentActor);
    goldiswap.sell(amount, 0);
  }

  function redeem(uint256 actorSeed, uint256 amount) public useActor(actorSeed) countCall("redeem") {
    amount = bound(amount, 0, goldiswap.balanceOf(currentActor));

    vm.prank(currentActor);
    goldiswap.redeem(amount);
  }

  function approve(
    uint256 actorSeed,
    uint256 spenderSeed,
    uint256 amount
  ) public useActor(actorSeed) countCall("approve") {
    address spender = randomActor(spenderSeed);

    vm.prank(currentActor);
    goldiswap.approve(spender, amount);
  }

  function transfer(
    uint256 actorSeed,
    uint256 toSeed,
    uint256 amount
  ) public useActor(actorSeed) countCall("transfer") {
    address to = randomActor(toSeed);
    amount = bound(amount, 0, goldiswap.balanceOf(currentActor));

    vm.prank(currentActor);
    goldiswap.transfer(to, amount);
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

    amount = bound(amount, 0, goldiswap.balanceOf(from));

    if(_approve) {
      vm.prank(from);
      goldiswap.approve(currentActor, amount);
    }
    else {
      amount = bound(amount, 0, goldiswap.allowance(currentActor, from));
    }  

    vm.prank(currentActor);
    goldiswap.transferFrom(from, to, amount);
  }

  function sendHoney(address actor, uint256 amount) internal {
    SafeTransferLib.safeTransfer(address(honey), actor, amount);
  }

}