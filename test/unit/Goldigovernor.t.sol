//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { BaseUnitTest } from "../base/BaseUnitTest.t.sol";
import { Goldigovernor } from "../../src/core/goldigovernance/Goldigovernor.sol";

contract UnitGoldigovernorTest is BaseUnitTest {

  function testStateSuccess() public {
    proposySamePropose();
    vm.roll(72);
    Goldigovernor.ProposalState state = goldigov.state(1);

    assertEq(uint256(state), 1);
  }

  function testReceiptSuccess() public {
    proposySamePropose();
    vm.roll(72);
    goldigov.castVote(1, 1);
    Goldigovernor.Receipt memory receipt = goldigov.receipt(1, address(this));

    assertEq(receipt.support, 1);
    assertEq(receipt.votes, 5e18);
    assertEq(receipt.hasVoted, true);
  }

  function testProposeFailThreshold() public {
    (
      address[] memory targets,
      string[] memory signatures,
      bytes[] memory calldatas,
      uint256[] memory values
    ) = proposySame();
    deal(address(goldiswap), address(this), 3e18);
    goldiswap.approve(address(govlocks), 3e18);
    govlocks.deposit(3e18);
    govlocks.delegate(address(this));
    vm.roll(2);
    vm.expectRevert(abi.encodeWithSelector(Goldigovernor.BelowThreshold.selector));
    goldigov.propose(targets, values, signatures, calldatas, "");
  }

  function testProposeFailArray() public {
    address[] memory targets = new address[](2);
    targets[0] = address(0x69);
    targets[1] = address(0x69);
    string[] memory signatures = new string[](1);
    signatures[0] = "hello";
    bytes[] memory calldatas = new bytes[](1);
    calldatas[0] = hex"8eed55d1";
    uint256[] memory values = new uint256[](1);
    values[0] = 69;
    deal(address(goldiswap), address(this), 5e18);
    goldiswap.approve(address(govlocks), 5e18);
    govlocks.deposit(5e18);
    govlocks.delegate(address(this));
    vm.roll(2);
    vm.expectRevert(abi.encodeWithSelector(Goldigovernor.ArrayMismatch.selector));
    goldigov.propose(targets, values, signatures, calldatas, "");
  }

  function testProposeFailNoTargets() public {
    address[] memory targets = new address[](0);
    string[] memory signatures = new string[](0);
    bytes[] memory calldatas = new bytes[](0);
    uint256[] memory values = new uint256[](0);
    deal(address(goldiswap), address(this), 5e18);
    goldiswap.approve(address(govlocks), 5e18);
    govlocks.deposit(5e18);
    govlocks.delegate(address(this));
    vm.roll(2);
    vm.expectRevert(abi.encodeWithSelector(Goldigovernor.InvalidProposalAction.selector));
    goldigov.propose(targets, values, signatures, calldatas, "");
  }

    function testProposeFailTooManyTargets() public {
    address[] memory targets = new address[](11);
    targets[0] = address(0x69);
    targets[1] = address(0x69);
    targets[2] = address(0x69);
    targets[3] = address(0x69);
    targets[4] = address(0x69);
    targets[5] = address(0x69);
    targets[6] = address(0x69);
    targets[7] = address(0x69);
    targets[8] = address(0x69);
    targets[9] = address(0x69);
    targets[10] = address(0x69);
    string[] memory signatures = new string[](11);
    signatures[0] = "hello";
    signatures[1] = "hello";
    signatures[2] = "hello";
    signatures[3] = "hello";
    signatures[4] = "hello";
    signatures[5] = "hello";
    signatures[6] = "hello";
    signatures[7] = "hello";
    signatures[8] = "hello";
    signatures[9] = "hello";
    signatures[10] = "hello";
    bytes[] memory calldatas = new bytes[](11);
    calldatas[0] = hex"8eed55d1";
    calldatas[1] = hex"8eed55d1";
    calldatas[2] = hex"8eed55d1";
    calldatas[3] = hex"8eed55d1";
    calldatas[4] = hex"8eed55d1";
    calldatas[5] = hex"8eed55d1";
    calldatas[6] = hex"8eed55d1";
    calldatas[7] = hex"8eed55d1";
    calldatas[8] = hex"8eed55d1";
    calldatas[9] = hex"8eed55d1";
    calldatas[10] = hex"8eed55d1";
    uint256[] memory values = new uint256[](11);
    values[0] = 69;
    values[1] = 69;
    values[2] = 69;
    values[3] = 69;
    values[4] = 69;
    values[5] = 69;
    values[6] = 69;
    values[7] = 69;
    values[8] = 69;
    values[9] = 69;
    values[10] = 69;
    deal(address(goldiswap), address(this), 5e18);
    goldiswap.approve(address(govlocks), 5e18);
    govlocks.deposit(5e18);
    govlocks.delegate(address(this));
    vm.roll(2);
    vm.expectRevert(abi.encodeWithSelector(Goldigovernor.InvalidProposalAction.selector));
    goldigov.propose(targets, values, signatures, calldatas, ""); 
  }

  function testProposeFailAlreadyProposingActive() public {
    (
      address[] memory targets,
      string[] memory signatures,
      bytes[] memory calldatas,
      uint256[] memory values
    ) = proposyDiff();
    deal(address(goldiswap), address(this), 5e18);
    goldiswap.approve(address(govlocks), 5e18);
    govlocks.deposit(5e18);
    govlocks.delegate(address(this));
    vm.roll(2);
    goldigov.propose(targets, values, signatures, calldatas, "");
    vm.roll(139);
    vm.expectRevert(abi.encodeWithSelector(Goldigovernor.AlreadyProposing.selector));
    goldigov.propose(targets, values, signatures, calldatas, "");
  }

  function testProposeFailAlreadyProposingPending() public {
    (
      address[] memory targets,
      string[] memory signatures,
      bytes[] memory calldatas,
      uint256[] memory values
    ) = proposySamePropose();
    vm.expectRevert(abi.encodeWithSelector(Goldigovernor.AlreadyProposing.selector));
    goldigov.propose(targets, values, signatures, calldatas, "");
  }

  function testProposeSuccess() public {
    proposySamePropose();
    (
      address proposer,
      uint256 id,
      uint256 eta,
      uint256 startBlock,
      uint256 endBlock, 
      uint256 forVotes, 
      uint256 againstVotes, 
      uint256 abstainVotes, 
      bool cancelled, 
      bool executed
    ) = goldigov.proposals(1);

    assertEq(proposer, address(this));
    assertEq(id, 1);
    assertEq(eta, 0);
    assertEq(startBlock, 71);
    assertEq(endBlock, 5832);
    assertEq(forVotes, 0);
    assertEq(againstVotes, 0);
    assertEq(abstainVotes, 0);
    assertEq(cancelled, false);    
    assertEq(executed, false);    
  }

  function testProposeProposeSuccess() public {
    (
      address[] memory targets,
      string[] memory signatures,
      bytes[] memory calldatas,
      uint256[] memory values
    ) = proposyDiffQueue();
    vm.warp(6 days);
    goldigov.execute(1);
    deal(address(goldiswap), address(this), 5e18);
    goldiswap.approve(address(govlocks), 5e18);
    govlocks.deposit(5e18);
    govlocks.delegate(address(this));
    vm.roll(6900);
    goldigov.propose(targets, values, signatures, calldatas, "");
  }

  function testQueueFailState() public {
    proposySamePropose();
    vm.expectRevert(abi.encodeWithSelector(Goldigovernor.InvalidProposalState.selector));
    goldigov.queue(1);
  }

  function testQueueFailAlready() public {
    proposySamePropose();
    vm.roll(72);
    goldigov.castVote(1, 1);
    vm.roll(5900);
    vm.expectRevert(abi.encodeWithSelector(Goldigovernor.AlreadyQueued.selector));
    goldigov.queue(1);
  }

  function testQueueSuccess() public {
    proposyDiffQueue();
    (, , uint256 eta, , , , , , ,) = goldigov.proposals(1);

    assertEq(eta, 432001);
  }

  function testExecuteFailState() public {
    (
      address[] memory targets,
      string[] memory signatures,
      bytes[] memory calldatas,
      uint256[] memory values
    ) = proposyDiff();
    deal(address(goldiswap), address(this), 5e18);
    goldiswap.approve(address(govlocks), 5e18);
    govlocks.deposit(5e18);
    govlocks.delegate(address(this));
    vm.roll(2);
    goldigov.propose(targets, values, signatures, calldatas, "");
    vm.roll(72);
    goldigov.castVote(1, 1);
    vm.expectRevert(abi.encodeWithSelector(Goldigovernor.InvalidProposalState.selector));
    goldigov.execute(1);
  }

  function testExecuteSuccess() public {
    proposyDiffQueue();
    vm.warp(6 days);
    goldigov.execute(1);
    (, , , , , , , , , bool executed) = goldigov.proposals(1);

    assertEq(executed, true);
  }

  function testCancelFailState() public {
    proposyDiffQueue();
    vm.warp(6 days);
    goldigov.execute(1);    
    vm.expectRevert(abi.encodeWithSelector(Goldigovernor.InvalidProposalState.selector));
    goldigov.cancel(1);
  }

  function testCancelFailProposer() public {
    (
      address[] memory targets,
      string[] memory signatures,
      bytes[] memory calldatas,
      uint256[] memory values
    ) = proposyDiff();
    deal(address(goldiswap), address(this), 5e18);
    goldiswap.approve(address(govlocks), 5e18);
    govlocks.deposit(5e18);
    govlocks.delegate(address(this));
    vm.roll(2);
    goldigov.propose(targets, values, signatures, calldatas, "");
    vm.roll(72);
    goldigov.castVote(1, 1);
    vm.roll(5900);
    goldigov.queue(1);
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(Goldigovernor.NotProposer.selector));
    goldigov.cancel(1);
  }

  function testCancelThresholdFail() public {
    (
      address[] memory targets,
      string[] memory signatures,
      bytes[] memory calldatas,
      uint256[] memory values
    ) = proposyDiff();
    deal(address(goldiswap), address(this), 5e18);
    goldiswap.approve(address(govlocks), 5e18);
    govlocks.deposit(5e18);
    govlocks.delegate(address(this));
    vm.roll(2);
    goldigov.propose(targets, values, signatures, calldatas, "");
    vm.roll(72);
    goldigov.castVote(1, 1);
    vm.roll(5900);
    goldigov.queue(1);
    vm.expectRevert(abi.encodeWithSelector(Goldigovernor.AboveThreshold.selector));
    goldigov.cancel(1);
  }

  function testCancelSuccess() public {
    (
      address[] memory targets,
      string[] memory signatures,
      bytes[] memory calldatas,
      uint256[] memory values
    ) = proposyDiff();
    deal(address(goldiswap), address(this), 5e18);
    goldiswap.approve(address(govlocks), 5e18);
    govlocks.deposit(5e18);
    govlocks.delegate(address(this));
    vm.roll(2);
    goldigov.propose(targets, values, signatures, calldatas, "");
    vm.roll(72);
    goldigov.castVote(1, 1);
    vm.roll(5900);
    goldigov.queue(1);
    govlocks.withdraw(2e18);
    vm.roll(5903);
    goldigov.cancel(1);
    (, , , , , , , , bool cancelled, ) = goldigov.proposals(1);
    Goldigovernor.ProposalState state = goldigov.state(1);

    assertEq(cancelled, true);
    assertEq(uint256(state), 2);
  }

  function testCastVoteFailState() public {
    (
      address[] memory targets,
      string[] memory signatures,
      bytes[] memory calldatas,
      uint256[] memory values
    ) = proposyDiff();
    deal(address(goldiswap), address(this), 5e18);
    goldiswap.approve(address(govlocks), 5e18);
    govlocks.deposit(5e18);
    govlocks.delegate(address(this));
    vm.roll(2);
    goldigov.propose(targets, values, signatures, calldatas, "");
    vm.roll(72);
    goldigov.castVote(1, 1);
    vm.roll(5900);
    goldigov.queue(1);
    govlocks.withdraw(2e18);
    vm.roll(5903);
    goldigov.cancel(1);
    vm.expectRevert(abi.encodeWithSelector(Goldigovernor.InvalidProposalState.selector));
    goldigov.castVote(1, 1);
  }

  function testCastVoteFailType() public {
    (
      address[] memory targets,
      string[] memory signatures,
      bytes[] memory calldatas,
      uint256[] memory values
    ) = proposySame();
    deal(address(goldiswap), address(this), 5e18);
    goldiswap.approve(address(govlocks), 5e18);
    govlocks.deposit(5e18);
    govlocks.delegate(address(this));
    vm.roll(2);
    goldigov.propose(targets, values, signatures, calldatas, "");
    vm.roll(72);
    vm.expectRevert(abi.encodeWithSelector(Goldigovernor.InvalidVoteType.selector));
    goldigov.castVote(1, 3);
  }

  function testCastVoteFailAlready() public {
    (
      address[] memory targets,
      string[] memory signatures,
      bytes[] memory calldatas,
      uint256[] memory values
    ) = proposySame();
    deal(address(goldiswap), address(this), 5e18);
    goldiswap.approve(address(govlocks), 5e18);
    govlocks.deposit(5e18);
    govlocks.delegate(address(this));
    vm.roll(2);
    goldigov.propose(targets, values, signatures, calldatas, "");
    vm.roll(72);
    goldigov.castVote(1, 1);
    vm.expectRevert(abi.encodeWithSelector(Goldigovernor.AlreadyVoted.selector));
    goldigov.castVote(1, 1);
  }

  function testCastVoteForSuccess() public {
    proposySamePropose();
    vm.roll(72);
    goldigov.castVote(1, 1);
    Goldigovernor.Receipt memory receipt = goldigov.receipt(1, address(this));

    assertEq(receipt.support, 1);
    assertEq(receipt.votes, 5e18);
    assertEq(receipt.hasVoted, true);
  }

  function testCastVoteAgainstSuccess() public {
    proposySamePropose();
    vm.roll(72);
    goldigov.castVote(1, 0);
    Goldigovernor.Receipt memory receipt = goldigov.receipt(1, address(this));

    assertEq(receipt.support, 0);
    assertEq(receipt.votes, 5e18);
    assertEq(receipt.hasVoted, true);
  }

  function testCastVoteAbstainSuccess() public {
    proposySamePropose();
    vm.roll(72);
    goldigov.castVote(1, 2);
    Goldigovernor.Receipt memory receipt = goldigov.receipt(1, address(this));

    assertEq(receipt.support, 2);
    assertEq(receipt.votes, 5e18);
    assertEq(receipt.hasVoted, true);
  }

  function testCastVoteWithReasonSuccess() public {
    proposySamePropose();
    vm.roll(72);
    goldigov.castVoteWithReason(1, 1, "reason");
    Goldigovernor.Receipt memory receipt = goldigov.receipt(1, address(this));

    assertEq(receipt.support, 1);
    assertEq(receipt.votes, 5e18);
    assertEq(receipt.hasVoted, true);
  }

  function testCastVoteBySigFailSignature() public {
    vm.expectRevert(abi.encodeWithSelector(Goldigovernor.InvalidSignature.selector));
    goldigov.castVoteBySig(1, 1, 1, "", "");
  }

  function testCastVoteBySigSuccess() public {
    (
      address[] memory targets,
      string[] memory signatures,
      bytes[] memory calldatas,
      uint256[] memory values
    ) = proposyDiff();
    address admin = 0x50A7dd4778724FbED41aCe9B3d3056a7B36E874C;
    deal(address(goldiswap), address(admin), 5e18);
    vm.prank(admin);
    goldiswap.approve(address(govlocks), 5e18);
    vm.prank(admin);
    govlocks.deposit(5e18);
    vm.prank(admin);
    govlocks.delegate(admin);
    deal(address(goldiswap), address(this), quorumVotesNum);
    goldiswap.approve(address(govlocks), quorumVotesNum);
    govlocks.deposit(quorumVotesNum);
    govlocks.delegate(address(this));
    vm.roll(2);
    goldigov.propose(targets, values, signatures, calldatas, "");
    vm.roll(72);
    uint8 v = 28;
    bytes32 r = 0x16b88e27f61da00072600b9b04049403f9f064b451d34a5b07aacd7dc48b1f9f;
    bytes32 s = 0x6613e63d75d423834a24b707d13a34304f3b66c6f2eaacb611b327550761215d;
    vm.prank(admin);
    goldigov.castVoteBySig(1, 1, v, r, s);
    Goldigovernor.Receipt memory receipt = goldigov.receipt(1, address(admin));

    assertEq(receipt.support, 1);
    assertEq(receipt.votes, 5e18);
    assertEq(receipt.hasVoted, true);
  }

  function testQueueEta() public {
    (
      address[] memory targets,
      string[] memory signatures,
      bytes[] memory calldatas,
      uint256[] memory values
    ) = proposyDiff();
    values[0] = 69;
    values[1] = 69;
    deal(address(goldiswap), address(this), 5e18);
    goldiswap.approve(address(govlocks), 5e18);
    govlocks.deposit(5e18);
    govlocks.delegate(address(this));
    vm.roll(2);
    goldigov.propose(targets, values, signatures, calldatas, "");
    vm.roll(72);
    goldigov.castVote(1, 1);
    vm.roll(5900);
    goldigov.queue(1);
    (, , uint256 eta, , , , , , ,) = goldigov.proposals(1);
    
    assertEq(432001, eta);
  }

  function testDefeatedProposal() public {
    (
      address[] memory targets,
      string[] memory signatures,
      bytes[] memory calldatas,
      uint256[] memory values
    ) = proposyDiff();
    deal(address(goldiswap), address(this), 399e18);
    goldiswap.approve(address(govlocks), 399e18);
    govlocks.deposit(399e18);
    govlocks.delegate(address(this));
    vm.roll(2);
    goldigov.propose(targets, values, signatures, calldatas, "");
    vm.roll(72);
    goldigov.castVote(1, 1);
    vm.roll(5900);
    goldigov.queue(1);
    Goldigovernor.ProposalState state = goldigov.state(1);

    assertEq(uint256(state), 3);
  }

  function testExpiredProposal() public {
    proposyDiffQueue();
    vm.warp(69 days);
    Goldigovernor.ProposalState state = goldigov.state(1);

    assertEq(uint256(state), 6);
  }

  function testSetVotingDelayFailMultisig() public {
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(Goldigovernor.NotMultisig.selector));
    goldigov.setVotingDelay(69);
  }

  function testSetVotingDelayFailParameter() public {
    vm.expectRevert(abi.encodeWithSelector(Goldigovernor.InvalidVotingParameter.selector));
    goldigov.setVotingDelay(0);
  }

  function testSetVotingDelaySuccess() public {
    goldigov.setVotingDelay(69);
    
    assertEq(goldigov.votingDelay(), 69);
  }

  function testSetVotingPeriodFailMultisig() public {
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(Goldigovernor.NotMultisig.selector));
    goldigov.setVotingPeriod(69);
  }

    function testSetVotingPeriodFailParameter() public {
    vm.expectRevert(abi.encodeWithSelector(Goldigovernor.InvalidVotingParameter.selector));
    goldigov.setVotingPeriod(5000);
  }

  function testSetVotingPeriodSuccess() public {
    goldigov.setVotingPeriod(6000);

    assertEq(6000, goldigov.votingPeriod());
  }

  function testSetProposalThresholdFailMultisig() public {
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(Goldigovernor.NotMultisig.selector));
    goldigov.setProposalThreshold(69);
  }

  function testSetProposalThresholdFailParameter() public {
    vm.expectRevert(abi.encodeWithSelector(Goldigovernor.InvalidVotingParameter.selector));
    goldigov.setProposalThreshold(1e17);
  }

  function testSetProposalThresholdSuccess() public {
    goldigov.setProposalThreshold(1000001e18);
    
    assertEq(goldigov.proposalThreshold(), 1000001e18);
  }

}