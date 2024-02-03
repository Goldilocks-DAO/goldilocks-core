//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../lib/forge-std/src/Test.sol";
import { LibRLP } from "../../lib/solady/src/utils/LibRLP.sol";
import { Honey } from "../../src/mock/Honey.sol";
import { Goldiswap } from "../../src/core/Goldiswap.sol";
import { Borrow } from "../../src/core/Borrow.sol";
import { Porridge } from "../../src/core/Porridge.sol";
import { Goldilend } from "../../src/core/Goldilend.sol";

contract BorrowTest is Test {

  using LibRLP for address;

  Honey honey;
  Goldiswap goldiswap;
  Borrow borrow;
  Porridge porridge;

  uint256 initialFSL = 1050000e18;
  uint256 initialPSL = 320000e18;

  uint256 locksAmount = 100000e18;
  uint256 borrowAmount = 1050e18;

  bytes4 InsufficientBorrowLimitSelector = 0xda392797;
  bytes4 ExcessiveRepaySelector = 0x7bc3c3ef;

  function setUp() public {
    Porridge porridgeComputed = Porridge(address(this).computeAddress(4));
    Borrow borrowComputed = Borrow(address(this).computeAddress(3));
    Goldilend goldilendComputed = Goldilend(address(this).computeAddress(13));
    honey = new Honey();
    goldiswap = new Goldiswap(initialFSL, initialPSL, address(this), address(porridgeComputed), address(borrowComputed), address(honey));
    borrow = new Borrow(address(goldiswap), address(porridgeComputed), address(honey));
    porridge = new Porridge(address(goldiswap), address(borrow), address(goldilendComputed), address(honey));
  }

  modifier dealandStake100000Locks() {
    deal(address(goldiswap), address(this), locksAmount);
    goldiswap.approve(address(porridge), locksAmount);
    porridge.stake(locksAmount);
    _;
  }

  modifier dealGammMaxHoney() {
    deal(address(honey), address(goldiswap), type(uint256).max);
    _;
  }

  function testInsufficientBorrowLimit() public dealandStake100000Locks dealGammMaxHoney {
    vm.expectRevert(InsufficientBorrowLimitSelector);
    borrow.borrow(borrowAmount + 1);
  }

  function testExcessiveRepay() public dealandStake100000Locks dealGammMaxHoney {
    borrow.borrow(borrowAmount);
    vm.expectRevert(ExcessiveRepaySelector);
    borrow.repay(borrowAmount + 1);
  }

  function testBorrowLimitCalculation() public dealandStake100000Locks {
    uint256 limit = borrow.borrowLimit(address(this));

    assertEq(limit, borrowAmount);
  }

  function testBorrowLocks() public dealandStake100000Locks dealGammMaxHoney{
    borrow.borrow(borrowAmount);

    uint256 goldiswapHoneyBalance = honey.balanceOf(address(goldiswap));
    uint256 userHoneyBalance = honey.balanceOf(address(this));
    uint256 locked = borrow.getLocked(address(this));
    uint256 borrowed = borrow.getBorrowed(address(this));

    assertEq(goldiswapHoneyBalance, type(uint256).max - borrowAmount);
    assertEq(userHoneyBalance, borrowAmount);
    assertEq(locked, locksAmount);
    assertEq(borrowed, borrowAmount);
  }

  function testRepay() public dealandStake100000Locks dealGammMaxHoney {
    borrow.borrow(borrowAmount);
    honey.approve(address(borrow), borrowAmount);
    borrow.repay(borrowAmount);

    uint256 locked = borrow.getLocked(address(this));
    uint256 borrowed = borrow.getBorrowed(address(this));
    uint256 userHoneyBalance = honey.balanceOf(address(this));
    uint256 userStakedLocksBalance = porridge.getStaked(address(this));

    assertEq(locked, 0);
    assertEq(borrowed, 0);
    assertEq(userHoneyBalance, 0);
    assertEq(userStakedLocksBalance, locksAmount);
  }

  function testLockedAfterRepay() public dealandStake100000Locks dealGammMaxHoney {
    borrow.borrow(borrowAmount);
    honey.approve(address(borrow), type(uint256).max);
    borrow.repay(borrowAmount);

    uint256 locked = borrow.getLocked(address(this));

    assertEq(locked, 0);
  }

}