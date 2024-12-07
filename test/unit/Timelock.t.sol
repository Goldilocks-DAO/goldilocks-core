//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { BaseUnitTest } from "../base/BaseUnitTest.t.sol";
import { Timelock } from "../../src/core/goldigovernance/Timelock.sol";

contract UnitTimelockTest is BaseUnitTest {

  function testQueueTransactionFailGoldigov() public {
    vm.expectRevert(abi.encodeWithSelector(Timelock.NotGoldigov.selector));
    timelock.queueTransaction(address(0x69), 69, 69, "", "");
  }

  function testQueueTransactionFailEta() public {
    vm.prank(address(goldigov));
    vm.expectRevert(abi.encodeWithSelector(Timelock.InvalidETA.selector));
    timelock.queueTransaction(address(0x69), 69, 69, "", "");
  }

  function testQueueTransactionSuccess() public {
    (
      address[] memory targets,
      string[] memory signatures,
      bytes[] memory calldatas,
      uint256[] memory values
    ) = proposyDiffQueue();
    
    assertEq(timelock.queuedTransactions(keccak256(abi.encode(targets[0], values[0], signatures[0], calldatas[0], 172801))), true);
  }

  function testExecuteTransactionFailGoldigov() public {
    vm.expectRevert(abi.encodeWithSelector(Timelock.NotGoldigov.selector));
    timelock.executeTransaction(address(0x69), 69, 69, "", "");
  }

  function testExecuteTransactionFailQueued() public {
    vm.prank(address(goldigov));
    vm.expectRevert(abi.encodeWithSelector(Timelock.TxNotQueued.selector));
    timelock.executeTransaction(address(0x69), 69, 69, "", "");
  }

  function testExecuteTransactionFailLocked() public {
    proposyDiffQueue();
    vm.expectRevert(abi.encodeWithSelector(Timelock.TxLocked.selector));
    goldigov.execute(1);
  }

  function testExecuteTransactionFailStale() public {
    (
      address[] memory targets,
      string[] memory signatures,
      bytes[] memory calldatas,
      uint256[] memory values
    ) = proposyDiffQueue();
    vm.warp(690 days);
    vm.prank(address(goldigov));
    vm.expectRevert(abi.encodeWithSelector(Timelock.TxStale.selector));
    timelock.executeTransaction(targets[0], 172801, values[0], calldatas[0], signatures[0]);
  }

  function testExecuteTransactionEmptySignature() public {
    address[] memory targets = new address[](2);
    targets[0] = address(0x69);
    targets[1] = address(0x69);
    string[] memory signatures = new string[](2);
    signatures[0] = "";
    signatures[1] = "";
    bytes[] memory calldatas = new bytes[](2);
    calldatas[0] = hex"8eed55d1";
    calldatas[1] = hex"8eed55d2";
    uint256[] memory values = new uint256[](2);
    values[0] = 0;
    values[1] = 0;
    deal(address(goldiswap), address(this), quorumVotesNum);
    goldiswap.approve(address(govlocks), quorumVotesNum);
    govlocks.deposit(quorumVotesNum);
    govlocks.delegate(address(this));
    vm.roll(2);
    goldigov.propose(targets, values, signatures, calldatas, "");
    vm.roll(52600);
    goldigov.castVote(1, 1);
    vm.roll(200000);
    goldigov.queue(1);
    vm.warp(6 days);
    goldigov.execute(1);
  }

  function testExecuteTransactionFailReverted() public {
    (
      address[] memory targets,
      string[] memory signatures,
      bytes[] memory calldatas,
      uint256[] memory values
    ) = proposyDiff();
    values[0] = 69;
    deal(address(goldiswap), address(this), quorumVotesNum);
    goldiswap.approve(address(govlocks), quorumVotesNum);
    govlocks.deposit(quorumVotesNum);
    govlocks.delegate(address(this));
    vm.roll(2);
    goldigov.propose(targets, values, signatures, calldatas, "");
    vm.roll(52600);
    goldigov.castVote(1, 1);
    vm.roll(200000);
    goldigov.queue(1);
    vm.warp(6 days);
    deal(address(goldigov), 1 ether);
    vm.prank(address(goldigov));
    vm.expectRevert(abi.encodeWithSelector(Timelock.TxReverted.selector));
    timelock.executeTransaction(targets[0], 172801, 69, calldatas[0], signatures[0]);  
  }

  function testExecuteTransactionSuccess() public {
    proposyDiffQueue();
    vm.warp(6 days);
    goldigov.execute(1);
    (, , , , , , , , , bool executed ) = goldigov.proposals(1);

    assertEq(executed, true);
  }

  function testCancelTransactionFailGoldigov() public {
    vm.expectRevert(abi.encodeWithSelector(Timelock.NotGoldigov.selector));
    timelock.cancelTransaction(address(0x69), 69, 69, "", "");
  }

  function testCancelTransactionSuccess() public {
    (
      address[] memory targets,
      string[] memory signatures,
      bytes[] memory calldatas,
      uint256[] memory values
    ) = proposyDiff();
    deal(address(goldiswap), address(this), quorumVotesNum);
    goldiswap.approve(address(govlocks), quorumVotesNum);
    govlocks.deposit(quorumVotesNum);
    govlocks.delegate(address(this));
    vm.roll(2);
    goldigov.propose(targets, values, signatures, calldatas, "");
    vm.roll(52600);
    goldigov.castVote(1, 1);
    vm.roll(200000);
    goldigov.queue(1);
    govlocks.withdraw(2e18);
    vm.roll(18003);
    goldigov.cancel(1);
    (, , , , , , , , bool cancelled, ) = goldigov.proposals(1);

    assertEq(cancelled, true);
  }

  function testSetDelayFailMultisig() public {
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(Timelock.NotMultisig.selector));
    timelock.setDelay(69);
  }

  function testSetDelayFailDelay() public {
    vm.expectRevert(abi.encodeWithSelector(Timelock.InvalidDelay.selector));
    timelock.setDelay(1 days);
  }

  function testSetDelaySuccess() public {
    timelock.setDelay(3 days);

    assertEq(timelock.delay(), 3 days);
  }

}