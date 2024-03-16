//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { BaseUnitTest } from "../base/BaseUnitTest.t.sol";
import { SafeTransferLib } from "../../lib/solady/src/utils/SafeTransferLib.sol";
import { GovLocks } from "../../src/core/goldigovernance/GovLocks.sol";

contract UnitGovLocksTest is BaseUnitTest {

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
    vm.expectRevert(abi.encodeWithSelector(GovLocks.NoSuchBlock.selector));
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
    assertEq(govlocks.getVotes(address(this)), govLocksAmt);
  }

  function testWithdrawSuccess() public {
    deal(address(goldiswap), address(this), govLocksAmt);
    goldiswap.approve(address(govlocks), govLocksAmt);
    govlocks.deposit(govLocksAmt);
    govlocks.delegate(address(this));
    govlocks.withdraw(govLocksAmt);

    assertEq(goldiswap.balanceOf(address(this)), govLocksAmt);
    assertEq(govlocks.balanceOf(address(this)), 0);
    assertEq(govlocks.getVotes(address(this)), 0);
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
    assertEq(govlocks.getVotes(address(0x6969)), 0);
    assertEq(govlocks.getVotes(address(0x420420)), govLocksAmt);
    assertEq(govlocks.getVotes(address(this)), 0);
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
    deal(address(goldiswap), address(this), quorumVotesNum);
    goldiswap.approve(address(govlocks), quorumVotesNum);
    govlocks.deposit(quorumVotesNum);
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
    vm.expectRevert(abi.encodeWithSelector(GovLocks.NotGoldilocked.selector));
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

  function testAPDAOGovernance() public {
    vm.warp(2);
    vm.prank(apdao);
    govlocks.delegate(apdao);
    vm.warp(4);

    assertEq(govlocks.getVotes(apdao), 95_000_000e17);
  }

  function testWithdrawDelegate() public {
    deal(address(goldiswap), address(this), govLocksAmt);
    goldiswap.approve(address(govlocks), govLocksAmt);
    govlocks.deposit(govLocksAmt);
    govlocks.withdraw(govLocksAmt);
    govlocks.delegate(address(0xabccba));

    assertEq(goldiswap.balanceOf(address(this)), govLocksAmt);
    assertEq(govlocks.balanceOf(address(this)), 0);
    assertEq(govlocks.getVotes(address(this)), 0);
    assertEq(govlocks.getVotes(address(0xabccba)), 0);
  }

  function testDelegateWithdraw() public {
    deal(address(goldiswap), address(this), govLocksAmt);
    goldiswap.approve(address(govlocks), govLocksAmt);
    govlocks.deposit(govLocksAmt);
    govlocks.delegate(address(0xabccba));
    assertEq(govlocks.getVotes(address(0xabccba)), govLocksAmt);
    govlocks.withdraw(govLocksAmt);

    assertEq(goldiswap.balanceOf(address(this)), govLocksAmt);
    assertEq(govlocks.balanceOf(address(this)), 0);
    assertEq(govlocks.getVotes(address(this)), 0);
    assertEq(govlocks.getVotes(address(0xabccba)), 0);
  }

  function testDepositTransfer() public {
    deal(address(goldiswap), address(this), govLocksAmt);
    goldiswap.approve(address(govlocks), govLocksAmt);
    govlocks.deposit(govLocksAmt);
    SafeTransferLib.safeTransfer(address(govlocks), address(0xabccba), govLocksAmt);

    assertEq(goldiswap.balanceOf(address(this)), 0);
    assertEq(govlocks.balanceOf(address(this)), 0);
    assertEq(govlocks.getVotes(address(this)), 0);
    assertEq(govlocks.balanceOf(address(0xabccba)), govLocksAmt);
    assertEq(govlocks.getVotes(address(0xabccba)), 0);
  }

  function testDepositDelegateTransfer() public {
    deal(address(goldiswap), address(this), govLocksAmt);
    goldiswap.approve(address(govlocks), govLocksAmt);
    govlocks.deposit(govLocksAmt);
    govlocks.delegate(address(0xabccba));
    SafeTransferLib.safeTransfer(address(govlocks), address(0xabccba), govLocksAmt);

    assertEq(goldiswap.balanceOf(address(this)), 0);
    assertEq(govlocks.balanceOf(address(this)), 0);
    assertEq(govlocks.getVotes(address(this)), 0);
    assertEq(govlocks.balanceOf(address(0xabccba)), govLocksAmt);
    assertEq(govlocks.getVotes(address(0xabccba)), 0);
  }

  function testDepositTransferOtherDelegateSelf() public {
    deal(address(goldiswap), address(this), govLocksAmt);
    goldiswap.approve(address(govlocks), govLocksAmt);
    govlocks.deposit(govLocksAmt);
    SafeTransferLib.safeTransfer(address(govlocks), address(0xabccba), govLocksAmt);
    vm.prank(address(0xabccba));
    govlocks.delegate(address(0xabccba));

    assertEq(goldiswap.balanceOf(address(this)), 0);
    assertEq(govlocks.balanceOf(address(this)), 0);
    assertEq(govlocks.getVotes(address(this)), 0);
    assertEq(govlocks.balanceOf(address(0xabccba)), govLocksAmt);
    assertEq(govlocks.getVotes(address(0xabccba)), govLocksAmt);
  }

  function testDepositDelegateTransferOtherDelegateSelf() public {
    deal(address(goldiswap), address(this), govLocksAmt);
    goldiswap.approve(address(govlocks), govLocksAmt);
    govlocks.deposit(govLocksAmt);
    govlocks.delegate(address(0xabccba));
    SafeTransferLib.safeTransfer(address(govlocks), address(0xabccba), govLocksAmt);
    vm.prank(address(0xabccba));
    govlocks.delegate(address(0xabccba));

    assertEq(goldiswap.balanceOf(address(this)), 0);
    assertEq(govlocks.balanceOf(address(this)), 0);
    assertEq(govlocks.getVotes(address(this)), 0);
    assertEq(govlocks.balanceOf(address(0xabccba)), govLocksAmt);
    assertEq(govlocks.getVotes(address(0xabccba)), govLocksAmt);
  }

  function testStakeDelegateStake() public dealStakeLocks {
    vm.warp(1 days + 1);
    deal(address(goldiswap), address(this), locksAmount);
    goldiswap.approve(address(goldilocked), locksAmount);
    govlocks.delegate(address(this));
    goldilocked.stake(locksAmount);

    assertEq(goldilocked.userStakedLocks(address(this)), locksAmount + locksAmount);
    assertEq(goldiswap.balanceOf(address(this)), 0);
    assertEq(govlocks.getVotes(address(this)), locksAmount + locksAmount);
  }

  function testStakeDepositDelegate() public {
    deal(address(goldiswap), address(this), locksAmount+locksAmount);
    goldiswap.approve(address(goldilocked), locksAmount);
    goldiswap.approve(address(govlocks), locksAmount);
    goldilocked.stake(locksAmount);
    govlocks.deposit(locksAmount);
    govlocks.delegate(address(this));

    assertEq(goldilocked.userStakedLocks(address(this)), locksAmount);
    assertEq(goldiswap.balanceOf(address(this)), 0);
    assertEq(govlocks.balanceOf(address(this)), locksAmount);
    assertEq(govlocks.getVotes(address(this)), locksAmount + locksAmount);
  }

  function testSeedInvestorVotes() public {
    assertEq(govlocks.getVotes(address(0x696969696969)), 7_000_000e18);
  }

}