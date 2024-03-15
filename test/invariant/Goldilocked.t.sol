//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { BaseInvariantTest } from "../base/BaseInvariantTest.t.sol";

contract InvariantGoldilockedTest is BaseInvariantTest {

  function invariant_conservationOfLocks() public {
    assertEq(
      goldiswap.balanceOf(address(goldilockedHandler)) + goldilocked.stakedLocks(address(goldilockedHandler)),
      goldilockedHandler.locksMintAmount()
    );
  }

  function invariant_solvencyStakes() public {
    assertEq(
    goldilocked.stakedLocks(address(goldilockedHandler)),
    goldilockedHandler.ghost_stakeSum() - goldilockedHandler.ghost_unstakeSum()
    );
  }

}