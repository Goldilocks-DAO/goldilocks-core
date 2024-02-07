//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../lib/forge-std/src/Test.sol";
import { LibRLP } from "../../lib/solady/src/utils/LibRLP.sol";
import { SafeTransferLib } from "../../lib/solady/src/utils/SafeTransferLib.sol";
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

contract govLOCKSTest is Test {

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

  bytes4 NoSuchBlockSelector = 0xfd8d4168;

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
    goldilocked = new Goldilocked(address(goldiswap), address(goldilend), address(govlocks), address(honey));
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

  function testLocksName() public {
    assertEq(govlocks.name(), "Governance Locks");
  }

  function testLocksSymbol() public {
    assertEq(govlocks.symbol(), "govLOCKS");
  }

  function testDeposit() public {
    deal(address(goldiswap), address(this), 5e18);
    goldiswap.approve(address(govlocks), 5e18);
    govlocks.deposit(5e18);

    assertEq(goldiswap.balanceOf(address(this)), 0);
    assertEq(govlocks.balanceOf(address(this)), 5e18);
  }

  function testWithdraw() public {
    deal(address(goldiswap), address(this), 5e18);
    goldiswap.approve(address(govlocks), 5e18);
    govlocks.deposit(5e18);
    govlocks.withdraw(5e18);

    assertEq(goldiswap.balanceOf(address(this)), 5e18);
    assertEq(govlocks.balanceOf(address(this)), 0);
  }

  function testNoSuchBlock() public {
    deal(address(goldiswap), address(this), 5e18);
    goldiswap.approve(address(govlocks), 5e18);
    govlocks.deposit(5e18);
    vm.roll(2);
    vm.expectRevert(NoSuchBlockSelector);
    govlocks.getPriorVotes(address(this), 2);
  }

  function testGetCurrentVotes() public {
    deal(address(goldiswap), address(this), 5e18);
    goldiswap.approve(address(govlocks), 5e18);
    govlocks.deposit(5e18);
    vm.roll(2);
    uint256 votes = govlocks.getCurrentVotes(address(this));

    assertEq(votes, 5e18);
  }

  function testGetPriorVotesNone() public {
    vm.roll(2);
    uint256 votes = govlocks.getPriorVotes(address(this), 1);

    assertEq(votes, 0);
  }

  function testGetPriorVotes() public {
    deal(address(goldiswap), address(this), 5e18);
    goldiswap.approve(address(govlocks), 5e18);
    govlocks.deposit(5e18);
    vm.roll(2);
    uint256 votes = govlocks.getPriorVotes(address(this), 1);

    assertEq(votes, 5e18);
  }

  function testGetPriorVotesImplicitZero() public {
    vm.roll(69);
    deal(address(goldiswap), address(this), 5e18);
    goldiswap.approve(address(govlocks), 5e18);
    govlocks.deposit(5e18);
    vm.roll(420);
    uint256 votes = govlocks.getPriorVotes(address(this), 40);

    assertEq(votes, 0);
  }

  function testGetPriorVotesNotMostRecentBalance() public {
    vm.roll(69);
    deal(address(goldiswap), address(this), 5e18);
    goldiswap.approve(address(govlocks), 5e18);
    govlocks.deposit(5e18);
    vm.roll(420);
    deal(address(goldiswap), address(this), 5e18);
    goldiswap.approve(address(govlocks), 5e18);
    govlocks.deposit(5e18);
    vm.roll(500);
    uint256 votes = govlocks.getPriorVotes(address(this), 80);

    assertEq(votes, 5e18);
  }

  function testGetPriorVotesNotMostRecentBalanceEqual() public {
    vm.roll(69);
    deal(address(goldiswap), address(this), 5e18);
    goldiswap.approve(address(govlocks), 5e18);
    govlocks.deposit(5e18);
    vm.roll(420);
    deal(address(goldiswap), address(this), 5e18);
    goldiswap.approve(address(govlocks), 5e18);
    govlocks.deposit(5e18);
    vm.roll(500);
    deal(address(goldiswap), address(this), 5e18);
    goldiswap.approve(address(govlocks), 5e18);
    govlocks.deposit(5e18);
    vm.roll(1000);
    deal(address(goldiswap), address(this), 5e18);
    goldiswap.approve(address(govlocks), 5e18);
    govlocks.deposit(5e18);
    uint256 votes = govlocks.getPriorVotes(address(this), 420);

    assertEq(votes, 10e18);
  }

  function testGetPriorVotesNotMostRecentBalanceLower() public {
    vm.roll(69);
    deal(address(goldiswap), address(this), 5e18);
    goldiswap.approve(address(govlocks), 5e18);
    govlocks.deposit(5e18);
    vm.roll(420);
    deal(address(goldiswap), address(this), 5e18);
    goldiswap.approve(address(govlocks), 5e18);
    govlocks.deposit(5e18);
    vm.roll(500);
    deal(address(goldiswap), address(this), 5e18);
    goldiswap.approve(address(govlocks), 5e18);
    govlocks.deposit(5e18);
    vm.roll(1000);
    deal(address(goldiswap), address(this), 5e18);
    goldiswap.approve(address(govlocks), 5e18);
    govlocks.deposit(5e18);
    uint256 votes = govlocks.getPriorVotes(address(this), 421);

    assertEq(votes, 10e18);
  }

  // function testDelegate() public {
  //   address user = address(0x69);
  //   deal(address(goldiswap), address(this), 5e18);
  //   goldiswap.approve(address(govlocks), 5e18);
  //   govlocks.deposit(5e18);
  //   vm.roll(2);
  //   govlocks.delegate(user);
  //   vm.roll(3);
  //   uint256 userVotes = govlocks.getPriorVotes(user, block.number - 1);
  //   uint256 thisVotes = govlocks.getPriorVotes(address(this), block.number - 1);

  //   assertEq(userVotes, 5e18);
  //   assertEq(thisVotes, 5e18);
  // }

  // function testDelegateDelegate() public {
  //   address user = address(0x69);
  //   address user2 = address(0x420);
  //   deal(address(goldiswap), address(this), 5e18);
  //   goldiswap.approve(address(govlocks), 5e18);
  //   govlocks.deposit(5e18);
  //   vm.roll(2);
  //   govlocks.delegate(user);
  //   vm.roll(3);
  //   govlocks.delegate(user2);
  //   vm.roll(4);
  //   uint256 userVotes = govlocks.getPriorVotes(user, block.number - 1);
  //   uint256 user2Votes = govlocks.getPriorVotes(user2, block.number - 1);
  //   uint256 thisVotes = govlocks.getPriorVotes(address(this), block.number - 1);

  //   assertEq(userVotes, 0);
  //   assertEq(user2Votes, 5e18);
  //   assertEq(thisVotes, 5e18);
  // }

  // function testDelegateDelegateVote() public {
  //   address user = address(0x69);
  //   address user2 = address(0x420);
  //   deal(address(goldiswap), user, 5e18);
  //   vm.startPrank(user);
  //   goldiswap.approve(address(govlocks), 5e18);
  //   govlocks.deposit(5e18);
  //   vm.roll(2);
  //   govlocks.delegate(user2);
  //   vm.stopPrank();
  //   address[] memory targets = new address[](2);
  //   targets[0] = address(0x69);
  //   targets[1] = address(0x69);
  //   string[] memory signatures = new string[](2);
  //   signatures[0] = "hello";
  //   signatures[1] = "helloagain";
  //   bytes[] memory calldatas = new bytes[](2);
  //   calldatas[0] = hex"8eed55d1";
  //   calldatas[1] = hex"8eed55d1";
  //   uint256[] memory values = new uint256[](2);
  //   values[0] = 0;
  //   values[1] = 0;
  //   deal(address(goldiswap), address(this), 401e18);
  //   goldiswap.approve(address(govlocks), 401e18);
  //   govlocks.deposit(401e18);
  //   vm.roll(3);
  //   goldigov.propose(targets, signatures, calldatas, values, "");

  //   vm.roll(20);
  //   vm.prank(user);
  //   SafeTransferLib.safeTransfer(address(govlocks), address(0x80085), 5e18);
  //   vm.roll(73);

  //   vm.prank(user);
  //   goldigov.castVote(1, 1);
  //   vm.prank(user2);
  //   goldigov.castVote(1, 1);
  //   console.log(govlocks.balanceOf(user));
  //   console.log(govlocks.balanceOf(user2));
  // }

  function testUpdatedStakedBalance() public {
    uint256 amt = 69e18;
    deal(address(goldiswap), address(this), amt + 5e18);
    goldiswap.approve(address(govlocks), amt);
    govlocks.deposit(amt);
    goldiswap.approve(address(goldilocked), 5e18);
    goldilocked.stake(5e18);
    vm.roll(2);

    uint256 votes = govlocks.getPriorVotes(address(this), 1);
    uint256 staked = goldilocked.getStaked(address(this));

    assertEq(votes, staked + amt);
  }

}