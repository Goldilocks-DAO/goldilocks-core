//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { BaseInvariantTest } from "../base/BaseInvariantTest.t.sol";
import { GoldilendHandler } from "../invariant/handlers/GoldilendHandler.t.sol";

contract InvariantGoldilendTest is BaseInvariantTest {

  function setUp() public override {
    deployProtocol();

    goldilendHandler = new GoldilendHandler(goldilend);
    bytes4[] memory goldilendSelectors = new bytes4[](3);
    goldilendSelectors[0] = goldilendHandler.approve.selector;
    goldilendSelectors[1] = goldilendHandler.transfer.selector;
    goldilendSelectors[2] = goldilendHandler.transferFrom.selector;
    targetSelector(FuzzSelector({
      addr: address(goldilendHandler),
      selectors: goldilendSelectors
    }));
    targetContract(address(goldilendHandler));
  }

  function invariant_depositorBalances() public {
    goldilendHandler.forEachActor(this.assertGoldilendBalanceLteTotalSupply);
  }

}