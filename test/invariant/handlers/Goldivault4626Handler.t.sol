//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { BaseHandler } from "../../base/BaseHandler.t.sol";
import { SafeTransferLib } from "../../../lib/solady/src/utils/SafeTransferLib.sol";
import { Goldivault4626 } from "../../../src/core/goldivault/Goldivault4626.sol";
import { OwnershipToken } from "../../../src/core/goldivault/OwnershipToken.sol";
import { YieldToken } from "../../../src/core/goldivault/YieldToken.sol";
import { iBGT } from "../../../src/mock/iBGT.sol";
import { oriBGT } from "../../../src/mock/oriBGT.sol";

contract Goldivault4626Handler is BaseHandler {

  Goldivault4626 public oribgtgoldivault;
  OwnershipToken public oribgtot;
  YieldToken public oribgtyt;
  iBGT public ibgt;
  oriBGT public oribgt;

  constructor(
    Goldivault4626 _oribgtgoldivault,
    OwnershipToken _oribgtot,
    YieldToken _oribgtyt,
    iBGT _ibgt,
    oriBGT _oribgt
  ) {
    oribgtgoldivault = _oribgtgoldivault;
    oribgtot = _oribgtot;
    oribgtyt = _oribgtyt;
    ibgt = _ibgt;
    oribgt = _oribgt;
    deal(address(ibgt), address(this), 100_000e18);
  }

  function deposit(uint256 amount) public createActor countCall("deposit") {
    amount = bound(amount, 0, 20_000_000e18);
    sendIbgt(currentActor, 10_000e18);

    vm.startPrank(currentActor);
    ibgt.approve(address(oribgtgoldivault), amount);
    oribgtyt.approve(address(oribgtgoldivault), amount);
    oribgtgoldivault.deposit(amount);
    vm.stopPrank();
  }

  function redeemOwnership(uint256 actorSeed, uint256 amount) public useActor(actorSeed) countCall("redeem") {
    amount = bound(amount, 0, oribgtot.balanceOf(currentActor));

    vm.prank(currentActor);
    oribgtgoldivault.redeemOwnership(amount);
  }

  function stakeYT(uint256 actorSeed, uint256 amount) public useActor(actorSeed) countCall("stake") {
    amount = bound(amount, 0, oribgtyt.balanceOf(currentActor));

    vm.prank(currentActor);
    oribgtgoldivault.stakeYT(amount);
  }

  function unstakeYT(uint256 actorSeed, uint256 amount) public useActor(actorSeed) countCall("unstake") {
    amount = bound(amount, 0, oribgtgoldivault.ytStaked(currentActor));
    
    vm.prank(currentActor);
    oribgtgoldivault.unstakeYT(amount);
  }

  function approveot(
    uint256 actorSeed,
    uint256 spenderSeed,
    uint256 amount
  ) public useActor(actorSeed) countCall("approve") {
    address spender = randomActor(spenderSeed);

    vm.prank(currentActor);
    oribgtot.approve(spender, amount);
  }

  function transferot(
    uint256 actorSeed,
    uint256 toSeed,
    uint256 amount
  ) public useActor(actorSeed) countCall("transfer") {
    address to = randomActor(toSeed);
    amount = bound(amount, 0, oribgtot.balanceOf(currentActor));

    vm.prank(currentActor);
    oribgtot.transfer(to, amount);
  }

  function transferFromot(
    uint256 actorSeed,
    uint256 fromSeed,
    uint256 toSeed,
    bool _approve,
    uint256 amount
  ) public useActor(actorSeed) countCall("transferFrom")
  {
    address from = randomActor(fromSeed);
    address to = randomActor(toSeed);
    amount = bound(amount, 0, oribgtot.balanceOf(from));
    if(_approve) {
      vm.prank(from);
      oribgtot.approve(currentActor, amount);
    }
    else {
      amount = bound(amount, 0, oribgtot.allowance(currentActor, from));
    }  
    vm.prank(currentActor);
    oribgtot.transferFrom(from, to, amount);
  }

  function approveyt(
    uint256 actorSeed,
    uint256 spenderSeed,
    uint256 amount
  ) public useActor(actorSeed) countCall("approve") {
    address spender = randomActor(spenderSeed);

    vm.prank(currentActor);
    oribgtyt.approve(spender, amount);
  }

  function transferyt(
    uint256 actorSeed,
    uint256 toSeed,
    uint256 amount
  ) public useActor(actorSeed) countCall("transfer") {
    address to = randomActor(toSeed);
    amount = bound(amount, 0, oribgtyt.balanceOf(currentActor));

    vm.prank(currentActor);
    oribgtyt.transfer(to, amount);
  }

  function transferFromyt(
    uint256 actorSeed,
    uint256 fromSeed,
    uint256 toSeed,
    bool _approve,
    uint256 amount
  ) public useActor(actorSeed) countCall("transferFrom")
  {
    address from = randomActor(fromSeed);
    address to = randomActor(toSeed);
    amount = bound(amount, 0, oribgtyt.balanceOf(from));
    if(_approve) {
      vm.prank(from);
      oribgtyt.approve(currentActor, amount);
    }
    else {
      amount = bound(amount, 0, oribgtyt.allowance(currentActor, from));
    }  
    vm.prank(currentActor);
    oribgtyt.transferFrom(from, to, amount);
  }

  function accumulateYield(uint256 amount) public countCall("accumulate") {
    deal(address(ibgt), address(oribgt), ibgt.balanceOf(address(oribgt)) + amount);
  }

  function sendIbgt(address actor, uint256 amount) internal {
    SafeTransferLib.safeTransfer(address(ibgt), actor, amount);
  }

}