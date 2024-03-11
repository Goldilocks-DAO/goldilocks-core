//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { BaseTest } from "../BaseTest.t.sol";
import { Goldigovernor } from "../../src/governance/Goldigovernor.sol";

contract FuzzGoldigovernorTest is BaseTest {

  function testFuzzPropose(
    address target,
    string memory signature,
    bytes memory _calldata,
    uint256 value
  ) public {
    address[] memory targets = new address[](1);
    targets[0] = target;
    string[] memory signatures = new string[](1);
    signatures[0] = signature;
    bytes[] memory calldatas = new bytes[](1);
    calldatas[0] = _calldata;
    uint256[] memory values = new uint256[](1);
    values[0] = value;
    deal(address(goldiswap), address(this), 5e18);
    goldiswap.approve(address(govlocks), 5e18);
    govlocks.deposit(5e18);
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
}