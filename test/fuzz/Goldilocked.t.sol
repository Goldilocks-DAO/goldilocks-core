//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../lib/forge-std/src/Test.sol";
import { BaseTest } from "../BaseTest.t.sol";
import { Goldilocked } from "../../src/core/Goldilocked.sol";

contract FuzzGoldilockedTest is BaseTest {

  uint256 locksAmountPrg = 100e18;
  uint256 locksAmount = 100000e18;
  uint256 borrowAmount = 1050e18;
  uint256 HalfDayofYield = 68493150684931500;
  uint256 OneDayofYield = 136986301369863000;
  uint256 OneDayandHalfofYield = 205479452054794500;
  uint256 TwoDaysofYield = 273972602739726000;
  uint256 twoMonthsOfGoldilendStakingYield = 43e18;

  function testFuzzStake(uint256 txAmount) public {
    vm.assume(txAmount < 100000000000e18);
    deal(address(goldiswap), address(this), txAmount);
    goldiswap.approve(address(goldilocked), txAmount);
    goldilocked.stake(txAmount);

    assertEq(goldiswap.balanceOf(address(this)), 0);
    assertEq(goldiswap.balanceOf(address(goldilocked)), txAmount + 100000000e18);
    assertEq(goldilocked.userStakedLocks(address(this)), txAmount);
  }

}