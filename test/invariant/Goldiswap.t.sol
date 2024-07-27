//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { BaseInvariantTest } from "../base/BaseInvariantTest.t.sol";
import { GoldiswapHandler } from "../invariant/handlers/GoldiswapHandler.t.sol";

contract InvariantGoldiswapTest is BaseInvariantTest {

  function setUp() public override {
    deployProtocol();

    goldiswapHandler = new GoldiswapHandler(goldiswap, honey);
    bytes4[] memory goldiswapSelectors = new bytes4[](3);
    goldiswapSelectors[0] = goldiswapHandler.approve.selector;
    goldiswapSelectors[1] = goldiswapHandler.transfer.selector;
    goldiswapSelectors[2] = goldiswapHandler.transferFrom.selector;
    targetSelector(FuzzSelector({
      addr: address(goldiswapHandler),
      selectors: goldiswapSelectors
    }));
    targetContract(address(goldiswapHandler));
  }

  function invariant_depositorBalances() public {
    goldiswapHandler.forEachActor(this.assertLocksBalanceLteTotalSupply);
  }

  function invariant_solvencyBalances() public {
    goldiswapHandler.forEachActor(this.assertHoneyBalanceLteInitalDeal);
  }

}