//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../lib/forge-std/src/Test.sol";
import { BaseTest } from "../BaseTest.t.sol";
import { Goldivault } from "../../src/core/Goldivault.sol";

contract UnitGoldivaultTest is BaseTest {

  function testDepositFailTime() public {
    vm.warp(1 + 364 days + 69);
    vm.expectRevert(abi.encodeWithSelector(Goldivault.InsufficientTime.selector));
    goldivault.deposit(69);
  }

  function testDepositSuccess() public {
    depositUnit();

    assertEq(ot.balanceOf(address(this)), txAmount);
    assertEq(yt.balanceOf(address(this)), txAmount);
    assertEq(unit.balanceOf(address(this)), 0);
  }

  function testRedeemYieldFailConcluded() public {
    vm.expectRevert(abi.encodeWithSelector(Goldivault.NotConcluded.selector));
    goldivault.redeemYield(txAmount);
  }

  function testRedeemYieldDistribute() public {
    depositUnit();
    deal(address(ibgt), address(goldivault), 69);
    vm.warp(366 days);
    goldivault.conclude();
    vm.warp(block.timestamp + 1 days + 1);
    goldivault.redeemYield(txAmount);

    assertEq(ibgt.balanceOf(address(this)), 69);
    assertEq(yt.balanceOf(address(this)), 0);
  }

  function testRedeemYieldSuccess() public {
    depositUnit();
    vm.warp(366 days);
    goldivault.conclude();
    vm.warp(block.timestamp + 1 days + 1);
    goldivault.redeemYield(txAmount);

    assertEq(yt.balanceOf(address(this)), 0);
  }

  function testRedeemOwnershipRemainingTime() public {
    depositUnit();
    vm.warp(180 days);
    goldivault.redeemOwnership(txAmount);

    assertEq(ot.balanceOf(address(this)), 0);
    assertEq(unit.balanceOf(address(this)), txAmount);
  }

  function testRedeemOwnershipRemainingTimeNonMultisig() public {
    deal(address(unit), address(0xbbb), txAmount);
    vm.startPrank(address(0xbbb));
    unit.approve(address(goldivault), txAmount);
    goldivault.deposit(txAmount);
    vm.stopPrank();
    vm.warp(180 days);
    vm.prank(address(0xbbb));
    goldivault.redeemOwnership(txAmount);

    assertEq(ot.balanceOf(address(this)), 0);
    assertEq(unit.balanceOf(address(0xbbb)), 97e17);
    assertEq(unit.balanceOf(address(this)), 3e17);
  }

  //todo: fix
  function testRedeemOwnershipSuccess() public {
    depositUnit();
    vm.warp(366 days);
    goldivault.redeemOwnership(txAmount);

    assertEq(ot.balanceOf(address(this)), 0);
    // assertEq(yt.balanceOf(address(this)), 0);
    assertEq(unit.balanceOf(address(this)), txAmount);
  }

  function testConcludeFailExpired() public {
    vm.expectRevert(abi.encodeWithSelector(Goldivault.NotExpired.selector));
    goldivault.conclude();
  }

  function testConcludeFailAlready() public {
    vm.warp(366 days);
    goldivault.conclude();
    vm.expectRevert(abi.encodeWithSelector(Goldivault.AlreadyConcluded.selector));
    goldivault.conclude();
  }

  function testConcludeSuccess() public {
    vm.warp(366 days);
    goldivault.conclude();

    assertEq(goldivault.concluded(), true);
    assertEq(goldivault.concludeTime(), block.timestamp);
  }

  function testRenewFailConcluded() public {
    vm.expectRevert(abi.encodeWithSelector(Goldivault.NotConcluded.selector));
    goldivault.renew();
  }

  function testRenewSuccess() public {
    vm.warp(366 days);
    goldivault.conclude();
    goldivault.renew();

    assertEq(goldivault.concluded(), false);
    assertEq(goldivault.startTime(), block.timestamp);
    assertEq(goldivault.endTime(), block.timestamp + 365 days);
  }

  function testCompoundSuccess() public {
    goldivault.compound();
  }

  function testAddYieldTokensFailMultisig() public {
    address[] memory yieldTokens = new address[](0);
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(Goldivault.NotMultisig.selector));
    goldivault.addYieldTokens(yieldTokens);
  }

  function testAddYieldTokensSuccess() public {
    address[] memory yieldTokens = new address[](1);
    yieldTokens[0] = address(0x69);
    goldivault.addYieldTokens(yieldTokens);
    address yieldToken = goldivault.yieldTokens(1);
    
    assertEq(yieldToken, address(0x69));
  }

  function testSetEarlyWithdrawalFeeFailMultisig() public {
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(Goldivault.NotMultisig.selector));
    goldivault.setEarlyWithdrawalFee(69);
  }

  function testSetEarlyWithdrawalFeeSuccess() public {    
    goldivault.setEarlyWithdrawalFee(69);

    assertEq(goldivault.earlyWithdrawalFee(), 69);
  }

  function testSetParametersFailMultisig() public {
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(Goldivault.NotMultisig.selector));
    goldivault.setParameters(69, 69, 69);
  }

  function testSetParametersSuccess() public {
    goldivault.setParameters(69, 69, 69);

    assertEq(goldivault.yieldFee(), 69);
    assertEq(goldivault.delay(), 69);
    assertEq(goldivault.duration(), 69);
  }
}