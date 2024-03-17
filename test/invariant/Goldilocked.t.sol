//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { BaseInvariantTest } from "../base/BaseInvariantTest.t.sol";

contract InvariantGoldilockedTest is BaseInvariantTest {

  function invariant_conservationOfLocks() public {
    uint256 sumOfStaked = goldilockedHandler.reduceActors(
      0,
      this.accumulateStakedLocks
    );
    assertEq(
      goldiswap.balanceOf(address(goldilockedHandler)) + sumOfStaked,
      goldilockedHandler.locksMintAmount()
    );
  }

  function invariant_solvencyStakes() public {
    uint256 sumOfStaked = goldilockedHandler.reduceActors(
      0,
      this.accumulateStakedLocks
    );
    assertEq(
    sumOfStaked,
    goldilockedHandler.ghost_stakeSum() - goldilockedHandler.ghost_unstakeSum()
    );
  }

  function invariant_depositorBalances() public {
    goldilockedHandler.forEachActor(this.assertStakedLocksBalanceLteTotalSupply);
  }

  // function invariant_callSummary() public view {
  //   goldilockedHandler.callSummary();
  // }

}