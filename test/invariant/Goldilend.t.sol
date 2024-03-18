//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { BaseInvariantTest } from "../base/BaseInvariantTest.t.sol";

contract InvariantGoldilendTest is BaseInvariantTest {

  function invariant_depositorBalances() public {
    goldilendHandler.forEachActor(this.assertGoldilendBalanceLteTotalSupply);
  }

}