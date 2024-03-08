//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../lib/forge-std/src/Test.sol";
import { BaseTest } from "../BaseTest.t.sol";
import { Goldilocked } from "../../src/core/Goldilocked.sol";

contract FuzzGoldilockedTest is BaseTest {

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