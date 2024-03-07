//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../lib/forge-std/src/Test.sol";
import { BaseTest } from "../BaseTest.t.sol";
import { Goldilocked } from "../../src/core/Goldilocked.sol";

contract GoldilockedTest is BaseTest {

  uint256 locksAmount = 100000e18;
  uint256 borrowAmount = 1050e18;
  uint256 prgMintAmount = 200000000e18;
  uint256 locksMintAmount = 100000000e18;
  uint256 oneDayPrg = 136986301369863000000;
  uint256 halfDayPrg = 68493150684931500000;
  uint256 oneDayHalfPrg = 205479452054794500000;
  uint256 twoDaysPrg = 273972602739726000000;
  uint256 twoMonthsOfGoldilendStakingYield = 34e18;


  modifier dealStakeLocks() {
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

  function testUserStakedLocksView() public dealStakeLocks {
    assertEq(goldilocked.userStakedLocks(address(this)), locksAmount);
  }

  function testUserClaimablePrgView() public dealStakeLocks {
    vm.warp(block.timestamp + 1 days);

    assertEq(goldilocked.userClaimablePrg(address(this)), oneDayPrg);
  }

  function testUserLockedLocksView() public dealStakeLocks dealGoldiswapMaxHoney {
    goldilocked.borrow(borrowAmount);

    assertEq(goldilocked.userLockedLocks(address(this)), locksAmount);
  }

  function testUserBorrowedHoneyView() public dealStakeLocks dealGoldiswapMaxHoney {
    goldilocked.borrow(borrowAmount);

    assertEq(goldilocked.userBorrowedHoney(address(this)), borrowAmount);
  }

  function testUserBorrowLimitView() public dealStakeLocks {
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
    assertEq(goldilocked.prgPerTokenDebt(address(this)), oneDayPrg / 1e5);
    assertEq(govlocks.getVotes(address(this)), locksAmount);
  }

  function testDoubleStakeSuccess() public dealStakeLocks {
    vm.warp(1 days + 1);
    deal(address(goldiswap), address(this), locksAmount);
    goldiswap.approve(address(goldilocked), locksAmount);
    goldilocked.stake(locksAmount);

    assertEq(goldilocked.userStakedLocks(address(this)), locksAmount + locksAmount);
    assertEq(goldiswap.balanceOf(address(goldilocked)), locksAmount + locksAmount + locksMintAmount);
    assertEq(goldiswap.balanceOf(address(this)), 0);
    assertEq(goldilocked.prgPerTokenDebt(address(this)), oneDayPrg / 1e5);
    assertEq(govlocks.getVotes(address(this)), locksAmount + locksAmount);
  }

  function testUnstakeFailVest() public {
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(Goldilocked.NotVested.selector));
    goldilocked.unstake(1);
  }

  function testUnstakeFailInvalid() public dealStakeLocks {
    vm.expectRevert(abi.encodeWithSelector(Goldilocked.InvalidUnstake.selector));
    goldilocked.unstake(locksAmount + 1);
  }

  function testUnstakeFailBorrowed() public dealStakeLocks dealGoldiswapMaxHoney {
    goldilocked.borrow(borrowAmount);
    vm.expectRevert(abi.encodeWithSelector(Goldilocked.LocksBorrowedAgainst.selector));
    goldilocked.unstake(1);
  }

  function testUnstakeSuccess() public dealStakeLocks {
    vm.warp(1 days + 1);
    goldilocked.unstake(locksAmount);

    assertEq(goldilocked.userStakedLocks(address(this)), 0);
    assertEq(govlocks.getVotes(address(this)), 0);
    assertEq(goldiswap.balanceOf(address(goldilocked)), locksMintAmount);
    assertEq(goldiswap.balanceOf(address(this)), locksAmount);
    assertEq(goldilocked.balanceOf(address(this)), prgMintAmount);
    assertEq(goldilocked.prgPerTokenDebt(address(this)), oneDayPrg / 1e5);
  }

  function testStirSuccess() public dealStakeLocks {
    uint256 oneDayPrgCost = 1438356164383561500;
    uint256 oneDayLocksProceeds = 136986301369863000000;
    deal(address(honey), address(this), oneDayPrgCost);
    honey.approve(address(goldilocked), oneDayPrgCost);
    vm.warp(1 days + 1);
    goldilocked.unstake(locksAmount);
    goldilocked.stir(oneDayPrg);

    assertEq(goldiswap.balanceOf(address(this)), oneDayLocksProceeds + locksAmount);
    assertEq(goldilocked.balanceOf(address(this)), prgMintAmount - oneDayPrg);
    assertEq(honey.balanceOf(address(this)), 0);
    assertEq(honey.balanceOf(address(goldiswap)), oneDayPrgCost);
  }

  function testHalfDayYield() public dealStakeLocks {
    vm.warp((1 days / 2) + 1);
    goldilocked.claim();
    
    assertEq(goldilocked.balanceOf(address(this)), halfDayPrg + prgMintAmount);
  }

  function testDayYield() public dealStakeLocks {
    vm.warp(1 days + 1);
    goldilocked.claim();

    assertEq(goldilocked.balanceOf(address(this)), oneDayPrg + prgMintAmount);
  }

  function testDayHalfYield() public dealStakeLocks {
    vm.warp(1 days + (1 days / 2) + 1);
    goldilocked.claim();
    
    assertEq(goldilocked.balanceOf(address(this)), oneDayHalfPrg + prgMintAmount);
  }

  function testTwoDaysYield() public dealStakeLocks {
    vm.warp(2 days + 1);
    goldilocked.claim();

    assertEq(goldilocked.balanceOf(address(this)), twoDaysPrg + prgMintAmount);
  }

  function testDoubleClaimFail() public dealStakeLocks {
    vm.warp(2 days + 1);
    goldilocked.claim();
    goldilocked.claim();
    goldilocked.claim();

    assertEq(goldilocked.balanceOf(address(this)), twoDaysPrg + prgMintAmount);
  }

  function testStakeUnstakeHalf() public dealStakeLocks {
    goldilocked.unstake(locksAmount / 2);
    vm.warp((1 days * 2) + 1);
    goldilocked.claim();

    assertEq(goldilocked.balanceOf(address(this)), oneDayPrg + prgMintAmount);
  }

  function testStakeWaitUnstakeHalf() public dealStakeLocks {
    vm.warp(1 days + 1);
    goldilocked.unstake(locksAmount / 2);
    vm.warp(1 days + block.timestamp);
    goldilocked.claim();
    goldilocked.claim();
    
    assertEq(goldilocked.balanceOf(address(this)), oneDayHalfPrg + prgMintAmount);
  }

  function testStakeStake() public {
    vm.warp(2 days + 1);
    deal(address(goldiswap), address(this), locksAmount*2);
    goldiswap.approve(address(goldilocked), locksAmount*2);
    goldilocked.stake(locksAmount);
    vm.warp((1 days / 2) + block.timestamp);
    goldilocked.stake(locksAmount);
    vm.warp(1 days + block.timestamp);
    goldilocked.claim();

    assertEq(goldilocked.balanceOf(address(this)), twoDaysPrg + halfDayPrg + prgMintAmount);
  }

  function testRandomStaking() public {
    deal(address(goldiswap), address(this), locksAmount*2);
    goldiswap.approve(address(goldilocked), locksAmount*2);
    goldilocked.stake(locksAmount / 2);
    vm.warp(4 days + 1);
    goldilocked.stake(locksAmount / 2);
    vm.warp(1 days + block.timestamp);
    goldilocked.stake(locksAmount);
    vm.warp(2 days + block.timestamp);
    goldilocked.unstake(locksAmount);
    vm.warp(1 days + block.timestamp);
    goldilocked.claim();

    assertEq(goldilocked.balanceOf(address(this)), (oneDayPrg * 8) + 1e5 + prgMintAmount);
  }

  function testMultipleUnstaking() public {
    vm.warp(1 days + 1);
    deal(address(goldiswap), address(this), locksAmount*2);
    goldiswap.approve(address(goldilocked), locksAmount*2);
    goldilocked.stake(locksAmount * 2);
    vm.warp(1 days + block.timestamp);
    goldilocked.unstake(locksAmount / 2);
    vm.warp(1 days + block.timestamp);
    goldilocked.unstake(locksAmount / 2);
    vm.warp(1 days + block.timestamp);
    goldilocked.unstake(locksAmount);
    goldilocked.claim();

    assertEq(goldilocked.balanceOf(address(this)), (oneDayPrg * 4) + halfDayPrg + prgMintAmount);
    assertEq(goldiswap.balanceOf(address(this)), locksAmount*2);
  }

  function testBorrowHoneyFailLimit() public dealStakeLocks dealGoldiswapMaxHoney {
    vm.expectRevert(abi.encodeWithSelector(Goldilocked.InsufficientBorrowLimit.selector));
    goldilocked.borrow(borrowAmount + 1);
  }

  function testBorrowHoneySuccess() public dealStakeLocks dealGoldiswapMaxHoney {
    goldilocked.borrow(borrowAmount);

    assertEq(goldilocked.userLockedLocks(address(this)), locksAmount);
    assertEq(goldilocked.userBorrowedHoney(address(this)), borrowAmount);
    assertEq(honey.balanceOf(address(this)), borrowAmount);
    assertEq(honey.balanceOf(address(goldiswap)), type(uint256).max - borrowAmount);
  }

  function testRepayHoneyFailExcessive() public dealStakeLocks dealGoldiswapMaxHoney {
    goldilocked.borrow(borrowAmount);
    vm.expectRevert(abi.encodeWithSelector(Goldilocked.ExcessiveRepay.selector));
    goldilocked.repay(borrowAmount + 1);
  }

  function testRepayHoneySuccess() public dealStakeLocks dealGoldiswapMaxHoney {
    goldilocked.borrow(borrowAmount);
    honey.approve(address(goldilocked), borrowAmount);
    goldilocked.repay(borrowAmount);

    assertEq(goldilocked.lockedLocks(address(this)), 0);
    assertEq(goldilocked.borrowedHoney(address(this)), 0);
    assertEq(goldilocked.stakedLocks(address(this)), locksAmount);
    assertEq(honey.balanceOf(address(this)), 0);
    assertEq(honey.balanceOf(address(goldiswap)), type(uint256).max);
  }

  function testHalfRepayHoneySuccess() public dealStakeLocks dealGoldiswapMaxHoney {
    goldilocked.borrow(borrowAmount);
    honey.approve(address(goldilocked), borrowAmount);
    goldilocked.repay(borrowAmount / 2);

    assertEq(goldilocked.lockedLocks(address(this)), locksAmount / 2);
    assertEq(goldilocked.borrowedHoney(address(this)), borrowAmount / 2);
    assertEq(goldilocked.stakedLocks(address(this)), locksAmount);
    assertEq(honey.balanceOf(address(this)), borrowAmount / 2);
    assertEq(honey.balanceOf(address(goldiswap)), type(uint256).max - (borrowAmount / 2));
  }

  function testTeamVest() public {    
    assertEq(goldilocked.userVestingCheck(address(0x69)), 0);
  }

  function testNonTeamVest() public {
    assertEq(goldilocked.userVestingCheck(address(0xaaa)), type(uint256).max);
  }

  function testSeedRoundNoVest() public {
    assertEq(goldilocked.userVestingCheck(address(0x69420)), 0);
  }

  function testSeedRoundFullVest() public {
    vm.warp(90 days + 365 days + 1);
    assertEq(goldilocked.userVestingCheck(address(0x69420)), 7000000e18);
  }

  function testGoldilendMintFailGoldilend() public {
    vm.expectRevert(abi.encodeWithSelector(Goldilocked.NotGoldilend.selector));
    goldilocked.goldilendMint(address(this), 69);
  }

  function testGoldilendMintSuccess() public {
    deal(address(goldilend), address(this), 1e18);
    goldilend.approve(address(goldilend), 1e18);
    goldilend.stake(1e18);
    vm.warp(block.timestamp + 60 days);
    goldilend.claim();

    assertEq(goldilocked.balanceOf(address(this)), twoMonthsOfGoldilendStakingYield + prgMintAmount);
  }

  function testChangePorridgeEmissionsFailMultisig() public {
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(Goldilocked.NotMultisig.selector));
    goldilocked.changePorridgeEmissions(69);
  }

  function testChangePorridgeEmissionsSuccess() public {
    goldilocked.changePorridgeEmissions(69);

    assertEq(goldilocked.ANNUAL_PORRIDGE_EMISSIONS(), 69);
  }

  function testMintPorridgeFailMultisig() public {
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(Goldilocked.NotMultisig.selector));
    goldilocked.mintPorridge(69);
  }

  function testMintPorridgeSuccess() public {
    goldilocked.mintPorridge(69);

    assertEq(goldilocked.balanceOf(address(this)), 69 + prgMintAmount);
  }

}