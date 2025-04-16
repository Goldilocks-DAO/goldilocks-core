//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { console } from "../../lib/forge-std/src/console.sol";
import { BaseInvariantTest } from "../base/BaseInvariantTest.t.sol";
import { Goldivault4626Handler } from "../invariant/handlers/Goldivault4626Handler.t.sol";

contract InvariantGoldivault4626Test is BaseInvariantTest {

  function setUp() public override {
    deployProtocol();

    goldivault4626Handler = new Goldivault4626Handler(oribgtgoldivault, oribgtot, oribgtyt, ibgt, oribgt);
    bytes4[] memory goldivault4626Selectors = new bytes4[](12);
    goldivault4626Selectors[0] = goldivault4626Handler.deposit.selector;
    goldivault4626Selectors[1] = goldivault4626Handler.redeemOwnership.selector;
    goldivault4626Selectors[2] = goldivault4626Handler.stakeYT.selector;
    goldivault4626Selectors[3] = goldivault4626Handler.unstakeYT.selector;
    goldivault4626Selectors[4] = goldivault4626Handler.approveot.selector;
    goldivault4626Selectors[5] = goldivault4626Handler.approveyt.selector;
    goldivault4626Selectors[6] = goldivault4626Handler.transferot.selector;
    goldivault4626Selectors[7] = goldivault4626Handler.transferyt.selector;
    goldivault4626Selectors[8] = goldivault4626Handler.transferFromot.selector;
    goldivault4626Selectors[9] = goldivault4626Handler.transferFromyt.selector;
    goldivault4626Selectors[10] = goldivault4626Handler.accumulateYield.selector;
    goldivault4626Selectors[11] = goldivault4626Handler.claim.selector;
    targetSelector(FuzzSelector({
      addr: address(goldivault4626Handler),
      selectors: goldivault4626Selectors
    }));
    targetContract(address(goldivault4626Handler));
  }

  function invariant_depositorBalances() public {
    goldivault4626Handler.forEachActor(this.assertOribgtotBalanceLteTotalSupply);
  }

  function invariant_solvencyOribgtDeposits() public {
    uint256 sumOfYield = goldivault4626Handler.reduceActors(
      0,
      this.accumulateClaimableYield
    );
    assertEq(
      sumOfYield + oribgtot.totalSupply() + 1,
      oribgt.convertToAssets(oribgt.balanceOf(address(oribgtgoldivault)))
    );
  }

  function invariant_solvencyBalances() public {
    goldivault4626Handler.forEachActor(this.assertOribgtotBalanceLteInitialDeal);
  }
}