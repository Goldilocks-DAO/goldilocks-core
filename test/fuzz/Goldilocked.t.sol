//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../lib/forge-std/src/Test.sol";
import { FixedPointMathLib } from "../../lib/solady/src/utils/FixedPointMathLib.sol";
import { BaseTest } from "../BaseTest.t.sol";
import { Goldilocked } from "../../src/core/Goldilocked.sol";

contract FuzzGoldilockedTest is BaseTest {

  function testFuzzStake(uint256 stakeAmount) public {
    vm.assume(stakeAmount < locksMintAmount);
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
    assertEq(goldilocked.prgPerTokenDebt(address(this)), oneDayPrg / 1e5);
  }

  function testFuzzStir(uint256 stirAmount) public {
    uint256 oneDayPrgCost = 1438356164383561500;
    uint256 oneDayLocksProceeds = 136986301369863000000;
    vm.assume(stirAmount < locksMintAmount);
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
    assertEq(honey.balanceOf(address(goldiswap)), oneDayPrgCost);
  }

}