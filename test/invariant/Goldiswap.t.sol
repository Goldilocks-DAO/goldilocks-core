//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { FixedPointMathLib } from "../../lib/solady/src/utils/FixedPointMathLib.sol";
import { BaseInvariantTest } from "../base/BaseInvariantTest.t.sol";
import { GoldiswapHandler } from "../invariant/handlers/GoldiswapHandler.t.sol";

contract InvariantGoldiswapTest is BaseInvariantTest {

  uint256 initialBorrowing;

  function setUp() public override {
    deployProtocol();

    uint256 initialSupply = goldiswap.totalSupply();
    initialBorrowing = FixedPointMathLib.mulWad(initialSupply, FixedPointMathLib.divWad(goldiswap.fsl(), initialSupply));

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

  function invariant_enoughHoney() public {
    uint256 honeyBalance = honey.balanceOf(address(goldiswap));
    uint256 honeyAccounted = goldiswap.fsl() + goldiswap.psl() - initialBorrowing;
    assertGe(honeyBalance, honeyAccounted, "not enough honey");
  }

  function invariant_enoughHoneyToCoverFloorPrice() public {
    uint256 totalSupply = goldiswap.totalSupply();
    uint256 floorPrice = goldiswap.floorPrice();
    assertGe(honey.balanceOf(address(goldiswap)) + initialBorrowing, totalSupply * floorPrice / 1e18, "not enough honey to cover floor price");
  }

}