//SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "../../lib/forge-std/src/Test.sol";
import { console } from "../../lib/forge-std/src/console.sol";
import { LibRLP } from "../../lib/solady/src/utils/LibRLP.sol";
import { IERC721 } from "../../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import { ERC20 } from "../../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import { ERC1967Proxy } from "../../lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { RebaseGoldilend } from "../../src/core/goldilend/RebaseGoldilend.sol";
import { IRebaseGoldilend } from "../../src/interfaces/IRebaseGoldilend.sol";
import { GoldilendDebtAsset } from "../../src/core/goldilend/GoldilendDebtAsset.sol";

contract IntegrationRebaseGoldilendTest is Test {

    using LibRLP for address;

    RebaseGoldilend rebasegoldilend;
    ERC1967Proxy rebaseproxy;
    GoldilendDebtAsset ghoney;
    ERC20 honey;

    address rawdog = 0x8FE7E03B5b2E49E3386BE79f0834B4B6D08E095c;
    address honeyaddy = 0xFCBD14DC51f0A4d49d5E53C2E0950e0bC26d0Dce;
    address anon = 0x7BFEe91193d9Df2Ac0bFe90191D40F23c773C060; // bonds: 54, 68, 87, 103

    address bitbears = 0x72D876D9cdf4001b836f8E47254d0551EdA2eebB;
    address bandbears = 0x7711B2Eb2451259dbF211e30157ceB7CFeb79a19;
    address babybears = 0xDDeAf391c4be2d01ca52aBb8C159a06820ef078C;
    address boobears = 0xf49ec5db255854C4a567de5AB3826c9AAbaFc7cF;
    address bondbears = 0xA0CF472E6132F6B822a944f6F31aA7b261c7c375;
    address bongbears = 0x141De07E5D4C4759EC9301DA106115D4841f66cD;

    address bitStreaming = 0x979EFC29797884c3342143eA7b91E55342F2f408;
    address bandStreaming = 0xaf30baa667Ce52c1fE5702A0F8CE9A31f0d751B6;
    address babyStreaming = 0x14E5930aD47Bfc9E7977547e263D5C3A090b777f;
    address booStreaming = 0x1229414CFEE4dEC0B488377B62e96B4094B6258C;
    address bondStreaming = 0xa63b5bc4Bab6593ACc78ef103fcb44A191BAe836;
    address bongStreaming = 0x1E54B85B3632F75E96Cc8d4FcB11BA7f0Ca69213;

    uint256 dealAmt = type(uint256).max / 2;
    uint256 txAmount = 10e18;
    uint256 goldilendDuration = 1209600;
    uint256 borrowInterest = 4572685306811784;
    uint256 singleBorrowInterestBoosted = 4545249194970913;
    uint256 singleBorrowInterestMaxBoost = 4339478356164383;
    uint256 interestCalculation1 = 8849690373428410538;
    uint256 rebaseIInterest = 6607768812159879;
    uint256 renewBorrowInterest = 7994895852880465;
    uint256 renewInterest = 8024319759804841;

    modifier prankAnon() {
        deal(address(honey), anon, dealAmt);
        vm.startPrank(anon);
        IERC721(bondbears).setApprovalForAll(address(rebaseproxy), true);
        _;
        vm.stopPrank();
    }

    function setUp() public {
        honey = ERC20(honeyaddy);
        GoldilendDebtAsset ghoneyComputed = GoldilendDebtAsset(rawdog.computeAddress(98));
        uint256 berachainFork = vm.createFork("https://rpc.berachain.com");
        vm.selectFork(berachainFork);
        vm.startPrank(rawdog);

        // deploy rebasegoldilend
        rebasegoldilend = new RebaseGoldilend();

        // initialization of rebasegoldilend
        bytes memory rebasedata = abi.encodeWithSelector(
            RebaseGoldilend.initialize.selector,
            rawdog,
            rawdog,
            address(honey),
            address(ghoneyComputed)
        );
        rebaseproxy = new ERC1967Proxy(address(rebasegoldilend), rebasedata);
        ghoney = new GoldilendDebtAsset("Goldilend Honey", "gHONEY", address(rebaseproxy));
        assert(RebaseGoldilend(address(rebaseproxy)).glDebtAsset() == address(ghoney));
        RebaseGoldilend(address(rebaseproxy)).changeLendingParams(
            2e17,
            2e18,
            0x2880aB155794e7179c9eE2e38200202908C17B43,
            0x962088abcfdbdb6e30db2e340c8cf887d9efb311b1f2f17b155a63dbb6d40265,
            75e16,
            2,
            5e17,
            100_000e18
        );
        RebaseGoldilend(address(rebaseproxy)).initializeGovParams(
            1 days,
            365 days,
            7 days,
            30 days,
            90
        );
        address[] memory rebasenfts = new address[](6);
        rebasenfts[0] = address(bitbears);
        rebasenfts[1] = address(bandbears);
        rebasenfts[2] = address(babybears);
        rebasenfts[3] = address(boobears);
        rebasenfts[4] = address(bondbears);
        rebasenfts[5] = address(bongbears);
        uint256[] memory rebasevalues = new uint256[](6);
        rebasevalues[0] = 30;
        rebasevalues[1] = 20;
        rebasevalues[2] = 20;
        rebasevalues[3] = 20;
        rebasevalues[4] = 20;
        rebasevalues[5] = 20;
        address[] memory rebasestreams = new address[](6);
        rebasestreams[0] = bitStreaming;
        rebasestreams[1] = bandStreaming;
        rebasestreams[2] = babyStreaming;
        rebasestreams[3] = booStreaming;
        rebasestreams[4] = bondStreaming;
        rebasestreams[5] = bongStreaming;
        RebaseGoldilend(address(rebaseproxy)).initializeBeras(rebasenfts, rebasevalues, rebasestreams);
        vm.stopPrank();
    }

    function testIGetUserLoanSuccess() public prankAnon {
        honey.approve(address(rebaseproxy), txAmount);
        RebaseGoldilend(address(rebaseproxy)).deposit(txAmount);
        IERC721(bondbears).setApprovalForAll(address(rebaseproxy), true);
        RebaseGoldilend(address(rebaseproxy)).borrow(1e18, 1_000e18, goldilendDuration, bondbears, 103);
        RebaseGoldilend.Loan memory userLoan = RebaseGoldilend(address(rebaseproxy)).getUserLoan(anon, 1);

        assertEq(userLoan.collateralNFT, bondbears);
        assertEq(userLoan.collateralNFTId, 103);
        assertEq(userLoan.borrowedAmount, 1e18);
        assertEq(userLoan.interest, rebaseIInterest);
        assertEq(userLoan.duration, goldilendDuration);
        assertEq(userLoan.endDate, block.timestamp + goldilendDuration);
        assertEq(userLoan.loanId, 1);
        assertEq(userLoan.repaid, false);
        assertEq(userLoan.liquidated, false);
    }

    function testICalculateInterestFailBorrowLimit() public prankAnon {
        honey.approve(address(rebaseproxy), 5_000_000e18);
        RebaseGoldilend(address(rebaseproxy)).deposit(5_000_000e18);
        vm.expectRevert(abi.encodeWithSelector(IRebaseGoldilend.BorrowLimitExceeded.selector));
        RebaseGoldilend(address(rebaseproxy)).calculateInterest(5000e18, 360 days, bondbears);
    }

    function testICalculateInterestSuccess() public prankAnon {
        honey.approve(address(rebaseproxy), txAmount);
        RebaseGoldilend(address(rebaseproxy)).deposit(txAmount);
        uint256 interest = RebaseGoldilend(address(rebaseproxy)).calculateInterest(1e18, goldilendDuration, bondbears);

        assertEq(interest, rebaseIInterest);
    }

    function testBorrowFailBorrowLimit() public prankAnon {
        honey.approve(address(rebaseproxy), 5_000_000e18);
        RebaseGoldilend(address(rebaseproxy)).deposit(5_000_000e18);
        vm.expectRevert(abi.encodeWithSelector(IRebaseGoldilend.BorrowLimitExceeded.selector));
        RebaseGoldilend(address(rebaseproxy)).borrow(5000e18, 1_000e18, 360 days, bondbears, 103);
    }

    function testBorrowFailMoreThanMaxInterest() public prankAnon {
        honey.approve(address(rebaseproxy), txAmount);
        RebaseGoldilend(address(rebaseproxy)).deposit(txAmount);
        vm.expectRevert(abi.encodeWithSelector(IRebaseGoldilend.MoreThanMaxInterest.selector));
        RebaseGoldilend(address(rebaseproxy)).borrow(1e18, 0, goldilendDuration, bondbears, 103);
    }

    function testRebaseBorrowSuccess() public prankAnon {
        honey.approve(address(rebaseproxy), txAmount);
        RebaseGoldilend(address(rebaseproxy)).deposit(txAmount);
        RebaseGoldilend(address(rebaseproxy)).borrow(1e18, 1_000e18, goldilendDuration, bondbears, 103);
        RebaseGoldilend.Loan memory userLoan = RebaseGoldilend(address(rebaseproxy)).getUserLoan(anon, 1);

        assertEq(RebaseGoldilend(address(rebaseproxy)).outstandingDebt(), 1e18);
        assertEq(userLoan.collateralNFT, bondbears);
        assertEq(userLoan.collateralNFTId, 103);
        assertEq(userLoan.borrowedAmount, 1e18);
        assertEq(userLoan.interest, rebaseIInterest);
        assertEq(userLoan.duration, goldilendDuration);
        assertEq(userLoan.endDate, block.timestamp + goldilendDuration);
        assertEq(userLoan.loanId, 1);
        assertEq(userLoan.repaid, false);
        assertEq(userLoan.liquidated, false);
        assertEq(RebaseGoldilend(address(rebaseproxy)).userLoanAmount(anon), 1);
        assertEq(IERC721(bondbears).balanceOf(address(rebaseproxy)), 1);
        assertEq(IERC721(bondbears).balanceOf(anon), 8);
        assertEq(honey.balanceOf(anon), dealAmt - txAmount + 1e18 - rebaseIInterest);
        assertEq(honey.balanceOf(address(rebaseproxy)), txAmount - 1e18);
    }

    function testPlaceBidFailUnliquidatable() public prankAnon {
        honey.approve(address(rebaseproxy), txAmount);
        RebaseGoldilend(address(rebaseproxy)).deposit(txAmount);
        RebaseGoldilend(address(rebaseproxy)).borrow(1e18, 1_000e18, goldilendDuration, bondbears, 103);
        honey.approve(address(rebaseproxy), 1e18);
        RebaseGoldilend(address(rebaseproxy)).repay(1e18, 1);
        vm.expectRevert(abi.encodeWithSelector(IRebaseGoldilend.Unliquidatable.selector));
        RebaseGoldilend(address(rebaseproxy)).placeBid(anon, 1, 69);
    }

    function testPlaceBidFailUnliquidatableTimestamp() public prankAnon {
        honey.approve(address(rebaseproxy), txAmount);
        RebaseGoldilend(address(rebaseproxy)).deposit(txAmount);
        RebaseGoldilend(address(rebaseproxy)).borrow(1e18, 1_000e18, goldilendDuration, bondbears, 103);
        vm.warp(block.timestamp + 15 days);
        vm.expectRevert(abi.encodeWithSelector(IRebaseGoldilend.Unliquidatable.selector));
        RebaseGoldilend(address(rebaseproxy)).placeBid(anon, 1, 69);
    }

    function testPlaceBidFailAuctionEnded() public prankAnon {
        honey.approve(address(rebaseproxy), txAmount);
        RebaseGoldilend(address(rebaseproxy)).deposit(txAmount);
        RebaseGoldilend(address(rebaseproxy)).borrow(1e18, 1_000e18, goldilendDuration, bondbears, 103);
        vm.warp(block.timestamp + 20 days);
        vm.expectRevert(abi.encodeWithSelector(IRebaseGoldilend.AuctionEnded.selector));
        RebaseGoldilend(address(rebaseproxy)).placeBid(anon, 1, 69);
    }

    function testPlaceBidFailInsufficient() public prankAnon {
        honey.approve(address(rebaseproxy), txAmount);
        RebaseGoldilend(address(rebaseproxy)).deposit(txAmount);
        RebaseGoldilend(address(rebaseproxy)).borrow(1e18, 1_000e18, goldilendDuration, bondbears, 103);
        vm.warp(block.timestamp + 16 days);
        vm.expectRevert(abi.encodeWithSelector(IRebaseGoldilend.InsufficientBid.selector));
        RebaseGoldilend(address(rebaseproxy)).placeBid(anon, 1, 5e17);
    }

    function testPlaceBidFailNotHighestBid() public prankAnon {
        honey.approve(address(rebaseproxy), txAmount);
        RebaseGoldilend(address(rebaseproxy)).deposit(txAmount);
        RebaseGoldilend(address(rebaseproxy)).borrow(1e18, 1_000e18, goldilendDuration, bondbears, 103);
        vm.warp(block.timestamp + 16 days);

        deal(address(honey), address(0xaabbcc), 10e18);
        vm.startPrank(address(0xaabbcc));
        honey.approve(address(rebaseproxy), 10e18);
        RebaseGoldilend(address(rebaseproxy)).placeBid(anon, 1, 10e18);
        vm.stopPrank();

        deal(address(honey), address(0xbbcc), 9e18);
        vm.prank(address(0xbbcc));
        honey.approve(address(rebaseproxy), 9e18);
        vm.prank(address(0xbbcc));
        vm.expectRevert(abi.encodeWithSelector(IRebaseGoldilend.NotHighestBid.selector));
        RebaseGoldilend(address(rebaseproxy)).placeBid(anon, 1, 9e18);
    }

    function testPlaceBidSuccess() public prankAnon {
        honey.approve(address(rebaseproxy), txAmount);
        RebaseGoldilend(address(rebaseproxy)).deposit(txAmount);
        RebaseGoldilend(address(rebaseproxy)).borrow(1e18, 1_000e18, goldilendDuration, bondbears, 103);
        vm.warp(block.timestamp + 16 days);
        deal(address(honey), address(0xaabbcc), 10e18);
        vm.startPrank(address(0xaabbcc));
        honey.approve(address(rebaseproxy), 10e18);
        RebaseGoldilend(address(rebaseproxy)).placeBid(anon, 1, 10e18);
        vm.stopPrank();
    }

    function testCloseAuctionFailUnliquidatable() public prankAnon {
        honey.approve(address(rebaseproxy), txAmount);
        RebaseGoldilend(address(rebaseproxy)).deposit(txAmount);
        RebaseGoldilend(address(rebaseproxy)).borrow(1e18, 1_000e18, goldilendDuration, bondbears, 103);
        honey.approve(address(rebaseproxy), 1e18);
        RebaseGoldilend(address(rebaseproxy)).repay(1e18, 1);
        vm.expectRevert(abi.encodeWithSelector(IRebaseGoldilend.Unliquidatable.selector));
        RebaseGoldilend(address(rebaseproxy)).closeAuction(anon, 1);
    }

    function testCloseAuctionFailNotEnded() public prankAnon {
        honey.approve(address(rebaseproxy), txAmount);
        RebaseGoldilend(address(rebaseproxy)).deposit(txAmount);
        RebaseGoldilend(address(rebaseproxy)).borrow(1e18, 1_000e18, goldilendDuration, bondbears, 103);
        vm.warp(15 days);
        vm.expectRevert(abi.encodeWithSelector(IRebaseGoldilend.AuctionNotEnded.selector));
        RebaseGoldilend(address(rebaseproxy)).closeAuction(anon, 1);
    }

    function testCloseAuctionSuccess() public prankAnon {
        honey.approve(address(rebaseproxy), txAmount);
        RebaseGoldilend(address(rebaseproxy)).deposit(txAmount);
        RebaseGoldilend(address(rebaseproxy)).borrow(1e18, 1_000e18, goldilendDuration, bondbears, 103);
        vm.warp(block.timestamp + 16 days);
        
        deal(address(honey), address(0xabc), 2e18);
        vm.startPrank(address(0xabc));
        honey.approve(address(rebaseproxy), 2e18);
        RebaseGoldilend(address(rebaseproxy)).placeBid(anon, 1, 2e18);
        vm.stopPrank();

        deal(address(honey), address(0xaabbcc), 15e18);
        vm.startPrank(address(0xaabbcc));
        honey.approve(address(rebaseproxy), 10e18);
        RebaseGoldilend(address(rebaseproxy)).placeBid(anon, 1, 10e18);
        vm.stopPrank();

        deal(address(honey), address(0xaaabbbccc), 105e18);
        vm.startPrank(address(0xaaabbbccc));
        honey.approve(address(rebaseproxy), 100e18);
        RebaseGoldilend(address(rebaseproxy)).placeBid(anon, 1, 100e18);
        vm.stopPrank();

        deal(address(honey), address(0xaaaabbbbcccc), 1000e18);
        vm.startPrank(address(0xaaaabbbbcccc));
        honey.approve(address(rebaseproxy), 1000e18);
        RebaseGoldilend(address(rebaseproxy)).placeBid(anon, 1, 1000e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 17 days + 2);
        RebaseGoldilend(address(rebaseproxy)).closeAuction(anon, 1);

        assertEq(honey.balanceOf(address(0xabc)), 2e18);
        assertEq(honey.balanceOf(address(0xaabbcc)), 15e18);
        assertEq(honey.balanceOf(address(0xaaabbbccc)), 105e18);
        assertEq(honey.balanceOf(address(0xaaaabbbbcccc)), 0);
        assertEq(IERC721(bondbears).balanceOf(address(0xaaaabbbbcccc)), 1);
        assertEq(IERC721(bondbears).balanceOf(address(rebaseproxy)), 0);
    }

    function testCloseAuctionNoBids() public prankAnon {
        honey.approve(address(rebaseproxy), txAmount);
        RebaseGoldilend(address(rebaseproxy)).deposit(txAmount);
        RebaseGoldilend(address(rebaseproxy)).borrow(1e18, 1_000e18, goldilendDuration, bondbears, 103);
        vm.warp(block.timestamp + 17 days + 2);
        RebaseGoldilend(address(rebaseproxy)).closeAuction(anon, 1);

        assertEq(IERC721(bondbears).balanceOf(anon), 8);
        assertEq(IERC721(bondbears).balanceOf(address(rebaseproxy)), 0);
    }

    function testRepayFailInvalid() public prankAnon {
        honey.approve(address(rebaseproxy), txAmount);
        RebaseGoldilend(address(rebaseproxy)).deposit(txAmount);
        RebaseGoldilend(address(rebaseproxy)).borrow(1e18, 1_000e18, goldilendDuration, bondbears, 103);
        honey.approve(address(rebaseproxy), 1e18);
        RebaseGoldilend(address(rebaseproxy)).repay(1e18, 1);
        vm.expectRevert(abi.encodeWithSelector(IRebaseGoldilend.InvalidRepay.selector));
        RebaseGoldilend(address(rebaseproxy)).repay(1e18, 1);
    }

    function testRepayFailLoanExpired() public prankAnon {
        honey.approve(address(rebaseproxy), txAmount);
        RebaseGoldilend(address(rebaseproxy)).deposit(txAmount);
        RebaseGoldilend(address(rebaseproxy)).borrow(1e18, 1_000e18, goldilendDuration, bondbears, 103);
        vm.warp(block.timestamp + 69 days);
        vm.expectRevert(abi.encodeWithSelector(IRebaseGoldilend.LoanExpired.selector));
        RebaseGoldilend(address(rebaseproxy)).repay(69, 1);
    }

    function testRepayFailOverPayment() public prankAnon {
        honey.approve(address(rebaseproxy), txAmount);
        RebaseGoldilend(address(rebaseproxy)).deposit(txAmount);
        RebaseGoldilend(address(rebaseproxy)).borrow(1e18, 1_000e18, goldilendDuration, bondbears, 103);
        honey.approve(address(rebaseproxy), 1e18);
        vm.expectRevert(abi.encodeWithSelector(IRebaseGoldilend.OverPayment.selector));
        RebaseGoldilend(address(rebaseproxy)).repay(2e18, 1);
    }

    function testRepaySuccess() public prankAnon {
        honey.approve(address(rebaseproxy), txAmount);
        RebaseGoldilend(address(rebaseproxy)).deposit(txAmount);
        RebaseGoldilend(address(rebaseproxy)).borrow(1e18, 1_000e18, goldilendDuration, bondbears, 103);
        honey.approve(address(rebaseproxy), 1e18);
        RebaseGoldilend(address(rebaseproxy)).repay(1e18, 1);
        RebaseGoldilend.Loan memory userLoan = RebaseGoldilend(address(rebaseproxy)).getUserLoan(anon, 1);

        assertEq(RebaseGoldilend(address(rebaseproxy)).outstandingDebt(), 0);
        assertEq(honey.balanceOf(anon), dealAmt - txAmount - userLoan.interest);
        assertEq(honey.balanceOf(address(rebaseproxy)), txAmount);
        assertEq(userLoan.repaid, true);
        assertEq(userLoan.borrowedAmount, 0);
        assertEq(IERC721(bondbears).balanceOf(address(rebaseproxy)), 0);
        assertEq(IERC721(bondbears).balanceOf(anon), 9);
    }

}