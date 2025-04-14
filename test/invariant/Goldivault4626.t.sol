//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { FixedPointMathLib } from "../../lib/solady/src/utils/FixedPointMathLib.sol";
import { BaseInvariantTest } from "../base/BaseInvariantTest.t.sol";
import { Goldivault4626Handler } from "../invariant/handlers/Goldivault4626Handler.t.sol";

contract InvariantGoldivault4626Test is BaseInvariantTest {

  function setUp() public override {
    deployProtocol();

    goldivault4626Handler = new Goldivault4626Handler(oribgtgoldivault, oribgtot, oribgtyt, ibgt);
    bytes4[] memory goldivault4626Selectors = new bytes4[](4);
    goldivault4626Selectors[0] = goldivault4626Handler.deposit.selector;
    goldivault4626Selectors[1] = goldivault4626Handler.redeemOwnership.selector;
    goldivault4626Selectors[2] = goldivault4626Handler.stakeYT.selector;
    goldivault4626Selectors[3] = goldivault4626Handler.unstakeYT.selector;
    targetSelector(FuzzSelector({
      addr: address(goldivault4626Handler),
      selectors: goldivault4626Selectors
    }));
    targetContract(address(goldivault4626Handler));
  }

  function invariant_depositorBalances() public {
    goldivault4626Handler.forEachActor(this.assertOribgtotBalanceLteTotalSupply);
  }

  function invariant_solvencyBalances() public {
    goldivault4626Handler.forEachActor(this.assertIbgtBalanceLteInitialDeal);
  }
}