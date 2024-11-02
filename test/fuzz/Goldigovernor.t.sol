//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { BaseFuzzTest } from "../base/BaseFuzzTest.t.sol";
import { Goldigovernor } from "../../src/core/goldigovernance/Goldigovernor.sol";

contract FuzzGoldigovernorTest is BaseFuzzTest {

  function testFuzzPropose(
    address target,
    string memory signature,
    bytes memory _calldata,
    uint256 value,
    uint256 votes
  ) public {
    vm.assume(votes > 5e18);
    address[] memory targets = new address[](1);
    targets[0] = target;
    string[] memory signatures = new string[](1);
    signatures[0] = signature;
    bytes[] memory calldatas = new bytes[](1);
    calldatas[0] = _calldata;
    uint256[] memory values = new uint256[](1);
    values[0] = value;
    deal(address(goldiswap), address(this), votes);
    goldiswap.approve(address(govlocks), votes);
    govlocks.deposit(votes);
    govlocks.delegate(address(this));
    vm.roll(2);
    goldigov.propose(targets, values, signatures, calldatas, "");
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
    assertEq(endBlock, 78911);
    assertEq(forVotes, 0);
    assertEq(againstVotes, 0);
    assertEq(abstainVotes, 0);
    assertEq(cancelled, false);    
    assertEq(executed, false);    
  }

  function testFuzzQueue(
    address target,
    string memory signature,
    bytes memory _calldata,
    uint256 value,
    uint256 votes
  ) public {
    vm.assume(votes > quorumVotesNum);
    address[] memory targets = new address[](1);
    targets[0] = target;
    string[] memory signatures = new string[](1);
    signatures[0] = signature;
    bytes[] memory calldatas = new bytes[](1);
    calldatas[0] = _calldata;
    uint256[] memory values = new uint256[](1);
    values[0] = value;
    deal(address(goldiswap), address(this), votes);
    goldiswap.approve(address(govlocks), votes);
    govlocks.deposit(votes);
    govlocks.delegate(address(this));
    vm.roll(2);
    goldigov.propose(targets, values, signatures, calldatas, "");
    vm.roll(72);
    goldigov.castVote(1, 1);
    vm.roll(80000);
    goldigov.queue(1);
    Goldigovernor.Receipt memory receipt = goldigov.receipt(1, address(this));
    (, , uint256 eta, , , , , , ,) = goldigov.proposals(1);

    assertEq(eta, 432001);
    assertEq(receipt.votes, votes);
  }

  function testFuzzExecute(
    uint256 votes
  ) public {
    vm.assume(votes > quorumVotesNum);
    vm.assume(votes < 1_000_000_000_000_000e18);
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
    deal(address(goldiswap), address(this), votes);
    goldiswap.approve(address(govlocks), votes);
    govlocks.deposit(votes);
    govlocks.delegate(address(this));
    vm.roll(2);
    goldigov.propose(targets, values, signatures, calldatas, "");
    vm.roll(72);
    goldigov.castVote(1, 1);
    vm.roll(80000);
    goldigov.queue(1);
    vm.warp(6 days);
    goldigov.execute(1);
    Goldigovernor.Receipt memory receipt = goldigov.receipt(1, address(this));
    (, , , , , , , , , bool executed) = goldigov.proposals(1);

    assertEq(executed, true);
    assertEq(receipt.votes, votes);
  }

  function testFuzzCancel(
    address target,
    address _target,
    string memory signature,
    string memory _signature,
    bytes memory _calldatas,
    bytes memory _calldattas,
    uint256 value,
    uint256 _value
  )  public {
    address[] memory targets = new address[](2);
    targets[0] = target;
    targets[1] = _target;
    string[] memory signatures = new string[](2);
    signatures[0] = signature;
    signatures[1] = _signature;
    bytes[] memory calldatas = new bytes[](2);
    calldatas[0] = _calldatas;
    calldatas[1] = _calldattas;
    uint256[] memory values = new uint256[](2);
    values[0] = value;
    values[1] = _value;
    deal(address(goldiswap), address(this), quorumVotesNum);
    goldiswap.approve(address(govlocks), quorumVotesNum);
    govlocks.deposit(quorumVotesNum);
    govlocks.delegate(address(this));
    vm.roll(2);
    goldigov.propose(targets, values, signatures, calldatas, "");
    vm.roll(72);
    goldigov.castVote(1, 1);
    vm.roll(80000);
    goldigov.queue(1);
    govlocks.withdraw(2e18);
    vm.roll(18003);
    goldigov.cancel(1);
    (, , , , , , , , bool cancelled, ) = goldigov.proposals(1);
    Goldigovernor.ProposalState state = goldigov.state(1);

    assertEq(cancelled, true);
    assertEq(uint256(state), 2);
  }

  function testFuzzCastVoteFor(
    address target,
    string memory signature,
    bytes memory _calldata,
    uint256 value,
    uint256 votes
  ) public {
    vm.assume(votes > quorumVotesNum);
    address[] memory targets = new address[](1);
    targets[0] = target;
    string[] memory signatures = new string[](1);
    signatures[0] = signature;
    bytes[] memory calldatas = new bytes[](1);
    calldatas[0] = _calldata;
    uint256[] memory values = new uint256[](1);
    values[0] = value;
    deal(address(goldiswap), address(this), votes);
    goldiswap.approve(address(govlocks), votes);
    govlocks.deposit(votes);
    govlocks.delegate(address(this));
    vm.roll(2);
    goldigov.propose(targets, values, signatures, calldatas, "");
    vm.roll(72);
    goldigov.castVote(1, 1);
    Goldigovernor.Receipt memory receipt = goldigov.receipt(1, address(this));

    assertEq(receipt.support, 1);
    assertEq(receipt.votes, votes);
    assertEq(receipt.hasVoted, true);
  }

  function testFuzzCastVoteAgainst(
    address target,
    string memory signature,
    bytes memory _calldata,
    uint256 value,
    uint256 votes
  ) public {
    vm.assume(votes > quorumVotesNum);
    address[] memory targets = new address[](1);
    targets[0] = target;
    string[] memory signatures = new string[](1);
    signatures[0] = signature;
    bytes[] memory calldatas = new bytes[](1);
    calldatas[0] = _calldata;
    uint256[] memory values = new uint256[](1);
    values[0] = value;
    deal(address(goldiswap), address(this), votes);
    goldiswap.approve(address(govlocks), votes);
    govlocks.deposit(votes);
    govlocks.delegate(address(this));
    vm.roll(2);
    goldigov.propose(targets, values, signatures, calldatas, "");
    vm.roll(72);
    goldigov.castVote(1, 0);
    Goldigovernor.Receipt memory receipt = goldigov.receipt(1, address(this));

    assertEq(receipt.support, 0);
    assertEq(receipt.votes, votes);
    assertEq(receipt.hasVoted, true);
  }

  function testFuzzCastVoteAbstain(
    address target,
    string memory signature,
    bytes memory _calldata,
    uint256 value,
    uint256 votes
  ) public {
    vm.assume(votes > quorumVotesNum);
    address[] memory targets = new address[](1);
    targets[0] = target;
    string[] memory signatures = new string[](1);
    signatures[0] = signature;
    bytes[] memory calldatas = new bytes[](1);
    calldatas[0] = _calldata;
    uint256[] memory values = new uint256[](1);
    values[0] = value;
    deal(address(goldiswap), address(this), votes);
    goldiswap.approve(address(govlocks), votes);
    govlocks.deposit(votes);
    govlocks.delegate(address(this));
    vm.roll(2);
    goldigov.propose(targets, values, signatures, calldatas, "");
    vm.roll(72);
    goldigov.castVote(1, 2);
    Goldigovernor.Receipt memory receipt = goldigov.receipt(1, address(this));

    assertEq(receipt.support, 2);
    assertEq(receipt.votes, votes);
    assertEq(receipt.hasVoted, true);
  }

  function testFuzzCastVoteWithReason(
    address target,
    string memory signature,
    bytes memory _calldata,
    uint256 value,
    uint256 votes,
    string memory reason
  ) public {
    vm.assume(votes > quorumVotesNum);
    address[] memory targets = new address[](1);
    targets[0] = target;
    string[] memory signatures = new string[](1);
    signatures[0] = signature;
    bytes[] memory calldatas = new bytes[](1);
    calldatas[0] = _calldata;
    uint256[] memory values = new uint256[](1);
    values[0] = value;
    deal(address(goldiswap), address(this), votes);
    goldiswap.approve(address(govlocks), votes);
    govlocks.deposit(votes);
    govlocks.delegate(address(this));
    vm.roll(2);
    goldigov.propose(targets, values, signatures, calldatas, "");
    vm.roll(72);
    goldigov.castVoteWithReason(1, 1, reason);
    Goldigovernor.Receipt memory receipt = goldigov.receipt(1, address(this));

    assertEq(receipt.support, 1);
    assertEq(receipt.votes, votes);
    assertEq(receipt.hasVoted, true);
  }

  function testFuzzCastVoteBySig(
    address target,
    address _target,
    string memory signature,
    string memory _signature,
    bytes memory _calldatas,
    bytes memory _calldattas,
    uint256 value,
    uint256 _value,
    uint256 votes,
    uint256 adminVotes
  ) public {
    vm.assume(votes > quorumVotesNum);
    vm.assume(votes < 1_000_000_000_000_000e18);
    vm.assume(adminVotes < 1_000_000_000_000_000e18);
    address[] memory targets = new address[](2);
    targets[0] = target;
    targets[1] = _target;
    string[] memory signatures = new string[](2);
    signatures[0] = signature;
    signatures[1] = _signature;
    bytes[] memory calldatas = new bytes[](2);
    calldatas[0] = _calldatas;
    calldatas[1] = _calldattas;
    uint256[] memory values = new uint256[](2);
    values[0] = value;
    values[1] = _value;
    address admin = 0x1e3C6BE5d1178E4BeFdE4Ff74cF19148F6416470;
    deal(address(goldiswap), address(admin), adminVotes);
    vm.prank(admin);
    goldiswap.approve(address(govlocks), adminVotes);
    vm.prank(admin);
    govlocks.deposit(adminVotes);
    vm.prank(admin);
    govlocks.delegate(admin);
    deal(address(goldiswap), address(this), votes);
    goldiswap.approve(address(govlocks), votes);
    govlocks.deposit(votes);
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
    assertEq(receipt.votes, adminVotes);
    assertEq(receipt.hasVoted, true);
  }
}