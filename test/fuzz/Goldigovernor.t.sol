//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { BaseTest } from "../BaseTest.t.sol";
import { Goldigovernor } from "../../src/governance/Goldigovernor.sol";

contract FuzzGoldigovernorTest is BaseTest {

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
    assertEq(endBlock, 5832);
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
    vm.assume(votes > 400e18);
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
    vm.roll(5900);
    goldigov.queue(1);
    Goldigovernor.Receipt memory receipt = goldigov.receipt(1, address(this));
    (, , uint256 eta, , , , , , ,) = goldigov.proposals(1);

    assertEq(eta, 432001);
    assertEq(receipt.votes, votes);
  }

  //todo: fix
  // function testFuzzExecute(
  //   address target,
  //   address _target,
  //   string memory signature,
  //   string memory _signature,
  //   bytes memory _calldata,
  //   bytes memory _calldatta,
  //   uint256 value,
  //   uint256 _value,
  //   uint256 votes
  // ) public {
  //   vm.assume(votes > 400e18);
  //   vm.assume(value != _value);
  //   vm.assume(value < 1_000_000_000_000_000);
  //   vm.assume(_value < 1_000_000_000_000_000);
  //   address[] memory targets = new address[](2);
  //   targets[0] = target;
  //   targets[1] = _target;
  //   string[] memory signatures = new string[](2);
  //   signatures[0] = signature;
  //   signatures[1] = _signature;
  //   bytes[] memory calldatas = new bytes[](2);
  //   calldatas[0] = _calldata;
  //   calldatas[1] = _calldatta;
  //   uint256[] memory values = new uint256[](2);
  //   values[0] = value;
  //   values[1] = _value;
  //   deal(address(timelock), value + _value);
  //   deal(address(goldigov), value + _value);
  //   deal(address(this), value + _value);
  //   deal(address(goldiswap), address(this), votes);
  //   goldiswap.approve(address(govlocks), votes);
  //   govlocks.deposit(votes);
  //   govlocks.delegate(address(this));
  //   vm.roll(2);
  //   goldigov.propose(targets, values, signatures, calldatas, "");
  //   vm.roll(72);
  //   goldigov.castVote(1, 1);
  //   vm.roll(5900);
  //   goldigov.queue(1);
  //   vm.warp(6 days);
  //   goldigov.execute(1);
  //   Goldigovernor.Receipt memory receipt = goldigov.receipt(1, address(this));
  //   (, , , , , , , , , bool executed) = goldigov.proposals(1);

  //   assertEq(executed, true);
  //   assertEq(receipt.votes, votes);
  // }

  function testFuzzCastVoteFor(
    address target,
    string memory signature,
    bytes memory _calldata,
    uint256 value,
    uint256 votes
  ) public {
    vm.assume(votes > 400e18);
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
}