//SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { BaseFuzzTest } from "../base/BaseFuzzTest.t.sol";
import { IERC721 } from "../../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import { INFT } from "../../src/mock/INFT.sol";
import { IRebaseGoldilend } from "../../src/interfaces/IRebaseGoldilend.sol";
import { RebaseGoldilend } from "../../src/core/goldilend/RebaseGoldilend.sol";

contract FuzzRebaseGoldilendTest is BaseFuzzTest {

    function testFuzzDeposit(uint256 depositAmount) public {
        vm.assume(depositAmount > 0 && depositAmount < 1e40);
        deal(address(honey), address(this), depositAmount);
        honey.approve(address(rebaseproxy), depositAmount);
        RebaseGoldilend(address(rebaseproxy)).deposit(depositAmount);

        assertEq(ghoney.balanceOf(address(this)), depositAmount);
        assertEq(honey.balanceOf(address(this)), 0);
        assertEq(honey.balanceOf(address(rebaseproxy)), depositAmount);
        assertEq(ghoney.totalSupply(), depositAmount);
    }

    function testFuzzWithdraw(uint256 depositAmount, uint256 withdrawAmount) public {
        vm.assume(depositAmount > withdrawAmount);
        vm.assume(1e5 < depositAmount && depositAmount < 1e40);
        vm.assume(1e5 < withdrawAmount && withdrawAmount < 1e40);
        deal(address(honey), address(this), depositAmount);
        honey.approve(address(rebaseproxy), depositAmount);
        RebaseGoldilend(address(rebaseproxy)).deposit(depositAmount);
        RebaseGoldilend(address(rebaseproxy)).withdraw(withdrawAmount);

        assertEq(ghoney.balanceOf(address(this)), depositAmount - withdrawAmount);
        assertEq(honey.balanceOf(address(this)), withdrawAmount);
        assertEq(honey.balanceOf(address(rebaseproxy)), depositAmount - withdrawAmount);
        assertEq(ghoney.totalSupply(), depositAmount - withdrawAmount);
    }

    function testFuzzBorrow(uint256 borrowAmount, uint256 duration) public {
        vm.assume(borrowAmount > 0 && borrowAmount < 1e17);
        vm.assume(duration >= 1 days && duration <= 365 days);

        INFT(address(bandbear)).mint(address(this));
        IERC721(bandbear).setApprovalForAll(address(rebaseproxy), true);

        deal(address(honey), address(this), 1e30);
        honey.approve(address(rebaseproxy), 1e30);
        RebaseGoldilend(address(rebaseproxy)).deposit(1e30);

        uint256 initialBalance = honey.balanceOf(address(this));
        RebaseGoldilend(address(rebaseproxy)).borrow(borrowAmount, 1_000e18, duration, address(bandbear), 1);
        uint256 finalBalance = honey.balanceOf(address(this));

        assertLe(finalBalance, initialBalance + borrowAmount);
        assertGe(finalBalance, initialBalance);
        assertEq(RebaseGoldilend(address(rebaseproxy)).outstandingDebt(), borrowAmount);
    }

    function testFuzzRepay(uint256 borrowAmount, uint256 repayAmount) public {
        vm.assume(borrowAmount > 0 && borrowAmount < 1e17);
        vm.assume(repayAmount > 0 && repayAmount <= borrowAmount);

        INFT(address(bandbear)).mint(address(this));
        IERC721(bandbear).setApprovalForAll(address(rebaseproxy), true);

        deal(address(honey), address(this), 1e30);
        honey.approve(address(rebaseproxy), 1e30);
        RebaseGoldilend(address(rebaseproxy)).deposit(1e30);

        RebaseGoldilend(address(rebaseproxy)).borrow(borrowAmount, 1_000e18, 30 days, address(bandbear), 1);
        uint256 initialBalance = honey.balanceOf(address(this));
        honey.approve(address(rebaseproxy), repayAmount);
        RebaseGoldilend(address(rebaseproxy)).repay(repayAmount, 1);

        assertEq(honey.balanceOf(address(this)), initialBalance - repayAmount);
        assertEq(RebaseGoldilend(address(rebaseproxy)).outstandingDebt(), borrowAmount - repayAmount);
    }

    function testFuzzMultipleDeposits(uint256[] calldata amounts) public {
        vm.assume(amounts.length > 0 && amounts.length <= 5);

        uint256 totalDeposited = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            vm.assume(amounts[i] > 0 && amounts[i] < 1e25);
            totalDeposited += amounts[i];
        }
        vm.assume(totalDeposited < 100_000e18 || RebaseGoldilend(address(rebaseproxy)).outstandingDebt() >= totalDeposited * 5 / 10);

        for (uint256 i = 0; i < amounts.length; i++) {
            deal(address(honey), address(this), amounts[i]);
            honey.approve(address(rebaseproxy), amounts[i]);
            RebaseGoldilend(address(rebaseproxy)).deposit(amounts[i]);
        }

        assertEq(ghoney.totalSupply(), totalDeposited);
    }

    function testFuzzMultipleBorrows(uint256 borrowAmount1, uint256 borrowAmount2) public {
        vm.assume(borrowAmount1 > 0 && borrowAmount1 < 1e16);
        vm.assume(borrowAmount2 > 0 && borrowAmount2 < 1e16);

        deal(address(honey), address(this), 1e30);
        honey.approve(address(rebaseproxy), 1e30);
        RebaseGoldilend(address(rebaseproxy)).deposit(1e30);

        INFT(address(bandbear)).mint(address(this));
        INFT(address(bandbear)).mint(address(this));
        IERC721(bandbear).setApprovalForAll(address(rebaseproxy), true);

        RebaseGoldilend(address(rebaseproxy)).borrow(borrowAmount1, 1_000e18, 30 days, address(bandbear), 1);
        RebaseGoldilend(address(rebaseproxy)).borrow(borrowAmount2, 1_000e18, 30 days, address(bandbear), 2);

        assertEq(RebaseGoldilend(address(rebaseproxy)).outstandingDebt(), borrowAmount1 + borrowAmount2);
    }

    function testFuzzRepayPartialAndFull(uint256 borrowAmount, uint256 partialRepay) public {
        vm.assume(borrowAmount > partialRepay && partialRepay > 0);
        vm.assume(borrowAmount < 1e17 && partialRepay < 1e17);

        INFT(address(bandbear)).mint(address(this));
        IERC721(bandbear).setApprovalForAll(address(rebaseproxy), true);

        deal(address(honey), address(this), 1e30);
        honey.approve(address(rebaseproxy), 1e30);
        RebaseGoldilend(address(rebaseproxy)).deposit(1e30);

        RebaseGoldilend(address(rebaseproxy)).borrow(borrowAmount, 1_000e18, 30 days, address(bandbear), 1);

        honey.approve(address(rebaseproxy), partialRepay);
        RebaseGoldilend(address(rebaseproxy)).repay(partialRepay, 1);
        assertEq(RebaseGoldilend(address(rebaseproxy)).outstandingDebt(), borrowAmount - partialRepay);

        honey.approve(address(rebaseproxy), borrowAmount - partialRepay);
        RebaseGoldilend(address(rebaseproxy)).repay(borrowAmount - partialRepay, 1);
        assertEq(RebaseGoldilend(address(rebaseproxy)).outstandingDebt(), 0);
    }

    function testFuzzBorrowWithDifferentCollateral(uint256 borrowAmount, uint256 duration) public {
        vm.assume(borrowAmount > 0 && borrowAmount < 1e17);
        vm.assume(duration >= 1 days && duration <= 365 days);

        deal(address(honey), address(this), 1e30);
        honey.approve(address(rebaseproxy), 1e30);
        RebaseGoldilend(address(rebaseproxy)).deposit(1e30);

        INFT(address(bondbear)).mint(address(this));
        IERC721(bondbear).setApprovalForAll(address(rebaseproxy), true);

        uint256 initialBalance = honey.balanceOf(address(this));
        RebaseGoldilend(address(rebaseproxy)).borrow(borrowAmount, 1_000e18, duration, address(bondbear), 1);
        uint256 finalBalance = honey.balanceOf(address(this));

        assertLe(finalBalance, initialBalance + borrowAmount);
        assertGe(finalBalance, initialBalance);
        assertEq(RebaseGoldilend(address(rebaseproxy)).outstandingDebt(), borrowAmount);
    }

    function testFuzzMaxUtilization(uint256 depositAmount, uint256 borrowAmount) public {
        vm.assume(depositAmount > 1e20 && depositAmount < 1e25);
        vm.assume(borrowAmount > 0 && borrowAmount < 1e17);
        vm.assume(borrowAmount < depositAmount / 10);

        INFT(address(bandbear)).mint(address(this));
        IERC721(bandbear).setApprovalForAll(address(rebaseproxy), true);

        deal(address(honey), address(this), depositAmount);
        honey.approve(address(rebaseproxy), depositAmount);
        RebaseGoldilend(address(rebaseproxy)).deposit(depositAmount);

        RebaseGoldilend(address(rebaseproxy)).borrow(borrowAmount, 1_000e18, 30 days, address(bandbear), 1);

        uint256 utilization = (RebaseGoldilend(address(rebaseproxy)).outstandingDebt() * 100) / ghoney.totalSupply();
        assertLe(utilization, 90);
    }


    function testFuzzLoanGracePeriod(uint256 borrowAmount) public {
        vm.assume(borrowAmount > 0 && borrowAmount < 1e17);

        INFT(address(bandbear)).mint(address(this));
        IERC721(bandbear).setApprovalForAll(address(rebaseproxy), true);

        deal(address(honey), address(this), 1e30);
        honey.approve(address(rebaseproxy), 1e30);
        RebaseGoldilend(address(rebaseproxy)).deposit(1e30);

        RebaseGoldilend(address(rebaseproxy)).borrow(borrowAmount, 1_000e18, 1 days, address(bandbear), 1);

        vm.warp(block.timestamp + 1 days + 12 hours);
        honey.approve(address(rebaseproxy), borrowAmount);
        RebaseGoldilend(address(rebaseproxy)).repay(borrowAmount, 1);

        assertEq(RebaseGoldilend(address(rebaseproxy)).outstandingDebt(), 0);
    }

}