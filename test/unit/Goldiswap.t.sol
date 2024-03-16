//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { BaseUnitTest } from "../base/BaseUnitTest.t.sol";
import { Goldiswap } from "../../src/core/goldiswap/Goldiswap.sol";
import { IGoldiswap } from "../../src/interfaces/IGoldiswap.sol";

contract UnitGoldiswapTest is BaseUnitTest {

  function testLocksName() public {
    assertEq(goldiswap.name(), "Locks");
  }

  function testLocksSymbol() public {
    assertEq(goldiswap.symbol(), "LOCKS");
  }

  function testFloorPrice() public {
    assertEq(goldiswap.floorPrice(), startingFloorPrice);
  }

  function testRandomFloorPrice() public {
    vm.store(address(goldiswap), bytes32(uint256(0)), bytes32(uint256(23457745e18)));
    vm.store(address(goldiswap), bytes32(uint256(1)), bytes32(uint256(8340957e18)));
    vm.store(address(goldiswap), bytes32(uint256(0x05345cdf77eb68f44c)), bytes32(uint256(4374e18)));
    
    assertEq(goldiswap.floorPrice(), randomFloorPrice);
  }

  function testMarketPrice() public {
    assertEq(goldiswap.marketPrice(), startingMarketPrice);
  }

  function testRandomMarketPrice() public {
    vm.store(address(goldiswap), bytes32(uint256(0)), bytes32(uint256(23457745e18)));
    vm.store(address(goldiswap), bytes32(uint256(1)), bytes32(uint256(8340957e18)));
    vm.store(address(goldiswap), bytes32(uint256(0x05345cdf77eb68f44c)), bytes32(uint256(4374e18)));

    assertEq(goldiswap.marketPrice(), randomMarketPrice);
  }

  function testBuyFailSlippage() public {
    vm.expectRevert(abi.encodeWithSelector(IGoldiswap.ExcessiveSlippage.selector));
    goldiswap.buy(txAmount, 0);
  }

  function testBuySuccess() public dealandApproveUserHoney {
    goldiswap.buy(txAmount, type(uint256).max);

    assertEq(goldiswap.balanceOf(address(this)), txAmount);
    assertEq(honey.balanceOf(address(this)), (type(uint256).max / 2) - costOf10Locks);
  }

  function testBuyNonMultisig() public {
    deal(address(honey), address(0xbbb), type(uint256).max / 2);
    vm.startPrank(address(0xbbb));
    honey.approve(address(goldiswap), type(uint256).max / 2);
    goldiswap.buy(txAmount, type(uint256).max);
    vm.stopPrank();

    assertEq(goldiswap.balanceOf(address(0xbbb)), txAmount);
    assertEq(honey.balanceOf(address(0xbbb)), (type(uint256).max / 2) - costOf10Locks - taxof10Locks);
  }

  function testSellFailSlippage() public {
    vm.expectRevert(abi.encodeWithSelector(IGoldiswap.ExcessiveSlippage.selector));
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

  function testFloorDecreaseNoDecrease() public dealLocks dealGoldiswapHoney {
    goldiswap.sell(txAmount, 0);

    assertEq(goldiswap.targetRatio(), 32e16);
  }

  function testFloorDecreaseNotElapsed() public dealLocks dealGoldiswapHoney {
    goldiswap.sell(txAmount, 0);
    
    assertEq(goldiswap.targetRatio(), 32e16);
    assertEq(goldiswap.lastFloorDecrease(), 1);
  }

  function testFloorDecreaseElapsed() public dealGoldiswapHoney {
    deal(address(goldiswap), address(this), txAmount*1000);
    vm.warp(2 days);
    goldiswap.sell(txAmount*1000, 0);
    vm.warp(block.timestamp + 69);

    assertEq(goldiswap.targetRatio(), decreasedTargetRatio);
    assertEq(goldiswap.lastFloorDecrease(), block.timestamp - 69);
  }

  function testFloorDecreaseMaxElapsed() public dealGoldiswapHoney {
    deal(address(goldiswap), address(this), txAmount*1000*2);
    goldiswap.sell(txAmount*1000, 0);
    vm.warp(2 days);
    goldiswap.sell(txAmount*1000, 0);

    assertEq(goldiswap.targetRatio(), decreasedTargetRatio);
    assertEq(goldiswap.lastFloorDecrease(), block.timestamp);
  }

  function testFloorDecreaseMaxDecrease() public dealGoldiswapHoney {
    deal(address(goldiswap), address(this), txAmount*1000*2);
    goldiswap.sell(txAmount*1000, 0);
    vm.warp(6 days);
    goldiswap.sell(txAmount*1000, 0);

    assertEq(goldiswap.targetRatio(), maxDecreasedTargetRatio);
    assertEq(goldiswap.lastFloorDecrease(), block.timestamp);
  }

  function testBorrowTransferFailGoldilocked() public {
    vm.expectRevert(abi.encodeWithSelector(IGoldiswap.NotGoldilocked.selector));
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
    vm.expectRevert(abi.encodeWithSelector(IGoldiswap.NotGoldilocked.selector));
    goldiswap.porridgeMint(address(0x69), 69, 69);
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

  function testInjectLiquidityFailGoldigov() public {
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(IGoldiswap.NotTimelock.selector));
    goldiswap.injectLiquidity(69, 69);
  }

  function testInjectLiquiditySuccess() public {
    bytes memory _calldata = abi.encodeWithSignature("approve(address,uint256)", address(goldiswap), 69+69);
    bytes memory _calldatta = abi.encodeWithSignature("injectLiquidity(uint256,uint256)", 69, 69);
    deal(address(honey), address(timelock), 69+69);
    address[] memory targets = new address[](2);
    targets[0] = address(honey);
    targets[1] = address(goldiswap);
    string[] memory signatures = new string[](2);
    signatures[0] = "";
    signatures[1] = "";
    bytes[] memory calldatas = new bytes[](2);
    calldatas[0] = _calldata;
    calldatas[1] = _calldatta;
    uint256[] memory values = new uint256[](2);
    values[0] = 0;
    values[1] = 0;
    deal(address(goldiswap), address(this), 401e18);
    goldiswap.approve(address(govlocks), 401e18);
    govlocks.deposit(401e18);
    govlocks.delegate(address(this));
    vm.roll(2);
    goldigov.propose(targets, values, signatures, calldatas, "");
    vm.roll(72);
    goldigov.castVote(1, 1);
    vm.roll(5900);
    goldigov.queue(1);
    vm.warp(6 days);
    goldigov.execute(1);
    (, , , , , , , , , bool executed) = goldigov.proposals(1);

    assertEq(executed, true);
    assertEq(goldiswap.fsl(), initialFSL + 69);
    assertEq(goldiswap.psl(), initialPSL + 69);
    assertEq(honey.balanceOf(address(goldiswap)), 69+69);
    assertEq(honey.balanceOf(address(timelock)), 0);
  }

}