//SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { console } from "../../lib/forge-std/src/console.sol";
import { OwnableUpgradeable } from "../../lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import { IERC721 } from "../../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import { BaseUnitTest } from "../base/BaseUnitTest.t.sol";
import { IBeraBondGoldilend } from "../../src/interfaces/IBeraBondGoldilend.sol";
import { BeraBondGoldilend } from "../../src/core/goldilend/BeraBondGoldilend.sol";
import { GoldilendDebtAsset } from "../../src/core/goldilend/GoldilendDebtAsset.sol";

contract TestUpgradeableBeraBondGoldilend is BeraBondGoldilend {
  uint256 public specialNumber;

  function setSpecialNumber() public {
    specialNumber = 69;
  }
}

contract NoTransfersAllowed {
    uint256 public hello;
}

contract UnitBeraBondGoldilendTest is BaseUnitTest {

    function testDepositFailInvalidAmount() public {
        vm.expectRevert(abi.encodeWithSelector(IBeraBondGoldilend.InvalidAmount.selector));
        BeraBondGoldilend(payable(address(berabondproxy))).deposit{value: 0}();
    }

    function testDepositSuccess() public dealBeraForGoldilend {
        uint256 initialBeraBalance = address(this).balance;
        uint256 initialGlDebtSupply = gbera.totalSupply();
        
        BeraBondGoldilend(payable(address(berabondproxy))).deposit{value: txAmount}();

        assertEq(gbera.balanceOf(address(this)), txAmount);
        assertEq(address(this).balance, initialBeraBalance - txAmount);
        assertEq(address(berabondproxy).balance, txAmount);
    }

    function testDepositWithExistingPool() public dealBeraForGoldilend {
        BeraBondGoldilend(payable(address(berabondproxy))).deposit{value: txAmount}();
        uint256 secondDeposit = txAmount / 2;
        uint256 initialGlDebtBalance = gbera.balanceOf(address(this));
        
        BeraBondGoldilend(payable(address(berabondproxy))).deposit{value: secondDeposit}();
        
        assertGt(gbera.balanceOf(address(this)), initialGlDebtBalance);
    }

    function testWithdrawFailTransfer() public {
        NoTransfersAllowed test = new NoTransfersAllowed();
        deal(address(test), dealAmt);
        vm.prank(address(test));
        BeraBondGoldilend(payable(address(berabondproxy))).deposit{value: txAmount}();
        vm.prank(address(test));
        vm.expectRevert(abi.encodeWithSelector(IBeraBondGoldilend.TransferFailed.selector));
        BeraBondGoldilend(payable(address(berabondproxy))).withdraw(txAmount);
    }

    function testWithdrawSuccess() public dealBeraForGoldilend {
        BeraBondGoldilend(payable(address(berabondproxy))).deposit{value: txAmount}();
        uint256 balanceAfterDeposit = address(this).balance;
        
        BeraBondGoldilend(payable(address(berabondproxy))).withdraw(txAmount);

        assertEq(gbera.balanceOf(address(this)), 0);
        assertEq(address(this).balance, balanceAfterDeposit + txAmount);
        assertEq(address(berabondproxy).balance, 0);
    }

    function testWithdrawPartial() public dealBeraForGoldilend {
        BeraBondGoldilend(payable(address(berabondproxy))).deposit{value: txAmount}();
        uint256 withdrawAmount = txAmount / 2;
        
        BeraBondGoldilend(payable(address(berabondproxy))).withdraw(withdrawAmount);

        assertEq(gbera.balanceOf(address(this)), txAmount - withdrawAmount);
    }

    function testGetUserLoan() public {
        IBeraBondGoldilend.Loan memory loan = BeraBondGoldilend(payable(address(berabondproxy))).getUserLoan(address(this), 1);
        assertEq(loan.collateralNFT, address(0));
        assertEq(loan.collateralNFTId, 0);
        assertEq(loan.borrowedAmount, 0);
        assertEq(loan.interest, 0);
        assertEq(loan.duration, 0);
        assertEq(loan.endDate, 0);
        assertEq(loan.loanId, 0);
        assertEq(loan.repaid, false);
        assertEq(loan.liquidated, false);
    }

    function testChangeLendingParamsFailNotMultisig() public {
        vm.prank(address(0x69));
        vm.expectRevert(abi.encodeWithSelector(IBeraBondGoldilend.NotMultisig.selector));
        BeraBondGoldilend(payable(address(berabondproxy))).changeLendingParams(25e18, 2 days, 730 days, 7 days, 30 days, 3e18, 95, 85);
    }

    function testChangeLendingParamsSuccess() public {
        uint256 newInterestRate = 25e18;
        uint256 newMinDuration = 2 days;
        uint256 newMaxDuration = 730 days;
        uint256 newSlope = 3e18;
        uint256 newMaxUtilization = 95;
        uint256 newLTV = 85;

        vm.expectEmit(true, false, false, true);
        emit IBeraBondGoldilend.NewProtocolInterestRate(newInterestRate);
        vm.expectEmit(true, false, false, true);
        emit IBeraBondGoldilend.NewDurations(newMinDuration, newMaxDuration);
        vm.expectEmit(true, false, false, true);
        emit IBeraBondGoldilend.NewSlope(newSlope);
        vm.expectEmit(true, false, false, true);
        emit IBeraBondGoldilend.NewMaxUtilization(newMaxUtilization);
        vm.expectEmit(true, false, false, true);
        emit IBeraBondGoldilend.NewLTV(newLTV);

        BeraBondGoldilend(payable(address(berabondproxy))).changeLendingParams(newInterestRate, newMinDuration, newMaxDuration, 7 days, 30 days, newSlope, newMaxUtilization, newLTV);

        assertEq(BeraBondGoldilend(payable(address(berabondproxy))).protocolInterestRate(), newInterestRate);
        assertEq(BeraBondGoldilend(payable(address(berabondproxy))).minDuration(), newMinDuration);
        assertEq(BeraBondGoldilend(payable(address(berabondproxy))).maxDuration(), newMaxDuration);
        assertEq(BeraBondGoldilend(payable(address(berabondproxy))).slope(), newSlope);
        assertEq(BeraBondGoldilend(payable(address(berabondproxy))).maxUtilization(), newMaxUtilization);
        assertEq(BeraBondGoldilend(payable(address(berabondproxy))).LTV(), newLTV);
    }

    function testChangeBorrowingActiveFailNotMultisig() public {
        vm.prank(address(0x69));
        vm.expectRevert(abi.encodeWithSelector(IBeraBondGoldilend.NotMultisig.selector));
        BeraBondGoldilend(payable(address(berabondproxy))).changeBorrowingActive(false);
    }

    function testChangeBorrowingActiveSuccess() public {
        vm.expectEmit(true, false, false, true);
        emit IBeraBondGoldilend.NewBorrowingActive(false);

        BeraBondGoldilend(payable(address(berabondproxy))).changeBorrowingActive(false);
        assertEq(BeraBondGoldilend(payable(address(berabondproxy))).borrowingActive(), false);

        vm.expectEmit(true, false, false, true);
        emit IBeraBondGoldilend.NewBorrowingActive(true);

        BeraBondGoldilend(payable(address(berabondproxy))).changeBorrowingActive(true);
        assertEq(BeraBondGoldilend(payable(address(berabondproxy))).borrowingActive(), true);
    }

    function testInitializeParametersFailNotMultisig() public {
        vm.prank(address(0x69));
        vm.expectRevert(abi.encodeWithSelector(IBeraBondGoldilend.NotMultisig.selector));
        BeraBondGoldilend(payable(address(berabondproxy))).initializeParameters(25e18, 2 days, 730 days, 7 days, 30 days, 3e18, 95, 85);
    }

    function testInitializeParametersFailAlreadyInitialized() public {
        vm.expectRevert(abi.encodeWithSelector(IBeraBondGoldilend.AlreadyInitialized.selector));
        BeraBondGoldilend(payable(address(berabondproxy))).initializeParameters(25e18, 2 days, 730 days, 7 days, 30 days, 3e18, 95, 85);
    }

    function testRecoverTokensFailNotMultisig() public {
        vm.prank(address(0x69));
        vm.expectRevert(abi.encodeWithSelector(IBeraBondGoldilend.NotMultisig.selector));
        BeraBondGoldilend(payable(address(berabondproxy))).recoverTokens(address(0x69));
    }

    function testRecoverTokensSuccess() public {
        deal(address(honey), address(berabondproxy), 69);
        BeraBondGoldilend(payable(address(berabondproxy))).recoverTokens(address(honey));

        assertEq(honey.balanceOf(address(this)), 69);
        assertEq(honey.balanceOf(address(berabondproxy)), 0);
    }

    function testUpgradeSuccess() public {
        TestUpgradeableBeraBondGoldilend newImplementation = new TestUpgradeableBeraBondGoldilend();
        bytes memory data = abi.encodeWithSelector(TestUpgradeableBeraBondGoldilend.setSpecialNumber.selector);
        BeraBondGoldilend(payable(address(berabondproxy))).upgradeToAndCall(address(newImplementation), data);

        assertEq(TestUpgradeableBeraBondGoldilend(payable(address(berabondproxy))).specialNumber(), 69);
        assertEq(TestUpgradeableBeraBondGoldilend(payable(address(berabondproxy))).multisig(), address(this));
    }

    function testUpgradeFailNotOwner() public {
        TestUpgradeableBeraBondGoldilend newImplementation = new TestUpgradeableBeraBondGoldilend();
        bytes memory data = abi.encodeWithSelector(TestUpgradeableBeraBondGoldilend.setSpecialNumber.selector);
        
        vm.prank(address(0x69));
        vm.expectRevert();
        BeraBondGoldilend(payable(address(berabondproxy))).upgradeToAndCall(address(newImplementation), data);
    }

    function testReceive() public {
        uint256 initialBalance = address(berabondproxy).balance;
        (bool success,) = address(berabondproxy).call{value: 100}("");
        assertTrue(success);
        assertEq(address(berabondproxy).balance, initialBalance + 100);
    }

    function testCalculateInterestFailDuration() public {
        vm.expectRevert(abi.encodeWithSelector(IBeraBondGoldilend.InvalidDuration.selector));
        BeraBondGoldilend(payable(address(berabondproxy))).calculateInterest(69, 69, address(0x69), 1);
    }

    function testCalculateInterestFailInvalidLoanAmount() public {
        vm.expectRevert(abi.encodeWithSelector(IBeraBondGoldilend.InvalidLoanAmount.selector));
        BeraBondGoldilend(payable(address(berabondproxy))).calculateInterest(69, 2 days, address(0x69), 1);
    }

    function testCalculateInterestFailCollateral() public {
        vm.expectRevert(abi.encodeWithSelector(IBeraBondGoldilend.InvalidCollateral.selector));
        BeraBondGoldilend(payable(address(berabondproxy))).calculateInterest(0, 2 days, address(0x69), 1);
    }

    function testBorrowFailActive() public {
        BeraBondGoldilend(payable(address(berabondproxy))).changeBorrowingActive(false);
        vm.expectRevert(abi.encodeWithSelector(IBeraBondGoldilend.NotActive.selector));
        BeraBondGoldilend(payable(address(berabondproxy))).borrow(69, 0, 69, address(0x69), 69);
    }

    function testBorrowFailDuration() public {
        vm.expectRevert(abi.encodeWithSelector(IBeraBondGoldilend.InvalidDuration.selector));
        BeraBondGoldilend(payable(address(berabondproxy))).borrow(69, 0, 69, address(0x69), 69);
    }

    function testBorrowFailCollateral() public dealBeraForGoldilend {
        BeraBondGoldilend(payable(address(berabondproxy))).deposit{value: txAmount}();
        vm.expectRevert(abi.encodeWithSelector(IBeraBondGoldilend.InvalidCollateral.selector));
        BeraBondGoldilend(payable(address(berabondproxy))).borrow(69, 0, 2 days, address(0x69), 69);
    }

    function testRepayFailInvalidAmount() public {
        vm.expectRevert(abi.encodeWithSelector(IBeraBondGoldilend.InvalidAmount.selector));
        BeraBondGoldilend(payable(address(berabondproxy))).repay(1);
    }

    function testManageDelegationFailNotMultisig() public {
        vm.prank(address(0x69));
        vm.expectRevert(abi.encodeWithSelector(IBeraBondGoldilend.NotMultisig.selector));
        BeraBondGoldilend(payable(address(berabondproxy))).manageDelegation(
            address(0x69), 1, address(0x420), 1
        );
    }

    receive() external payable {}
}