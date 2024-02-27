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

contract TimelockTest is Test {

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

  bytes4 InvalidDelaySelector = 0x4fbe5dba;
  bytes4 InvalidETASelector = 0x50076458;
  bytes4 NotAdminSelector = 0x7bfa4b9f;
  bytes4 TxNotQueuedSelector = 0xccc85ba3;
  bytes4 TxLockedSelector = 0x30f4d404;
  bytes4 TxStaleSelector = 0x961c3199;
  bytes4 TxRevertedSelector = 0x51188255;

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

  function testEmptySignatures() public {
    address[] memory targets = new address[](2);
    targets[0] = address(0x69);
    targets[1] = address(0x69);
    string[] memory signatures = new string[](2);
    signatures[0] = "";
    signatures[1] = "";
    bytes[] memory calldatas = new bytes[](2);
    calldatas[0] = hex"8eed55d1";
    calldatas[1] = hex"8eed55d2";
    uint256[] memory values = new uint256[](2);
    values[0] = 0;
    values[1] = 0;
    deal(address(goldiswap), address(this), 401e18);
    goldiswap.approve(address(govlocks), 401e18);
    govlocks.deposit(401e18);
    vm.roll(2);
    goldigov.propose(targets, signatures, calldatas, values, "");
    vm.roll(72);
    goldigov.castVote(1, 1);
    vm.roll(5900);
    goldigov.queue(1);
    vm.warp(6 days);
    goldigov.execute(1);
  }

  function testSetAdminFail() public {
    vm.prank(address(0x69));
    vm.expectRevert(NotAdminSelector);
    timelock.setAdmin(address(0x69));
  }

  function testSetAdmin() public {
    vm.prank(address(goldigov));
    timelock.setAdmin(address(0x69));
    
    assertEq(timelock.admin(), address(0x69));
  }

  function testSetDelayFailAdmin() public {
    vm.prank(address(0x69));
    vm.expectRevert(NotAdminSelector);
    timelock.setDelay(69);
  }

  function testSetDelayFailDelay() public {
    vm.prank(address(goldigov));
    vm.expectRevert(InvalidDelaySelector);
    timelock.setDelay(1 days);
  }

  function testSetDelaySuccess() public {
    uint256 delay = 3 days;
    vm.prank(address(goldigov));
    timelock.setDelay(delay);

    assertEq(timelock.delay(), delay);
  }

  function testExecuteTxAdminFail() public {
    vm.prank(address(0x69));
    vm.expectRevert(NotAdminSelector);
    timelock.executeTransaction(address(0x69), 69, 69, "69", "69");
  }

  function testExecuteTxNotQueuedFail() public {
    vm.prank(address(goldigov));
    vm.expectRevert(TxNotQueuedSelector);
    timelock.executeTransaction(address(0x69), 69, 69, "69", "69");
  }

  function testExecuteLockedFail() public {
    address[] memory targets = new address[](2);
    targets[0] = address(0x69);
    targets[1] = address(0x69);
    string[] memory signatures = new string[](2);
    signatures[0] = "hello";
    signatures[1] = "helloagain";
    bytes[] memory calldatas = new bytes[](2);
    calldatas[0] = hex"8eed55d1";
    calldatas[1] = hex"8eed55d1";
    uint256[] memory values = new uint256[](2);
    values[0] = 0;
    values[1] = 0;
    deal(address(goldiswap), address(this), 401e18);
    goldiswap.approve(address(govlocks), 401e18);
    govlocks.deposit(401e18);
    vm.roll(2);
    goldigov.propose(targets, signatures, calldatas, values, "");
    vm.roll(72);
    goldigov.castVote(1, 1);
    vm.roll(5900);
    goldigov.queue(1);
    vm.expectRevert(TxLockedSelector);
    goldigov.execute(1);
  }

  function testExecuteStaleFail() public {
    address[] memory targets = new address[](2);
    targets[0] = address(0x69);
    targets[1] = address(0x69);
    string[] memory signatures = new string[](2);
    signatures[0] = "hello";
    signatures[1] = "helloagain";
    bytes[] memory calldatas = new bytes[](2);
    calldatas[0] = hex"8eed55d1";
    calldatas[1] = hex"8eed55d1";
    uint256[] memory values = new uint256[](2);
    values[0] = 0;
    values[1] = 0;
    deal(address(goldiswap), address(this), 401e18);
    goldiswap.approve(address(govlocks), 401e18);
    govlocks.deposit(401e18);
    vm.roll(2);
    goldigov.propose(targets, signatures, calldatas, values, "");
    vm.roll(72);
    goldigov.castVote(1, 1);
    vm.roll(5900);
    goldigov.queue(1);
    vm.warp(690 days);
    vm.prank(address(goldigov));
    vm.expectRevert(TxStaleSelector);
    timelock.executeTransaction(targets[0], 432001, values[0], calldatas[0], signatures[0]);
  }

  function testExecuteRevertFail() public {
    // deal(address(goldigov), 1 ether);
    address[] memory targets = new address[](2);
    targets[0] = address(0x69);
    targets[1] = address(0x69);
    string[] memory signatures = new string[](2);
    signatures[0] = "hello";
    signatures[1] = "helloagain";
    bytes[] memory calldatas = new bytes[](2);
    calldatas[0] = hex"8eed55d1";
    calldatas[1] = hex"8eed55d1";
    uint256[] memory values = new uint256[](2);
    values[0] = 69;
    values[1] = 0;
    deal(address(goldiswap), address(this), 401e18);
    goldiswap.approve(address(govlocks), 401e18);
    govlocks.deposit(401e18);
    vm.roll(2);
    goldigov.propose(targets, signatures, calldatas, values, "");
    vm.roll(72);
    goldigov.castVote(1, 1);
    vm.roll(5900);
    goldigov.queue(1);
    vm.warp(6 days);
    vm.prank(address(goldigov));
    vm.expectRevert(TxRevertedSelector);
    timelock.executeTransaction(targets[0], 432001, 69, calldatas[0], signatures[0]);
  }

  function testCancelAdminFail() public {
    vm.expectRevert(NotAdminSelector);
    timelock.cancelTransaction(address(0x69), 69, 69, "", "");
  }

  function testQueueAdminFail() public {
    vm.expectRevert(NotAdminSelector);
    timelock.queueTransaction(address(0x69), 69, 69, "", "");
  }

  function testQueueETAFail() public {
    vm.prank(address(goldigov));
    vm.expectRevert(InvalidETASelector);
    timelock.queueTransaction(address(0x69), 0, 69, "", "");
  }

}