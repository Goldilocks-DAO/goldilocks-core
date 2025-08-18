//SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { console } from "../../lib/forge-std/src/console.sol";
import { OwnableUpgradeable } from "../../lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import { IERC721 } from "../../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import { BaseUnitTest } from "../base/BaseUnitTest.t.sol";
import { GoldilendBase } from "../../src/core/goldilend/GoldilendBase.sol";
import { IGoldilendBase } from "../../src/interfaces/IGoldilendBase.sol";
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
        GoldilendBase(address(rebaseproxy)).deposit(txAmount);
        RebaseGoldilend(address(rebaseproxy)).borrow(1e18, goldilendDuration, address(bandbear), 1);
        GoldilendBase.Loan memory userLoan = GoldilendBase(address(rebaseproxy)).getUserLoan(address(this), 1);

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
        vm.expectRevert(abi.encodeWithSelector(IGoldilendBase.InvalidDuration.selector));
        GoldilendBase(address(rebaseproxy)).calculateInterest(69, 69, address(bandbear));
    }

    function testCalculateInterestFailInvalidLoanAmount() public {
        vm.expectRevert(abi.encodeWithSelector(IGoldilendBase.InvalidLoanAmount.selector));
        GoldilendBase(address(rebaseproxy)).calculateInterest(69, 2 days, address(bandbear));
    }

    function testCalculateInterestFailCollateral() public {
        vm.expectRevert(abi.encodeWithSelector(IGoldilendBase.InvalidCollateral.selector));
        GoldilendBase(address(rebaseproxy)).calculateInterest(0, 2 days, address(0x69));
    }

    function testCalculateInterestFailBorrowLimit() public dealHoneyForGoldilend {
        honey.approve(address(rebaseproxy), 5000e18);
        GoldilendBase(address(rebaseproxy)).deposit(5000e18);
        vm.expectRevert(abi.encodeWithSelector(IGoldilendBase.BorrowLimitExceeded.selector));
        GoldilendBase(address(rebaseproxy)).calculateInterest(51e18, 2 days, address(bandbear));
    }

    function testCalculateInterestSuccess() public dealHoneyForGoldilend{
        honey.approve(address(rebaseproxy), txAmount);
        GoldilendBase(address(rebaseproxy)).deposit(txAmount);
        uint256 interest = GoldilendBase(address(rebaseproxy)).calculateInterest(1e18, goldilendDuration, address(bandbear));

        assertEq(interest, rebaseInterest);
    }

    function testDepositSuccess() public dealHoneyForGoldilend {
        honey.approve(address(rebaseproxy), txAmount);
        GoldilendBase(address(rebaseproxy)).deposit(txAmount);

        assertEq(honey.balanceOf(address(this)), dealAmt - txAmount);
        assertEq(glhoney.balanceOf(address(this)), txAmount);
        assertEq(honey.balanceOf(address(rebaseproxy)), txAmount);
        assertEq(GoldilendBase(address(rebaseproxy)).poolSize(), txAmount);
    }

    function testWithdrawSuccess() public dealHoneyForGoldilend {
        honey.approve(address(rebaseproxy), txAmount);
        GoldilendBase(address(rebaseproxy)).deposit(txAmount);
        GoldilendBase(address(rebaseproxy)).withdraw(txAmount);

        assertEq(honey.balanceOf(address(this)), dealAmt);
        assertEq(glhoney.balanceOf(address(this)), 0);
        assertEq(honey.balanceOf(address(rebaseproxy)), 0);
        assertEq(GoldilendBase(address(rebaseproxy)).poolSize(), 0);
    }

    function testBorrowFailActive() public {
        GoldilendBase(address(rebaseproxy)).changeBorrowingActive(false);
        vm.expectRevert(abi.encodeWithSelector(IGoldilendBase.NotActive.selector));
        RebaseGoldilend(address(rebaseproxy)).borrow(69, 69, address(0x69), 69);
    }

    function testBorrowFailDuration() public {
        vm.expectRevert(abi.encodeWithSelector(IGoldilendBase.InvalidDuration.selector));
        RebaseGoldilend(address(rebaseproxy)).borrow(69, 69, address(0x69), 69);
    }

    function testBorrowFailLoanAmount() public {
        vm.expectRevert(abi.encodeWithSelector(IGoldilendBase.InvalidLoanAmount.selector));
        RebaseGoldilend(address(rebaseproxy)).borrow(69, 2 days, address(0x69), 69);
    }

    function testBorrowFailCollateral() public dealHoneyForGoldilend {
        honey.approve(address(rebaseproxy), txAmount);
        GoldilendBase(address(rebaseproxy)).deposit(txAmount);
        vm.expectRevert(abi.encodeWithSelector(IGoldilendBase.InvalidCollateral.selector));
        RebaseGoldilend(address(rebaseproxy)).borrow(69, 2 days, address(0x69), 69);
    }

    function testRebaseBorrowFailMaxUtilization() public dealHoneyForGoldilend dealUserABunchOfBeras {
        honey.approve(address(rebaseproxy), txAmount);
        GoldilendBase(address(rebaseproxy)).deposit(txAmount);
        RebaseGoldilend(address(rebaseproxy)).borrow(1e18, 2 days, address(bandbear), 1);
        RebaseGoldilend(address(rebaseproxy)).borrow(1e18, 2 days, address(bandbear), 2);
        RebaseGoldilend(address(rebaseproxy)).borrow(1e18, 2 days, address(bandbear), 3);
        RebaseGoldilend(address(rebaseproxy)).borrow(1e18, 2 days, address(bandbear), 4);
        RebaseGoldilend(address(rebaseproxy)).borrow(1e18, 2 days, address(bandbear), 5);
        RebaseGoldilend(address(rebaseproxy)).borrow(1e18, 2 days, address(bandbear), 6);
        RebaseGoldilend(address(rebaseproxy)).borrow(1e18, 2 days, address(bandbear), 7);
        RebaseGoldilend(address(rebaseproxy)).borrow(1e18, 2 days, address(bandbear), 8);
        RebaseGoldilend(address(rebaseproxy)).borrow(1e18, 2 days, address(bandbear), 9);
        vm.expectRevert(abi.encodeWithSelector(IGoldilendBase.MaxUtilizationExceeded.selector));
        RebaseGoldilend(address(rebaseproxy)).borrow(1e18, 2 days, address(bandbear), 10);
    }

    function testBorrowFailBorrowLimit() public dealUserBeras {
        deal(address(honey), address(this), 1_000_000e18);
        honey.approve(address(rebaseproxy), 1_000_000e18);
        GoldilendBase(address(rebaseproxy)).deposit(1_000_000e18);
        vm.expectRevert(abi.encodeWithSelector(IGoldilendBase.BorrowLimitExceeded.selector));
        RebaseGoldilend(address(rebaseproxy)).borrow(49e18, 300 days, address(bandbear), 10);
    }

    function testRebaseBorrowSuccess() public dealHoneyForGoldilend dealUserBeras {
        honey.approve(address(rebaseproxy), txAmount);
        GoldilendBase(address(rebaseproxy)).deposit(txAmount);
        RebaseGoldilend(address(rebaseproxy)).borrow(1e18, goldilendDuration, address(bandbear), 1);
        GoldilendBase.Loan memory userLoan = GoldilendBase(address(rebaseproxy)).getUserLoan(address(this), 1);

        assertEq(GoldilendBase(address(rebaseproxy)).outstandingDebt(), 1e18);
        assertEq(userLoan.collateralNFT, address(bandbear));
        assertEq(userLoan.collateralNFTId, 1);
        assertEq(userLoan.borrowedAmount, 1e18);
        assertEq(userLoan.interest, rebaseInterest);
        assertEq(userLoan.duration, goldilendDuration);
        assertEq(userLoan.endDate, block.timestamp + goldilendDuration);
        assertEq(userLoan.loanId, 1);
        assertEq(userLoan.repaid, false);
        assertEq(userLoan.liquidated, false);
        assertEq(GoldilendBase(address(rebaseproxy)).userLoanAmount(address(this)), 1);
        assertEq(IERC721(address(bandbear)).balanceOf(address(rebaseproxy)), 1);
        assertEq(IERC721(address(bandbear)).balanceOf(address(this)), 0);
        assertEq(honey.balanceOf(address(this)), dealAmt - txAmount + 1e18);
        assertEq(honey.balanceOf(address(rebaseproxy)), txAmount - 1e18);
    }

    function testRenewFailBackwards() public dealHoneyForGoldilend dealUserBeras {
        honey.approve(address(rebaseproxy), txAmount);
        GoldilendBase(address(rebaseproxy)).deposit(txAmount);
        vm.warp(70);
        RebaseGoldilend(address(rebaseproxy)).borrow(1e18, goldilendDuration, address(bandbear), 1);
        vm.expectRevert(abi.encodeWithSelector(RebaseGoldilend.BackwardsExpiry.selector));
        RebaseGoldilend(address(rebaseproxy)).renew(1, 69, 69);
    }

    function testRenewFailActive() public dealHoneyForGoldilend {
        honey.approve(address(rebaseproxy), txAmount);
        GoldilendBase(address(rebaseproxy)).deposit(txAmount);
        GoldilendBase(address(rebaseproxy)).changeBorrowingActive(false);
        vm.expectRevert(abi.encodeWithSelector(IGoldilendBase.NotActive.selector));
        RebaseGoldilend(address(rebaseproxy)).renew(1, 69, 69);
    }

    function testRenewFailDuration() public dealHoneyForGoldilend {
        honey.approve(address(rebaseproxy), txAmount);
        GoldilendBase(address(rebaseproxy)).deposit(txAmount);
        vm.expectRevert(abi.encodeWithSelector(IGoldilendBase.InvalidDuration.selector));
        RebaseGoldilend(address(rebaseproxy)).renew(1, 69, 69);
    }

    function testChangeLendingParamsFailMultisig() public {
        vm.prank(address(0x69));
        vm.expectRevert(abi.encodeWithSelector(IGoldilendBase.NotMultisig.selector));
        GoldilendBase(address(rebaseproxy)).changeLendingParams(69, 69, 69, 69);
    }

    function testChangeLendingParamsSuccess() public {
        GoldilendBase(address(rebaseproxy)).changeLendingParams(69, 69, 69, 69);

        assertEq(GoldilendBase(address(rebaseproxy)).protocolInterestRate(), 69);
        assertEq(GoldilendBase(address(rebaseproxy)).slope(), 69);
        assertEq(GoldilendBase(address(rebaseproxy)).minDuration(), 69);
        assertEq(GoldilendBase(address(rebaseproxy)).maxDuration(), 69);
    }

    function testChangeBorrowingActiveFailMultisig() public {
        vm.prank(address(0x69));
        vm.expectRevert(abi.encodeWithSelector(IGoldilendBase.NotMultisig.selector));
        GoldilendBase(address(rebaseproxy)).changeBorrowingActive(false);
    }

    function testChangeBorrowingActiveSuccess() public {
        GoldilendBase(address(rebaseproxy)).changeBorrowingActive(false);

        assertEq(GoldilendBase(address(rebaseproxy)).borrowingActive(), false);
    }

    function testInitializeParametersFailMultisig() public {
        vm.prank(address(0x69));
        vm.expectRevert(abi.encodeWithSelector(IGoldilendBase.NotMultisig.selector));
        GoldilendBase(address(rebaseproxy)).initializeParameters(69, 69, 69, 69, 69);
    }

    function testInitializeParametersFailAlready() public {
        vm.expectRevert(abi.encodeWithSelector(IGoldilendBase.AlreadyInitialized.selector));
        GoldilendBase(address(rebaseproxy)).initializeParameters(69, 69, 69, 69, 69);
    }

    function testRecoverTokensFailMultisig() public {
        vm.prank(address(0x69));
        vm.expectRevert(abi.encodeWithSelector(IGoldilendBase.NotMultisig.selector));
        GoldilendBase(address(rebaseproxy)).recoverTokens(address(0x69));
    }

    function testRecoverTokensSuccess() public {
        deal(address(honey), address(rebaseproxy), 69);
        GoldilendBase(address(rebaseproxy)).recoverTokens(address(honey));

        assertEq(honey.balanceOf(address(this)), 69);
    }

    function testIncreaseglDebtAssetBackingFailMultisig() public {
        vm.prank(address(0x69));
        vm.expectRevert(abi.encodeWithSelector(IGoldilendBase.NotMultisig.selector));
        GoldilendBase(address(rebaseproxy)).increaseglDebtAssetBacking(69);
    }

    function testIncreaseglDebtAssetBackingSuccess() public {
        deal(address(honey), address(this), 69);
        honey.approve(address(rebaseproxy), 69);
        GoldilendBase(address(rebaseproxy)).increaseglDebtAssetBacking(69);

        assertEq(honey.balanceOf(address(this)), 0);
        assertEq(honey.balanceOf(address(rebaseproxy)), 69);
        assertEq(GoldilendBase(address(rebaseproxy)).poolSize(), 69);
    }

    function testChangeValueFailMultisig() public {
        address[] memory nfts = new address[](2);
        nfts[0] = address(bondbear);
        nfts[1] = address(bandbear);
        uint256[] memory values = new uint256[](2);
        values[0] = 50;
        values[1] = 50;
        vm.prank(address(0x69));
        vm.expectRevert(abi.encodeWithSelector(IGoldilendBase.NotMultisig.selector));
        RebaseGoldilend(address(rebaseproxy)).changeValue(nfts, values);
    }

    function testChangeValueFailArray() public {
        address[] memory nfts = new address[](2);
        nfts[0] = address(bondbear);
        nfts[1] = address(bandbear);
        uint256[] memory values = new uint256[](1);
        values[0] = 50;
        vm.expectRevert(abi.encodeWithSelector(IGoldilendBase.ArrayMismatch.selector));
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

        assertEq(GoldilendBase(address(rebaseproxy)).nftFairValues(address(bondbear)), 50);
        assertEq(GoldilendBase(address(rebaseproxy)).nftFairValues(address(bandbear)), 50);
    }

    function testInitializeBerasFailMultisig() public {
        address[] memory nfts = new address[](2);
        nfts[0] = address(bondbear);
        nfts[1] = address(bandbear);
        uint256[] memory values = new uint256[](2);
        values[0] = 50;
        values[1] = 50;
        vm.prank(address(0x69));
        vm.expectRevert(abi.encodeWithSelector(IGoldilendBase.NotMultisig.selector));
        RebaseGoldilend(address(rebaseproxy)).initializeBeras(nfts, values);
    }

    function testInitializeBerasFailArray() public {
        address[] memory nfts = new address[](2);
        nfts[0] = address(bondbear);
        nfts[1] = address(bandbear);
        uint256[] memory values = new uint256[](1);
        values[0] = 50;
        vm.expectRevert(abi.encodeWithSelector(IGoldilendBase.ArrayMismatch.selector));
        RebaseGoldilend(address(rebaseproxy)).initializeBeras(nfts, values);
    }

    function testInitializeBerasFailAlready() public {
        address[] memory nfts = new address[](2);
        nfts[0] = address(bondbear);
        nfts[1] = address(bandbear);
        uint256[] memory values = new uint256[](2);
        values[0] = 50;
        values[1] = 50;
        vm.expectRevert(abi.encodeWithSelector(IGoldilendBase.AlreadyInitialized.selector));
        RebaseGoldilend(address(rebaseproxy)).initializeBeras(nfts, values);
    }

    function testOnERC721Received() public {
        bandbear.mint(address(rebaseproxy));

        assert(IERC721(bandbear).balanceOf(address(rebaseproxy)) > 0);
    }

    function testUpgradeRebaseGoldilendFailOwner() public {
        vm.prank(address(0x69));
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, address(0x69)));
        GoldilendBase(address(rebaseproxy)).upgradeToAndCall(address(0x69), "");
    }

    function testUpgradeRebaseGoldilendSuccess() public {
        TestUpgradeableRebaseGoldilend newRebaseGoldilend = new TestUpgradeableRebaseGoldilend();
        bytes memory data = abi.encodeWithSelector(TestUpgradeableRebaseGoldilend.setSpecialNumber.selector);
        GoldilendBase(address(rebaseproxy)).upgradeToAndCall(address(newRebaseGoldilend), data);

        assertEq(TestUpgradeableRebaseGoldilend(address(rebaseproxy)).specialNumber(), 69);
        assertEq(TestUpgradeableRebaseGoldilend(address(rebaseproxy)).multisig(), address(this));
    }

    
}