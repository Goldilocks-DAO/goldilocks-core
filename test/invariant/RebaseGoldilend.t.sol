//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { BaseInvariantTest } from "../base/BaseInvariantTest.t.sol";
import { RebaseGoldilendHandler } from "../invariant/handlers/RebaseGoldilendHandler.t.sol";

contract InvariantRebaseGoldilendTest is BaseInvariantTest {

  function setUp() public override {
    deployProtocol();

    rebasegoldilendHandler = new RebaseGoldilendHandler(address(rebaseproxy), glhoney, honey);
    bytes4[] memory rebasegoldilendSelectors = new bytes4[](5);
    rebasegoldilendSelectors[0] = rebasegoldilendHandler.deposit.selector;
    rebasegoldilendSelectors[1] = rebasegoldilendHandler.withdraw.selector;
    rebasegoldilendSelectors[2] = rebasegoldilendHandler.approve.selector;
    rebasegoldilendSelectors[3] = rebasegoldilendHandler.transfer.selector;
    rebasegoldilendSelectors[4] = rebasegoldilendHandler.transferFrom.selector;
    targetSelector(FuzzSelector({
      addr: address(rebasegoldilendHandler),
      selectors: rebasegoldilendSelectors
    }));
    targetContract(address(rebasegoldilendHandler));
  }

  function invariant_basic() public {
    assertTrue(true);
  }

  function invariant_handler_works() public {
    assertTrue(address(rebasegoldilendHandler) != address(0));
    assertTrue(address(rebasegoldilendHandler.rebasegoldilend()) != address(0));
  }

  function invariant_glhoney_eq_deposited() public {
    uint256 sumOfMinted = rebasegoldilendHandler.reduceActors(
      0,
      this.accumulateMintedGlhoney
    );
    assertEq(
      sumOfMinted,
      rebasegoldilendHandler.ghost_depositSum() - rebasegoldilendHandler.ghost_withdrawSum()
    );
  }

  function invariant_glhoney_lte_poolsize() public {
    rebasegoldilendHandler.forEachActor(this.assertMintedGlhoneyLtePoolSize);
  }

}