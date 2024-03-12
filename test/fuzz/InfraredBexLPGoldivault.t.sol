//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { BaseTest } from "../BaseTest.t.sol";
import { FixedPointMathLib } from "../../lib/solady/src/utils/FixedPointMathLib.sol";
import { Goldivault } from "../../src/core/goldivault/Goldivault.sol";

contract FuzzInfraredBexLPGoldivaultTest is BaseTest {

  function testFuzzDepositBexLP(uint256 depositAmount) public {
    vm.assume(depositAmount < 1e40);
    deal(address(bexlp), address(this), depositAmount);
    bexlp.approve(address(goldivault), depositAmount);
    goldivault.deposit(depositAmount);

    assertEq(ot.balanceOf(address(this)), depositAmount);
    assertEq(yt.balanceOf(address(this)), depositAmount);
    assertEq(bexlp.balanceOf(address(this)), 0);
    assertEq(bexlp.balanceOf(address(goldivault)), 0);
    assertEq(bexlp.balanceOf(address(bexvault)), depositAmount);
  }

  function testFuzzRedeemYield(uint256 redeemAmount, uint256 duration) public {
    vm.assume(redeemAmount > 0 && redeemAmount < 1e40);
    vm.assume(duration > 365 days + 1 && duration < 1e40);
    deal(address(bexlp), address(this), redeemAmount);
    bexlp.approve(address(goldivault), redeemAmount);
    goldivault.deposit(redeemAmount);
    vm.warp(duration);
    goldivault.conclude();
    vm.warp(block.timestamp + 1 days + 1);
    goldivault.redeemYield(redeemAmount);

    assertEq(yt.balanceOf(address(this)), 0);
  }

  //todo: make differential
  function testFuzzRedeemOwnership(uint256 redeemAmount, uint256 duration) public {
    vm.assume(redeemAmount > 0 && redeemAmount < 1e40);
    vm.assume(duration > 100 && duration < 1e40);
    deal(address(bexlp), address(this), redeemAmount);
    bexlp.approve(address(goldivault), redeemAmount);
    goldivault.deposit(redeemAmount);
    vm.warp(duration);
    // uint256 remainingTime = block.timestamp > goldivault.endTime() ? 0 : goldivault.endTime() - block.timestamp;
    // uint256 timeshare = FixedPointMathLib.divWad(remainingTime, goldivault.duration());
    // uint256 ytBalance = yt.balanceOf(address(this));
    // uint256 bexlpBalance = remainingTime > 0 ? (redeemAmount * (1000 - goldivault.earlyWithdrawalFee()) / 1000) : redeemAmount;
    goldivault.redeemOwnership(redeemAmount);

    assertEq(ot.balanceOf(address(this)), 0);
    // assertEq(yt.balanceOf(address(this)), ytBalance - FixedPointMathLib.mulWad(redeemAmount, timeshare));
    // assertEq(bexlp.balanceOf(address(this)), bexlpBalance);
    assertEq(bexlp.balanceOf(address(bexvault)), 0);
  }

  function testFuzzConclude(uint256 duration) public {
    vm.assume(duration > 365 days + 1 && duration < 1e40);
    vm.warp(duration);
    goldivault.conclude();

    assertEq(goldivault.concluded(), true);
    assertEq(goldivault.concludeTime(), block.timestamp);
  }

  function testFuzzRenew(uint256 duration) public {
    vm.assume(duration > 365 days + 1 && duration < 1e40);
    vm.warp(duration);
    goldivault.conclude();
    goldivault.renew();

    assertEq(goldivault.concluded(), false);
    assertEq(goldivault.startTime(), block.timestamp);
    assertEq(goldivault.endTime(), block.timestamp + goldivault.duration());
  }

  function testFuzzAddYieldTokens(address[] memory yieldTokens) public {
    goldivault.addYieldTokens(yieldTokens);
    
    for(uint8 i; i < yieldTokens.length; ++i) {
      address yieldToken = goldivault.yieldTokens(1 + i);
      assertEq(yieldToken, yieldTokens[i]);
    }
  }
}