//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { BaseFuzzTest } from "../base/BaseFuzzTest.t.sol";
import { FixedPointMathLib } from "../../lib/solady/src/utils/FixedPointMathLib.sol";
import { Goldiswap } from "../../src/core/goldiswap/Goldiswap.sol";

contract FuzzGoldiswapTest is BaseFuzzTest {

  function testFuzzBuy(uint256 buyAmount) public {
    vm.assume(buyAmount < 200_000_000e18 + 1);
    deal(address(honey), address(this), type(uint256).max / 2);
    honey.approve(address(goldiswap), type(uint256).max / 2);
    goldiswap.buy(buyAmount, type(uint256).max);
    uint256 amountRatio = FixedPointMathLib.divWad(buyAmount, txAmount);
    uint256 cost = FixedPointMathLib.mulWad(amountRatio, costOf10Locks);

    assertEq(goldiswap.balanceOf(address(this)), buyAmount);
    assertEq(withinVariance(honey.balanceOf(address(this)), (type(uint256).max / 2) - cost), true);
  }

  //todo: make differential
  function testFuzzSell(uint256 sellAmount) public {
    vm.assume(sellAmount < 1_000_000e18 + 1);
    deal(address(goldiswap), address(this), sellAmount);
    deal(address(honey), address(goldiswap), type(uint256).max);
    goldiswap.sell(sellAmount, 0);
    // uint256 amountRatio = FixedPointMathLib.divWad(sellAmount, txAmount);
    // uint256 proceeds = FixedPointMathLib.mulWad(amountRatio, proceedsof10Locks);

    assertEq(goldiswap.balanceOf(address(this)), 0);
    // assertEq(withinVarianceSell(honey.balanceOf(address(this)), proceeds), true);
  }

  function testFuzzRedeem(uint256 redeemAmount) public {
    vm.assume(redeemAmount < 1_000_000e18 + 1);
    deal(address(goldiswap), address(this), redeemAmount);
    deal(address(honey), address(goldiswap), type(uint256).max);
    goldiswap.redeem(redeemAmount);
    uint256 rawTotal = FixedPointMathLib.mulWad(goldiswap.floorPrice(), redeemAmount);

    assertEq(goldiswap.fsl(), initialFSL - rawTotal);
    assertEq(goldiswap.totalSupply(), locksMintAmount - redeemAmount);
    assertEq(goldiswap.balanceOf(address(this)), 0);
    assertEq(honey.balanceOf(address(this)), FixedPointMathLib.mulWad(goldiswap.floorPrice(), redeemAmount));
  }

  function testFuzzBorrowTransfer(uint256 borrowTransferAmount) public {
    vm.assume(borrowTransferAmount < 1_000_000_000_000e18 + 1);
    uint256 borrowAmount = FixedPointMathLib.mulWad(goldiswap.floorPrice(), borrowTransferAmount);
    deal(address(goldiswap), address(this), borrowTransferAmount);
    goldiswap.approve(address(goldilocked), borrowTransferAmount);
    goldilocked.stake(borrowTransferAmount);
    deal(address(honey), address(goldiswap), type(uint256).max);
    goldilocked.borrow(borrowAmount);

    assertEq(honey.balanceOf(address(this)), borrowAmount);
    assertEq(honey.balanceOf(address(goldiswap)), type(uint256).max - borrowAmount);
  }

  function testFuzzInjectLiquidity(uint256 fsl, uint256 psl) public {
    vm.assume(fsl < type(uint256).max / 4);
    vm.assume(psl < type(uint256).max / 4);
    deal(address(honey), address(timelock), fsl + psl);
    vm.prank(goldiswap.timelock());
    honey.approve(address(goldiswap), fsl + psl);
    vm.prank(goldiswap.timelock());
    goldiswap.injectLiquidity(fsl, psl);

    assertEq(goldiswap.fsl(), initialFSL + fsl);
    assertEq(goldiswap.psl(), initialPSL + psl);
    assertEq(honey.balanceOf(address(goldiswap)), fsl + psl);
    assertEq(honey.balanceOf(address(this)), 0);
  }

}