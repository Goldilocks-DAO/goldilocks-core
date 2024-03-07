//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../lib/forge-std/src/Test.sol";
import { LibRLP } from "../lib/solady/src/utils/LibRLP.sol";
import { IERC721Receiver } from "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import { Goldiswap } from "../src/core/Goldiswap.sol";
import { Goldilocked } from "../src/core/Goldilocked.sol";
import { Goldilend } from "../src/core/Goldilend.sol";
import { Goldigovernor } from "../src/governance/Goldigovernor.sol";
import { Timelock } from "../src/governance/Timelock.sol";
import { govLocks } from "../src/governance/govLocks.sol";
import { Honey } from "../src/mock/Honey.sol";
import { iBGT } from "../src/mock/iBGT.sol";
import { HoneyComb } from "../src/mock/HoneyComb.sol";
import { Beradrome } from "../src/mock/Beradrome.sol";
import { BondBear } from "../src/mock/BondBear.sol";
import { BandBear } from "../src/mock/BandBear.sol";
import { iBGTVault } from "../src/mock/iBGTVault.sol";

contract BaseTest is Test, IERC721Receiver {

  using LibRLP for address;

  Goldiswap goldiswap;
  Goldilend goldilend;
  govLocks govlocks;
  Timelock timelock;
  Goldilocked goldilocked;
  Goldigovernor goldigov;
  Honey honey;
  iBGT ibgt;
  HoneyComb honeycomb;
  Beradrome beradrome;
  BondBear bondbear;
  BandBear bandbear;
  iBGTVault ibgtvault;

  uint256 initialFSL = 1050000e18;
  uint256 initialPSL = 320000e18;
  
  address honeyjar = address(0x69420);

  function setUp() public {
    Goldilocked goldilockedComputed = Goldilocked(address(this).computeAddress(12));
    Goldigovernor goldigovComputed = Goldigovernor(address(this).computeAddress(13));

    honey = new Honey();
    ibgt = new iBGT();
    honeycomb = new HoneyComb();
    beradrome = new Beradrome();
    bondbear = new BondBear();
    bandbear = new BandBear();
    ibgtvault = new iBGTVault(address(ibgt), address(ibgt));

    goldiswap = new Goldiswap(initialFSL, initialPSL, address(goldilockedComputed), address(honey), address(this));

    // amount of porridge earned per gbera per second
    // depends on what we want the initial apr
    // apr will be a function of the bera and porridge prices
    uint256 startingPoolSize = 1000e18;
    uint256 protocolInterestRate = 1e17;
    uint256 porridgeMultiple = 1e13;
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
      address(ibgt),
      address(ibgtvault),
      boostNfts,
      boosts
    );
    govlocks = new govLocks(address(goldiswap), address(goldigovComputed), address(goldilockedComputed));
    timelock = new Timelock(address(goldigovComputed), 5 days);
    address[] memory allocationsAddress = new address[](4);
    allocationsAddress[0] = address(0x69);
    allocationsAddress[1] = address(0x420);
    allocationsAddress[2] = address(0x42069);
    allocationsAddress[3] = address(0x69420);
    uint256[] memory allocationsAmt = new uint256[](4);
    allocationsAmt[0] = 12000000e18;
    allocationsAmt[1] = 12000000e18;
    allocationsAmt[2] = 10000000e18;
    allocationsAmt[3] = 7000000e18;
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
    deal(address(ibgt), address(goldilend), startingPoolSize);
    deal(address(ibgt), address(ibgtvault), type(uint256).max / 2);
  }

  function proposySame() public pure returns (address[] memory, string[] memory, bytes[] memory, uint256[] memory) {
    address[] memory targets = new address[](2);
    targets[0] = address(0x69);
    targets[1] = address(0x69);
    string[] memory signatures = new string[](2);
    signatures[0] = "hello";
    signatures[1] = "hello";
    bytes[] memory calldatas = new bytes[](2);
    calldatas[0] = hex"8eed55d1";
    calldatas[1] = hex"8eed55d1";
    uint256[] memory values = new uint256[](2);
    values[0] = 69;
    values[1] = 69;

    return (targets, signatures, calldatas, values);
  }

  function proposySamePropose() public returns (address[] memory, string[] memory, bytes[] memory, uint256[] memory) {
    address[] memory targets = new address[](2);
    targets[0] = address(0x69);
    targets[1] = address(0x69);
    string[] memory signatures = new string[](2);
    signatures[0] = "hello";
    signatures[1] = "hello";
    bytes[] memory calldatas = new bytes[](2);
    calldatas[0] = hex"8eed55d1";
    calldatas[1] = hex"8eed55d1";
    uint256[] memory values = new uint256[](2);
    values[0] = 69;
    values[1] = 69;
    deal(address(goldiswap), address(this), 5e18);
    goldiswap.approve(address(govlocks), 5e18);
    govlocks.deposit(5e18);
    vm.roll(2);
    goldigov.propose(targets, values, signatures, calldatas, "");

    return (targets, signatures, calldatas, values);
  }

  function proposyDiffQueue() public returns (address[] memory, string[] memory, bytes[] memory, uint256[] memory) {
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
    goldigov.propose(targets, values, signatures, calldatas, "");
    vm.roll(72);
    goldigov.castVote(1, 1);
    vm.roll(5900);
    goldigov.queue(1);

    return (targets, signatures, calldatas, values);
  }

  function proposyDiff() public pure returns (address[] memory, string[] memory, bytes[] memory, uint256[] memory) {
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

    return (targets, signatures, calldatas, values);
  }

  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) external virtual returns (bytes4) {
    return IERC721Receiver.onERC721Received.selector;
  }
}