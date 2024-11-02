//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { BaseFuzzTest } from "../base/BaseFuzzTest.t.sol";
import { Timelock } from "../../src/core/goldigovernance/Timelock.sol";
import { Goldigovernor } from "../../src/core/goldigovernance/Goldigovernor.sol";

contract FuzzTimelockTest is BaseFuzzTest {

  function testFuzzQueueTransaction(
    address target,
    string memory sig,
    bytes memory _calldata,
    uint256 value,
    uint256 votes
  ) public {
    vm.assume(votes > quorumVotesNum);
    address[] memory targets = new address[](1);
    targets[0] = target;
    string[] memory signatures = new string[](1);
    signatures[0] = sig;
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

    assertEq(timelock.queuedTransactions(keccak256(abi.encode(target, value, sig, _calldata, 432001))), true);
  }

  function testFuzzExecuteTransaction(
    uint256 votes
  ) public {
    vm.assume(votes > quorumVotesNum);
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
    (, , , , , , , , , bool executed ) = goldigov.proposals(1);

    assertEq(executed, true);
    assertEq(receipt.votes, votes);
  }

  function testFuzzCancelTransaction(
    address target,
    address _target,
    string memory signature,
    string memory _signature,
    bytes memory _calldatas,
    bytes memory _calldattas,
    uint256 value,
    uint256 _value
  ) public {
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
}