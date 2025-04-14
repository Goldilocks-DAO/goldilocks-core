//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { BaseHandler } from "../../base/BaseHandler.t.sol";
import { SafeTransferLib } from "../../../lib/solady/src/utils/SafeTransferLib.sol";
import { Goldivault4626 } from "../../../src/core/goldivault/Goldivault4626.sol";
import { OwnershipToken } from "../../../src/core/goldivault/OwnershipToken.sol";
import { YieldToken } from "../../../src/core/goldivault/YieldToken.sol";
import { iBGT } from "../../../src/mock/iBGT.sol";

contract Goldivault4626Handler is BaseHandler {

  Goldivault4626 public oribgtgoldivault;
  OwnershipToken public oribgtot;
  YieldToken public oribgtyt;
  iBGT public ibgt;

  constructor(
    Goldivault4626 _oribgtgoldivault,
    OwnershipToken _oribgtot,
    YieldToken _oribgtyt,
    iBGT _ibgt
  ) {
    oribgtgoldivault = _oribgtgoldivault;
    oribgtot = _oribgtot;
    oribgtyt = _oribgtyt;
    ibgt = _ibgt;
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

  function sendIbgt(address actor, uint256 amount) internal {
    SafeTransferLib.safeTransfer(address(ibgt), actor, amount);
  }

}