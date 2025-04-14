//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { BaseFuzzTest } from "../base/BaseFuzzTest.t.sol";

contract FuzzGoldivault4626Test is BaseFuzzTest {

  address user = address(0xabc123);

  function testFuzzDeposit(uint256 depositAmt) public {
    vm.assume(depositAmt > 0);
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

  function testFuzzRedeemOwnership(uint256 redeemAmt) public {
    vm.assume(redeemAmt > 0 && redeemAmt < 1e70);
    deal(address(ibgt), user, redeemAmt);
    vm.startPrank(user);
    ibgt.approve(address(oribgtgoldivault), redeemAmt);
    oribgtyt.approve(address(oribgtgoldivault), redeemAmt);
    oribgtgoldivault.deposit(redeemAmt);
    oribgtgoldivault.redeemOwnership(redeemAmt);
    vm.stopPrank();

    assertEq(oribgtgoldivault.ytStaked(user), 0);
    assertEq(oribgtot.balanceOf(user), 0);
    assertEq(oribgtyt.balanceOf(user), 0);
    assertEq(oribgtgoldivault.totalYtStaked(), 0);
    assertEq(ibgt.balanceOf(user), redeemAmt);
    assertEq(oribgt.balanceOf(address(oribgtgoldivault)), 0);
    assertEq(ibgt.balanceOf(address(oribgtgoldivault)), 0);
    assertEq(ibgt.balanceOf(address(oribgt)), 0);
  }

  function testFuzzStakeYt(uint256 stakeAmt) public {
    deal(address(oribgtyt), user, stakeAmt);
    vm.startPrank(user);
    oribgtyt.approve(address(oribgtgoldivault), stakeAmt);
    oribgtgoldivault.stakeYT(stakeAmt);
    vm.stopPrank();

    assertEq(oribgtgoldivault.ytStaked(user), stakeAmt);
    assertEq(oribgtgoldivault.totalYtStaked(), stakeAmt);
    assertEq(oribgtyt.balanceOf(address(oribgtgoldivault)), stakeAmt);
    assertEq(oribgtyt.balanceOf(user), 0);
  }

  function testFuzzUnstakeYt(uint256 unstakeAmt) public {
    deal(address(oribgtyt), user, unstakeAmt);
    vm.startPrank(user);
    oribgtyt.approve(address(oribgtgoldivault), unstakeAmt);
    oribgtgoldivault.stakeYT(unstakeAmt);
    oribgtgoldivault.unstakeYT(unstakeAmt);
    vm.stopPrank();

    assertEq(oribgtgoldivault.ytStaked(user), 0);
    assertEq(oribgtgoldivault.totalYtStaked(), 0);
    assertEq(oribgtyt.balanceOf(address(oribgtgoldivault)), 0);
    assertEq(oribgtyt.balanceOf(user), unstakeAmt);
  }
}