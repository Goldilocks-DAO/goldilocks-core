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

contract GoldiswapGasTest is Test {

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
  uint256 mediumTxAmount = 100e18;
  uint256 largeTxAmount = 1000e18;

  uint256 gas10Buy = 10e18;
  uint256 gas100Buy = 10e18;
  uint256 gas1000Buy = 10e18;

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
      10,
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
    goldilend.setDurations(7 days, 21 days);
    goldilend.setBorrowingActive(true);
    deal(address(bera), address(goldilend), startingPoolSize);
    deal(address(bera), address(consensusvault), type(uint256).max / 2);
  }

  modifier dealandApproveUserHoney() {
    deal(address(honey), address(this), type(uint256).max / 2);
    honey.approve(address(goldiswap), type(uint256).max);
    _;
  }

  modifier dealUserLocks() {
    deal(address(goldiswap), address(this), type(uint256).max / 2);
    _;
  }

  modifier dealGammHoney() {
    deal(address(honey), address(goldiswap), type(uint256).max / 2);
    _;
  }

  // gasused = 119360, actual = 114264
  function test10Buy() public dealandApproveUserHoney {
    uint256 gasStart = gasleft();
    goldiswap.buy(txAmount, type(uint256).max);
    uint256 gasEnd = gasleft();
    uint256 gasUsed = gasStart   - gasEnd;
    assert(gasUsed <= 119360);
  }

  // gasused = 301430, actual = 296334
  function test100Buy() public dealandApproveUserHoney {
    uint256 gasStart = gasleft();
    goldiswap.buy(mediumTxAmount, type(uint256).max);
    uint256 gasEnd = gasleft();
    uint256 gasUsed = gasStart - gasEnd;
    assert(gasUsed <= 310430);
  }

  // gasused = 2110494, actual = 2105398
  function test1000Buy() public dealandApproveUserHoney {
    uint256 gasStart = gasleft();
    goldiswap.buy(largeTxAmount, type(uint256).max);
    uint256 gasEnd = gasleft();
    uint256 gasUsed = gasStart - gasEnd;
    assert(gasUsed <= 2110494);
  }

  // 10buy -    114264   | cost - 5641049601535046139648

  // 100buy -   296334   | cost - 57852097809804339185412

  // 1000buy -  2105398  | cost - 935738532191833460868212

  // 7   / 5641   = 0.001240915
  // 18  / 57852  = 0.000311139
  // 132 / 935738 = 0.000141065


  // gasused = 128109, actual = 122898
  function testnew10000Buy() public dealandApproveUserHoney {
    uint256 gasStart = gasleft();
    goldiswap.buy(txAmount*1000, type(uint256).max);
    uint256 gasEnd = gasleft();
    uint256 gasUsed = gasStart   - gasEnd;
    console.log(gasUsed);
    assert(gasUsed <= 128109);
  }

  // gasused = 323893, actual = 318682
  function testnew100000Buy() public dealandApproveUserHoney {
    uint256 gasStart = gasleft();
    goldiswap.buy(mediumTxAmount*1000, type(uint256).max);
    uint256 gasEnd = gasleft();
    uint256 gasUsed = gasStart - gasEnd;
    console.log(gasUsed);
    // assert(gasUsed <= 323893);
  }

  // gasused = 2477458, actual = 2263778
  function testnew1000000Buy() public dealandApproveUserHoney {
    uint256 gasStart = gasleft();
    goldiswap.buy(largeTxAmount*1000, type(uint256).max);
    uint256 gasEnd = gasleft();
    uint256 gasUsed = gasStart - gasEnd;
    console.log(gasUsed);
    // assert(gasUsed <= 2477458);
  }

}