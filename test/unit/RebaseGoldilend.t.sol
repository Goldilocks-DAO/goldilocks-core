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
        assertEq(ghoney.name(), "Goldilend Honey");
    }

    function testGoldilendDebtAssetSymbol() public view {
        assertEq(ghoney.symbol(), "gHONEY");
    }

    function testMintglDebtAssetFailGoldilend() public {
        vm.expectRevert(abi.encodeWithSelector(GoldilendDebtAsset.NotGoldilend.selector));
        ghoney.mintglDebtAsset(address(0x69), 69);
    }

    function testBurnglDebtAssetFailGoldilend() public {
        vm.expectRevert(abi.encodeWithSelector(GoldilendDebtAsset.NotGoldilend.selector));
        ghoney.burnglDebtAsset(address(0x69), 69);
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

    function testDepositFailMinUtilizationExceeded() public {
        deal(address(honey), address(this), 1_000_000e18);
        honey.approve(address(rebaseproxy), 150_000e18);
        RebaseGoldilend(address(rebaseproxy)).deposit(120_000e18);
        vm.expectRevert(abi.encodeWithSelector(IRebaseGoldilend.MinUtilizationExceeded.selector));
        RebaseGoldilend(address(rebaseproxy)).deposit(1_000e18);
    }

    function testDepositSuccess() public dealHoneyForGoldilend {
        honey.approve(address(rebaseproxy), txAmount);
        RebaseGoldilend(address(rebaseproxy)).deposit(txAmount);

        assertEq(honey.balanceOf(address(this)), dealAmt - txAmount);
        assertEq(ghoney.balanceOf(address(this)), txAmount);
        assertEq(honey.balanceOf(address(rebaseproxy)), txAmount);
        assertEq(ghoney.totalSupply(), txAmount);
    }

    function testWithdrawSuccess() public dealHoneyForGoldilend {
        honey.approve(address(rebaseproxy), txAmount);
        RebaseGoldilend(address(rebaseproxy)).deposit(txAmount);
        RebaseGoldilend(address(rebaseproxy)).withdraw(txAmount);

        assertEq(honey.balanceOf(address(this)), dealAmt);
        assertEq(ghoney.balanceOf(address(this)), 0);
        assertEq(honey.balanceOf(address(rebaseproxy)), 0);
        assertEq(ghoney.totalSupply(), 0);
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
        RebaseGoldilend(address(rebaseproxy)).borrow(69, 0, 2 days, address(bandbear), 69);
    }

    function testBorrowFailCollateral() public dealHoneyForGoldilend {
        honey.approve(address(rebaseproxy), txAmount);
        RebaseGoldilend(address(rebaseproxy)).deposit(txAmount);
        vm.expectRevert(abi.encodeWithSelector(IRebaseGoldilend.InvalidCollateral.selector));
        RebaseGoldilend(address(rebaseproxy)).borrow(69, 0, 2 days, address(0x69), 69);
    }

    function testRenewFailActive() public dealHoneyForGoldilend {
        honey.approve(address(rebaseproxy), txAmount);
        RebaseGoldilend(address(rebaseproxy)).deposit(txAmount);
        RebaseGoldilend(address(rebaseproxy)).changeBorrowingActive(false);
        vm.expectRevert(abi.encodeWithSelector(IRebaseGoldilend.NotActive.selector));
        RebaseGoldilend(address(rebaseproxy)).renew(1, 69, 69, 0);
    }

    function testRenewFailDuration() public dealHoneyForGoldilend {
        honey.approve(address(rebaseproxy), txAmount);
        RebaseGoldilend(address(rebaseproxy)).deposit(txAmount);
        vm.expectRevert(abi.encodeWithSelector(IRebaseGoldilend.InvalidDuration.selector));
        RebaseGoldilend(address(rebaseproxy)).renew(1, 69, 69, 0);
    }

    function testChangeLendingParamsFailMultisig() public {
        vm.prank(address(0x69));
        vm.expectRevert(abi.encodeWithSelector(IRebaseGoldilend.NotMultisig.selector));
        RebaseGoldilend(address(rebaseproxy)).changeLendingParams(69, 69, address(0x69), 0x962088abcfdbdb6e30db2e340c8cf887d9efb311b1f2f17b155a63dbb6d40265, 69, 69, 69, 69);
    }

    function testChangeLendingParamsSuccess() public {
        RebaseGoldilend(address(rebaseproxy)).changeLendingParams(69, 69, address(0x69), 0x962088abcfdbdb6e30db2e340c8cf887d9efb311b1f2f17b155a63dbb6d40265, 69, 69, 69, 69);

        assertEq(RebaseGoldilend(address(rebaseproxy)).protocolInterestRate(), 69);
        assertEq(RebaseGoldilend(address(rebaseproxy)).slope(), 69);
    }

    function testChangeGovParamsFailTimelock() public {
        vm.prank(address(0x69));
        vm.expectRevert(abi.encodeWithSelector(IRebaseGoldilend.NotTimelock.selector));
        RebaseGoldilend(address(rebaseproxy)).changeGovParams(69, 69, 69, 69, 69);
    }

    function testChangeGovParamsSuccess() public {
        bytes memory _calldata = abi.encodeWithSignature("changeGovParams(uint256,uint256,uint256,uint256,uint256)", 69, 69, 69, 69, 69);
        address[] memory targets = new address[](1);
        targets[0] = address(rebaseproxy);
        string[] memory signatures = new string[](1);
        signatures[0] = "";
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = _calldata;
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        deal(address(goldiswap), address(this), quorumVotesNum);
        goldiswap.approve(address(govlocks), quorumVotesNum);
        govlocks.deposit(quorumVotesNum);
        govlocks.delegate(address(this));
        vm.roll(2);
        goldigov.propose(targets, values, signatures, calldatas, "");
        vm.roll(52600);
        goldigov.castVote(1, 1);
        vm.roll(200000);
        goldigov.queue(1);
        vm.warp(6 days);
        goldigov.execute(1);
        (, , , , , , , , , bool executed) = goldigov.proposals(1);

        assertEq(executed, true);
        assertEq(RebaseGoldilend(address(rebaseproxy)).minDuration(), 69);
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

    function testChangeUnvestedWeightsFailMultisig() public {
        address[] memory nfts = new address[](2);
        nfts[0] = address(bondbear);
        nfts[1] = address(bandbear);
        uint256[] memory values = new uint256[](2);
        values[0] = 50;
        values[1] = 50;
        address[] memory streams = new address[](2);
        streams[0] = address(0x69);
        streams[1] = address(0x69);
        vm.prank(address(0x69));
        vm.expectRevert(abi.encodeWithSelector(IRebaseGoldilend.NotMultisig.selector));
        RebaseGoldilend(address(rebaseproxy)).changeUnvestedWeights(nfts, values, streams);
    }

    function testChangeUnvestedWeightsFailArray() public {
        address[] memory nfts = new address[](2);
        nfts[0] = address(bondbear);
        nfts[1] = address(bandbear);
        uint256[] memory values = new uint256[](1);
        values[0] = 50;
        address[] memory streams = new address[](2);
        streams[0] = address(0x69);
        streams[1] = address(0x69);
        vm.expectRevert(abi.encodeWithSelector(IRebaseGoldilend.ArrayMismatch.selector));
        RebaseGoldilend(address(rebaseproxy)).changeUnvestedWeights(nfts, values, streams);
    }

    function testChangeUnvestedWeightsFailStreamsArray() public {
        address[] memory nfts = new address[](2);
        nfts[0] = address(bondbear);
        nfts[1] = address(bandbear);
        uint256[] memory values = new uint256[](2);
        values[0] = 50;
        values[1] = 50;
        address[] memory streams = new address[](1);
        streams[0] = address(0x69);
        vm.expectRevert(abi.encodeWithSelector(IRebaseGoldilend.ArrayMismatch.selector));
        RebaseGoldilend(address(rebaseproxy)).changeUnvestedWeights(nfts, values, streams);
    }

    function testChangeUnvestedWeightsSuccess() public {
        address[] memory nfts = new address[](2);
        nfts[0] = address(bondbear);
        nfts[1] = address(bandbear);
        uint256[] memory values = new uint256[](2);
        values[0] = 50;
        values[1] = 50;
        address[] memory streams = new address[](2);
        streams[0] = address(0x69);
        streams[1] = address(0x69);
        RebaseGoldilend(address(rebaseproxy)).changeUnvestedWeights(nfts, values, streams);    

        assertEq(RebaseGoldilend(address(rebaseproxy)).unvestedWeights(address(bondbear)), 50);
        assertEq(RebaseGoldilend(address(rebaseproxy)).unvestedWeights(address(bandbear)), 50);
    }

    function testInitializeGovParamsFailMultisig() public {
        vm.prank(address(0x69));
        vm.expectRevert(abi.encodeWithSelector(IRebaseGoldilend.NotMultisig.selector));
        RebaseGoldilend(address(rebaseproxy)).initializeGovParams(69, 69, 69, 69, 69);
    }

    function testInitializeBerasFailMultisig() public {
        address[] memory nfts = new address[](2);
        nfts[0] = address(bondbear);
        nfts[1] = address(bandbear);
        uint256[] memory values = new uint256[](2);
        values[0] = 50;
        values[1] = 50;
        address[] memory streams = new address[](2);
        streams[0] = address(0x69);
        streams[1] = address(0x69);
        vm.prank(address(0x69));
        vm.expectRevert(abi.encodeWithSelector(IRebaseGoldilend.NotMultisig.selector));
        RebaseGoldilend(address(rebaseproxy)).initializeBeras(nfts, values, streams);
    }

    function testInitializeBerasFailAlready() public {
        address[] memory nfts = new address[](2);
        nfts[0] = address(bondbear);
        nfts[1] = address(bandbear);
        uint256[] memory values = new uint256[](2);
        values[0] = 50;
        values[1] = 50;
        address[] memory streams = new address[](2);
        streams[0] = address(0x69);
        streams[1] = address(0x69);
        vm.expectRevert(abi.encodeWithSelector(IRebaseGoldilend.AlreadyInitialized.selector));
        RebaseGoldilend(address(rebaseproxy)).initializeBeras(nfts, values, streams);
    }

    function testWithdrawSurplusFailMultisig() public {
        vm.prank(address(0xabc));
        vm.expectRevert(abi.encodeWithSelector(IRebaseGoldilend.NotMultisig.selector));
        RebaseGoldilend(address(rebaseproxy)).withdrawSurplus();
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