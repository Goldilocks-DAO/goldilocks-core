//SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { BaseFuzzTest } from "../base/BaseFuzzTest.t.sol";
import { IGoldilendBase } from "../../src/interfaces/IGoldilendBase.sol";
import { GoldilendBase } from "../../src/core/goldilend/GoldilendBase.sol";
import { RebaseGoldilend } from "../../src/core/goldilend/RebaseGoldilend.sol";

contract FuzzRebaseGoldilendTest is BaseFuzzTest {

    function testFuzzDeposit(uint256 depositAmount) public {
        deal(address(honey), address(this), depositAmount);
        honey.approve(address(rebaseproxy), depositAmount);
        GoldilendBase(address(rebaseproxy)).deposit(depositAmount);

        assertEq(glhoney.balanceOf(address(this)), depositAmount);
        assertEq(honey.balanceOf(address(this)), 0);
        assertEq(honey.balanceOf(address(rebaseproxy)), depositAmount);
        assertEq(GoldilendBase(address(rebaseproxy)).poolSize(), depositAmount);
    }

    function testFuzzWithdraw(uint256 depositAmount, uint256 withdrawAmount) public {
        vm.assume(depositAmount > withdrawAmount);
        vm.assume(1e5 < depositAmount && depositAmount < 1e40);
        vm.assume(1e5 < withdrawAmount && withdrawAmount < 1e40);
        deal(address(honey), address(this), depositAmount);
        honey.approve(address(rebaseproxy), depositAmount);
        GoldilendBase(address(rebaseproxy)).deposit(depositAmount);
        GoldilendBase(address(rebaseproxy)).withdraw(withdrawAmount);

        assertEq(glhoney.balanceOf(address(this)), depositAmount - withdrawAmount);
        assertEq(honey.balanceOf(address(this)), withdrawAmount);
        assertEq(honey.balanceOf(address(rebaseproxy)), depositAmount - withdrawAmount);
        assertEq(GoldilendBase(address(rebaseproxy)).poolSize(), depositAmount - withdrawAmount);
    }

    function testFuzzRebaseBorrow(uint256 durationAmount) public dealUserBeras {
        // vm.assume(durationAmount > goldilend.minDuration() && durationAmount < goldilend.maxDuration());
        // goldilend.borrow(1e18, durationAmount, address(bondbear), 1);
        // Goldilend.Loan memory userLoan = goldilend.lookupLoan(address(this), 1);

        // assertEq(userLoan.collateralNFTs[0], address(bondbear));
        // assertEq(userLoan.collateralNFTIds[0], 1);
        // assertEq(userLoan.duration, durationAmount);
        // assertEq(userLoan.endDate, block.timestamp + durationAmount);
        // assertEq(userLoan.loanId, 1);
        // assertEq(userLoan.liquidated, false);
    }

      function testFuzzRepayiBGT(uint256 durationAmount) public dealUseriBGT dealUserBeras {
        // vm.assume(durationAmount > goldilend.minDuration() && durationAmount < goldilend.maxDuration());
        // goldilend.borrow(1e18, durationAmount, address(bondbear), 1);
        // Goldilend.Loan memory userLoanBefore = goldilend.lookupLoan(address(this), 1);
        // uint256 interestLoanRatio = FixedPointMathLib.divWad(userLoanBefore.interest, userLoanBefore.borrowedAmount);
        // uint256 interest = FixedPointMathLib.mulWadUp(1e18+userLoanBefore.interest, interestLoanRatio);
        // goldilend.repay(1e18+userLoanBefore.interest, 1);
        // Goldilend.Loan memory userLoan = goldilend.lookupLoan(address(this), 1);

        // assertEq(IERC721(address(bondbear)).balanceOf(address(goldilend)), 0);
        // assertEq(IERC721(address(bondbear)).balanceOf(address(this)), 1);
        // assertEq(userLoan.collateralNFTs[0], address(bondbear));
        // assertEq(userLoan.collateralNFTIds[0], 1);
        // assertEq(userLoan.borrowedAmount, 0);
        // assertLe(userLoan.interest, 2);
        // assertEq(userLoan.duration, durationAmount);
        // assertEq(userLoan.endDate, block.timestamp + durationAmount);
        // assertEq(userLoan.loanId, 1);
        // assertEq(userLoan.liquidated, false);
        // assertEq(goldilend.outstandingDebt(), 0);
        // assertEq(goldilend.poolSize(), 1000e18 + (interest * 950 / 1000));
    }

  function testFuzzLiquidate(uint256 time, uint256 durationAmount) public dealUseriBGT dealUserBeras {
        // vm.assume(time < type(uint256).max / 2);
        // vm.assume(durationAmount > goldilend.minDuration() && durationAmount < goldilend.maxDuration());
        // goldilend.borrow(1e18, durationAmount, address(bondbear), 1);
        // vm.warp(time);
        // Goldilend.Loan memory userLoan = goldilend.lookupLoan(address(this), 1);    
        // if(time > userLoan.endDate + 86401) {
        //   goldilend.liquidate(address(this), 1);
        //   assertEq(userLoan.collateralNFTs[0], address(bondbear));
        //   assertEq(userLoan.collateralNFTIds[0], 1);
        //   assertEq(userLoan.duration, durationAmount);
        //   assertEq(userLoan.endDate, durationAmount + 1);
        //   assertEq(userLoan.loanId, 1);
        //   assertEq(IERC721(address(bondbear)).balanceOf(address(goldilend)), 0);
        //   assertEq(IERC721(address(bondbear)).balanceOf(address(this)), 1);
        // }
        // else {
        //   vm.expectRevert(abi.encodeWithSelector(IGoldilend.Unliquidatable.selector));
        //   goldilend.liquidate(address(this), 1);
        // }
    }

}