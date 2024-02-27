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

  uint256 locksAmount = 100000e18;
  uint256 borrowAmount = 1050e18;
  uint256 prgMintAmount = 200000000e18;
  uint256 locksMintAmount = 100000000e18;
  uint256 oneDayPrg = 136986301369863000000;
  uint256 HalfDayofYield = 68493150684931500000;
  uint256 OneDayandHalfofYield = 205479452054794500000;
  uint256 twoDaysPrg = 273972602739726000000;
  uint256 twoMonthsOfGoldilendStakingYield = 43e18;

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
    allocationsAmt[2] = 10000000e18;
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

  modifier dealAndStake100000Locks() {
    deal(address(goldiswap), address(this), locksAmount);
    goldiswap.approve(address(goldilocked), locksAmount);
    goldilocked.stake(locksAmount);
    _;
  }

  modifier dealGoldiswapMaxHoney() {
    deal(address(honey), address(goldiswap), type(uint256).max);
    _;
  }

  function testPRGName() public {
    assertEq(goldilocked.name(), "Porridge");
  }

  function testPRGSymbol() public {
    assertEq(goldilocked.symbol(), "PRG");
  }

  function testUserStakedLocksView() public dealAndStake100000Locks {
    assertEq(goldilocked.userStakedLocks(address(this)), locksAmount);
  }

  function testUserClaimablePrgView() public dealAndStake100000Locks {
    vm.warp(block.timestamp + 1 days);

    assertEq(goldilocked.userClaimablePrg(address(this)), oneDayPrg);
  }

  function testUserLockedLocksView() public dealAndStake100000Locks dealGoldiswapMaxHoney {
    goldilocked.borrow(borrowAmount);

    assertEq(goldilocked.userLockedLocks(address(this)), locksAmount);
  }

  function testUserBorrowedHoneyView() public dealAndStake100000Locks dealGoldiswapMaxHoney {
    goldilocked.borrow(borrowAmount);

    assertEq(goldilocked.userBorrowedHoney(address(this)), borrowAmount);
  }

  function testUserBorrowLimitView() public dealAndStake100000Locks {
    assertEq(goldilocked.userBorrowLimit(address(this)), borrowAmount);
  }

  function testStakeLocksSuccess() public {
    vm.warp(1 days + 1);
    deal(address(goldiswap), address(this), locksAmount);
    goldiswap.approve(address(goldilocked), locksAmount);
    goldilocked.stake(locksAmount);

    assertEq(goldilocked.userStakedLocks(address(this)), locksAmount);
    assertEq(goldiswap.balanceOf(address(goldilocked)), locksAmount + locksMintAmount);
    assertEq(goldiswap.balanceOf(address(this)), 0);
    assertEq(goldilocked.prgRewardDebt(address(this)), oneDayPrg);
    assertEq(govlocks.getCurrentVotes(address(this)), locksAmount);
  }

  function testDoubleStakeSuccess() public dealAndStake100000Locks {
    vm.warp(1 days + 1);
    deal(address(goldiswap), address(this), locksAmount);
    goldiswap.approve(address(goldilocked), locksAmount);
    goldilocked.stake(locksAmount);

    assertEq(goldilocked.userStakedLocks(address(this)), locksAmount + locksAmount);
    assertEq(goldiswap.balanceOf(address(goldilocked)), locksAmount + locksAmount + locksMintAmount);
    assertEq(goldiswap.balanceOf(address(this)), 0);
    assertEq(goldilocked.prgRewardDebt(address(this)), oneDayPrg);
    assertEq(govlocks.getCurrentVotes(address(this)), locksAmount + locksAmount);
  }

  function testUnstakeFailVest() public {
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(Goldilocked.NotVested.selector));
    goldilocked.unstake(1);
  }

  function testUnstakeFailInvalid() public dealAndStake100000Locks {
    vm.expectRevert(abi.encodeWithSelector(Goldilocked.InvalidUnstake.selector));
    goldilocked.unstake(locksAmount + 1);
  }

  function testUnstakeFailBorrowed() public dealAndStake100000Locks dealGoldiswapMaxHoney {
    goldilocked.borrow(borrowAmount);
    vm.expectRevert(abi.encodeWithSelector(Goldilocked.LocksBorrowedAgainst.selector));
    goldilocked.unstake(1);
  }

  function testUnstakeSuccess() public dealAndStake100000Locks {
    vm.warp(1 days + 1);
    goldilocked.unstake(locksAmount);

    assertEq(goldilocked.userStakedLocks(address(this)), 0);
    assertEq(goldiswap.balanceOf(address(goldilocked)), locksMintAmount);
    assertEq(goldiswap.balanceOf(address(this)), locksAmount);
    assertEq(goldilocked.balanceOf(address(this)), oneDayPrg + prgMintAmount);
    assertEq(goldilocked.prgRewardDebt(address(this)), 0);
    assertEq(govlocks.getCurrentVotes(address(this)), 0);
  }

  // function testStakeUnstakeClaim() public dealAndStake100000Locks {
  //   goldiswap.approve(address(goldilocked), locksAmount);
  //   vm.warp(block.timestamp + 180 days);
  //   goldilocked.unstake(locksAmount);
  //   vm.warp(block.timestamp + 180 days);
  //   goldilocked.stake(100e18);
  //   vm.warp(block.timestamp + 180 days);

  //   uint256 stakedLocks = goldilocked.userStakedLocks(address(this));
  //   uint256 claimablePrg = goldilocked.userClaimablePrg(address(this));
  //   uint256 prgRewardDebt = goldilocked.prgRewardDebt(address(this));
  //   uint256 prgBalance = goldilocked.balanceOf(address(this));

  //   assertEq(stakedLocks, 100000000000000000000);
  //   assertEq(claimablePrg, 24657534246575342450);
  //   assertEq(prgRewardDebt, 49315068493150684900);
  //   assertEq(prgBalance, 24657534246575342450 + prgMintAmount);
  // }


  // function testStir() public dealAndStake100000Locks {
  //   deal(address(honey), address(this), 280e18);
  //   honey.approve(address(goldilocked), 280e18);
  //   vm.warp(block.timestamp + (2 * 1 days));
  //   goldilocked.unstake(locksAmount);
  //   goldilocked.stir(twoDaysPrg);

  //   uint256 userBalanceofPrg = goldilocked.balanceOf(address(this));
  //   uint256 userBalanceofLocks = goldiswap.balanceOf(address(this));
  //   uint256 userBalanceofHoney = honey.balanceOf(address(this));
  //   uint256 goldiswapBalanceofHoney = honey.balanceOf(address(goldiswap));

  //   assertEq(userBalanceofPrg, 0 + prgMintAmount);
  //   assertEq(userBalanceofLocks, 100273972602739726000);
  //   assertEq(userBalanceofHoney, 279997123287671232877);
  //   assertEq(goldiswapBalanceofHoney, 2876712328767123);
  // }


  // function testCalculateHalfDayofYield() public dealAndStake100000Locks {
  //   vm.warp(block.timestamp + (1 days / 2));
  //   goldilocked.claim();

  //   uint256 prgBalance = goldilocked.balanceOf(address(this));
    
  //   assertEq(prgBalance, HalfDayofYield + prgMintAmount);
  // }

  // function testCalculate1DayofYield() public dealAndStake100000Locks {
  //   vm.warp(block.timestamp + 1 days);
  //   goldilocked.claim();

  //   uint256 prgBalance = goldilocked.balanceOf(address(this));

  //   assertEq(prgBalance, oneDayPrg + prgMintAmount);
  // }

  // function testCalculate1andHalfDayofYield() public dealAndStake100000Locks {
  //   vm.warp(block.timestamp + 1 days + (1 days / 2));
  //   goldilocked.claim();

  //   uint256 prgBalance = goldilocked.balanceOf(address(this));
    
  //   assertEq(prgBalance, OneDayandHalfofYield + prgMintAmount);
  // }

  // function testCalculate2daysofyield

    // function testNotGoldilend() public { 
  //   vm.prank(address(0x01));
  //   vm.expectRevert(NotGoldilendSelector);
  //   goldilocked.goldilendMint(address(this), 69e18);
  // }

  // function testInvalidUnstake() public dealAndStake100000Locks {
  //   vm.expectRevert(InvalidUnstakeSelector);
  //   goldilocked.unstake(locksAmount + 1);
  // }

  // function testLocksBorrowedAgainst() public dealGoldiswapMaxHoney {
  //   deal(address(goldiswap), address(this), 100000e18);
  //   goldiswap.approve(address(goldilocked), 100000e18);
  //   goldilocked.stake(100000e18);
  //   goldilocked.borrow(1050e18);
  //   vm.expectRevert(LocksBorrowedAgainstSelector);
  //   goldilocked.unstake(1e18);
  // }


  // function testClaim() public dealAndStake100000Locks {
  //   vm.warp(block.timestamp + 1 days);
  //   goldilocked.claim();

  //   uint256 userBalanceofPrg = goldilocked.balanceOf(address(this));
  //   uint256 userStakedLocks = goldilocked.userStakedLocks(address(this));

  //   assertEq(userBalanceofPrg, oneDayPrg + prgMintAmount);
  //   assertEq(userStakedLocks, locksAmount);
  // }

  // function testGetClaimable() public dealAndStake100000Locks {
  //   vm.warp(block.timestamp + 1 days);

  //   uint256 claimable = goldilocked.userClaimablePrg(address(this));

  //   assertEq(claimable, oneDayPrg);
  // }

  // function testGoldilendMint() public {
  //   deal(address(goldilend), address(this), 1e18);
  //   goldilend.approve(address(goldilend), 1e18);
  //   goldilend.stake(1e18);
  //   vm.warp(block.timestamp + (goldilend.MONTH_DAYS() * 2));
  //   goldilend.claim();

  //   uint256 userPrgBalance = goldilocked.balanceOf(address(this));

  //   assertEq(userPrgBalance, twoMonthsOfGoldilendStakingYield + prgMintAmount);
  // }

  // function testInsufficientBorrowLimit() public dealAndStake100000Locks dealGoldiswapMaxHoney {
  //   vm.expectRevert(InsufficientBorrowLimitSelector);
  //   goldilocked.borrow(borrowAmount + 1);
  // }

  // function testExcessiveRepay() public dealAndStake100000Locks dealGoldiswapMaxHoney {
  //   goldilocked.borrow(borrowAmount);
  //   vm.expectRevert(ExcessiveRepaySelector);
  //   goldilocked.repay(borrowAmount + 1);
  // }

  // function testBorrowLimitCalculation() public dealAndStake100000Locks {
  //   uint256 limit = goldilocked.userBorrowLimit(address(this));

  //   assertEq(limit, borrowAmount);
  // }

  // function testBorrowLocks() public dealAndStake100000Locks dealGoldiswapMaxHoney{
  //   goldilocked.borrow(borrowAmount);

  //   uint256 goldiswapHoneyBalance = honey.balanceOf(address(goldiswap));
  //   uint256 userHoneyBalance = honey.balanceOf(address(this));
  //   uint256 locked = goldilocked.userLockedLocks(address(this));
  //   uint256 borrowed = goldilocked.userBorrowedHoney(address(this));

  //   assertEq(goldiswapHoneyBalance, type(uint256).max - borrowAmount);
  //   assertEq(userHoneyBalance, borrowAmount);
  //   assertEq(locked, locksAmount);
  //   assertEq(borrowed, borrowAmount);
  // }

  // function testRepay() public dealAndStake100000Locks dealGoldiswapMaxHoney {
  //   goldilocked.borrow(borrowAmount);
  //   honey.approve(address(goldilocked), borrowAmount);
  //   goldilocked.repay(borrowAmount);

  //   uint256 locked = goldilocked.userLockedLocks(address(this));
  //   uint256 borrowed = goldilocked.userBorrowedHoney(address(this));
  //   uint256 userHoneyBalance = honey.balanceOf(address(this));
  //   uint256 userStakedLocksBalance = goldilocked.userStakedLocks(address(this));

  //   assertEq(locked, 0);
  //   assertEq(borrowed, 0);
  //   assertEq(userHoneyBalance, 0);
  //   assertEq(userStakedLocksBalance, locksAmount);
  // }

  // function testLockedAfterRepay() public dealAndStake100000Locks dealGoldiswapMaxHoney {
  //   goldilocked.borrow(borrowAmount);
  //   honey.approve(address(goldilocked), type(uint256).max);
  //   goldilocked.repay(borrowAmount);

  //   uint256 locked = goldilocked.userLockedLocks(address(this));

  //   assertEq(locked, 0);
  // }

}