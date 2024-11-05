//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { BaseFuzzTest } from "../base/BaseFuzzTest.t.sol";
import { Goldivault } from "../../src/core/goldivault/Goldivault.sol";

contract FuzzGoldivaultTest is BaseFuzzTest {

  function testFuzzDepositBexLP(uint256 depositAmount) public {
    vm.assume(depositAmount < 1e40);
    deal(address(bexlp), address(this), depositAmount);
    bexlp.approve(address(goldivault), depositAmount);
    goldivault.deposit(depositAmount);

    assertEq(ot.balanceOf(address(this)), depositAmount);
    assertEq(yt.balanceOf(address(this)), depositAmount);
    assertEq(bexlp.balanceOf(address(this)), 0);
    assertEq(bexlp.balanceOf(address(goldivault)), depositAmount);
    assertEq(bexlp.balanceOf(address(bexvault)), 0);
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

  function testFuzzRedeemOwnership(uint256 redeemAmount, uint256 duration) public {
    vm.assume(redeemAmount > 0 && redeemAmount < 1e40);
    vm.assume(duration > 100 && duration < 1e40);
    deal(address(bexlp), address(this), redeemAmount);
    bexlp.approve(address(goldivault), redeemAmount);
    goldivault.deposit(redeemAmount);
    vm.warp(duration);
    goldivault.redeemOwnership(redeemAmount);

    assertEq(ot.balanceOf(address(this)), 0);
    assertEq(bexlp.balanceOf(address(bexvault)), 0);
  }

  function testFuzzConclude(uint256 duration) public {
    vm.assume(duration > 365 days + 1 && duration < 1e40);
    vm.warp(duration);
    goldivault.conclude();
    assertEq(goldivault.concludeTime(), block.timestamp);
  }

  function testFuzzRenew(uint256 duration) public {
    vm.assume(duration > 365 days + 1 && duration < 1e40);
    vm.warp(duration);
    goldivault.conclude();
    vm.prank(address(timelock));
    goldivault.renew();

    assertEq(goldivault.startTime(), block.timestamp);
    assertEq(goldivault.endTime(), block.timestamp + goldivault.duration());
  }

}