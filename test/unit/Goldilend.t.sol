//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { BaseTest } from "../BaseTest.t.sol";
import { IERC721 } from "../../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import { INFT } from "../../src/mock/INFT.sol";
import { Goldilend } from "../../src/core/Goldilend.sol";

contract UnitGoldilendTest is BaseTest {

  function testGiBGTName() public {
    assertEq(goldilend.name(), "GiBGT Token");
  }

  function testGiBGTSymbol() public {
    assertEq(goldilend.symbol(), "GiBGT");
  }

  function testLookupLoans() public dealUserBeras {
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 1);
    goldilend.borrow(1e18, goldilendDuration, address(bandbear), 1);
    Goldilend.Loan[] memory userLoans = goldilend.lookupLoans(address(this));

    assertEq(userLoans[0].duration, goldilendDuration);
    assertEq(userLoans[0].collateralNFTs[0], address(bondbear));
    assertEq(userLoans[0].borrowedAmount, 1e18 + singleBorrowInterest);
    assertEq(userLoans[1].duration, goldilendDuration);
    assertEq(userLoans[1].collateralNFTs[0], address(bandbear));
  }

  function testLookupLoanFailNotFound() public {
    vm.expectRevert(abi.encodeWithSelector(Goldilend.LoanNotFound.selector));
    goldilend.lookupLoan(address(this), 2);
  }

  function testLookupLoan() public dealUserBeras {
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 1);
    Goldilend.Loan memory userLoan = goldilend.lookupLoan(address(this), 1);

    assertEq(userLoan.collateralNFTs[0], address(bondbear));
    assertEq(userLoan.collateralNFTIds[0], 1);
    assertEq(userLoan.borrowedAmount, 1e18 + singleBorrowInterest);
  }

  function testLookupBoost() public dealUserPartnerNFTs {
    (address[] memory nfts, uint256[] memory ids) = boosty();
    goldilend.boost(nfts, ids);
    Goldilend.Boost memory userBoost = goldilend.lookupBoost(address(this));

    assertEq(IERC721(honeycomb).balanceOf(address(this)), 0);
    assertEq(IERC721(beradrome).balanceOf(address(this)), 0);
    assertEq(IERC721(honeycomb).balanceOf(address(goldilend)), 1);
    assertEq(IERC721(beradrome).balanceOf(address(goldilend)), 1);
    assertEq(userBoost.expiry, 30 days + 1);
    assertEq(userBoost.boostMagnitude, 15);
  }

  function testUserClaimablePrg() public {
    deal(address(goldilend), address(this), locksAmount);
    goldilend.approve(address(goldilend), locksAmount);
    goldilend.stake(locksAmount);
    vm.warp(1 days + 1);

    assertEq(goldilend.userClaimablePrg(address(this)), oneDayPrg);
  }

  function testGetGiBGTRatio() public {
    deal(address(ibgt), address(this), 11157e16);
    ibgt.approve(address(goldilend), type(uint256).max);
    goldilend.lock(100e18);
    vm.store(address(goldilend), bytes32(uint256(0x05345cdf77eb68f44c)), bytes32(uint256(100e18)));
    vm.store(address(goldilend), bytes32(uint256(12)), bytes32(uint256(1000e18)));

    assertEq(goldilend.getGiBGTRatio(), 10e16);
  }

  function testGetFairValues() public {
    address[] memory nfts = new address[](2);
    nfts[0] = address(bondbear);
    nfts[1] = address(bandbear);

    assertEq(goldilend.getFairValues(nfts), 100e18);
  }

  function testSingleBoostFailPartner() public {
    vm.expectRevert(abi.encodeWithSelector(Goldilend.InvalidBoostNFT.selector));
    goldilend.boost(address(0x69), 69);
  }

  function testSingleBoostSuccess() public dealUserPartnerNFTs {
    goldilend.boost(address(honeycomb), 1);
    Goldilend.Boost memory userBoost = goldilend.lookupBoost(address(this));

    assertEq(IERC721(honeycomb).balanceOf(address(this)), 0);
    assertEq(IERC721(honeycomb).balanceOf(address(goldilend)), 1);
    assertEq(userBoost.expiry, 30 days + 1);
    assertEq(userBoost.boostMagnitude, 6);
  }

  function testMultipleBoostFailPartner() public {
    (address[] memory nfts, uint256[] memory ids) = boosty();
    nfts[0] = address(0x696969);
    vm.expectRevert(abi.encodeWithSelector(Goldilend.InvalidBoostNFT.selector));
    goldilend.boost(nfts, ids);
  }

  function testMultipleBoostFailArray() public {
    (address[] memory nfts, ) = boosty();
    uint256[] memory ids = new uint256[](3);
    ids[0] = 6;
    ids[1] = 9;
    ids[2] = 50;
    vm.expectRevert(abi.encodeWithSelector(Goldilend.ArrayMismatch.selector));
    goldilend.boost(nfts, ids);
  }

  function testMultipleBoostSuccess() public dealUserPartnerNFTs {
    (address[] memory nfts, uint256[] memory ids) = boosty();
    goldilend.boost(nfts, ids);
    Goldilend.Boost memory userBoost = goldilend.lookupBoost(address(this));

    assertEq(IERC721(honeycomb).balanceOf(address(this)), 0);
    assertEq(IERC721(beradrome).balanceOf(address(this)), 0);
    assertEq(IERC721(honeycomb).balanceOf(address(goldilend)), 1);
    assertEq(IERC721(beradrome).balanceOf(address(goldilend)), 1);
    assertEq(userBoost.expiry, 30 days + 1);
    assertEq(userBoost.boostMagnitude, 15);
  }

  function testWithdrawBoostFailInvalid() public dealUserPartnerNFTs {
    vm.expectRevert(abi.encodeWithSelector(Goldilend.InvalidBoost.selector));
    goldilend.withdrawBoost();
  }

  function testWithdrawBoostFailExpired() public dealUserPartnerNFTs {
    (address[] memory nfts, uint256[] memory ids) = boosty();
    goldilend.boost(nfts, ids);
    vm.expectRevert(abi.encodeWithSelector(Goldilend.BoostNotExpired.selector));
    goldilend.withdrawBoost();
  }

  function testWithdrawBoostSuccess() public dealUserPartnerNFTs {
    (address[] memory nfts, uint256[] memory ids) = boosty();
    goldilend.boost(nfts, ids);
    vm.warp(69e18);
    goldilend.withdrawBoost();
  }

    function testBoostBoostWaitWithdrawBoost() public dealUserPartnerNFTs {
    INFT(address(honeycomb)).mint(address(this));
    INFT(address(beradrome)).mint(address(this));
    (address[] memory nfts, uint256[] memory ids) = boosty();
    goldilend.boost(nfts, ids);
    uint256[] memory ids2 = new uint256[](2);
    ids2[0] = 2;
    ids2[1] = 2;
    goldilend.boost(nfts, ids2);
    vm.warp(30 days + 2);
    goldilend.withdrawBoost();
    Goldilend.Boost memory userBoost = goldilend.lookupBoost(address(this));

    assertEq(IERC721(honeycomb).balanceOf(address(this)), 2);
    assertEq(IERC721(beradrome).balanceOf(address(this)), 2);
    assertEq(IERC721(honeycomb).balanceOf(address(goldilend)), 0);
    assertEq(IERC721(beradrome).balanceOf(address(goldilend)), 0);
    assertEq(userBoost.expiry, 0);
    assertEq(userBoost.boostMagnitude, 0);
  }

  function testSingleBoostMultipleBoost() public dealUserPartnerNFTs {
    INFT(address(honeycomb)).mint(address(this));
    (address[] memory nfts, uint256[] memory ids) = boosty();
    ids[0] = 2;
    goldilend.boost(address(honeycomb), 1);
    goldilend.boost(nfts, ids);
    Goldilend.Boost memory userBoost = goldilend.lookupBoost(address(this));

    assertEq(IERC721(honeycomb).balanceOf(address(this)), 0);
    assertEq(IERC721(beradrome).balanceOf(address(this)), 0);
    assertEq(IERC721(honeycomb).balanceOf(address(goldilend)), 2);
    assertEq(IERC721(beradrome).balanceOf(address(goldilend)), 1);
    assertEq(userBoost.expiry, 30 days + 1);
    assertEq(userBoost.boostMagnitude, 21);
  }

  function testSingleBoostSingleBoost() public dealUserPartnerNFTs {
    goldilend.boost(address(honeycomb), 1);
    goldilend.boost(address(beradrome), 1);
    Goldilend.Boost memory userBoost = goldilend.lookupBoost(address(this));

    assertEq(IERC721(honeycomb).balanceOf(address(this)), 0);
    assertEq(IERC721(beradrome).balanceOf(address(this)), 0);
    assertEq(IERC721(honeycomb).balanceOf(address(goldilend)), 1);
    assertEq(IERC721(beradrome).balanceOf(address(goldilend)), 1);
    assertEq(userBoost.expiry, 30 days + 1);
    assertEq(userBoost.boostMagnitude, 15);
    assertEq(userBoost.partnerNFTs[0], address(honeycomb));
    assertEq(userBoost.partnerNFTs[1], address(beradrome));
  }

    function testLockSuccess() public {
    vm.store(address(goldilend), bytes32(uint256(0x05345cdf77eb68f44c)), bytes32(uint256(1000e18)));
    deal(address(ibgt), address(this), 100e18);
    ibgt.approve(address(goldilend), type(uint256).max);
    goldilend.lock(100e18);

    assertEq(goldilend.balanceOf(address(this)), 90909090909090909000);
  }

  function testStakeSuccess() public {
    deal(address(goldilend), address(this), 2e18);
    goldilend.approve(address(goldilend), 2e18);
    goldilend.stake(2e18);

    assertEq(goldilend.balanceOf(address(this)), 0);
    assertEq(goldilend.balanceOf(address(goldilend)), 2e18);
  }

  function testUnstakeFailInvalid() public {
    vm.expectRevert(abi.encodeWithSelector(Goldilend.InvalidUnstake.selector));
    goldilend.unstake(69);
  }

  function testUnstakeSuccess() public {
    deal(address(goldilend), address(this), 1e18);
    goldilend.approve(address(goldilend), 1e18);
    goldilend.stake(1e18);
    vm.warp(block.timestamp + (30 days * 2));
    goldilend.unstake(1e18);

    assertEq(goldilocked.balanceOf(address(this)), prgMintAmount);
    assertEq(goldilend.balanceOf(address(goldilend)), 0);
    assertEq(goldilend.balanceOf(address(this)), 1e18);
    assertEq(goldilend.stakedGiBGT(address(this)), 0);
  }

  function testClaimSuccess() public {
    deal(address(goldilend), address(this), locksAmount);
    goldilend.approve(address(goldilend), locksAmount);
    goldilend.stake(locksAmount);
    vm.warp(1 days + 1);
    goldilend.claim();

    assertEq(goldilocked.balanceOf(address(this)), oneDayPrg + prgMintAmount);
    assertEq(goldilend.claimablePrg(address(this)), 0);
  }

  function testClaimBoostedClaim() public dealUserPartnerNFTs {
    goldilend.boost(address(honeycomb), 1);
    deal(address(goldilend), address(this), locksAmount);
    goldilend.approve(address(goldilend), locksAmount);
    goldilend.stake(locksAmount);
    vm.warp(1 days + 1);
    goldilend.claim();

    assertEq(goldilocked.balanceOf(address(this)), oneDayPrgBoosted + prgMintAmount);
  }

  function testClaimBoostedClaimTwoDays() public dealUserPartnerNFTs {
    goldilend.boost(address(honeycomb), 1);
    deal(address(goldilend), address(this), locksAmount);
    goldilend.approve(address(goldilend), locksAmount);
    goldilend.stake(locksAmount);
    vm.warp(2 days + 1);
    goldilend.claim();

    assertEq(goldilocked.balanceOf(address(this)), oneDayPrgBoosted*2 + prgMintAmount);
  }

  function testClaimZeroClaim() public {
    goldilend.claim();

    assertEq(goldilocked.balanceOf(address(this)), prgMintAmount);
  }

  function testClaimMaxBoostedClaim() public {
    (address[] memory nfts, uint256[] memory ids) = maxBoosty();
    goldilend.boost(nfts, ids);
    deal(address(goldilend), address(this), locksAmount);
    goldilend.approve(address(goldilend), locksAmount);
    goldilend.stake(locksAmount);
    vm.warp(1 days + 1);
    goldilend.claim();

    assertEq(goldilocked.balanceOf(address(this)), oneDayPrgMaxBoosted + prgMintAmount);
  }

  function testSingleBorrowFailActive() public {
    goldilend.setBorrowingActive(false);
    vm.expectRevert(abi.encodeWithSelector(Goldilend.NotActive.selector));
    goldilend.borrow(69, 69, address(0x69), 69);
  }

  function testSingleBorrowFailDuration() public {
    vm.expectRevert(abi.encodeWithSelector(Goldilend.InvalidDuration.selector));
    goldilend.borrow(69, 69, address(0x69), 69);
  }

  function testSingleBorrowFailAmount() public {
    vm.expectRevert(abi.encodeWithSelector(Goldilend.InvalidLoanAmount.selector));
    goldilend.borrow(690000e18, 8 days, address(0x69), 69);
  }

  function testSingleBorrowFailCollateral() public {
    vm.expectRevert(abi.encodeWithSelector(Goldilend.InvalidCollateral.selector));
    goldilend.borrow(69, 8 days, address(0x69), 69);
  }

  function testSingleBorrowFailLimit() public {
    vm.expectRevert(abi.encodeWithSelector(Goldilend.BorrowLimitExceeded.selector));
    goldilend.borrow(51e18, 8 days, address(bondbear), 69);
  }

  function testSingleBorrowSuccess() public dealUserBeras {
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 1);
    Goldilend.Loan memory userLoan = goldilend.lookupLoan(address(this), 1);

    assertEq(userLoan.collateralNFTs[0], address(bondbear));
    assertEq(userLoan.collateralNFTIds[0], 1);
    assertEq(userLoan.borrowedAmount, 1e18 + singleBorrowInterest);
    assertEq(userLoan.interest, singleBorrowInterest);
    assertEq(userLoan.duration, goldilendDuration);
    assertEq(userLoan.endDate, block.timestamp + goldilendDuration);
    assertEq(userLoan.loanId, 1);
    assertEq(userLoan.liquidated, false);
  }

  function testSingleBoostedBorrow() public dealUserBeras dealUserPartnerNFTs {
    goldilend.boost(address(honeycomb), 1);
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 1);
    Goldilend.Loan memory userLoan = goldilend.lookupLoan(address(this), 1);

    assertEq(userLoan.collateralNFTs[0], address(bondbear));
    assertEq(userLoan.collateralNFTIds[0], 1);
    assertEq(userLoan.borrowedAmount, 1e18 + singleBorrowInterestBoosted);
    assertEq(userLoan.interest, singleBorrowInterestBoosted);
    assertEq(userLoan.duration, goldilendDuration);
    assertEq(userLoan.endDate, block.timestamp + goldilendDuration);
    assertEq(userLoan.loanId, 1);
    assertEq(userLoan.liquidated, false);
  }

  function testSingleMaxBoostedBorrow() public dealUserBeras  {
    (address[] memory nfts, uint256[] memory ids) = maxBoosty();
    goldilend.boost(nfts, ids);
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 1);
    Goldilend.Loan memory userLoan = goldilend.lookupLoan(address(this), 1);

    assertEq(userLoan.collateralNFTs[0], address(bondbear));
    assertEq(userLoan.collateralNFTIds[0], 1);
    assertEq(userLoan.borrowedAmount, 1e18 + singleBorrowInterestMaxBoost);
    assertEq(userLoan.interest, singleBorrowInterestMaxBoost);
    assertEq(userLoan.duration, goldilendDuration);
    assertEq(userLoan.endDate, block.timestamp + goldilendDuration);
    assertEq(userLoan.loanId, 1);
    assertEq(userLoan.liquidated, false);
  }

  function testMultipleBorrowFailActive() public {
    (address[] memory nfts, uint256[] memory ids) = beras();
    goldilend.setBorrowingActive(false);
    vm.expectRevert(abi.encodeWithSelector(Goldilend.NotActive.selector));
    goldilend.borrow(69, 69, nfts, ids);
  }

  function testMultipleBorrowFailCollateral() public {
    (address[] memory nfts, uint256[] memory ids) = beras();
    nfts[0] = address(0xaaa);
    vm.expectRevert(abi.encodeWithSelector(Goldilend.InvalidCollateral.selector));
    goldilend.borrow(69, 69, nfts, ids);

  }

  function testMultipleBorrowFailDuration() public {
    (address[] memory nfts, uint256[] memory ids) = beras();
    vm.expectRevert(abi.encodeWithSelector(Goldilend.InvalidDuration.selector));
    goldilend.borrow(69, 69, nfts, ids);
  }

  function testMultipleBorrowFailAmount() public {
    (address[] memory nfts, uint256[] memory ids) = beras();
    vm.expectRevert(abi.encodeWithSelector(Goldilend.InvalidLoanAmount.selector));
    goldilend.borrow(690000e18, 8 days, nfts, ids);
  }

  function testMultipleBorrowFailArray() public {
    address[] memory nfts = new address[](2);
    nfts[0] = address(bondbear);
    nfts[1] = address(bandbear);
    uint256[] memory ids = new uint256[](3);
    ids[0] = 1;
    ids[1] = 1;
    ids[2] = 1;
    vm.expectRevert(abi.encodeWithSelector(Goldilend.ArrayMismatch.selector));
    goldilend.borrow(1e18, goldilendDuration, nfts, ids);
  }

  function testMultipleBorrowFailLimit() public {
    address[] memory nfts = new address[](1);
    nfts[0] = address(bondbear);
    uint256[] memory ids = new uint256[](1);
    ids[0] = 1;
    vm.expectRevert(abi.encodeWithSelector(Goldilend.BorrowLimitExceeded.selector));
    goldilend.borrow(99e18, 8 days, nfts, ids);
  }

  function testMultipleBorrowSuccess() public dealUserBeras {
    (address[] memory nfts, uint256[] memory ids) = beras();
    goldilend.borrow(1e18, goldilendDuration, nfts, ids);
    Goldilend.Loan memory userLoan = goldilend.lookupLoan(address(this), 1);

    assertEq(userLoan.collateralNFTs[0], address(bondbear));
    assertEq(userLoan.collateralNFTIds[0], 1);
    assertEq(userLoan.collateralNFTs[1], address(bandbear));
    assertEq(userLoan.collateralNFTIds[1], 1);
    assertEq(userLoan.borrowedAmount, 1e18 + singleBorrowInterest);
    assertEq(userLoan.interest, singleBorrowInterest);
    assertEq(userLoan.duration, goldilendDuration);
    assertEq(userLoan.endDate, block.timestamp + goldilendDuration);
    assertEq(userLoan.loanId, 1);
    assertEq(userLoan.liquidated, false);
  }

  function testMultipleBoostedBorrow() public dealUserBeras dealUserPartnerNFTs {
    goldilend.boost(address(honeycomb), 1);
    (address[] memory nfts, uint256[] memory ids) = beras();
    goldilend.borrow(1e18, goldilendDuration, nfts, ids);
    Goldilend.Loan memory userLoan = goldilend.lookupLoan(address(this), 1);

    assertEq(userLoan.collateralNFTs[0], address(bondbear));
    assertEq(userLoan.collateralNFTIds[0], 1);
    assertEq(userLoan.borrowedAmount, 1e18 + singleBorrowInterestBoosted);
    assertEq(userLoan.interest, singleBorrowInterestBoosted);
    assertEq(userLoan.duration, goldilendDuration);
    assertEq(userLoan.endDate, block.timestamp + goldilendDuration);
    assertEq(userLoan.loanId, 1);
    assertEq(userLoan.liquidated, false);
  }

  function testMultipleMaxBoostedBorrow() public dealUserBeras {
    (address[] memory nfts, uint256[] memory ids) = maxBoosty();
    goldilend.boost(nfts, ids);
    (address[] memory nftss, uint256[] memory idss) = beras();
    goldilend.borrow(1e18, goldilendDuration, nftss, idss);
    Goldilend.Loan memory userLoan = goldilend.lookupLoan(address(this), 1);

    assertEq(userLoan.collateralNFTs[0], address(bondbear));
    assertEq(userLoan.collateralNFTIds[0], 1);
    assertEq(userLoan.borrowedAmount, 1e18 + singleBorrowInterestMaxBoost);
    assertEq(userLoan.interest, singleBorrowInterestMaxBoost);
    assertEq(userLoan.duration, goldilendDuration);
    assertEq(userLoan.endDate, block.timestamp + goldilendDuration);
    assertEq(userLoan.loanId, 1);
    assertEq(userLoan.liquidated, false);
  }

  function testRepayFailExcessive() public dealUserBeras {
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 1);
    vm.expectRevert(abi.encodeWithSelector(Goldilend.ExcessiveRepay.selector));
    goldilend.repay(2e18, 1);
  }

  function testRepayFailExpired() public dealUserBeras {
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 1);
    vm.warp(69e18);
    vm.expectRevert(abi.encodeWithSelector(Goldilend.LoanExpired.selector));
    goldilend.repay(1e18, 1);
  }

  function testRepaySuccess() public dealUseriBGT dealUserBeras {
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 1);
    Goldilend.Loan memory userLoanBefore = goldilend.lookupLoan(address(this), 1);
    goldilend.repay(1e18+userLoanBefore.interest, 1);
    Goldilend.Loan memory userLoan = goldilend.lookupLoan(address(this), 1);

    assertEq(IERC721(address(bondbear)).balanceOf(address(goldilend)), 0);
    assertEq(IERC721(address(bondbear)).balanceOf(address(this)), 1);
    assertEq(userLoan.collateralNFTs[0], address(bondbear));
    assertEq(userLoan.collateralNFTIds[0], 1);
    assertEq(userLoan.borrowedAmount, 0);
    assertEq(userLoan.interest, 0);
    assertEq(userLoan.duration, goldilendDuration);
    assertEq(userLoan.endDate, block.timestamp + goldilendDuration);
    assertEq(userLoan.loanId, 1);
    assertEq(userLoan.liquidated, false);
    assertEq(goldilend.outstandingDebt(), 0);
    assertEq(goldilend.poolSize(), 1000e18 + (userLoanBefore.interest * 950 / 1000));
  }

  function testMultipleBorrowRepayTransfers() public dealUseriBGT dealUserBeras {
    (address[] memory nfts, uint256[] memory ids) = beras();
    goldilend.borrow(1e18, goldilendDuration, nfts, ids);
    Goldilend.Loan memory userLoanBefore = goldilend.lookupLoan(address(this), 1);
    goldilend.repay(1e18+userLoanBefore.interest, 1);
    Goldilend.Loan memory userLoan = goldilend.lookupLoan(address(this), 1);

    assertEq(IERC721(address(bondbear)).ownerOf(1), address(this));
    assertEq(IERC721(address(bandbear)).ownerOf(1), address(this));
    assertEq(userLoan.borrowedAmount, 0);
  }

  function testMultipleBorrowRepay() public dealUseriBGT dealUserBeras {
    (address[] memory nfts, uint256[] memory ids) = beras();
    goldilend.borrow(1e18, goldilendDuration, nfts, ids);
    Goldilend.Loan memory userLoanBefore = goldilend.lookupLoan(address(this), 1);
    goldilend.repay(1e18+userLoanBefore.interest, 1);
    Goldilend.Loan memory userLoan = goldilend.lookupLoan(address(this), 1);

    assertEq(IERC721(address(bondbear)).balanceOf(address(goldilend)), 0);
    assertEq(IERC721(address(bondbear)).balanceOf(address(this)), 1);
    assertEq(IERC721(address(bandbear)).balanceOf(address(goldilend)), 0);
    assertEq(IERC721(address(bandbear)).balanceOf(address(this)), 1);
    assertEq(userLoan.collateralNFTs[0], address(bondbear));
    assertEq(userLoan.collateralNFTIds[0], 1);
    assertEq(userLoan.borrowedAmount, 0);
    assertEq(userLoan.interest, 0);
    assertEq(userLoan.duration, goldilendDuration);
    assertEq(userLoan.endDate, block.timestamp + goldilendDuration);
    assertEq(userLoan.loanId, 1);
    assertEq(userLoan.liquidated, false);
    assertEq(goldilend.outstandingDebt(), 0);
    assertEq(goldilend.poolSize(), 1000e18 + (userLoanBefore.interest * 950 / 1000));
  }

  function testLiquidateFailUnliquidatable() public dealUseriBGT dealUserBeras {
    (address[] memory nfts, uint256[] memory ids) = beras();
    goldilend.borrow(1e18, goldilendDuration, nfts, ids);
    vm.expectRevert(abi.encodeWithSelector(Goldilend.Unliquidatable.selector));
    goldilend.liquidate(address(this), 1);
  }
  
  function testLiquidateSuccess() public dealUseriBGT dealUserBeras {
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 1);
    vm.warp(1209602);
    goldilend.liquidate(address(this), 1);
    Goldilend.Loan memory userLoan = goldilend.lookupLoan(address(this), 1);    

    assertEq(userLoan.collateralNFTs[0], address(bondbear));
    assertEq(userLoan.collateralNFTIds[0], 1);
    assertEq(userLoan.borrowedAmount, 0);
    assertEq(userLoan.duration, goldilendDuration);
    assertEq(userLoan.endDate, 1209601);
    assertEq(userLoan.loanId, 1);
    assertEq(userLoan.liquidated, true);
    assertEq(IERC721(address(bondbear)).balanceOf(address(goldilend)), 0);
    assertEq(IERC721(address(bondbear)).balanceOf(address(this)), 1);
  }

  function testLiquidateMultisigLiquidate() public dealUseriBGT dealUserBeras {
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 1);
    vm.warp(68e18);
    goldilend.liquidate(address(this), 1);
    Goldilend.Loan memory userLoan = goldilend.lookupLoan(address(this), 1);
    
    assertEq(goldilend.poolSize(), 999e18);
    assertEq(userLoan.collateralNFTs[0], address(bondbear));
    assertEq(userLoan.collateralNFTIds[0], 1);
    assertEq(userLoan.borrowedAmount, 0);
    assertEq(userLoan.duration, goldilendDuration);
    assertEq(userLoan.endDate, 1209601);
    assertEq(userLoan.loanId, 1);
    assertEq(userLoan.liquidated, true);
    assertEq(IERC721(address(bondbear)).balanceOf(address(goldilend)), 0);
    assertEq(IERC721(address(bondbear)).balanceOf(address(this)), 1);
  }

  function testSetMultisigFailMultisig() public {
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(Goldilend.NotMultisig.selector));
    goldilend.setMultisig(address(0x69));
  }

  function testSetMultisigSuccess() public {
    goldilend.setMultisig(address(0x69));
    
    assertEq(goldilend.multisig(), address(0x69));
  }

  function testSetValueFailMultisig() public {
    address[] memory nfts = new address[](2);
    nfts[0] = address(bondbear);
    nfts[1] = address(bandbear);
    uint256[] memory values = new uint256[](2);
    values[0] = 50;
    values[1] = 50;
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(Goldilend.NotMultisig.selector));
    goldilend.setValue(69, nfts, values);
  }

  function testSetValueSuccess() public {
    address[] memory nfts = new address[](2);
    nfts[0] = address(bondbear);
    nfts[1] = address(bandbear);
    uint256[] memory values = new uint256[](2);
    values[0] = 50;
    values[1] = 50;
    goldilend.setValue(69, nfts, values);

    assertEq(goldilend.totalValuation(), 69);
    assertEq(goldilend.nftFairValues(address(bondbear)), 50);
    assertEq(goldilend.nftFairValues(address(bandbear)), 50);
  }

  function testSetProtocolInterestRateFailMultisig() public {
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(Goldilend.NotMultisig.selector));
    goldilend.setProtocolInterestRate(69);
  }

  function testSetProtocolInterestRateSuccess() public {
    goldilend.setProtocolInterestRate(69);

    assertEq(goldilend.protocolInterestRate(), 69);
  }

  function testSetShareRatesFailMultisig() public {
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(Goldilend.NotMultisig.selector));
    goldilend.setShareRates(69, 69);
  }

  function testSetShareRatesSuccess() public {
    goldilend.setShareRates(69, 69);

    assertEq(goldilend.multisigShare(), 69);
    assertEq(goldilend.honeyjarShare(), 69);
  }

  function testEmergencyWithdrawFailMultisig() public {
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(Goldilend.NotMultisig.selector));
    goldilend.emergencyWithdraw();
  }

  function testEmergencyWithdrawSuccess() public {
    goldilend.emergencyWithdraw();

    assertEq(ibgt.balanceOf(address(this)), 1000e18);
    assertEq(ibgt.balanceOf(address(goldilend)), 0);
  }

  function testMultisigInterestClaimFailMultisig() public {
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(Goldilend.NotMultisig.selector));
    goldilend.multisigInterestClaim();
  }

  function testMultisigInterestClaimSuccess() public dealUseriBGT dealUserBeras {
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 1);
    Goldilend.Loan memory userLoanBefore = goldilend.lookupLoan(address(this), 1);
    goldilend.repay(1e18+userLoanBefore.interest, 1);
    uint256 multisigibgtBalanceBefore = ibgt.balanceOf(address(this));
    uint256 goldilendibgtBalanceBefore = ibgt.balanceOf(address(goldilend));
    goldilend.multisigInterestClaim();
    
    assertEq(goldilend.multisigClaims(), 0);
    assertEq(ibgt.balanceOf(address(this)), multisigibgtBalanceBefore + 2057708388065);
    assertEq(ibgt.balanceOf(address(goldilend)), goldilendibgtBalanceBefore - 2057708388065);
  }

  function testHoneyjarInterestClaimFailMultisig() public {
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(Goldilend.NotHoneyjar.selector));
    goldilend.honeyjarInterestClaim();
  }

  function testHoneyjarInterestClaimSuccess() public dealUseriBGT dealUserBeras {
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 1);
    Goldilend.Loan memory userLoanBefore = goldilend.lookupLoan(address(this), 1);
    goldilend.repay(1e18+userLoanBefore.interest, 1);
    uint256 honeyibgtBalanceBefore = ibgt.balanceOf(honeyjar);
    uint256 goldilendibgtBalanceBefore = ibgt.balanceOf(address(goldilend));
    vm.prank(honeyjar);
    goldilend.honeyjarInterestClaim();

    assertEq(goldilend.honeyjarClaims(), 0);
    assertEq(ibgt.balanceOf(honeyjar), honeyibgtBalanceBefore + 228634265340);
    assertEq(ibgt.balanceOf(address(goldilend)), goldilendibgtBalanceBefore - 228634265340);
  }

  function testSetSlopeFailMultisig() public {
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(Goldilend.NotMultisig.selector));
    goldilend.setSlope(69);
  }

  function testSetSlopeSuccess() public {
    goldilend.setSlope(69);
    
    assertEq(goldilend.slope(), 69);
  }

  function testSetDurationsFailMultisig() public {
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(Goldilend.NotMultisig.selector));
    goldilend.setDurations(69, 69);
  }

  function testSetDurationsSuccess() public {
    goldilend.setDurations(69, 69);

    assertEq(goldilend.minDuration(), 69);
    assertEq(goldilend.maxDuration(), 69);
  }

  function testSetBorrowingActiveFailMultisig() public {
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(Goldilend.NotMultisig.selector));
    goldilend.setBorrowingActive(false);
  }

  function testSetBorrowingActiveSuccess() public {
    goldilend.setBorrowingActive(false);
    
    assertEq(goldilend.borrowingActive(), false);
  }

  function testChangePrgEmissionsFailMultisig() public {
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(Goldilend.NotMultisig.selector));
    goldilend.changePrgEmissions(69);
  }

  function testChangePrgEmissionsSuccess() public {
    goldilend.changePrgEmissions(69);

    assertEq(goldilend.ANNUAL_PORRIDGE_EMISSIONS(), 69);
  }
}