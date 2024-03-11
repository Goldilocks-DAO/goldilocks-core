//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../lib/forge-std/src/Test.sol";
import { SafeTransferLib } from "../../lib/solady/src/utils/SafeTransferLib.sol";
import { BaseTest } from "../BaseTest.t.sol";
import { govLocks } from "../../src/governance/govLocks.sol";

contract UnitgovLocksTest is BaseTest {

  function testgovLocksName() public {
    assertEq(govlocks.name(), "Governance Locks");
  }

  function testgovLocksSymbol() public {
    assertEq(govlocks.symbol(), "govLOCKS");
  }

  function testGetVotes() public {
    deal(address(goldiswap), address(this), govLocksAmt);
    goldiswap.approve(address(govlocks), govLocksAmt);
    govlocks.deposit(govLocksAmt);
    govlocks.delegate(address(this));
    vm.roll(2);

    assertEq(govlocks.getVotes(address(this)), govLocksAmt);
  }
  
  function testGetPriorVotesFailBlock() public {
    deal(address(goldiswap), address(this), govLocksAmt);
    goldiswap.approve(address(govlocks), govLocksAmt);
    govlocks.deposit(govLocksAmt);
    govlocks.delegate(address(this));
    vm.roll(2);
    vm.expectRevert(abi.encodeWithSelector(govLocks.NoSuchBlock.selector));
    govlocks.getPriorVotes(address(this), 2);
  }

  function testGetPriorVotesSuccess() public {
    deal(address(goldiswap), address(this), govLocksAmt);
    goldiswap.approve(address(govlocks), govLocksAmt);
    govlocks.deposit(govLocksAmt);
    govlocks.delegate(address(this));
    vm.roll(2);

    assertEq(govlocks.getPriorVotes(address(this), 1), govLocksAmt);
  }

  function testGetPriorVotesNone() public {
    vm.roll(2);

    assertEq(govlocks.getPriorVotes(address(this), 1), 0);
  }

  function testGetPriorVotesImplicitZero() public {
    vm.roll(69);
    deal(address(goldiswap), address(this), govLocksAmt);
    goldiswap.approve(address(govlocks), govLocksAmt);
    govlocks.deposit(govLocksAmt);
    govlocks.delegate(address(this));
    vm.roll(420);

    assertEq(govlocks.getPriorVotes(address(this), 40), 0);
  }

  function testGetPriorVotesNotMostRecentBalanceHigher() public {
    vm.roll(69);
    deal(address(goldiswap), address(this), govLocksAmt);
    goldiswap.approve(address(govlocks), govLocksAmt);
    govlocks.deposit(govLocksAmt);
    govlocks.delegate(address(this));
    vm.roll(420);
    deal(address(goldiswap), address(this), govLocksAmt);
    goldiswap.approve(address(govlocks), govLocksAmt);
    govlocks.deposit(govLocksAmt);
    govlocks.delegate(address(this));
    vm.roll(500);

    assertEq(govlocks.getPriorVotes(address(this), 80), govLocksAmt);
  }

  function testGetPriorVotesNotMostRecentBalanceEqual() public {
    vm.roll(69);
    deal(address(goldiswap), address(this), govLocksAmt);
    goldiswap.approve(address(govlocks), govLocksAmt);
    govlocks.deposit(govLocksAmt);
    govlocks.delegate(address(this));
    vm.roll(420);
    deal(address(goldiswap), address(this), govLocksAmt);
    goldiswap.approve(address(govlocks), govLocksAmt);
    govlocks.deposit(govLocksAmt);
    govlocks.delegate(address(this));
    vm.roll(500);
    deal(address(goldiswap), address(this), govLocksAmt);
    goldiswap.approve(address(govlocks), govLocksAmt);
    govlocks.deposit(govLocksAmt);
    govlocks.delegate(address(this));
    vm.roll(1000);
    deal(address(goldiswap), address(this), govLocksAmt);
    goldiswap.approve(address(govlocks), govLocksAmt);
    govlocks.deposit(govLocksAmt);
    govlocks.delegate(address(this));

    assertEq(govlocks.getPriorVotes(address(this), 420), govLocksAmt+govLocksAmt);
  }

  function testGetPriorVotesNotMostRecentBalanceLower() public {
    vm.roll(69);
    deal(address(goldiswap), address(this), govLocksAmt);
    goldiswap.approve(address(govlocks), govLocksAmt);
    govlocks.deposit(govLocksAmt);
    govlocks.delegate(address(this));
    vm.roll(420);
    deal(address(goldiswap), address(this), govLocksAmt);
    goldiswap.approve(address(govlocks), govLocksAmt);
    govlocks.deposit(govLocksAmt);
    govlocks.delegate(address(this));
    vm.roll(500);
    deal(address(goldiswap), address(this), govLocksAmt);
    goldiswap.approve(address(govlocks), govLocksAmt);
    govlocks.deposit(govLocksAmt);
    govlocks.delegate(address(this));
    vm.roll(1000);
    deal(address(goldiswap), address(this), govLocksAmt);
    goldiswap.approve(address(govlocks), govLocksAmt);
    govlocks.deposit(govLocksAmt);
    govlocks.delegate(address(this));

    assertEq(govlocks.getPriorVotes(address(this), 421), govLocksAmt+govLocksAmt);
  }

  function testDepositSuccess() public {
    deal(address(goldiswap), address(this), govLocksAmt);
    goldiswap.approve(address(govlocks), govLocksAmt);
    govlocks.deposit(govLocksAmt);
    govlocks.delegate(address(this));

    assertEq(goldiswap.balanceOf(address(this)), 0);
    assertEq(govlocks.balanceOf(address(this)), govLocksAmt);
  }

  function testWithdrawSuccess() public {
    deal(address(goldiswap), address(this), govLocksAmt);
    goldiswap.approve(address(govlocks), govLocksAmt);
    govlocks.deposit(govLocksAmt);
    govlocks.delegate(address(this));
    govlocks.withdraw(govLocksAmt);

    assertEq(goldiswap.balanceOf(address(this)), govLocksAmt);
    assertEq(govlocks.balanceOf(address(this)), 0);
  }

  function testDelegateOtherSuccess() public {
    deal(address(goldiswap), address(this), govLocksAmt);
    goldiswap.approve(address(govlocks), govLocksAmt);
    govlocks.deposit(govLocksAmt);
    govlocks.delegate(address(0x6969));
    vm.roll(2);

    assertEq(govlocks.getPriorVotes(address(0x6969), block.number - 1), govLocksAmt);
    assertEq(govlocks.balanceOf(address(0x6969)), 0);
    assertEq(govlocks.getPriorVotes(address(this), block.number - 1), 0);
    assertEq(govlocks.balanceOf(address(this)), govLocksAmt);
  }

  function testDelegateSelfSuccess() public {
    deal(address(goldiswap), address(this), govLocksAmt);
    goldiswap.approve(address(govlocks), govLocksAmt);
    govlocks.deposit(govLocksAmt);
    govlocks.delegate(address(this));
    vm.roll(2);

    assertEq(govlocks.getPriorVotes(address(this), block.number - 1), govLocksAmt);
    assertEq(govlocks.balanceOf(address(this)), govLocksAmt);
  }

  function testDelegateDelegate() public {
    deal(address(goldiswap), address(this), govLocksAmt);
    goldiswap.approve(address(govlocks), govLocksAmt);
    govlocks.deposit(govLocksAmt);
    govlocks.delegate(address(this));
    vm.roll(2);
    govlocks.delegate(address(0x6969));
    vm.roll(3);
    govlocks.delegate(address(0x420420));
    vm.roll(4);

    assertEq(govlocks.getPriorVotes(address(0x6969), block.number - 1), 0);
    assertEq(govlocks.getPriorVotes(address(0x420420), block.number - 1), govLocksAmt);
    assertEq(govlocks.getPriorVotes(address(this), block.number - 1), 0);
  }

  function testDelegateDelegateVote() public {
    address user = address(0x69);
    address user2 = address(0x420);
    deal(address(goldiswap), user, govLocksAmt);
    vm.startPrank(user);
    goldiswap.approve(address(govlocks), govLocksAmt);
    govlocks.deposit(govLocksAmt);
    govlocks.delegate(address(this));
    vm.roll(2);
    govlocks.delegate(user2);
    vm.stopPrank();
    address[] memory targets = new address[](2);
    targets[0] = address(0x69);
    targets[1] = address(0x69);
    string[] memory signatures = new string[](2);
    signatures[0] = "hello";
    signatures[1] = "helloagain";
    bytes[] memory calldatas = new bytes[](2);
    calldatas[0] = hex"8eed55d1";
    calldatas[1] = hex"8eed55d1";
    uint256[] memory values = new uint256[](2);
    values[0] = 0;
    values[1] = 0;
    deal(address(goldiswap), address(this), 401e18);
    goldiswap.approve(address(govlocks), 401e18);
    govlocks.deposit(401e18);
    govlocks.delegate(address(this));
    vm.roll(3);
    goldigov.propose(targets, values, signatures, calldatas, "");

    vm.roll(20);
    vm.prank(user);
    SafeTransferLib.safeTransfer(address(govlocks), address(0x80085), govLocksAmt);
    vm.roll(73);

    vm.prank(user);
    goldigov.castVote(1, 1);
    vm.prank(user2);
    goldigov.castVote(1, 1);
    console.log(govlocks.balanceOf(user));
    console.log(govlocks.balanceOf(user2));
  }

  function testMoveDelegatesSrcRepNonZero() public {
    deal(address(goldiswap), address(this), govLocksAmt);
    goldiswap.approve(address(govlocks), govLocksAmt);
    govlocks.deposit(govLocksAmt);
    vm.roll(3);
    govlocks.delegate(address(this));
    vm.roll(5);
    govlocks.delegate(address(0x6699));
    vm.roll(10);
    govlocks.delegate(address(0x6969));
    vm.roll(69);

    (uint256 fromBlockUser, uint256 votesUser) = govlocks.checkpoints(address(0x6699), 1);
    (uint256 fromBlock69, uint256 votes69) = govlocks.checkpoints(address(0x6969), 0);
    uint256 numUser = govlocks.numCheckpoints(address(this));
    uint256 num69 = govlocks.numCheckpoints(address(0x6969));
    
    assertEq(fromBlockUser, 10);
    assertEq(fromBlock69, 10);
    assertEq(numUser, 2);
    assertEq(num69, 1);
    assertEq(votesUser, 0);
    assertEq(votes69, govLocksAmt);
  }

  function testUpdateStakedBalanceFailGoldilocked() public {
    vm.expectRevert(abi.encodeWithSelector(govLocks.NotGoldilocked.selector));
    govlocks.updateStakedBalance(address(0x69), address(0x69), govLocksAmt);
  }

  function testUpdatedStakedBalanceSuccess() public {
    deal(address(goldiswap), address(this), govLocksAmt + govLocksAmt);
    goldiswap.approve(address(govlocks), govLocksAmt);
    govlocks.deposit(govLocksAmt);
    govlocks.delegate(address(this));
    goldiswap.approve(address(goldilocked), govLocksAmt);
    goldilocked.stake(govLocksAmt);
    vm.roll(2);

    assertEq(govlocks.getPriorVotes(address(this), 1), goldilocked.userStakedLocks(address(this)) + govLocksAmt);
  }

  function testHoneyjarGovernance() public {
    vm.warp(2);
    vm.prank(honeyjar);
    govlocks.delegate(honeyjar);
    vm.warp(4);

    assertEq(govlocks.getVotes(honeyjar), 5_000_000e18);
  }

}