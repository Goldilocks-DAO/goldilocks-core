//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { BaseFuzzTest } from "../base/BaseFuzzTest.t.sol";
import { FixedPointMathLib } from "../../lib/solady/src/utils/FixedPointMathLib.sol";
import { Goldilocked } from "../../src/core/goldiswap/Goldilocked.sol";

contract FuzzGoldilockedTest is BaseFuzzTest {

  function testFuzzStake(uint256 stakeAmount) public {
    vm.assume(stakeAmount < locksMintAmount);
    vm.assume(stakeAmount > 1e5);
    deal(address(goldiswap), address(this), stakeAmount);
    goldiswap.approve(address(goldilocked), stakeAmount);
    goldilocked.stake(stakeAmount);

    assertEq(goldiswap.balanceOf(address(this)), 0);
    assertEq(goldiswap.balanceOf(address(goldilocked)), stakeAmount + locksMintAmount);
    assertEq(goldilocked.userStakedLocks(address(this)), stakeAmount);
    assertEq(govlocks.getVotes(address(this)), stakeAmount);
  }

  function testFuzzUnstake(uint256 unstakeAmount) public {
    vm.assume(unstakeAmount < locksMintAmount);
    vm.assume(unstakeAmount > 1e5);
    deal(address(goldiswap), address(this), unstakeAmount);
    goldiswap.approve(address(goldilocked), unstakeAmount);
    goldilocked.stake(unstakeAmount);
    vm.warp(1 days + 1);
    goldilocked.unstake(unstakeAmount);

    assertEq(goldilocked.userStakedLocks(address(this)), 0);
    assertEq(govlocks.getVotes(address(this)), 0);
    assertEq(goldiswap.balanceOf(address(goldilocked)), locksMintAmount);
    assertEq(goldiswap.balanceOf(address(this)), unstakeAmount);
    assertEq(goldilocked.balanceOf(address(this)), prgMintAmount);
    assertEq(goldilocked.prgPerTokenDebt(address(this)), dayOfPrgDebt);
  }

  function testFuzzStir(uint256 stirAmount) public {
    vm.assume(stirAmount < locksMintAmount);
    vm.assume(stirAmount > 1e5);
    uint256 oneDayPrgCost = 821917808219178000;
    uint256 oneDayLocksProceeds = 136986301369863000000;
    deal(address(goldiswap), address(this), stirAmount);
    goldiswap.approve(address(goldilocked), stirAmount);
    goldilocked.stake(stirAmount);
    deal(address(honey), address(this), oneDayPrgCost);
    honey.approve(address(goldilocked), oneDayPrgCost);
    vm.warp(1 days + 1);
    goldilocked.unstake(stirAmount);
    goldilocked.stir(oneDayPrg);

    assertEq(goldiswap.balanceOf(address(this)), oneDayLocksProceeds + stirAmount);
    assertEq(goldilocked.balanceOf(address(this)), prgMintAmount - oneDayPrg);
    assertEq(honey.balanceOf(address(this)), 0);
    assertEq(honey.balanceOf(address(goldiswap)), oneDayPrgCost + initialPSL);
  }

  function testFuzzClaim(uint256 claimAmount) public {
    vm.assume(claimAmount < locksMintAmount);
    vm.assume(claimAmount > 1e5);
    deal(address(goldiswap), address(this), claimAmount);
    goldiswap.approve(address(goldilocked), claimAmount);
    goldilocked.stake(claimAmount);
    vm.warp(1 days + 1);
    goldilocked.claim();
    uint256 claimMagnitude = FixedPointMathLib.divWad(claimAmount, locksAmount);

    assertLe(goldilocked.balanceOf(address(this)), FixedPointMathLib.mulWad(oneDayPrg, claimMagnitude) + prgMintAmount + 500);
    assertGe(goldilocked.balanceOf(address(this)),  FixedPointMathLib.mulWad(oneDayPrg, claimMagnitude) + prgMintAmount - 500);
  }

  function testFuzzBorrowHoney(uint256 borrowHoneyAmount) public {
    vm.assume(borrowHoneyAmount < locksMintAmount);
    vm.assume(borrowHoneyAmount > 1e5);
    uint256 fuzzedBorrowAmount = FixedPointMathLib.mulWad(borrowHoneyAmount, goldiswap.floorPrice());
    uint256 lockedLocksAmount = FixedPointMathLib.divWad(fuzzedBorrowAmount, goldiswap.floorPrice());
    deal(address(goldiswap), address(this), borrowHoneyAmount);
    deal(address(honey), address(goldiswap), type(uint256).max / 2);
    goldiswap.approve(address(goldilocked), borrowHoneyAmount);
    goldilocked.stake(borrowHoneyAmount);
    goldilocked.borrow(fuzzedBorrowAmount);

    assertEq(goldilocked.userLockedLocks(address(this)), lockedLocksAmount);
    assertEq(goldilocked.userBorrowedHoney(address(this)), fuzzedBorrowAmount);
    assertEq(honey.balanceOf(address(this)), fuzzedBorrowAmount);
    assertEq(honey.balanceOf(address(goldiswap)), (type(uint256).max / 2) - fuzzedBorrowAmount);
  }

  function testFuzzRepayHoney(uint256 repayHoneyAmount) public {
    vm.assume(repayHoneyAmount < locksMintAmount);
    vm.assume(repayHoneyAmount > 1e5);
    uint256 fuzzedBorrowAmount = FixedPointMathLib.mulWad(repayHoneyAmount, goldiswap.floorPrice());
    deal(address(goldiswap), address(this), repayHoneyAmount);
    deal(address(honey), address(goldiswap), type(uint256).max / 2);
    goldiswap.approve(address(goldilocked), repayHoneyAmount);
    goldilocked.stake(repayHoneyAmount);
    goldilocked.borrow(fuzzedBorrowAmount);
    honey.approve(address(goldilocked), fuzzedBorrowAmount);
    goldilocked.repay(fuzzedBorrowAmount);

    assertEq(goldilocked.userLockedLocks(address(this)), 0);
    assertEq(goldilocked.borrowedHoney(address(this)), 0);
    assertEq(goldilocked.stakedLocks(address(this)), repayHoneyAmount);
    assertEq(honey.balanceOf(address(this)), 0);
    assertEq(honey.balanceOf(address(goldiswap)), type(uint256).max / 2);
  }

}