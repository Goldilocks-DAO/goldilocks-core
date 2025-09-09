//SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { console } from "../../lib/forge-std/src/console.sol";
import { OwnableUpgradeable } from "../../lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import { IERC721 } from "../../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import { BaseUnitTest } from "../base/BaseUnitTest.t.sol";
import { IRebaseGoldilend } from "../../src/interfaces/IRebaseGoldilend.sol";
import { RebaseGoldilend } from "../../src/core/goldilend/RebaseGoldilend.sol";
import { GoldilendDebtAsset } from "../../src/core/goldilend/GoldilendDebtAsset.sol";

contract TestUpgradeableRebaseGoldilend is RebaseGoldilend {
  uint256 public specialNumber;

  function setSpecialNumber() public {
    specialNumber = 69;
  }
}

contract UnitRebaseGoldilendTest is BaseUnitTest {

    function testGoldilendDebtAssetName() public view {
        assertEq(glhoney.name(), "Goldilend Honey");
    }

    function testGoldilendDebtAssetSymbol() public view {
        assertEq(glhoney.symbol(), "glHONEY");
    }

    function testMintglDebtAssetFailGoldilend() public {
        vm.expectRevert(abi.encodeWithSelector(GoldilendDebtAsset.NotGoldilend.selector));
        glhoney.mintglDebtAsset(address(0x69), 69);
    }

    function testBurnglDebtAssetFailGoldilend() public {
        vm.expectRevert(abi.encodeWithSelector(GoldilendDebtAsset.NotGoldilend.selector));
        glhoney.burnglDebtAsset(address(0x69), 69);
    }

    function testGetUserLoanSuccess() public dealHoneyForGoldilend dealUserBeras {
        honey.approve(address(rebaseproxy), txAmount);
        RebaseGoldilend(address(rebaseproxy)).deposit(txAmount);
        RebaseGoldilend(address(rebaseproxy)).borrow(1e18, 0, goldilendDuration, address(bandbear), 1);
        RebaseGoldilend.Loan memory userLoan = RebaseGoldilend(address(rebaseproxy)).getUserLoan(address(this), 1);

        assertEq(userLoan.collateralNFT, address(bandbear));
        assertEq(userLoan.collateralNFTId, 1);
        assertEq(userLoan.borrowedAmount, 1e18);
        assertEq(userLoan.interest, rebaseInterest);
        assertEq(userLoan.duration, goldilendDuration);
        assertEq(userLoan.endDate, block.timestamp + goldilendDuration);
        assertEq(userLoan.loanId, 1);
        assertEq(userLoan.repaid, false);
        assertEq(userLoan.liquidated, false);
    }

    function testCalculateInterestFailDuration() public {
        vm.expectRevert(abi.encodeWithSelector(IRebaseGoldilend.InvalidDuration.selector));
        RebaseGoldilend(address(rebaseproxy)).calculateInterest(69, 69, address(bandbear));
    }

    function testCalculateInterestFailInvalidLoanAmount() public {
        vm.expectRevert(abi.encodeWithSelector(IRebaseGoldilend.InvalidLoanAmount.selector));
        RebaseGoldilend(address(rebaseproxy)).calculateInterest(69, 2 days, address(bandbear));
    }

    function testCalculateInterestFailCollateral() public {
        vm.expectRevert(abi.encodeWithSelector(IRebaseGoldilend.InvalidCollateral.selector));
        RebaseGoldilend(address(rebaseproxy)).calculateInterest(0, 2 days, address(0x69));
    }

    function testCalculateInterestFailBorrowLimit() public dealHoneyForGoldilend {
        honey.approve(address(rebaseproxy), 5000e18);
        RebaseGoldilend(address(rebaseproxy)).deposit(5000e18);
        vm.expectRevert(abi.encodeWithSelector(IRebaseGoldilend.BorrowLimitExceeded.selector));
        RebaseGoldilend(address(rebaseproxy)).calculateInterest(51e18, 2 days, address(bandbear));
    }

    function testCalculateInterestSuccess() public dealHoneyForGoldilend{
        honey.approve(address(rebaseproxy), txAmount);
        RebaseGoldilend(address(rebaseproxy)).deposit(txAmount);
        uint256 interest = RebaseGoldilend(address(rebaseproxy)).calculateInterest(1e18, goldilendDuration, address(bandbear));

        assertEq(interest, rebaseInterest);
    }

    function testDepositSuccess() public dealHoneyForGoldilend {
        honey.approve(address(rebaseproxy), txAmount);
        RebaseGoldilend(address(rebaseproxy)).deposit(txAmount);

        assertEq(honey.balanceOf(address(this)), dealAmt - txAmount);
        assertEq(glhoney.balanceOf(address(this)), txAmount);
        assertEq(honey.balanceOf(address(rebaseproxy)), txAmount);
        assertEq(RebaseGoldilend(address(rebaseproxy)).poolSize(), txAmount);
    }

    function testWithdrawSuccess() public dealHoneyForGoldilend {
        honey.approve(address(rebaseproxy), txAmount);
        RebaseGoldilend(address(rebaseproxy)).deposit(txAmount);
        RebaseGoldilend(address(rebaseproxy)).withdraw(txAmount);

        assertEq(honey.balanceOf(address(this)), dealAmt);
        assertEq(glhoney.balanceOf(address(this)), 0);
        assertEq(honey.balanceOf(address(rebaseproxy)), 0);
        assertEq(RebaseGoldilend(address(rebaseproxy)).poolSize(), 0);
    }

    function testBorrowFailActive() public {
        RebaseGoldilend(address(rebaseproxy)).changeBorrowingActive(false);
        vm.expectRevert(abi.encodeWithSelector(IRebaseGoldilend.NotActive.selector));
        RebaseGoldilend(address(rebaseproxy)).borrow(69, 0, 69, address(0x69), 69);
    }

    function testBorrowFailDuration() public {
        vm.expectRevert(abi.encodeWithSelector(IRebaseGoldilend.InvalidDuration.selector));
        RebaseGoldilend(address(rebaseproxy)).borrow(69, 0, 69, address(0x69), 69);
    }

    function testBorrowFailLoanAmount() public {
        vm.expectRevert(abi.encodeWithSelector(IRebaseGoldilend.InvalidLoanAmount.selector));
        RebaseGoldilend(address(rebaseproxy)).borrow(69, 0, 2 days, address(0x69), 69);
    }

    function testBorrowFailCollateral() public dealHoneyForGoldilend {
        honey.approve(address(rebaseproxy), txAmount);
        RebaseGoldilend(address(rebaseproxy)).deposit(txAmount);
        vm.expectRevert(abi.encodeWithSelector(IRebaseGoldilend.InvalidCollateral.selector));
        RebaseGoldilend(address(rebaseproxy)).borrow(69, 0, 2 days, address(0x69), 69);
    }

    function testRebaseBorrowFailMaxUtilization() public dealHoneyForGoldilend dealUserABunchOfBeras {
        honey.approve(address(rebaseproxy), txAmount);
        RebaseGoldilend(address(rebaseproxy)).deposit(txAmount);
        RebaseGoldilend(address(rebaseproxy)).borrow(1e18, 0, 2 days, address(bandbear), 1);
        RebaseGoldilend(address(rebaseproxy)).borrow(1e18, 0, 2 days, address(bandbear), 2);
        RebaseGoldilend(address(rebaseproxy)).borrow(1e18, 0, 2 days, address(bandbear), 3);
        RebaseGoldilend(address(rebaseproxy)).borrow(1e18, 0, 2 days, address(bandbear), 4);
        RebaseGoldilend(address(rebaseproxy)).borrow(1e18, 0, 2 days, address(bandbear), 5);
        RebaseGoldilend(address(rebaseproxy)).borrow(1e18, 0, 2 days, address(bandbear), 6);
        RebaseGoldilend(address(rebaseproxy)).borrow(1e18, 0, 2 days, address(bandbear), 7);
        RebaseGoldilend(address(rebaseproxy)).borrow(1e18, 0, 2 days, address(bandbear), 8);
        RebaseGoldilend(address(rebaseproxy)).borrow(1e18, 0, 2 days, address(bandbear), 9);
        vm.expectRevert(abi.encodeWithSelector(IRebaseGoldilend.MaxUtilizationExceeded.selector));
        RebaseGoldilend(address(rebaseproxy)).borrow(1e18, 0, 2 days, address(bandbear), 10);
    }

    function testBorrowFailBorrowLimit() public dealUserBeras {
        deal(address(honey), address(this), 1_000_000e18);
        honey.approve(address(rebaseproxy), 1_000_000e18);
        RebaseGoldilend(address(rebaseproxy)).deposit(1_000_000e18);
        vm.expectRevert(abi.encodeWithSelector(IRebaseGoldilend.BorrowLimitExceeded.selector));
        RebaseGoldilend(address(rebaseproxy)).borrow(49e18, 0, 300 days, address(bandbear), 10);
    }

    function testBorrowFailLessThanMinOut() public dealHoneyForGoldilend dealUserBeras {
        honey.approve(address(rebaseproxy), txAmount);
        RebaseGoldilend(address(rebaseproxy)).deposit(txAmount);
        vm.expectRevert(abi.encodeWithSelector(IRebaseGoldilend.LessThanMinOut.selector));
        RebaseGoldilend(address(rebaseproxy)).borrow(1e18, 10e18, goldilendDuration, address(bandbear), 1);
    }

    function testRebaseBorrowSuccess() public dealHoneyForGoldilend dealUserBeras {
        honey.approve(address(rebaseproxy), txAmount);
        RebaseGoldilend(address(rebaseproxy)).deposit(txAmount);
        RebaseGoldilend(address(rebaseproxy)).borrow(1e18, 0, goldilendDuration, address(bandbear), 1);
        RebaseGoldilend.Loan memory userLoan = RebaseGoldilend(address(rebaseproxy)).getUserLoan(address(this), 1);

        assertEq(RebaseGoldilend(address(rebaseproxy)).outstandingDebt(), 1e18);
        assertEq(userLoan.collateralNFT, address(bandbear));
        assertEq(userLoan.collateralNFTId, 1);
        assertEq(userLoan.borrowedAmount, 1e18);
        assertEq(userLoan.interest, rebaseInterest);
        assertEq(userLoan.duration, goldilendDuration);
        assertEq(userLoan.endDate, block.timestamp + goldilendDuration);
        assertEq(userLoan.loanId, 1);
        assertEq(userLoan.repaid, false);
        assertEq(userLoan.liquidated, false);
        assertEq(RebaseGoldilend(address(rebaseproxy)).userLoanAmount(address(this)), 1);
        assertEq(IERC721(address(bandbear)).balanceOf(address(rebaseproxy)), 1);
        assertEq(IERC721(address(bandbear)).balanceOf(address(this)), 0);
        assertEq(honey.balanceOf(address(this)), dealAmt - txAmount + 1e18);
        assertEq(honey.balanceOf(address(rebaseproxy)), txAmount - 1e18);
    }

    function testRepayFailLoanExpired() public dealHoneyForGoldilend dealUserBeras {
        honey.approve(address(rebaseproxy), txAmount);
        RebaseGoldilend(address(rebaseproxy)).deposit(txAmount);
        RebaseGoldilend(address(rebaseproxy)).borrow(1e18, 0, goldilendDuration, address(bandbear), 1);
        vm.warp(block.timestamp + 69 days);
        vm.expectRevert(abi.encodeWithSelector(IRebaseGoldilend.LoanExpired.selector));
        RebaseGoldilend(address(rebaseproxy)).repay(69, 1);
    }

    function testRepaySuccess() public dealHoneyForGoldilend dealUserBeras {
        honey.approve(address(rebaseproxy), txAmount);
        RebaseGoldilend(address(rebaseproxy)).deposit(txAmount);
        RebaseGoldilend(address(rebaseproxy)).borrow(1e18, 0, goldilendDuration, address(bandbear), 1);
        honey.approve(address(rebaseproxy), 1e18);
        RebaseGoldilend(address(rebaseproxy)).repay(1e18, 1);
        RebaseGoldilend.Loan memory userLoan = RebaseGoldilend(address(rebaseproxy)).getUserLoan(address(this), 1);

        assertEq(RebaseGoldilend(address(rebaseproxy)).outstandingDebt(), 0);
        assertEq(honey.balanceOf(address(this)), dealAmt - txAmount);
        assertEq(honey.balanceOf(address(rebaseproxy)), txAmount);
        assertEq(userLoan.repaid, true);
        assertEq(userLoan.borrowedAmount, 0);
        assertEq(IERC721(address(bandbear)).balanceOf(address(rebaseproxy)), 0);
        assertEq(IERC721(address(bandbear)).balanceOf(address(this)), 1);
    }

    function testRepaySuccessAmountTooHigh() public dealHoneyForGoldilend dealUserBeras {
        honey.approve(address(rebaseproxy), txAmount);
        RebaseGoldilend(address(rebaseproxy)).deposit(txAmount);
        RebaseGoldilend(address(rebaseproxy)).borrow(1e18, 0, goldilendDuration, address(bandbear), 1);
        honey.approve(address(rebaseproxy), 2e18);
        RebaseGoldilend(address(rebaseproxy)).repay(2e18, 1);
        RebaseGoldilend.Loan memory userLoan = RebaseGoldilend(address(rebaseproxy)).getUserLoan(address(this), 1);

        assertEq(RebaseGoldilend(address(rebaseproxy)).outstandingDebt(), 0);
        assertEq(honey.balanceOf(address(this)), dealAmt - txAmount);
        assertEq(honey.balanceOf(address(rebaseproxy)), txAmount);
        assertEq(userLoan.repaid, true);
        assertEq(userLoan.borrowedAmount, 0);
        assertEq(IERC721(address(bandbear)).balanceOf(address(rebaseproxy)), 0);
        assertEq(IERC721(address(bandbear)).balanceOf(address(this)), 1);
    }

    function testPartialRepaySuccess() public dealHoneyForGoldilend dealUserBeras {
        honey.approve(address(rebaseproxy), txAmount);
        RebaseGoldilend(address(rebaseproxy)).deposit(txAmount);
        RebaseGoldilend(address(rebaseproxy)).borrow(1e18, 0, goldilendDuration, address(bandbear), 1);
        honey.approve(address(rebaseproxy), 5e17);
        RebaseGoldilend(address(rebaseproxy)).repay(5e17, 1);
        RebaseGoldilend.Loan memory userLoan = RebaseGoldilend(address(rebaseproxy)).getUserLoan(address(this), 1);

        assertEq(RebaseGoldilend(address(rebaseproxy)).outstandingDebt(), 5e17);
        assertEq(honey.balanceOf(address(this)), dealAmt - txAmount + 5e17);
        assertEq(honey.balanceOf(address(rebaseproxy)), txAmount - 5e17);
        assertEq(userLoan.repaid, false);
        assertEq(userLoan.borrowedAmount, 5e17);
        assertEq(IERC721(address(bandbear)).balanceOf(address(rebaseproxy)), 1);
        assertEq(IERC721(address(bandbear)).balanceOf(address(this)), 0);
    }

    function testLiquidateFailUnliquidatable() public dealHoneyForGoldilend dealUserBeras {
        honey.approve(address(rebaseproxy), txAmount);
        RebaseGoldilend(address(rebaseproxy)).deposit(txAmount);
        RebaseGoldilend(address(rebaseproxy)).borrow(1e18, 0, goldilendDuration, address(bandbear), 1);
        vm.expectRevert(abi.encodeWithSelector(IRebaseGoldilend.Unliquidatable.selector));
        RebaseGoldilend(address(rebaseproxy)).liquidate(address(this), 1);
    }

    function testLiquidateSuccess() public dealHoneyForGoldilend dealUserBeras {
        honey.approve(address(rebaseproxy), txAmount);
        RebaseGoldilend(address(rebaseproxy)).deposit(txAmount);
        RebaseGoldilend(address(rebaseproxy)).borrow(1e18, 0, goldilendDuration, address(bandbear), 1);
        vm.warp(block.timestamp + 69 days);
        RebaseGoldilend(address(rebaseproxy)).liquidate(address(this), 1);
        RebaseGoldilend.Loan memory userLoan = RebaseGoldilend(address(rebaseproxy)).getUserLoan(address(this), 1);

        assertEq(userLoan.liquidated, true);
        assertEq(userLoan.borrowedAmount, 0);
        assertEq(RebaseGoldilend(address(rebaseproxy)).outstandingDebt(), 0);
        assertEq(IERC721(address(bandbear)).balanceOf(address(rebaseproxy)), 0);
        assertEq(IERC721(address(bandbear)).balanceOf(address(this)), 1);
    }

    function testRenewFailActive() public dealHoneyForGoldilend {
        honey.approve(address(rebaseproxy), txAmount);
        RebaseGoldilend(address(rebaseproxy)).deposit(txAmount);
        RebaseGoldilend(address(rebaseproxy)).changeBorrowingActive(false);
        vm.expectRevert(abi.encodeWithSelector(IRebaseGoldilend.NotActive.selector));
        RebaseGoldilend(address(rebaseproxy)).renew(1, 69, 69, 0);
    }

    function testRebaseRenewFailInvalid() public dealHoneyForGoldilend dealUserBeras {
        honey.approve(address(rebaseproxy), txAmount);
        RebaseGoldilend(address(rebaseproxy)).deposit(txAmount);
        RebaseGoldilend(address(rebaseproxy)).borrow(1e18, 0, goldilendDuration, address(bandbear), 1);
        honey.approve(address(rebaseproxy), 1e18);
        RebaseGoldilend(address(rebaseproxy)).repay(1e18, 1);
        vm.expectRevert(abi.encodeWithSelector(IRebaseGoldilend.InvalidRenew.selector));
        RebaseGoldilend(address(rebaseproxy)).renew(1, goldilendDuration, 1e18, 0);
    }

    function testRenewFailExpired() public dealHoneyForGoldilend dealUserBeras {
        honey.approve(address(rebaseproxy), txAmount + txAmount);
        RebaseGoldilend(address(rebaseproxy)).deposit(txAmount + txAmount);
        RebaseGoldilend(address(rebaseproxy)).borrow(1e18, 0, goldilendDuration, address(bandbear), 1);
        vm.warp(6969696969);
        vm.expectRevert(abi.encodeWithSelector(IRebaseGoldilend.LoanExpired.selector));
        RebaseGoldilend(address(rebaseproxy)).renew(1, goldilendDuration, 1e18, 0);
    }

    function testRenewFailDuration() public dealHoneyForGoldilend {
        honey.approve(address(rebaseproxy), txAmount);
        RebaseGoldilend(address(rebaseproxy)).deposit(txAmount);
        vm.expectRevert(abi.encodeWithSelector(IRebaseGoldilend.InvalidDuration.selector));
        RebaseGoldilend(address(rebaseproxy)).renew(1, 69, 69, 0);
    }

    function testRenewFailInvalidLoanAmount() public dealHoneyForGoldilend dealUserBeras {
        honey.approve(address(rebaseproxy), txAmount*2);
        RebaseGoldilend(address(rebaseproxy)).deposit(txAmount*2);
        RebaseGoldilend(address(rebaseproxy)).borrow(1e18, 0, goldilendDuration, address(bandbear), 1);
        vm.expectRevert(abi.encodeWithSelector(IRebaseGoldilend.InvalidLoanAmount.selector));
        RebaseGoldilend(address(rebaseproxy)).renew(1, 6 days, 69000e18, 0);
    }

    function testRenewFailBorrowLimit() public dealUserBeras {
        deal(address(honey), address(this), 1_000_000e18);
        honey.approve(address(rebaseproxy), 1_000_000e18);
        RebaseGoldilend(address(rebaseproxy)).deposit(1_000_000e18);
        RebaseGoldilend(address(rebaseproxy)).borrow(1e18, 0, 1 days, address(bandbear),1);
        vm.expectRevert(abi.encodeWithSelector(IRebaseGoldilend.BorrowLimitExceeded.selector));
        RebaseGoldilend(address(rebaseproxy)).renew(1, 300 days, 49e18, 0);
    }

    function testRenewFailLessThanMinOut() public dealHoneyForGoldilend dealUserBeras {
        honey.approve(address(rebaseproxy), txAmount + txAmount);
        RebaseGoldilend(address(rebaseproxy)).deposit(txAmount + txAmount);
        RebaseGoldilend(address(rebaseproxy)).borrow(1e18, 0, goldilendDuration, address(bandbear), 1);
        vm.expectRevert(abi.encodeWithSelector(IRebaseGoldilend.LessThanMinOut.selector));
        RebaseGoldilend(address(rebaseproxy)).renew(1, goldilendDuration, 1e18, 10e18);
    }

    function testRebaseRenewSuccess() public dealHoneyForGoldilend dealUserBeras {
        honey.approve(address(rebaseproxy), txAmount + txAmount);
        RebaseGoldilend(address(rebaseproxy)).deposit(txAmount + txAmount);
        RebaseGoldilend(address(rebaseproxy)).borrow(1e18, 0, goldilendDuration, address(bandbear), 1);
        RebaseGoldilend(address(rebaseproxy)).renew(1, goldilendDuration, 1e18, 0);
        RebaseGoldilend.Loan memory userLoan = RebaseGoldilend(address(rebaseproxy)).getUserLoan(address(this), 1);

        assertEq(RebaseGoldilend(address(rebaseproxy)).outstandingDebt(), 2e18);
        assertEq(userLoan.borrowedAmount, 2e18);
        assertEq(userLoan.interest, renewBorrowInterest + renewInterest);
        assertEq(userLoan.duration, 28 days);
        assertEq(userLoan.endDate, block.timestamp + 14 days);
        assertEq(honey.balanceOf(address(this)), dealAmt - 18e18);
        assertEq(honey.balanceOf(address(rebaseproxy)), 18e18);

    }

    function testChangeLendingParamsFailMultisig() public {
        vm.prank(address(0x69));
        vm.expectRevert(abi.encodeWithSelector(IRebaseGoldilend.NotMultisig.selector));
        RebaseGoldilend(address(rebaseproxy)).changeLendingParams(69, 69, 69, 69, 69);
    }

    function testChangeLendingParamsSuccess() public {
        RebaseGoldilend(address(rebaseproxy)).changeLendingParams(69, 69, 69, 69, 69);

        assertEq(RebaseGoldilend(address(rebaseproxy)).protocolInterestRate(), 69);
        assertEq(RebaseGoldilend(address(rebaseproxy)).slope(), 69);
        assertEq(RebaseGoldilend(address(rebaseproxy)).minDuration(), 69);
        assertEq(RebaseGoldilend(address(rebaseproxy)).maxDuration(), 69);
    }

    function testChangeBorrowingActiveFailMultisig() public {
        vm.prank(address(0x69));
        vm.expectRevert(abi.encodeWithSelector(IRebaseGoldilend.NotMultisig.selector));
        RebaseGoldilend(address(rebaseproxy)).changeBorrowingActive(false);
    }

    function testChangeBorrowingActiveSuccess() public {
        RebaseGoldilend(address(rebaseproxy)).changeBorrowingActive(false);

        assertEq(RebaseGoldilend(address(rebaseproxy)).borrowingActive(), false);
    }

    function testInitializeParametersFailMultisig() public {
        vm.prank(address(0x69));
        vm.expectRevert(abi.encodeWithSelector(IRebaseGoldilend.NotMultisig.selector));
        RebaseGoldilend(address(rebaseproxy)).initializeParameters(69, 69, 69, 69, 69);
    }

    function testInitializeParametersFailAlready() public {
        vm.expectRevert(abi.encodeWithSelector(IRebaseGoldilend.AlreadyInitialized.selector));
        RebaseGoldilend(address(rebaseproxy)).initializeParameters(69, 69, 69, 69, 69);
    }

    function testRecoverTokensFailMultisig() public {
        vm.prank(address(0x69));
        vm.expectRevert(abi.encodeWithSelector(IRebaseGoldilend.NotMultisig.selector));
        RebaseGoldilend(address(rebaseproxy)).recoverTokens(address(0x69));
    }

    function testRecoverTokensSuccess() public {
        deal(address(honey), address(rebaseproxy), 69);
        RebaseGoldilend(address(rebaseproxy)).recoverTokens(address(honey));

        assertEq(honey.balanceOf(address(this)), 69);
    }

    function testIncreaseglDebtAssetBackingFailMultisig() public {
        vm.prank(address(0x69));
        vm.expectRevert(abi.encodeWithSelector(IRebaseGoldilend.NotMultisig.selector));
        RebaseGoldilend(address(rebaseproxy)).increaseglDebtAssetBacking(69);
    }

    function testIncreaseglDebtAssetBackingSuccess() public {
        deal(address(honey), address(this), 69);
        honey.approve(address(rebaseproxy), 69);
        RebaseGoldilend(address(rebaseproxy)).increaseglDebtAssetBacking(69);

        assertEq(honey.balanceOf(address(this)), 0);
        assertEq(honey.balanceOf(address(rebaseproxy)), 69);
        assertEq(RebaseGoldilend(address(rebaseproxy)).poolSize(), 69);
    }

    function testChangeValueFailMultisig() public {
        address[] memory nfts = new address[](2);
        nfts[0] = address(bondbear);
        nfts[1] = address(bandbear);
        uint256[] memory values = new uint256[](2);
        values[0] = 50;
        values[1] = 50;
        vm.prank(address(0x69));
        vm.expectRevert(abi.encodeWithSelector(IRebaseGoldilend.NotMultisig.selector));
        RebaseGoldilend(address(rebaseproxy)).changeValue(nfts, values);
    }

    function testChangeValueFailArray() public {
        address[] memory nfts = new address[](2);
        nfts[0] = address(bondbear);
        nfts[1] = address(bandbear);
        uint256[] memory values = new uint256[](1);
        values[0] = 50;
        vm.expectRevert(abi.encodeWithSelector(IRebaseGoldilend.ArrayMismatch.selector));
        RebaseGoldilend(address(rebaseproxy)).changeValue(nfts, values);
    }

    function testChangeValueSuccess() public {
        address[] memory nfts = new address[](2);
        nfts[0] = address(bondbear);
        nfts[1] = address(bandbear);
        uint256[] memory values = new uint256[](2);
        values[0] = 50;
        values[1] = 50;
        RebaseGoldilend(address(rebaseproxy)).changeValue(nfts, values);    

        assertEq(RebaseGoldilend(address(rebaseproxy)).nftFairValues(address(bondbear)), 50);
        assertEq(RebaseGoldilend(address(rebaseproxy)).nftFairValues(address(bandbear)), 50);
    }

    function testInitializeBerasFailMultisig() public {
        address[] memory nfts = new address[](2);
        nfts[0] = address(bondbear);
        nfts[1] = address(bandbear);
        uint256[] memory values = new uint256[](2);
        values[0] = 50;
        values[1] = 50;
        vm.prank(address(0x69));
        vm.expectRevert(abi.encodeWithSelector(IRebaseGoldilend.NotMultisig.selector));
        RebaseGoldilend(address(rebaseproxy)).initializeBeras(nfts, values);
    }

    function testInitializeBerasFailAlready() public {
        address[] memory nfts = new address[](2);
        nfts[0] = address(bondbear);
        nfts[1] = address(bandbear);
        uint256[] memory values = new uint256[](2);
        values[0] = 50;
        values[1] = 50;
        vm.expectRevert(abi.encodeWithSelector(IRebaseGoldilend.AlreadyInitialized.selector));
        RebaseGoldilend(address(rebaseproxy)).initializeBeras(nfts, values);
    }

    function testUpgradeRebaseGoldilendFailOwner() public {
        vm.prank(address(0x69));
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, address(0x69)));
        RebaseGoldilend(address(rebaseproxy)).upgradeToAndCall(address(0x69), "");
    }

    function testUpgradeRebaseGoldilendSuccess() public {
        TestUpgradeableRebaseGoldilend newRebaseGoldilend = new TestUpgradeableRebaseGoldilend();
        bytes memory data = abi.encodeWithSelector(TestUpgradeableRebaseGoldilend.setSpecialNumber.selector);
        RebaseGoldilend(address(rebaseproxy)).upgradeToAndCall(address(newRebaseGoldilend), data);

        assertEq(TestUpgradeableRebaseGoldilend(address(rebaseproxy)).specialNumber(), 69);
        assertEq(TestUpgradeableRebaseGoldilend(address(rebaseproxy)).multisig(), address(this));
    }

    
}