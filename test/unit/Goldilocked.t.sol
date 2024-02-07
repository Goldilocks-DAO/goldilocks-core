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

contract GoldilockedTest is Test {

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

  uint256 locksAmountPrg = 100e18;
  uint256 locksAmount = 100000e18;
  uint256 borrowAmount = 1050e18;
  uint256 HalfDayofYield = 68493150684931500;
  uint256 OneDayofYield = 136986301369863000;
  uint256 OneDayandHalfofYield = 205479452054794500;
  uint256 TwoDaysofYield = 273972602739726000;
  uint256 twoMonthsOfGoldilendStakingYield = 43e18;

  bytes4 NotGoldilendSelector = 0xc81d51dc;
  bytes4 InvalidUnstakeSelector = 0x280cf628;
  bytes4 LocksBorrowedAgainstSelector = 0xad7facc8;
  bytes4 InsufficientBorrowLimitSelector = 0xda392797;
  bytes4 ExcessiveRepaySelector = 0x7bc3c3ef;

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

  modifier dealandStake100Locks() {
    deal(address(goldiswap), address(this), locksAmountPrg);
    goldiswap.approve(address(goldilocked), locksAmountPrg);
    goldilocked.stake(locksAmountPrg);
    _;
  }

  modifier dealandStake100000Locks() {
    deal(address(goldiswap), address(this), locksAmount);
    goldiswap.approve(address(goldilocked), locksAmount);
    goldilocked.stake(locksAmount);
    _;
  }

  modifier dealUser280Honey() {
    deal(address(honey), address(this), 280e18);
    honey.approve(address(goldilocked), 280e18);
    _;
  }

  modifier dealGammMaxHoney() {
    deal(address(honey), address(goldiswap), type(uint256).max);
    _;
  }

  function testNotGoldilend() public { 
    vm.prank(address(0x01));
    vm.expectRevert(NotGoldilendSelector);
    goldilocked.goldilendMint(address(this), 69e18);
  }

  function testInvalidUnstake() public dealandStake100Locks {
    vm.expectRevert(InvalidUnstakeSelector);
    goldilocked.unstake(locksAmountPrg + 1);
  }

  function testLocksBorrowedAgainst() public dealGammMaxHoney {
    deal(address(goldiswap), address(this), 100000e18);
    goldiswap.approve(address(goldilocked), 100000e18);
    goldilocked.stake(100000e18);
    goldilocked.borrow(1050e18);
    vm.expectRevert(LocksBorrowedAgainstSelector);
    goldilocked.unstake(1e18);
  }

  function testPRGName() public {
    assertEq(goldilocked.name(), "Porridge Token");
  }

  function testPRGSymbol() public {
    assertEq(goldilocked.symbol(), "PRG");
  }

  function testCalculateHalfDayofYield() public dealandStake100Locks {
    vm.warp(block.timestamp + (1 days / 2));
    goldilocked.claim();

    uint256 prgBalance = goldilocked.balanceOf(address(this));
    
    assertEq(prgBalance, HalfDayofYield);
  }

  function testCalculate1DayofYield() public dealandStake100Locks {
    vm.warp(block.timestamp + 1 days);
    goldilocked.claim();

    uint256 prgBalance = goldilocked.balanceOf(address(this));

    assertEq(prgBalance, OneDayofYield);
  }

  function testCalculate1andHalfDayofYield() public dealandStake100Locks {
    vm.warp(block.timestamp + 1 days + (1 days / 2));
    goldilocked.claim();

    uint256 prgBalance = goldilocked.balanceOf(address(this));
    
    assertEq(prgBalance, OneDayandHalfofYield);
  }

  function testStake() public dealandStake100Locks {
    uint256 userBalanceofLocks = goldiswap.balanceOf(address(this));
    uint256 contractBalance = goldiswap.balanceOf(address(goldilocked));
    uint256 getStakedUserBalance = goldilocked.getStaked(address(this));

    assertEq(userBalanceofLocks, 0);
    assertEq(contractBalance, locksAmountPrg);
    assertEq(getStakedUserBalance, locksAmountPrg);
  }

  function testDoubleStake() public dealandStake100Locks {
    deal(address(goldiswap), address(this), locksAmountPrg);
    goldiswap.approve(address(goldilocked), locksAmountPrg);
    goldilocked.stake(locksAmountPrg);
  }

  function testUnstake() public dealandStake100Locks {
    vm.warp(block.timestamp + 1 days);
    goldilocked.unstake(locksAmountPrg);

    uint256 userBalanceofLocks = goldiswap.balanceOf(address(this));
    uint256 contractBalance = goldiswap.balanceOf(address(goldilocked));
    uint256 getStakedUserBalance = goldilocked.getStaked(address(this));
    uint256 prgBalance = goldilocked.balanceOf(address(this));

    assertEq(userBalanceofLocks, locksAmountPrg);
    assertEq(contractBalance, 0);
    assertEq(getStakedUserBalance, 0);
    assertEq(prgBalance, OneDayofYield);
  }

  function testStakeUnstake() public dealandStake100Locks {
    goldilocked.unstake(locksAmountPrg);

    uint256 userBalanceofLocks = goldiswap.balanceOf(address(this));
    uint256 getStakedUserBalance = goldilocked.getStaked(address(this));

    assertEq(userBalanceofLocks, locksAmountPrg);
    assertEq(getStakedUserBalance, 0);
  }

  function testStir() public dealandStake100Locks dealUser280Honey {
    vm.warp(block.timestamp + (2 * 1 days));
    goldilocked.unstake(locksAmountPrg);
    goldilocked.stir(TwoDaysofYield);

    uint256 userBalanceofPrg = goldilocked.balanceOf(address(this));
    uint256 userBalanceofLocks = goldiswap.balanceOf(address(this));
    uint256 userBalanceofHoney = honey.balanceOf(address(this));
    uint256 goldiswapBalanceofHoney = honey.balanceOf(address(goldiswap));

    assertEq(userBalanceofPrg, 0);
    assertEq(userBalanceofLocks, 100273972602739726000);
    assertEq(userBalanceofHoney, 279997123287671232877);
    assertEq(goldiswapBalanceofHoney, 2876712328767123);
  }

  function testClaim() public dealandStake100Locks {
    vm.warp(block.timestamp + 1 days);
    goldilocked.claim();

    uint256 userBalanceofPrg = goldilocked.balanceOf(address(this));
    uint256 userStakedLocks = goldilocked.getStaked(address(this));

    assertEq(userBalanceofPrg, OneDayofYield);
    assertEq(userStakedLocks, locksAmountPrg);
  }

  function testGetStaked() public dealandStake100Locks{
    uint256 userStakedLocks = goldilocked.getStaked(address(this));

    assertEq(userStakedLocks, locksAmountPrg);
  }

  function testGetStakeStartTime() public {
    vm.warp(69);
    deal(address(goldiswap), address(this), locksAmountPrg);
    goldiswap.approve(address(goldilocked), locksAmountPrg);
    goldilocked.stake(locksAmountPrg);

    uint256 timestamp = goldilocked.getStakeStartTime(address(this));

    assertEq(timestamp, 69);
  }

  function testGetClaimable() public dealandStake100Locks {
    vm.warp(block.timestamp + 1 days);

    uint256 claimable = goldilocked.getClaimable(address(this));

    assertEq(claimable, OneDayofYield);
  }

  function testGoldilendMint() public {
    deal(address(goldilend), address(this), 1e18);
    goldilend.approve(address(goldilend), 1e18);
    goldilend.stake(1e18);
    vm.warp(block.timestamp + (goldilend.MONTH_DAYS() * 2));
    goldilend.claim();

    uint256 userPrgBalance = goldilocked.balanceOf(address(this));

    assertEq(userPrgBalance, twoMonthsOfGoldilendStakingYield);
  }

    function testInsufficientBorrowLimit() public dealandStake100000Locks dealGammMaxHoney {
    vm.expectRevert(InsufficientBorrowLimitSelector);
    goldilocked.borrow(borrowAmount + 1);
  }

  function testExcessiveRepay() public dealandStake100000Locks dealGammMaxHoney {
    goldilocked.borrow(borrowAmount);
    vm.expectRevert(ExcessiveRepaySelector);
    goldilocked.repay(borrowAmount + 1);
  }

  function testBorrowLimitCalculation() public dealandStake100000Locks {
    uint256 limit = goldilocked.borrowLimit(address(this));

    assertEq(limit, borrowAmount);
  }

  function testBorrowLocks() public dealandStake100000Locks dealGammMaxHoney{
    goldilocked.borrow(borrowAmount);

    uint256 goldiswapHoneyBalance = honey.balanceOf(address(goldiswap));
    uint256 userHoneyBalance = honey.balanceOf(address(this));
    uint256 locked = goldilocked.getLocked(address(this));
    uint256 borrowed = goldilocked.getBorrowed(address(this));

    assertEq(goldiswapHoneyBalance, type(uint256).max - borrowAmount);
    assertEq(userHoneyBalance, borrowAmount);
    assertEq(locked, locksAmount);
    assertEq(borrowed, borrowAmount);
  }

  function testRepay() public dealandStake100000Locks dealGammMaxHoney {
    goldilocked.borrow(borrowAmount);
    honey.approve(address(goldilocked), borrowAmount);
    goldilocked.repay(borrowAmount);

    uint256 locked = goldilocked.getLocked(address(this));
    uint256 borrowed = goldilocked.getBorrowed(address(this));
    uint256 userHoneyBalance = honey.balanceOf(address(this));
    uint256 userStakedLocksBalance = goldilocked.getStaked(address(this));

    assertEq(locked, 0);
    assertEq(borrowed, 0);
    assertEq(userHoneyBalance, 0);
    assertEq(userStakedLocksBalance, locksAmount);
  }

  function testLockedAfterRepay() public dealandStake100000Locks dealGammMaxHoney {
    goldilocked.borrow(borrowAmount);
    honey.approve(address(goldilocked), type(uint256).max);
    goldilocked.repay(borrowAmount);

    uint256 locked = goldilocked.getLocked(address(this));

    assertEq(locked, 0);
  }

}