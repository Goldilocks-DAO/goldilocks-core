//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { BaseInvariantTest } from "../base/BaseInvariantTest.t.sol";

contract InvariantGoldilockedTest is BaseInvariantTest {

  function invariant_handlerStakedIsAlwaysZero() public {
    assertEq(goldilocked.stakedLocks(address(goldilockedHandler)), 0);
  }

}