//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../lib/forge-std/src/Test.sol";
import { LibRLP } from "../../lib/solady/src/utils/LibRLP.sol";
import { Goldiswap } from "../../src/core/Goldiswap.sol";
import { Goldilocked } from "../../src/core/Goldilocked.sol";
import { Goldilend } from "../../src/core/Goldilend.sol";
import { Goldigovernor } from "../../src/governance/Goldigovernor.sol";
import { Timelock } from "../../src/governance/Timelock.sol";
import { govLOCKS } from "../../src/governance/govLOCKS.sol";
import { Honey } from "../../src/mock/Honey.sol";
import { Bera } from "../../src/mock/Bera.sol";
import { HoneyComb } from "../../src/mock/HoneyComb.sol";
import { Beradrome } from "../../src/mock/Beradrome.sol";
import { BondBear } from "../../src/mock/BondBear.sol";
import { BandBear } from "../../src/mock/BandBear.sol";
import { ConsensusVault } from "../../src/mock/ConsensusVault.sol";

contract GoldiswapTest is Test {

  using LibRLP for address;

  Goldiswap goldiswap;
  Goldilend goldilend;
  govLOCKS govlocks;
  Timelock timelock;
  Goldilocked goldilocked;
  Goldigovernor goldigov;
  Honey honey;
  Bera bera;
  HoneyComb honeycomb;
  Beradrome beradrome;
  BondBear bondbear;
  BandBear bandbear;
  ConsensusVault consensusvault;

  uint256 initialFSL = 1050000e18;
  uint256 initialPSL = 320000e18;

  uint256 txAmount = 10e18;
  // uint256 costOf10Locks = 5641049601535046139648;
  // uint256 costOf10Locks = 5627518081751651091792;
  // uint256 costOf10Locks = 6413739173303640480000;
  uint256 costOf10Locks = 262883805905681940;
  // uint256 proceedsof10Locks = 5300673535135953225736;
  // uint256 proceedsof10Locks = 5313319664425536973008;
  // uint256 proceedsof10Locks = 6073810997118547534560;
  uint256 proceedsof10Locks = 248950964192680847;

  bytes4 NotMultisigSelector = 0xf05e412b;
  bytes4 NotGoldilockedSelector = 0xfce9a065;
  bytes4 ExcessiveSlippageSelector = 0x97c7f537;

  function setUp() public {
    Goldilocked goldilockedComputed = Goldilocked(address(this).computeAddress(12));
    Goldigovernor goldigovComputed = Goldigovernor(address(this).computeAddress(13));

    honey = new Honey();
    bera = new Bera();
    honeycomb = new HoneyComb();
    beradrome = new Beradrome();
    bondbear = new BondBear();
    bandbear = new BandBear();
    consensusvault = new ConsensusVault(address(bera));

    goldiswap = new Goldiswap(initialFSL, initialPSL, address(goldilockedComputed), address(honey), address(this));
    uint256 startingPoolSize = 1000e18;
    uint256 protocolInterestRate = 1e17;
    uint256 porridgeMultiple = 1e13;
    address honeyjar = address(0x69420);
    address[] memory boostNfts = new address[](2);
    boostNfts[0] = address(honeycomb);
    boostNfts[1] = address(beradrome);
    uint8[] memory boosts = new uint8[](2);
    boosts[0] = 6;
    boosts[1] = 9;
    goldilend = new Goldilend(
      startingPoolSize,
      protocolInterestRate,
      porridgeMultiple,
      address(goldilockedComputed),
      address(this),
      honeyjar,
      address(bera),
      address(consensusvault),
      boostNfts,
      boosts
    );
    govlocks = new govLOCKS(address(goldiswap), address(goldigovComputed), address(goldilockedComputed));
    timelock = new Timelock(address(goldigovComputed), 5 days);
    address[] memory allocationsAddress = new address[](3);
    allocationsAddress[0] = address(0x69);
    allocationsAddress[1] = address(0x420);
    allocationsAddress[2] = address(0x42069);
    uint256[] memory allocationsAmt = new uint256[](3);
    allocationsAmt[0] = 12000000e18;
    allocationsAmt[1] = 12000000e18;
    allocationsAmt[2] = 12000000e18;
    goldilocked = new Goldilocked(address(goldiswap), address(goldilend), address(govlocks), address(honey), allocationsAddress, allocationsAmt);
    goldigov = new Goldigovernor(address(timelock), address(govlocks), address(this), 5761, 69, 4e18);

    address[] memory nfts = new address[](2);
    nfts[0] = address(bondbear);
    nfts[1] = address(bandbear);
    uint256[] memory values = new uint256[](2);
    values[0] = 50;
    values[1] = 50;
    goldilend.setValue(100e18, nfts, values);
    goldilend.setShareRates(45, 5);
    deal(address(bera), address(goldilend), startingPoolSize);
    deal(address(bera), address(consensusvault), type(uint256).max / 2);
  }

  modifier dealandApproveUserHoney() {
    deal(address(honey), address(this), type(uint256).max / 2);
    honey.approve(address(goldiswap), type(uint256).max / 2);
    _;
  }

  modifier dealLocks() {
    deal(address(goldiswap), address(this), txAmount);
    _;
  }

  modifier dealGammHoney() {
    deal(address(honey), address(goldiswap), type(uint256).max);
    _;
  }

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

  function testBuy() public dealandApproveUserHoney {
    goldiswap.buy(txAmount, type(uint256).max);

    uint256 userLocksBalance = goldiswap.balanceOf(address(this));
    uint256 userHoneyBalance = honey.balanceOf(address(this));

    assertEq(userLocksBalance, txAmount);
    assertEq(userHoneyBalance, (type(uint256).max / 2) - costOf10Locks);
  }

  function testSell() public dealLocks dealGammHoney {
    goldiswap.sell(txAmount, 0);

    uint256 userLocksBalance = goldiswap.balanceOf(address(this));
    uint256 userHoneyBalance = honey.balanceOf(address(this));

    assertEq(userLocksBalance, 0);
    assertEq(userHoneyBalance, proceedsof10Locks);
  }

  function testRedeemed() public dealLocks dealGammHoney {
    goldiswap.redeem(txAmount);

    uint256 userLocksBalance = goldiswap.balanceOf(address(this));
    uint256 userHoneyBalance = honey.balanceOf(address(this));
    uint256 floorPriceof10Locks = goldiswap.floorPrice() * 10;

    assertEq(userLocksBalance, 0);
    assertEq(userHoneyBalance, floorPriceof10Locks);
  }

  function testSuccessfulTransfer() public dealLocks {
    // bytes4(keccak256(bytes('transfer(address,uint256)')));
    (bool success, bytes memory data) = address(goldiswap).call(abi.encodeWithSelector(0xa9059cbb, address(0x01), 5e18));
    require(data.length == 0 || abi.decode(data, (bool)), 'transfer failed');
    assertEq(true, success);
    assertEq(goldiswap.balanceOf(address(0x01)), 5e18);
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

    assertEq(goldiswap.targetRatio(), 342000000000000000);
  }

  function testMaxFloorReduce() public {
    vm.store(address(goldiswap), bytes32(uint256(0)), bytes32(uint256(12424533327755417665454800)));
    vm.store(address(goldiswap), bytes32(uint256(1)), bytes32(uint256(6069210257394481945730874)));
    vm.store(address(goldiswap), bytes32(uint256(0x05345cdf77eb68f44c)), bytes32(uint256(8402860035123450385400)));
    vm.store(address(goldiswap), bytes32(uint256(4)), bytes32(uint256(1692551675)));

    deal(address(honey), address(this), 1251210488977958997148919);
    deal(address(goldiswap), address(this), 543082473864185130000);
    deal(address(honey), address(goldiswap), 16442576931719627115185675);

    vm.warp(1693936841);
    goldiswap.sell(5000000000000000000, 9886383387107016000000);

    assertEq(goldiswap.targetRatio(), 342000000000000000);
  }

  function testInjectLiquidity() public {
    uint256 fsltemp = goldiswap.fsl();
    uint256 psltemp = goldiswap.psl();
    uint256 injected = 69e18;
    deal(address(honey), address(this), injected * 2);
    honey.approve(address(goldiswap), injected * 2);
    goldiswap.injectLiquidity(injected, injected);

    assertEq(goldiswap.fsl(), fsltemp + injected);
    assertEq(goldiswap.psl(), psltemp + injected);
    assertEq(honey.balanceOf(address(goldiswap)), injected * 2);
  }

  function testSetMultisigFail() public {
    vm.prank(address(0x69));
    vm.expectRevert(NotMultisigSelector);
    goldiswap.setMultisig(address(0x69));
  }

  function testSetMultisig() public {
    goldiswap.setMultisig(address(0x69));
    
    assertEq(goldiswap.multisig(), address(0x69));
  }

  function testDrainGamm() public {
    uint256 milly = 1000000e18;
    deal(address(honey), address(this), milly);
    honey.approve(address(goldiswap), milly);
    deal(address(honey), address(goldiswap), milly);

    uint256 beforeGammLocks = goldiswap.balanceOf(address(goldiswap));
    uint256 beforeGammHoney = honey.balanceOf(address(goldiswap));
    uint256 beforeUserLocks = goldiswap.balanceOf(address(this));
    uint256 beforeUserHoney = honey.balanceOf(address(this));
    console.log("before: goldiswap $LOCKS balance", beforeGammLocks);
    console.log("before: goldiswap $HONEY balance", beforeGammHoney);
    console.log("before: user $LOCKS balance", beforeUserLocks);
    console.log("before: user $HONEY balance", beforeUserHoney);
    console.log("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");



    goldiswap.buy(10e18, type(uint256).max);



    uint256 afterGammLocks = goldiswap.balanceOf(address(goldiswap));
    uint256 afterGammHoney = honey.balanceOf(address(goldiswap));
    uint256 afterUserLocks = goldiswap.balanceOf(address(this));
    uint256 afterUserHoney = honey.balanceOf(address(this));
    console.log("after: goldiswap $LOCKS balance", afterGammLocks);
    console.log("after: goldiswap $HONEY balance", afterGammHoney);
    console.log("after: user $LOCKS balance", afterUserLocks);
    console.log("after: user $HONEY balance", afterUserHoney);
    console.log(beforeUserHoney - afterUserHoney);
  }

}