//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../lib/forge-std/src/Test.sol";
import { BaseTest } from "../BaseTest.t.sol";
import { Goldivault } from "../../src/core/goldivault/Goldivault.sol";
import { OwnershipToken } from "../../src/core/goldivault/OwnershipToken.sol";
import { YieldToken } from "../../src/core/goldivault/YieldToken.sol";

contract UnitInfraredBexLPGoldivaultTest is BaseTest {

  function testOTName() public {
    assertEq(ot.name(), "oBexLPToken");
  }

  function testOTSymbol() public {
    assertEq(ot.symbol(), "oBEXLP");
  }

  function testYTName() public {
    assertEq(yt.name(), "yBexLPToken");
  }

  function testYTSymbol() public {
    assertEq(yt.symbol(), "yBEXLP");
  }

  function testMintOTFailVault() public {
    vm.prank(address(0xdddd));
    vm.expectRevert(abi.encodeWithSelector(OwnershipToken.NotVault.selector));
    ot.mintOT(address(this), 69);
  }

  function testBurnOTFailVault() public {
    vm.prank(address(0xdddd));
    vm.expectRevert(abi.encodeWithSelector(OwnershipToken.NotVault.selector));
    ot.burnOT(address(this), 69);
  }

  function testMintYTFailVault() public {
    vm.prank(address(0xdddd));
    vm.expectRevert(abi.encodeWithSelector(YieldToken.NotVault.selector));
    yt.mintYT(address(this), 69);
  }

  function testBurnYTFailVault() public {
    vm.prank(address(0xdddd));
    vm.expectRevert(abi.encodeWithSelector(YieldToken.NotVault.selector));
    yt.burnYT(address(this), 69);
  }

  function testDepositFailTime() public {
    vm.warp(1 + 364 days + 69);
    vm.expectRevert(abi.encodeWithSelector(Goldivault.InsufficientTime.selector));
    goldivault.deposit(69);
  }

  function testDepositSuccess() public {
    depositBexLP();

    assertEq(ot.balanceOf(address(this)), txAmount);
    assertEq(yt.balanceOf(address(this)), txAmount);
    assertEq(bexlp.balanceOf(address(this)), 0);
    assertEq(bexlp.balanceOf(address(goldivault)), 0);
    assertEq(bexlp.balanceOf(address(bexvault)), txAmount);
  }

  function testRedeemYieldFailInvalid() public {
    vm.expectRevert(abi.encodeWithSelector(Goldivault.InvalidRedemption.selector));
    goldivault.redeemYield(0);
  }

  function testRedeemYieldFailConcluded() public {
    vm.expectRevert(abi.encodeWithSelector(Goldivault.NotConcluded.selector));
    goldivault.redeemYield(txAmount);
  }

  function testRedeemYieldDistribute() public {
    depositBexLP();    
    vm.warp(366 days);
    goldivault.conclude();
    vm.warp(block.timestamp + 1 days + 1);
    goldivault.redeemYield(txAmount);

    assertEq(ibgt.balanceOf(address(this)), yearMockBexLPYield);
    assertEq(yt.balanceOf(address(this)), 0);
  }

  function testRedeemYieldSuccess() public {
    depositBexLP();
    vm.warp(366 days);
    goldivault.conclude();
    vm.warp(block.timestamp + 1 days + 1);
    goldivault.redeemYield(txAmount);

    assertEq(yt.balanceOf(address(this)), 0);
  }

  function testRedeemOwnershipFailInvalid() public {
    vm.expectRevert(abi.encodeWithSelector(Goldivault.InvalidRedemption.selector));
    goldivault.redeemOwnership(0);
  }

  function testRedeemOwnershipRemainingTime() public {
    depositBexLP();
    vm.warp(180 days);
    goldivault.redeemOwnership(txAmount);

    assertEq(ot.balanceOf(address(this)), 0);
    assertEq(bexlp.balanceOf(address(this)), txAmount);
  }

  function testRedeemOwnershipRemainingTimeNonMultisig() public {
    deal(address(bexlp), address(0xbbb), txAmount);
    vm.startPrank(address(0xbbb));
    bexlp.approve(address(goldivault), txAmount);
    goldivault.deposit(txAmount);
    vm.stopPrank();
    vm.warp(180 days);
    vm.prank(address(0xbbb));
    goldivault.redeemOwnership(txAmount);

    assertEq(ot.balanceOf(address(this)), 0);
    assertEq(bexlp.balanceOf(address(0xbbb)), 97e17);
    assertEq(bexlp.balanceOf(address(this)), 3e17);
  }

  function testRedeemOwnershipSuccess() public {
    depositBexLP();
    vm.warp(366 days);
    goldivault.redeemOwnership(txAmount);

    assertEq(ot.balanceOf(address(this)), 0);
    assertEq(yt.balanceOf(address(this)), txAmount);
    assertEq(bexlp.balanceOf(address(this)), txAmount);
    assertEq(bexlp.balanceOf(address(bexvault)), 0);
  }

  function testRedeemOwnershipSuccessHalf() public {
    depositBexLP();
    vm.warp(1 + (365 days / 2));
    goldivault.redeemOwnership(txAmount);

    assertEq(ot.balanceOf(address(this)), 0);
    assertEq(yt.balanceOf(address(this)), txAmount / 2);
    assertEq(bexlp.balanceOf(address(this)), txAmount);
    assertEq(bexlp.balanceOf(address(bexvault)), 0);
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

  function testRenewFailMultisig() public {
    vm.prank(address(0xbbbb));
    vm.expectRevert(abi.encodeWithSelector(Goldivault.NotMultisig.selector));
    goldivault.renew();
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