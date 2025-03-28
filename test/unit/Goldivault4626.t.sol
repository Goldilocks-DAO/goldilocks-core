//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { BaseUnitTest } from "../base/BaseUnitTest.t.sol";
import { IGoldivault4626 } from "../../src/interfaces/IGoldivault4626.sol";

contract UnitGoldivault4626Test is BaseUnitTest {

  address user = address(0xabc123);
  uint256 depositAmt = 100e18;

  function testDepositFailInvalid() public {
    vm.expectRevert(abi.encodeWithSelector(IGoldivault4626.InvalidDeposit.selector));
    vm.prank(user);
    oribgtgoldivault.deposit(0);
  }

  function testDepositSuccess() public {
    deal(address(ibgt), user, depositAmt);
    vm.startPrank(user);
    ibgt.approve(address(oribgtgoldivault), depositAmt);
    oribgtyt.approve(address(oribgtgoldivault), depositAmt);
    oribgtgoldivault.deposit(depositAmt);
    vm.stopPrank();

    assertEq(oribgtgoldivault.ytStaked(user), depositAmt);
    assertEq(oribgtot.balanceOf(user), depositAmt);
    assertEq(oribgtyt.balanceOf(user), 0);
    assertEq(oribgtgoldivault.totalYtStaked(), depositAmt);
    assertEq(ibgt.balanceOf(user), 0);
    assertEq(oribgt.balanceOf(address(oribgtgoldivault)), depositAmt);
    assertEq(ibgt.balanceOf(address(oribgtgoldivault)), 0);
    assertEq(ibgt.balanceOf(address(oribgt)), depositAmt);
  }

  function testRedeemOwnershipFailInvalid() public {
    vm.expectRevert(abi.encodeWithSelector(IGoldivault4626.InvalidRedemption.selector));
    vm.prank(user);
    oribgtgoldivault.redeemOwnership(0);
  }

  function testRedeemOwnershipSuccess() public {
    deal(address(ibgt), user, depositAmt);
    vm.startPrank(user);
    ibgt.approve(address(oribgtgoldivault), depositAmt);
    oribgtyt.approve(address(oribgtgoldivault), depositAmt);
    oribgtgoldivault.deposit(depositAmt);
    oribgtgoldivault.redeemOwnership(depositAmt);
    vm.stopPrank();

    assertEq(oribgtgoldivault.ytStaked(user), 0);
    assertEq(oribgtot.balanceOf(user), 0);
    assertEq(oribgtyt.balanceOf(user), 0);
    assertEq(oribgtgoldivault.totalYtStaked(), 0);
    assertEq(ibgt.balanceOf(user), depositAmt);
    assertEq(oribgt.balanceOf(address(oribgtgoldivault)), 0);
    assertEq(ibgt.balanceOf(address(oribgtgoldivault)), 0);
    assertEq(ibgt.balanceOf(address(oribgt)), 0);
  }

  function testRedeemOwnershipNoRemainingTimeSuccess() public {
    deal(address(ibgt), user, depositAmt);
    vm.startPrank(user);
    ibgt.approve(address(oribgtgoldivault), depositAmt);
    oribgtyt.approve(address(oribgtgoldivault), depositAmt);
    oribgtgoldivault.deposit(depositAmt);
    vm.stopPrank();

    vm.warp(block.timestamp + 366 days);
    vm.prank(user);
    oribgtgoldivault.redeemOwnership(depositAmt);

    assertEq(oribgtgoldivault.ytStaked(user), 0);
    assertEq(oribgtot.balanceOf(user), 0);
    assertEq(oribgtyt.balanceOf(user), depositAmt);
    assertEq(oribgtgoldivault.totalYtStaked(), 0);
    assertEq(ibgt.balanceOf(user), depositAmt);
    assertEq(oribgt.balanceOf(address(oribgtgoldivault)), 0);
    assertEq(ibgt.balanceOf(address(oribgtgoldivault)), 0);
    assertEq(ibgt.balanceOf(address(oribgt)), 0);
  }

  function testStakeYTSuccess() public {
    deal(address(oribgtyt), user, depositAmt);
    vm.startPrank(user);
    oribgtyt.approve(address(oribgtgoldivault), depositAmt);
    oribgtgoldivault.stakeYT(depositAmt);
    vm.stopPrank();

    assertEq(oribgtgoldivault.ytStaked(user), depositAmt);
    assertEq(oribgtgoldivault.totalYtStaked(), depositAmt);
    assertEq(oribgtyt.balanceOf(address(oribgtgoldivault)), depositAmt);
    assertEq(oribgtyt.balanceOf(user), 0);
  }

  function testUnstakeYTFailInvalid() public {
    deal(address(oribgtyt), user, depositAmt);
    vm.startPrank(user);
    oribgtyt.approve(address(oribgtgoldivault), depositAmt);
    oribgtgoldivault.stakeYT(depositAmt);
    vm.expectRevert(abi.encodeWithSelector(IGoldivault4626.InvalidUnstake.selector));
    oribgtgoldivault.unstakeYT(depositAmt + 1);
    vm.stopPrank();
  }

  function testUntakeYTSuccess() public {
    deal(address(oribgtyt), user, depositAmt);
    vm.startPrank(user);
    oribgtyt.approve(address(oribgtgoldivault), depositAmt);
    oribgtgoldivault.stakeYT(depositAmt);
    oribgtgoldivault.unstakeYT(depositAmt);
    vm.stopPrank();

    assertEq(oribgtgoldivault.ytStaked(user), 0);
    assertEq(oribgtgoldivault.totalYtStaked(), 0);
    assertEq(oribgtyt.balanceOf(address(oribgtgoldivault)), 0);
    assertEq(oribgtyt.balanceOf(user), depositAmt);
  }

}