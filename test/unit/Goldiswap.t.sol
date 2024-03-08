//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../lib/forge-std/src/Test.sol";
import { BaseTest } from "../BaseTest.t.sol";
import { Goldiswap } from "../../src/core/Goldiswap.sol";

contract UnitGoldiswapTest is BaseTest {

  function testLocksName() public {
    assertEq(goldiswap.name(), "Locks Token");
  }

  function testLocksSymbol() public {
    assertEq(goldiswap.symbol(), "LOCKS");
  }

  function testFloorPrice() public {
    uint256 floorPrice = goldiswap.floorPrice();
    string[] memory inputs = new string[](2);
    inputs[0] = "python3";
    inputs[1] = "price_tests/floor_test/test.py";
    bytes memory result = vm.ffi(inputs);
    uint256 pythonFloorPrice = abi.decode(result, (uint256));
    uint256 variance = pythonFloorPrice / 1000;

    assert(pythonFloorPrice + variance > floorPrice);
    assert(pythonFloorPrice - variance < floorPrice);
  }

  function testRandomFloorPrice() public {
    vm.store(address(goldiswap), bytes32(uint256(0)), bytes32(uint256(23457745e18)));
    vm.store(address(goldiswap), bytes32(uint256(1)), bytes32(uint256(8340957e18)));
    vm.store(address(goldiswap), bytes32(uint256(0x05345cdf77eb68f44c)), bytes32(uint256(4374e18)));
    uint256 floorPrice = goldiswap.floorPrice();
    string[] memory inputs = new string[](2);
    inputs[0] = "python3";
    inputs[1] = "price_tests/floor_test/random_test.py";
    bytes memory result = vm.ffi(inputs);
    uint256 pythonFloorPrice = abi.decode(result, (uint256));
    uint256 variance = pythonFloorPrice / 1000;

    assert(pythonFloorPrice + variance > floorPrice);
    assert(pythonFloorPrice - variance < floorPrice);
  }

  function testMarketPrice() public {
    uint256 marketPrice = goldiswap.marketPrice();
    string[] memory inputs = new string[](2);
    inputs[0] = "python3";
    inputs[1] = "price_tests/market_test/test.py";
    bytes memory result = vm.ffi(inputs);
    uint256 pythonMarketPrice = abi.decode(result, (uint256));
    uint256 variance = pythonMarketPrice / 1000;

    assert(pythonMarketPrice + variance > marketPrice);
    assert(pythonMarketPrice - variance < marketPrice);
  }

  function testRandomMarketPrice() public {
    vm.store(address(goldiswap), bytes32(uint256(0)), bytes32(uint256(23457745e18)));
    vm.store(address(goldiswap), bytes32(uint256(1)), bytes32(uint256(8340957e18)));
    vm.store(address(goldiswap), bytes32(uint256(0x05345cdf77eb68f44c)), bytes32(uint256(4374e18)));
    uint256 marketPrice = goldiswap.marketPrice();
    string[] memory inputs = new string[](2);
    inputs[0] = "python3";
    inputs[1] = "price_tests/market_test/random_test.py";
    bytes memory result = vm.ffi(inputs);
    uint256 pythonMarketPrice = abi.decode(result, (uint256));
    uint256 variance = pythonMarketPrice / 1000;

    assert(pythonMarketPrice + variance > marketPrice);
    assert(pythonMarketPrice - variance < marketPrice);
  }

  function testBuyFailSlippage() public {
    vm.expectRevert(abi.encodeWithSelector(Goldiswap.ExcessiveSlippage.selector));
    goldiswap.buy(txAmount, 0);
  }

  function testBuySuccess() public dealandApproveUserHoney {
    goldiswap.buy(txAmount, type(uint256).max);

    assertEq(goldiswap.balanceOf(address(this)), txAmount);
    assertEq(honey.balanceOf(address(this)), (type(uint256).max / 2) - costOf10Locks);
  }

  function testSellFailSlippage() public {
    vm.expectRevert(abi.encodeWithSelector(Goldiswap.ExcessiveSlippage.selector));
    goldiswap.sell(txAmount, type(uint256).max);
  }

  function testSellSuccess() public dealLocks dealGoldiswapHoney {
    goldiswap.sell(txAmount, 0);

    assertEq(goldiswap.balanceOf(address(this)), 0);
    assertEq(honey.balanceOf(address(this)), proceedsof10Locks);
  }

  function testRedeemSuccess() public dealLocks dealGoldiswapHoney {
    uint256 rawTotal = 105000000000000000;
    goldiswap.redeem(txAmount);

    assertEq(goldiswap.fsl(), initialFSL - rawTotal);
    assertEq(goldiswap.totalSupply(), locksMintAmount - txAmount);
    assertEq(goldiswap.balanceOf(address(this)), 0);
    assertEq(honey.balanceOf(address(this)), goldiswap.floorPrice() * 10);
  }

  function testFloorReduce() public {
    vm.store(address(goldiswap), bytes32(uint256(0)), bytes32(uint256(12424533327755417665454800)));
    vm.store(address(goldiswap), bytes32(uint256(1)), bytes32(uint256(6069210257394481945730874)));
    vm.store(address(goldiswap), bytes32(uint256(0x05345cdf77eb68f44c)), bytes32(uint256(8402860035123450385400)));
    vm.store(address(goldiswap), bytes32(uint256(4)), bytes32(uint256(1692551675)));
    deal(address(honey), address(this), 1251210488977958997148919);
    deal(address(goldiswap), address(this), 543082473864185130000);
    deal(address(honey), address(goldiswap), 16442576931719627115185675);
    vm.warp(1692836841);
    goldiswap.sell(5000000000000000000, 9886383387107016000000);

    assertEq(goldiswap.targetRatio(), 304000000000000000);
  }

  function testFloorReduceMax() public {
    vm.store(address(goldiswap), bytes32(uint256(0)), bytes32(uint256(12424533327755417665454800)));
    vm.store(address(goldiswap), bytes32(uint256(1)), bytes32(uint256(6069210257394481945730874)));
    vm.store(address(goldiswap), bytes32(uint256(0x05345cdf77eb68f44c)), bytes32(uint256(8402860035123450385400)));
    vm.store(address(goldiswap), bytes32(uint256(4)), bytes32(uint256(1692551675)));
    deal(address(honey), address(this), 1251210488977958997148919);
    deal(address(goldiswap), address(this), 543082473864185130000);
    deal(address(honey), address(goldiswap), 16442576931719627115185675);
    vm.warp(1693936841);
    goldiswap.sell(5000000000000000000, 9886383387107016000000);

    assertEq(goldiswap.targetRatio(), 304000000000000000);
  }

  function testFloorReduceNoReduce() public dealLocks dealGoldiswapHoney {
    goldiswap.sell(txAmount, 0);

    assertEq(goldiswap.targetRatio(), 32e16);
  }

  function testBorrowTransferFailGoldilocked() public {
    vm.expectRevert(abi.encodeWithSelector(Goldiswap.NotGoldilocked.selector));
    goldiswap.borrowTransfer(address(0x69), 69, 69);
  }

  function testBorrowTransferSuccess() public {
    uint256 locksAmount = 100000e18;
    uint256 borrowAmount = 1050e18;
    deal(address(goldiswap), address(this), locksAmount);
    goldiswap.approve(address(goldilocked), locksAmount);
    goldilocked.stake(locksAmount);
    deal(address(honey), address(goldiswap), type(uint256).max);
    goldilocked.borrow(borrowAmount);

    assertEq(honey.balanceOf(address(this)), borrowAmount);
    assertEq(honey.balanceOf(address(goldiswap)), type(uint256).max - borrowAmount);
  }

  function testPorridgeMintFailGoldilocked() public {
    vm.expectRevert(abi.encodeWithSelector(Goldiswap.NotGoldilocked.selector));
    goldiswap.porridgeMint(address(0x69), 69);
  }

  function testPorridgeMintSuccess() public {
    uint256 locksAmount = 100000e18;
    uint256 oneDayPrg = 136986301369863000000;
    uint256 oneDayPrgCost = 1438356164383561500;
    uint256 oneDayLocksProceeds = 136986301369863000000;
    deal(address(goldiswap), address(this), locksAmount);
    goldiswap.approve(address(goldilocked), locksAmount);
    goldilocked.stake(locksAmount);
    deal(address(honey), address(this), oneDayPrgCost);
    honey.approve(address(goldilocked), oneDayPrgCost);
    vm.warp(1 days + 1);
    goldilocked.unstake(locksAmount);
    goldilocked.stir(oneDayPrg);

    assertEq(goldiswap.balanceOf(address(this)), oneDayLocksProceeds + locksAmount);
  }

  function testInjectLiquidityFailMultisig() public {
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(Goldiswap.NotMultisig.selector));
    goldiswap.injectLiquidity(69, 69);
  }

  function testInjectLiquiditySuccess() public {
    deal(address(honey), address(this), 69+69);
    honey.approve(address(goldiswap), 69+69);
    goldiswap.injectLiquidity(69, 69);

    assertEq(goldiswap.fsl(), initialFSL + 69);
    assertEq(goldiswap.psl(), initialPSL + 69);
    assertEq(honey.balanceOf(address(goldiswap)), 69+69);
    assertEq(honey.balanceOf(address(this)), 0);
  }

  function testSetMultisigFailMultisig() public {
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(Goldiswap.NotMultisig.selector));
    goldiswap.setMultisig(address(0x69));
  }

  function testSetMultisigSuccess() public {
    goldiswap.setMultisig(address(0x69));

    assertEq(goldiswap.multisig(), address(0x69));
  }

}