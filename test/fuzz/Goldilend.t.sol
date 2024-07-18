//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { BaseFuzzTest } from "../base/BaseFuzzTest.t.sol";
import { FixedPointMathLib } from "../../lib/solady/src/utils/FixedPointMathLib.sol";
import { IERC721 } from "../../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import { Goldilend } from "../../src/core/goldilend/Goldilend.sol";
import { IGoldilend } from "../../src/interfaces/IGoldilend.sol";

contract FuzzGoldilendTest is BaseFuzzTest {

  function testFuzzSingleBoost(uint256 time) public dealUserPartnerNFTs {
    vm.assume(time < type(uint256).max / 2);
    vm.warp(time);
    goldilend.boost(address(honeycomb), 1);
    Goldilend.Boost memory userBoost = goldilend.lookupBoost(address(this));

    assertEq(IERC721(honeycomb).balanceOf(address(this)), 0);
    assertEq(IERC721(honeycomb).balanceOf(address(goldilend)), 1);
    assertEq(userBoost.expiry, 30 days + time);
    assertEq(userBoost.boostMagnitude, 6);
  }

  function testFuzzMultipleBoost(uint256 time) public dealUserPartnerNFTs {
    vm.assume(time < type(uint256).max / 2);
    vm.warp(time);
    (address[] memory nfts, uint256[] memory ids) = boosty();
    goldilend.boost(nfts, ids);
    Goldilend.Boost memory userBoost = goldilend.lookupBoost(address(this));

    assertEq(IERC721(honeycomb).balanceOf(address(this)), 0);
    assertEq(IERC721(beradrome).balanceOf(address(this)), 0);
    assertEq(IERC721(honeycomb).balanceOf(address(goldilend)), 1);
    assertEq(IERC721(beradrome).balanceOf(address(goldilend)), 1);
    assertEq(userBoost.expiry, 30 days + time);
    assertEq(userBoost.boostMagnitude, 15);
  }

  function testFuzzLock(uint256 lockAmount) public {
    vm.assume(lockAmount < 1e21);
    deal(address(ibgt), address(this), lockAmount);
    ibgt.approve(address(goldilend), lockAmount);
    goldilend.lock(lockAmount);

    assertEq(goldilend.balanceOf(address(this)), lockAmount + 1000e18);
    assertEq(ibgt.balanceOf(address(this)), 0);
    assertEq(ibgt.balanceOf(address(goldilend)), 0);
    assertEq(ibgt.balanceOf(address(ibgtvault)), (type(uint256).max / 2) + lockAmount);
    assertEq(goldilend.poolSize(), 1000e18 + lockAmount);
  }

  function testFuzzStake(uint256 stakeAmount) public {
    deal(address(goldilend), address(this), stakeAmount);
    goldilend.approve(address(goldilend), stakeAmount);
    goldilend.stake(stakeAmount);

    assertEq(goldilend.balanceOf(address(this)), 0);
    assertEq(goldilend.balanceOf(address(goldilend)), stakeAmount);
  }

  function testFuzzUnstake(uint256 unstakeAmount) public {
    vm.assume(unstakeAmount < 1e40);
    deal(address(goldilend), address(this), unstakeAmount);
    goldilend.approve(address(goldilend), unstakeAmount);
    goldilend.stake(unstakeAmount);
    vm.warp(block.timestamp + (30 days * 2));
    goldilend.unstake(unstakeAmount);

    assertEq(goldilocked.balanceOf(address(this)), prgMintAmount);
    assertEq(goldilend.balanceOf(address(goldilend)), 0);
    assertEq(goldilend.balanceOf(address(this)), unstakeAmount);
    assertEq(goldilend.stakedGiBGT(address(this)), 0);
  }

  function testFuzzClaim(uint256 claimAmount) public {
    vm.assume(claimAmount < locksMintAmount);
    vm.assume(claimAmount > 1e5);
    deal(address(goldilend), address(this), claimAmount);
    goldilend.approve(address(goldilend), claimAmount);
    goldilend.stake(claimAmount);
    vm.warp(1 days + 1);
    goldilend.claim();
    uint256 claimMagnitude = FixedPointMathLib.divWad(claimAmount, locksAmount);

    assertLe(goldilocked.balanceOf(address(this)), FixedPointMathLib.mulWad(oneDayPrg, claimMagnitude) + prgMintAmount + 500);
    assertGe(goldilocked.balanceOf(address(this)),  FixedPointMathLib.mulWad(oneDayPrg, claimMagnitude) + prgMintAmount - 500);
    assertEq(goldilend.claimablePrg(address(this)), 0);
  }

  function testFuzzSingleBorrow(uint256 durationAmount) public dealUserBeras {
    vm.assume(durationAmount > goldilend.minDuration() && durationAmount < goldilend.maxDuration());
    goldilend.borrow(1e18, durationAmount, address(bondbear), 1);
    Goldilend.Loan memory userLoan = goldilend.lookupLoan(address(this), 1);

    assertEq(userLoan.collateralNFTs[0], address(bondbear));
    assertEq(userLoan.collateralNFTIds[0], 1);
    assertEq(userLoan.duration, durationAmount);
    assertEq(userLoan.endDate, block.timestamp + durationAmount);
    assertEq(userLoan.loanId, 1);
    assertEq(userLoan.liquidated, false);
  }

  function testFuzzMultipleBorrow(uint256 durationAmount) public dealUserBeras {
    vm.assume(durationAmount > goldilend.minDuration() && durationAmount < goldilend.maxDuration());
    (address[] memory nfts, uint256[] memory ids) = beras();
    goldilend.borrow(1e18, durationAmount, nfts, ids);
    Goldilend.Loan memory userLoan = goldilend.lookupLoan(address(this), 1);

    assertEq(userLoan.collateralNFTs[0], address(bondbear));
    assertEq(userLoan.collateralNFTIds[0], 1);
    assertEq(userLoan.collateralNFTs[1], address(bandbear));
    assertEq(userLoan.collateralNFTIds[1], 1);
    assertEq(userLoan.duration, durationAmount);
    assertEq(userLoan.endDate, block.timestamp + durationAmount);
    assertEq(userLoan.loanId, 1);
    assertEq(userLoan.liquidated, false);
  }

  function testFuzzRepayiBGT(uint256 durationAmount) public dealUseriBGT dealUserBeras {
    vm.assume(durationAmount > goldilend.minDuration() && durationAmount < goldilend.maxDuration());
    goldilend.borrow(1e18, durationAmount, address(bondbear), 1);
    Goldilend.Loan memory userLoanBefore = goldilend.lookupLoan(address(this), 1);
    uint256 interestLoanRatio = FixedPointMathLib.divWad(userLoanBefore.interest, userLoanBefore.borrowedAmount);
    uint256 interest = FixedPointMathLib.mulWadUp(1e18+userLoanBefore.interest, interestLoanRatio);
    goldilend.repay(1e18+userLoanBefore.interest, 1);
    Goldilend.Loan memory userLoan = goldilend.lookupLoan(address(this), 1);

    assertEq(IERC721(address(bondbear)).balanceOf(address(goldilend)), 0);
    assertEq(IERC721(address(bondbear)).balanceOf(address(this)), 1);
    assertEq(userLoan.collateralNFTs[0], address(bondbear));
    assertEq(userLoan.collateralNFTIds[0], 1);
    assertEq(userLoan.borrowedAmount, 0);
    assertLe(userLoan.interest, 2);
    assertEq(userLoan.duration, durationAmount);
    assertEq(userLoan.endDate, block.timestamp + durationAmount);
    assertEq(userLoan.loanId, 1);
    assertEq(userLoan.liquidated, false);
    assertEq(goldilend.outstandingDebt(), 0);
    assertEq(goldilend.poolSize(), 1000e18 + (interest * 950 / 1000));
  }

  function testFuzzLiquidate(uint256 time, uint256 durationAmount) public dealUseriBGT dealUserBeras {
    vm.assume(time < type(uint256).max / 2);
    vm.assume(durationAmount > goldilend.minDuration() && durationAmount < goldilend.maxDuration());
    goldilend.borrow(1e18, durationAmount, address(bondbear), 1);
    vm.warp(time);
    Goldilend.Loan memory userLoan = goldilend.lookupLoan(address(this), 1);    
    if(time > userLoan.endDate) {
      goldilend.liquidate(address(this), 1);
      assertEq(userLoan.collateralNFTs[0], address(bondbear));
      assertEq(userLoan.collateralNFTIds[0], 1);
      assertEq(userLoan.duration, durationAmount);
      assertEq(userLoan.endDate, durationAmount + 1);
      assertEq(userLoan.loanId, 1);
      assertEq(IERC721(address(bondbear)).balanceOf(address(goldilend)), 0);
      assertEq(IERC721(address(bondbear)).balanceOf(address(this)), 1);
    }
    else {
      vm.expectRevert(abi.encodeWithSelector(IGoldilend.Unliquidatable.selector));
      goldilend.liquidate(address(this), 1);
    }
  }
}