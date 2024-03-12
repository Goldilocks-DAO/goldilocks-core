//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { BaseTest } from "../BaseTest.t.sol";
import { govLocks } from "../../src/core/goldigovernance/govLocks.sol";

contract FuzzgovLocksTest is BaseTest {

  function testFuzzDeposit(uint256 depositAmount) public {
    deal(address(goldiswap), address(this), depositAmount);
    goldiswap.approve(address(govlocks), depositAmount);
    govlocks.deposit(depositAmount);
    govlocks.delegate(address(this));

    assertEq(goldiswap.balanceOf(address(this)), 0);
    assertEq(govlocks.balanceOf(address(this)), depositAmount);
    assertEq(govlocks.getVotes(address(this)), depositAmount);
  }

  function testFuzWithdraw(uint256 withdrawAmount) public {
    deal(address(goldiswap), address(this), withdrawAmount);
    goldiswap.approve(address(govlocks), withdrawAmount);
    govlocks.deposit(withdrawAmount);
    govlocks.delegate(address(this));
    govlocks.withdraw(withdrawAmount);

    assertEq(goldiswap.balanceOf(address(this)), withdrawAmount);
    assertEq(govlocks.balanceOf(address(this)), 0);
  }

  function testFuzzDelegateOther(address delegatee, uint256 delegateAmount) public {
    deal(address(goldiswap), address(this), delegateAmount);
    goldiswap.approve(address(govlocks), delegateAmount);
    govlocks.deposit(delegateAmount);
    govlocks.delegate(delegatee);
    vm.roll(2);

    assertEq(govlocks.getPriorVotes(delegatee, block.number - 1), delegateAmount);
    assertEq(govlocks.balanceOf(delegatee), 0);
    assertEq(govlocks.getPriorVotes(address(this), block.number - 1), 0);
    assertEq(govlocks.balanceOf(address(this)), delegateAmount);
  }

  function testFuzzDelegateSelf(uint256 delegateAmount) public {
    deal(address(goldiswap), address(this), delegateAmount);
    goldiswap.approve(address(govlocks), delegateAmount);
    govlocks.deposit(delegateAmount);
    govlocks.delegate(address(this));
    vm.roll(2);

    assertEq(govlocks.getPriorVotes(address(this), block.number - 1), delegateAmount);
    assertEq(govlocks.balanceOf(address(this)), delegateAmount);
  }

  function testFuzzUpdateStakedBalance(uint256 updateAmount) public {
    vm.assume(updateAmount < 1_000_000_000_000_000e18);
    deal(address(goldiswap), address(this), updateAmount + updateAmount);
    goldiswap.approve(address(govlocks), updateAmount);
    govlocks.deposit(updateAmount);
    govlocks.delegate(address(this));
    goldiswap.approve(address(goldilocked), updateAmount);
    goldilocked.stake(updateAmount);
    vm.roll(2);

    assertEq(govlocks.getPriorVotes(address(this), 1), goldilocked.userStakedLocks(address(this)) + updateAmount);
  }


}