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

    function testCalculateInterestFailDuration() public {
        vm.expectRevert(abi.encodeWithSelector(IBeraBondGoldilend.InvalidDuration.selector));
        BeraBondGoldilend(payable(address(berabondproxy))).calculateInterest(69, 69, address(bandbear), 1);
    }

    function testCalculateInterestFailInvalidLoanAmount() public {
        vm.expectRevert(abi.encodeWithSelector(IBeraBondGoldilend.InvalidLoanAmount.selector));
        BeraBondGoldilend(payable(address(berabondproxy))).calculateInterest(69, 2 days, address(bandbear), 1);
    }

    function testCalculateInterestFailCollateral() public {
        vm.expectRevert(abi.encodeWithSelector(IBeraBondGoldilend.InvalidCollateral.selector));
        BeraBondGoldilend(payable(address(berabondproxy))).calculateInterest(0, 2 days, address(0x69), 1);
    }

    function testDepositFailInvalidAmount() public {
        vm.expectRevert(abi.encodeWithSelector(IBeraBondGoldilend.InvalidAmount.selector));
        BeraBondGoldilend(payable(address(berabondproxy))).deposit{value: 0}();
    }

    function testDepositSuccess() public dealBeraForGoldilend {
        uint256 initialBeraBalance = address(this).balance;
        BeraBondGoldilend(payable(address(berabondproxy))).deposit{value: txAmount}();

        assertEq(glbera.balanceOf(address(this)), txAmount);
        assertEq(BeraBondGoldilend(payable(address(berabondproxy))).poolSize(), txAmount);
        assertEq(address(this).balance, initialBeraBalance - txAmount);
        assertEq(address(berabondproxy).balance, txAmount);
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

        assertEq(glbera.balanceOf(address(this)), 0);
        assertEq(BeraBondGoldilend(payable(address(berabondproxy))).poolSize(), 0);
        assertEq(address(this).balance, balanceAfterDeposit + txAmount);
        assertEq(address(berabondproxy).balance, 0);
    }

    function testBorrowFailActive() public {
        BeraBondGoldilend(payable(address(berabondproxy))).changeBorrowingActive(false);
        vm.expectRevert(abi.encodeWithSelector(IBeraBondGoldilend.NotActive.selector));
        BeraBondGoldilend(payable(address(berabondproxy))).borrow(69, 69, address(0x69), 69);
    }

    function testBorrowFailDuration() public {
        vm.expectRevert(abi.encodeWithSelector(IBeraBondGoldilend.InvalidDuration.selector));
        BeraBondGoldilend(payable(address(berabondproxy))).borrow(69, 69, address(0x69), 69);
    }

    function testBorrowFailCollateral() public dealBeraForGoldilend {
        BeraBondGoldilend(payable(address(berabondproxy))).deposit{value: txAmount}();
        vm.expectRevert(abi.encodeWithSelector(IBeraBondGoldilend.InvalidCollateral.selector));
        BeraBondGoldilend(payable(address(berabondproxy))).borrow(69, 2 days, address(0x69), 69);
    }

    function testRecoverTokensFailMultisig() public {
        vm.prank(address(0x69));
        vm.expectRevert(abi.encodeWithSelector(IBeraBondGoldilend.NotMultisig.selector));
        BeraBondGoldilend(payable(address(berabondproxy))).recoverTokens(address(0x69));
    }

    function testRecoverTokensSuccess() public {
        deal(address(honey), address(berabondproxy), 69);
        BeraBondGoldilend(payable(address(berabondproxy))).recoverTokens(address(honey));

        assertEq(honey.balanceOf(address(this)), 69);
    }

    function testIncreaseglDebtAssetBackingFailMultisig() public {
        deal(address(0x69), 69);
        vm.prank(address(0x69));
        vm.expectRevert(abi.encodeWithSelector(IBeraBondGoldilend.NotMultisig.selector));
        BeraBondGoldilend(payable(address(berabondproxy))).increaseglDebtAssetBacking{ value: 69 }();
    }

    function testIncreaseglDebtAssetBackingSuccess() public {
        deal(address(this), 69);
        BeraBondGoldilend(payable(address(berabondproxy))).increaseglDebtAssetBacking{ value: 69 }();

        assertEq(address(this).balance, 0);
        assertEq(address(berabondproxy).balance, 69);
        assertEq(BeraBondGoldilend(payable(address(berabondproxy))).poolSize(), 69);
    }

    receive() external payable {}
}