//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { BaseInvariantTest } from "../base/BaseInvariantTest.t.sol";
import { RebaseGoldilendHandler } from "../invariant/handlers/RebaseGoldilendHandler.t.sol";

contract InvariantRebaseGoldilendTest is BaseInvariantTest {

  function setUp() public override {
    deployProtocol();

    rebasegoldilendHandler = new RebaseGoldilendHandler(rebasegoldilend);
    bytes4[] memory rebasegoldilendSelectors = new bytes4[](0);
    targetSelector(FuzzSelector({
      addr: address(rebasegoldilendHandler),
      selectors: rebasegoldilendSelectors
    }));
    targetContract(address(rebasegoldilendHandler));
  }

}