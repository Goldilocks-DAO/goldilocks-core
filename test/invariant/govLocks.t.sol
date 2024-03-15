//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { BaseInvariantTest } from "../base/BaseInvariantTest.t.sol";

contract InvariantgovLockstest is BaseInvariantTest {

  function invariant_conservationOfLocks() public {
    assertEq(
      goldiswap.balanceOf(address(govlocksHandler)) + govlocks.totalSupply(),
      govlocksHandler.locksMintAmount()
    );
  }

  function invariant_solvencyDeposits() public {
    assertEq(
    goldiswap.balanceOf(address(govlocks)),
    govlocksHandler.ghost_depositSum() - govlocksHandler.ghost_withdrawSum()
    );
  }

  function invariant_solvencyBalances() public {
    uint256 sumOfBalances = govlocksHandler.reduceActors(
      0,
      this.accumulategovLocksBalance
    );
    assertEq(
      sumOfBalances,
      goldiswap.balanceOf(address(govlocks))
    );
  }

  function invariant_solvencyVotes() public {
    uint256 sumOfVotes = govlocksHandler.reduceActors(
      0,
      this.accumulategovLocksVotes
    );
    uint256 sumOfStaked = govlocksHandler.reduceActors(
      0,
      this.accumulateStakedLocks
    );
    assertGe(
      goldiswap.balanceOf(address(govlocks)) + sumOfStaked,
      sumOfVotes
    );
  }

  function invariant_depositorBalances() public {
    govlocksHandler.forEachActor(this.assertgovlocksBalanceLteTotalSupply);
  }

  function invariant_callSummary() public view {
    govlocksHandler.callSummary();
  }

}