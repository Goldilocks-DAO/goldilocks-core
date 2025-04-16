//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { BaseUnitTest } from "../base/BaseUnitTest.t.sol";
import { IGoldivault4626 } from "../../src/interfaces/IGoldivault4626.sol";
import { FixedPointMathLib } from "../../lib/solady/src/utils/FixedPointMathLib.sol";

contract UnitGoldivault4626Test is BaseUnitTest {

  address user = address(0xabc123);
  uint256 depositAmt = 100e18;
  uint256 four626yield = 1000e18;
  uint256 four626claimable = 999999999999999999900;

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

    assertEq(oribgtgoldivault.ytStaked(user), depositAmt);
    assertEq(oribgtot.balanceOf(user), 0);
    assertEq(oribgtyt.balanceOf(user), 0);
    assertEq(oribgtgoldivault.totalYtStaked(), depositAmt);
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

  function testClaimUnderlyingFailNegativeYield() public {
    deal(address(ibgt), user, depositAmt);
    vm.startPrank(user);
    ibgt.approve(address(oribgtgoldivault), depositAmt);
    oribgtyt.approve(address(oribgtgoldivault), depositAmt);
    oribgtgoldivault.deposit(depositAmt);
    vm.stopPrank();
    deal(address(ibgt), address(oribgt), 1e18);
    vm.expectRevert(abi.encodeWithSelector(IGoldivault4626.NegativeYield.selector));
    vm.prank(user);
    oribgtgoldivault.claim();
  }

  function testClaimUnderlyingSuccess() public {
    deal(address(ibgt), user, depositAmt);
    vm.startPrank(user);
    ibgt.approve(address(oribgtgoldivault), depositAmt);
    oribgtyt.approve(address(oribgtgoldivault), depositAmt);
    oribgtgoldivault.deposit(depositAmt);
    vm.stopPrank();
    deal(address(ibgt), address(oribgt), depositAmt + four626yield);
    vm.prank(user);
    oribgtgoldivault.claim();
    uint256 fee = four626claimable * oribgtgoldivault.yieldFee() / 100;

    assertEq(ibgt.balanceOf(user), four626claimable - fee);
    assertEq(ibgt.balanceOf(address(this)), fee);
    assertEq(oribgtgoldivault.ytStaked(user), depositAmt);
    assertEq(oribgtgoldivault.userClaimableUnderlying(user), 0);
  }

  function testViewUserClaimableUnderlying() public {
    deal(address(ibgt), user, depositAmt);
    vm.startPrank(user);
    ibgt.approve(address(oribgtgoldivault), depositAmt);
    oribgtyt.approve(address(oribgtgoldivault), depositAmt);
    oribgtgoldivault.deposit(depositAmt);
    vm.stopPrank();
    deal(address(ibgt), address(oribgt), depositAmt + four626yield);

    assertEq(oribgtgoldivault.userClaimableUnderlying(user), four626claimable);
  }

  function testTwoClaimers() public {
    deal(address(ibgt), user, depositAmt);
    vm.startPrank(user);
    ibgt.approve(address(oribgtgoldivault), depositAmt);
    oribgtyt.approve(address(oribgtgoldivault), depositAmt);
    oribgtgoldivault.deposit(depositAmt);
    vm.stopPrank();

    address user2 = address(0x123abc);
    deal(address(ibgt), user2, depositAmt);
    vm.startPrank(user2);
    ibgt.approve(address(oribgtgoldivault), depositAmt);
    oribgtyt.approve(address(oribgtgoldivault), depositAmt);
    oribgtgoldivault.deposit(depositAmt);
    vm.stopPrank();
    
    deal(address(ibgt), address(oribgt), (depositAmt * 2) + four626yield);
    vm.prank(user);
    oribgtgoldivault.claim();
    vm.prank(user2);
    oribgtgoldivault.claim();
    uint256 fee = (four626claimable / 2) * oribgtgoldivault.yieldFee() / 100;

    assertEq(ibgt.balanceOf(user), ibgt.balanceOf(user2));
    assertEq(oribgtgoldivault.ytStaked(user), depositAmt);
    assertEq(oribgtgoldivault.userClaimableUnderlying(user), 0);
    assertEq(oribgtgoldivault.ytStaked(user2), depositAmt);
    assertEq(oribgtgoldivault.userClaimableUnderlying(user2), 0);
    assertEq(ibgt.balanceOf(address(this)), (fee * 2) - 2);
  }

  function testTwoDifferentClaimers() public {
    deal(address(ibgt), user, 75e18);
    vm.startPrank(user);
    ibgt.approve(address(oribgtgoldivault), 75e18);
    oribgtyt.approve(address(oribgtgoldivault), 75e18);
    oribgtgoldivault.deposit(75e18);
    vm.stopPrank();

    address user2 = address(0x123abc);
    deal(address(ibgt), user2, 25e18);
    vm.startPrank(user2);
    ibgt.approve(address(oribgtgoldivault), 25e18);
    oribgtyt.approve(address(oribgtgoldivault), 25e18);
    oribgtgoldivault.deposit(25e18);
    vm.stopPrank();
    
    deal(address(ibgt), address(oribgt), depositAmt + four626yield);
    vm.prank(user);
    oribgtgoldivault.claim();
    vm.prank(user2);
    oribgtgoldivault.claim();
    uint256 fee = four626claimable * oribgtgoldivault.yieldFee() / 100;

    assertEq(ibgt.balanceOf(user), ibgt.balanceOf(user2) * 3);
    assertEq(oribgtgoldivault.ytStaked(user), 75e18);
    assertEq(oribgtgoldivault.userClaimableUnderlying(user), 0);
    assertEq(oribgtgoldivault.ytStaked(user2), 25e18);
    assertEq(oribgtgoldivault.userClaimableUnderlying(user2), 0);
    assertEq(ibgt.balanceOf(address(this)), fee - 1);
  }

  function testFourDifferentClaimers() public {
    deal(address(ibgt), user, 50e18);
    vm.startPrank(user);
    ibgt.approve(address(oribgtgoldivault), 50e18);
    oribgtyt.approve(address(oribgtgoldivault), 50e18);
    oribgtgoldivault.deposit(50e18);
    vm.stopPrank();

    address user2 = address(0x123abc);
    deal(address(ibgt), user2, 10e18);
    vm.startPrank(user2);
    ibgt.approve(address(oribgtgoldivault), 10e18);
    oribgtyt.approve(address(oribgtgoldivault), 10e18);
    oribgtgoldivault.deposit(10e18);
    vm.stopPrank();

    address user3 = address(0x123abccc);
    deal(address(ibgt), user3, 20e18);
    vm.startPrank(user3);
    ibgt.approve(address(oribgtgoldivault), 20e18);
    oribgtyt.approve(address(oribgtgoldivault), 20e18);
    oribgtgoldivault.deposit(20e18);
    vm.stopPrank();

    address user4 = address(0x123abcaa);
    deal(address(ibgt), user4, 20e18);
    vm.startPrank(user4);
    ibgt.approve(address(oribgtgoldivault), 20e18);
    oribgtyt.approve(address(oribgtgoldivault), 20e18);
    oribgtgoldivault.deposit(20e18);
    vm.stopPrank();
    
    deal(address(ibgt), address(oribgt), depositAmt + four626yield);
    vm.prank(user);
    oribgtgoldivault.claim();
    vm.prank(user2);
    oribgtgoldivault.claim();
    vm.prank(user3);
    oribgtgoldivault.claim();
    vm.prank(user4);
    oribgtgoldivault.claim();
    uint256 fee = four626claimable * oribgtgoldivault.yieldFee() / 100;

    assertEq(ibgt.balanceOf(user), (ibgt.balanceOf(user2) * 5) - 3);
    assertEq(ibgt.balanceOf(user3), ibgt.balanceOf(user4));
    assertEq(oribgtgoldivault.ytStaked(user), 50e18);
    assertEq(oribgtgoldivault.userClaimableUnderlying(user), 0);
    assertEq(oribgtgoldivault.ytStaked(user2), 10e18);
    assertEq(oribgtgoldivault.userClaimableUnderlying(user2), 0);
    assertEq(oribgtgoldivault.ytStaked(user3), 20e18);
    assertEq(oribgtgoldivault.userClaimableUnderlying(user3), 0);
    assertEq(oribgtgoldivault.ytStaked(user4), 20e18);
    assertEq(oribgtgoldivault.userClaimableUnderlying(user4), 0);
    assertEq(ibgt.balanceOf(address(this)), fee - 2);
  }

  function testAssetBacking() public {
    deal(address(ibgt), user, depositAmt);
    vm.startPrank(user);
    ibgt.approve(address(oribgtgoldivault), depositAmt);
    oribgtyt.approve(address(oribgtgoldivault), depositAmt);
    oribgtgoldivault.deposit(depositAmt);
    vm.stopPrank();

    address user2 = address(0x123abc);
    deal(address(ibgt), user2, depositAmt);
    vm.startPrank(user2);
    ibgt.approve(address(oribgtgoldivault), depositAmt);
    oribgtyt.approve(address(oribgtgoldivault), depositAmt);
    oribgtgoldivault.deposit(depositAmt);
    vm.stopPrank();

    address user3 = address(0x123abccc);
    deal(address(ibgt), user3, 20e18);
    vm.startPrank(user3);
    ibgt.approve(address(oribgtgoldivault), 20e18);
    oribgtyt.approve(address(oribgtgoldivault), 20e18);
    oribgtgoldivault.deposit(20e18);
    vm.stopPrank();

    deal(address(ibgt), address(oribgt), (depositAmt * 2) + 20e18 + four626yield);
    vm.prank(user);
    oribgtgoldivault.claim();
    vm.prank(user2);
    oribgtgoldivault.claim();
    vm.prank(user3);
    oribgtgoldivault.claim();

    assertEq(oribgt.convertToAssets(oribgt.balanceOf(address(oribgtgoldivault))), oribgtot.totalSupply() + 115);
  }

  function testAllRedeem() public {
    deal(address(ibgt), user, depositAmt);
    vm.startPrank(user);
    ibgt.approve(address(oribgtgoldivault), depositAmt);
    oribgtyt.approve(address(oribgtgoldivault), depositAmt);
    oribgtgoldivault.deposit(depositAmt);
    vm.stopPrank();

    address user2 = address(0x123abc);
    deal(address(ibgt), user2, depositAmt);
    vm.startPrank(user2);
    ibgt.approve(address(oribgtgoldivault), depositAmt);
    oribgtyt.approve(address(oribgtgoldivault), depositAmt);
    oribgtgoldivault.deposit(depositAmt);
    vm.stopPrank();

    address user3 = address(0x123abccc);
    deal(address(ibgt), user3, 20e18);
    vm.startPrank(user3);
    ibgt.approve(address(oribgtgoldivault), 20e18);
    oribgtyt.approve(address(oribgtgoldivault), 20e18);
    oribgtgoldivault.deposit(20e18);
    vm.stopPrank();

    vm.startPrank(user);
    oribgtgoldivault.claim();
    oribgtgoldivault.redeemOwnership(depositAmt);
    vm.stopPrank();
    vm.startPrank(user2);
    oribgtgoldivault.claim();
    oribgtgoldivault.redeemOwnership(depositAmt);
    vm.stopPrank();
    vm.startPrank(user3);
    oribgtgoldivault.claim();
    oribgtgoldivault.redeemOwnership(20e18);
    vm.stopPrank();

    assertEq(oribgt.balanceOf(address(oribgtgoldivault)), 0);
  }

  function testAllRedeemBackwards() public {
    deal(address(ibgt), user, depositAmt);
    vm.startPrank(user);
    ibgt.approve(address(oribgtgoldivault), depositAmt);
    oribgtyt.approve(address(oribgtgoldivault), depositAmt);
    oribgtgoldivault.deposit(depositAmt);
    vm.stopPrank();

    address user2 = address(0x123abc);
    deal(address(ibgt), user2, depositAmt);
    vm.startPrank(user2);
    ibgt.approve(address(oribgtgoldivault), depositAmt);
    oribgtyt.approve(address(oribgtgoldivault), depositAmt);
    oribgtgoldivault.deposit(depositAmt);
    vm.stopPrank();

    address user3 = address(0x123abccc);
    deal(address(ibgt), user3, 20e18);
    vm.startPrank(user3);
    ibgt.approve(address(oribgtgoldivault), 20e18);
    oribgtyt.approve(address(oribgtgoldivault), 20e18);
    oribgtgoldivault.deposit(20e18);
    vm.stopPrank();

    vm.startPrank(user3);
    oribgtgoldivault.claim();
    oribgtgoldivault.redeemOwnership(20e18);
    vm.stopPrank();
    vm.startPrank(user2);
    oribgtgoldivault.claim();
    oribgtgoldivault.redeemOwnership(depositAmt);
    vm.stopPrank();
    vm.startPrank(user);
    oribgtgoldivault.claim();
    oribgtgoldivault.redeemOwnership(depositAmt);
    vm.stopPrank();

    assertEq(oribgt.balanceOf(address(oribgtgoldivault)), 0);
  }

  function testStakeSums() public {
    deal(address(ibgt), user, depositAmt);
    vm.startPrank(user);
    ibgt.approve(address(oribgtgoldivault), depositAmt);
    oribgtyt.approve(address(oribgtgoldivault), depositAmt);
    oribgtgoldivault.deposit(depositAmt);
    vm.stopPrank();

    address user2 = address(0x123abc);
    deal(address(ibgt), user2, depositAmt);
    vm.startPrank(user2);
    ibgt.approve(address(oribgtgoldivault), depositAmt);
    oribgtyt.approve(address(oribgtgoldivault), depositAmt);
    oribgtgoldivault.deposit(depositAmt);
    vm.stopPrank();

    deal(address(ibgt), address(oribgt), (depositAmt * 2) + four626yield);
    vm.prank(user);
    oribgtgoldivault.claim();

    deal(address(ibgt), address(oribgt), (depositAmt * 2) + four626yield + four626yield);
    vm.prank(user);
    oribgtgoldivault.claim();
    vm.prank(user2);
    oribgtgoldivault.claim();
    
    assertEq(ibgt.balanceOf(user), ibgt.balanceOf(user2));
    assertEq(oribgt.balanceOf(user), oribgt.balanceOf(user2));
    assertEq(oribgtot.balanceOf(user), oribgtot.balanceOf(user2));
    assertEq(oribgtyt.balanceOf(user), oribgtyt.balanceOf(user2));
  }

  function testDifferentStakeTimes() public {
    deal(address(ibgt), user, depositAmt);
    vm.startPrank(user);
    ibgt.approve(address(oribgtgoldivault), depositAmt);
    oribgtyt.approve(address(oribgtgoldivault), depositAmt);
    oribgtgoldivault.deposit(depositAmt);
    vm.stopPrank();

    deal(address(ibgt), address(oribgt), depositAmt + four626yield);

    address user2 = address(0x123abc);
    deal(address(ibgt), user2, depositAmt);
    vm.startPrank(user2);
    ibgt.approve(address(oribgtgoldivault), depositAmt);
    oribgtyt.approve(address(oribgtgoldivault), depositAmt);
    oribgtgoldivault.deposit(depositAmt);
    vm.stopPrank();

    deal(address(ibgt), address(oribgt), (depositAmt * 2) + four626yield + (four626yield / 10));

    vm.startPrank(user);
    oribgtgoldivault.claim();
    oribgtgoldivault.redeemOwnership(depositAmt);
    vm.stopPrank();
    vm.startPrank(user2);
    oribgtgoldivault.claim();
    oribgtgoldivault.redeemOwnership(depositAmt);
    vm.stopPrank();

    assertEq(ibgt.balanceOf(user) / 10, 111849999999999999990);
    assertEq(ibgt.balanceOf(user2), 148500000000000000000);
    assertEq(oribgt.balanceOf(user), 0);
    assertEq(oribgt.balanceOf(user), oribgt.balanceOf(user2));
    assertEq(oribgtot.balanceOf(user), 0);
    assertEq(oribgtot.balanceOf(user), oribgtot.balanceOf(user2));
    assertEq(oribgtyt.balanceOf(user), 0);
    assertEq(oribgtyt.balanceOf(user), oribgtyt.balanceOf(user2));
  }

  function testNoYtRedeemSuccess() public {
    deal(address(ibgt), user, depositAmt);
    vm.startPrank(user);
    ibgt.approve(address(oribgtgoldivault), depositAmt);
    oribgtyt.approve(address(oribgtgoldivault), depositAmt);
    oribgtgoldivault.deposit(depositAmt);
    oribgtgoldivault.unstakeYT(depositAmt);
    oribgtyt.transfer(address(0x0), depositAmt);
    vm.stopPrank();

    vm.warp(block.timestamp + 366 days);
    vm.prank(user);
    oribgtgoldivault.redeemOwnership(depositAmt);

    assertEq(oribgtgoldivault.ytStaked(user), 0);
    assertEq(oribgtot.balanceOf(user), 0);
    assertEq(oribgtyt.balanceOf(user), 0);
    assertEq(oribgtgoldivault.totalYtStaked(), 0);
    assertEq(ibgt.balanceOf(user), depositAmt);
    assertEq(oribgt.balanceOf(address(oribgtgoldivault)), 0);
    assertEq(ibgt.balanceOf(address(oribgtgoldivault)), 0);
    assertEq(ibgt.balanceOf(address(oribgt)), 0);
  }

  function testRecoverFailMultisig() public {
    deal(address(oribgt), address(oribgtgoldivault), depositAmt);
    vm.expectRevert(abi.encodeWithSelector(IGoldivault4626.NotMultisig.selector));
    vm.prank(user);
    oribgtgoldivault.recoverYield();
  }

  function testRecoverFailDelay() public {
    deal(address(oribgt), address(oribgtgoldivault), depositAmt);
    vm.expectRevert(abi.encodeWithSelector(IGoldivault4626.DelayTooShort.selector));
    oribgtgoldivault.recoverYield();
  }

  function testRecoverSuccess() public {
    deal(address(oribgt), address(oribgtgoldivault), depositAmt);
    vm.warp(block.timestamp + 373 days);
    oribgtgoldivault.recoverYield();

    assertEq(oribgt.balanceOf(address(oribgtgoldivault)), 0);
    assertEq(oribgt.balanceOf(address(this)), depositAmt);
  }

  function testDifferentClaimTimes() public {
    deal(address(ibgt), user, depositAmt);
    vm.startPrank(user);
    ibgt.approve(address(oribgtgoldivault), depositAmt);
    oribgtyt.approve(address(oribgtgoldivault), depositAmt);
    oribgtgoldivault.deposit(depositAmt);
    vm.stopPrank();

    ibgt.mint(address(oribgt), four626yield/2);
    address user2 = address(0x123abc);
    deal(address(ibgt), user2, depositAmt*2);
    vm.startPrank(user2);
    ibgt.approve(address(oribgtgoldivault), depositAmt*2);
    oribgtyt.approve(address(oribgtgoldivault), depositAmt*2);
    oribgtgoldivault.deposit(depositAmt*2);
    vm.stopPrank();

    ibgt.mint(address(oribgt), four626yield/2);
    address user3 = address(0x123abccc);
    deal(address(ibgt), user3, depositAmt/2);
    vm.startPrank(user3);
    ibgt.approve(address(oribgtgoldivault), depositAmt/2);
    oribgtyt.approve(address(oribgtgoldivault), depositAmt/2);
    oribgtgoldivault.deposit(depositAmt/2);
    vm.stopPrank();

    ibgt.mint(address(oribgt), four626yield/2);
    vm.prank(user);
    oribgtgoldivault.claim();
    ibgt.mint(address(oribgt), four626yield/4);
    vm.prank(user2);
    oribgtgoldivault.claim();
    ibgt.mint(address(oribgt), four626yield/4);
    vm.prank(user3);
    oribgtgoldivault.claim();

    ibgt.mint(address(oribgt), four626yield/2);
    vm.startPrank(user);
    oribgtgoldivault.claim();
    oribgtgoldivault.redeemOwnership(depositAmt);
    vm.stopPrank();
    vm.startPrank(user2);
    oribgtgoldivault.claim();
    oribgtgoldivault.redeemOwnership(depositAmt*2);
    vm.stopPrank();
    vm.startPrank(user3);
    oribgtgoldivault.claim();
    oribgtgoldivault.redeemOwnership(depositAmt/2);
    vm.stopPrank();

    uint256 num = oribgt.balanceOf(address(oribgtgoldivault));
    assertEq(oribgt.convertToAssets(num), oribgtot.totalSupply() + 1056);
  }

  function testSolvencyDeposits() public {
    address guy = address(0xE);
    deal(address(ibgt), guy, 885);
    vm.startPrank(guy);
    ibgt.approve(address(oribgtgoldivault), 885);
    oribgtyt.approve(address(oribgtgoldivault), 885);
    oribgtgoldivault.deposit(885);
    vm.stopPrank();
    deal(address(ibgt), address(oribgt), 885 + 41601461799406086449130643529608617149993532349104);

    assertEq(oribgtgoldivault.userClaimableUnderlying(guy) + oribgtot.totalSupply() + 1, oribgt.convertToAssets(oribgt.balanceOf(address(oribgtgoldivault))));
  }

  function testSolvencyDeposits2() public {
    address guy = address(0xA5c);
    deal(address(ibgt), guy, 5197288472372036);
    vm.startPrank(guy);
    ibgt.approve(address(oribgtgoldivault), 5197288472372036);
    oribgtyt.approve(address(oribgtgoldivault), 5197288472372036);
    oribgtgoldivault.deposit(5197288472372036);
    vm.stopPrank();
    deal(address(ibgt), address(oribgt), 5197288472372036 + 8379);

    assertEq(oribgtgoldivault.userClaimableUnderlying(guy) + oribgtot.totalSupply() + 1, oribgt.convertToAssets(oribgt.balanceOf(address(oribgtgoldivault))));
  }

  function testRandomStakers() public {
    address user2 = address(0x123abc);
    address user3 = address(0x123abccc);
    uint256 user1Amt = 60e18;
    uint256 user2Amt = 74e18;
    uint256 user3Amt = 26e18;

    deal(address(ibgt), user, user1Amt);
    vm.startPrank(user);
    ibgt.approve(address(oribgtgoldivault), user1Amt);
    oribgtyt.approve(address(oribgtgoldivault), user1Amt);
    oribgtgoldivault.deposit(user1Amt);
    vm.stopPrank();

    ibgt.mint(address(oribgt), 4e18);

    deal(address(ibgt), user2, user2Amt);
    vm.startPrank(user2);
    ibgt.approve(address(oribgtgoldivault), user2Amt);
    oribgtyt.approve(address(oribgtgoldivault), user2Amt);
    oribgtgoldivault.deposit(user2Amt);
    vm.stopPrank();

    deal(address(ibgt), user3, user3Amt);
    vm.startPrank(user3);
    ibgt.approve(address(oribgtgoldivault), user3Amt);
    oribgtyt.approve(address(oribgtgoldivault), user3Amt);
    oribgtgoldivault.deposit(user3Amt);
    vm.stopPrank();

    ibgt.mint(address(oribgt), 7e18);

    vm.startPrank(user);
    oribgtgoldivault.claim();
    oribgtgoldivault.redeemOwnership(user1Amt);
    vm.stopPrank();
    vm.startPrank(user2);
    oribgtgoldivault.claim();
    oribgtgoldivault.redeemOwnership(user2Amt);
    vm.stopPrank();

    ibgt.mint(address(oribgt), 4e18);

    vm.startPrank(user3);
    oribgtgoldivault.claim();
    oribgtgoldivault.redeemOwnership(user3Amt);
    vm.stopPrank();

    uint256 num = oribgt.balanceOf(address(oribgtgoldivault));
    assertEq(oribgtot.totalSupply(), 0);
    assertEq(oribgt.convertToAssets(num), oribgtot.totalSupply() + 69);
  }

}