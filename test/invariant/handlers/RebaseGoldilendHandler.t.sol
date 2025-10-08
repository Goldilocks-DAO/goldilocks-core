//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { BaseHandler } from "../../base/BaseHandler.t.sol";
import { SafeTransferLib } from "../../../lib/solady/src/utils/SafeTransferLib.sol";
import { RebaseGoldilend } from "../../../src/core/goldilend/RebaseGoldilend.sol";
import { GoldilendDebtAsset } from "../../../src/core/goldilend/GoldilendDebtAsset.sol";
import { Honey } from "../../../src/mock/Honey.sol";
import { BandBear } from "../../../src/mock/BandBear.sol";
import { IERC721 } from "../../../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

contract RebaseGoldilendHandler is BaseHandler {

  RebaseGoldilend public rebasegoldilend;
  GoldilendDebtAsset public ghoney;
  Honey public honey;
  BandBear public bandbear;

  uint256 public ghost_depositSum;
  uint256 public ghost_withdrawSum;
  uint256 public ghost_zeroWithdraws;
  uint256 public ghost_borrowSum;
  uint256 public ghost_repaySum;
  uint256 public ghost_liquidateSum;
  uint256 public ghost_renewSum;
  uint256 public ghost_interestSum;
  uint256 public ghost_collateralDeposited;
  uint256 public ghost_collateralReturned;
  uint256 public ghost_collateralLiquidated;

  mapping(address => uint256) public userLoanCount;
  mapping(address => mapping(uint256 => bool)) public activeLoans;
  mapping(address => uint256) public userTotalBorrowed;
  mapping(address => uint256) public userTotalRepaid;
  mapping(address => uint256[]) public userNFTs;
  mapping(address => uint256) public userNFTCount;

  constructor(address _rebaseproxy, GoldilendDebtAsset _ghoney, Honey _honey, BandBear _bandbear) {
    rebasegoldilend = RebaseGoldilend(_rebaseproxy);
    ghoney = _ghoney;
    honey = _honey;
    bandbear = _bandbear;
    deal(address(honey), address(this), 100_000e18);
  }

  function mintNFTForActor(address actor) external {
    if (userNFTCount[actor] == 0) {
      bandbear.mint(actor);
      userNFTs[actor].push(userNFTCount[actor] + 1);
      userNFTCount[actor]++;
    }
  }

  function deposit(uint256 amount) public createActor countCall("deposit") {
    amount = bound(amount, 0, honey.balanceOf(address(this)));
    amount = bound(amount, 0, 1_000_000e18);

    sendHoney(currentActor, amount);
    vm.startPrank(currentActor);
    honey.approve(address(rebasegoldilend), amount);
    try RebaseGoldilend(address(rebasegoldilend)).deposit(amount) {
      ghost_depositSum += amount;
    } catch {
      // Deposit failed, continue
    }
    vm.stopPrank();
  }

  function withdraw(uint256 actorSeed, uint256 amount) public useActor(actorSeed) countCall("withdraw") {
    amount = bound(amount, 0, ghoney.balanceOf(currentActor));
    if(amount == 0) ghost_zeroWithdraws++;

    vm.startPrank(currentActor);
    try RebaseGoldilend(address(rebasegoldilend)).withdraw(amount) {
      ghost_withdrawSum += amount;
    } catch {
      // Withdraw failed, continue
    }
    vm.stopPrank();
  }

  function borrow(
    uint256 actorSeed,
    uint256 borrowAmount,
    uint256 duration,
    uint256 nftId
  ) public useActor(actorSeed) countCall("borrow") {
    if (!rebasegoldilend.borrowingActive() || !rebasegoldilend.berasInitialized()) return;
    if (userNFTCount[currentActor] == 0 || nftId >= userNFTCount[currentActor]) {
      bandbear.mint(currentActor);
      userNFTs[currentActor].push(userNFTCount[currentActor] + 1);
      userNFTCount[currentActor]++;
      nftId = userNFTCount[currentActor] - 1;
    }
    uint256 actualTokenId = userNFTs[currentActor][nftId];
    uint256 maxBorrow = ghoney.totalSupply() / 10;
    uint256 nftValue = RebaseGoldilend(address(rebasegoldilend)).unvestedWeights(address(bandbear));
    borrowAmount = bound(borrowAmount, 0, maxBorrow);
    borrowAmount = bound(borrowAmount, 0, nftValue);
    duration = bound(duration, RebaseGoldilend(address(rebasegoldilend)).minDuration(), RebaseGoldilend(address(rebasegoldilend)).maxDuration());

    if (RebaseGoldilend(address(rebasegoldilend)).outstandingDebt() + borrowAmount > ghoney.totalSupply() * RebaseGoldilend(address(rebasegoldilend)).maxUtilization() / 100) return;
    try RebaseGoldilend(address(rebasegoldilend)).borrow(borrowAmount, 1_000e18, duration, address(bandbear), actualTokenId) {
      userLoanCount[currentActor]++;
      uint256 loanId = userLoanCount[currentActor];
      activeLoans[currentActor][loanId] = true;
      userTotalBorrowed[currentActor] += borrowAmount;
      ghost_borrowSum += borrowAmount;
      ghost_collateralDeposited++;
      uint256 interest = RebaseGoldilend(address(rebasegoldilend)).calculateInterest(borrowAmount, duration, address(bandbear));
      ghost_interestSum += interest;
    } catch {
      // Borrow failed, continue
    }
  }

  function renew(
    uint256 actorSeed,
    uint256 loanId,
    uint256 newDuration,
    uint256 newBorrowAmount
  ) public useActor(actorSeed) countCall("renew") {
    if (!RebaseGoldilend(address(rebasegoldilend)).borrowingActive() || !RebaseGoldilend(address(rebasegoldilend)).berasInitialized()) return;
    if (!activeLoans[currentActor][loanId]) return;
    RebaseGoldilend.Loan memory loan = RebaseGoldilend(address(rebasegoldilend)).getUserLoan(currentActor, loanId);
    if (loan.borrowedAmount == 0 || loan.repaid || loan.liquidated) return;
    uint256 maxBorrow = ghoney.totalSupply() / 10;
    newBorrowAmount = bound(newBorrowAmount, 0, maxBorrow);
    newDuration = bound(newDuration, RebaseGoldilend(address(rebasegoldilend)).minDuration(), RebaseGoldilend(address(rebasegoldilend)).maxDuration());

    if (RebaseGoldilend(address(rebasegoldilend)).outstandingDebt() + newBorrowAmount > ghoney.totalSupply() * RebaseGoldilend(address(rebasegoldilend)).maxUtilization() / 100) return;
    try RebaseGoldilend(address(rebasegoldilend)).renew(loanId, newDuration, newBorrowAmount, 1_000e18) {
      userTotalBorrowed[currentActor] += newBorrowAmount;
      ghost_renewSum += newBorrowAmount;
      ghost_borrowSum += newBorrowAmount;
      uint256 newInterest = RebaseGoldilend(address(rebasegoldilend)).calculateInterest(loan.borrowedAmount + newBorrowAmount, newDuration, loan.collateralNFT);
      ghost_interestSum += newInterest;
    } catch {
      // Renew failed, continue
    }
  }

  function repay(
    uint256 actorSeed,
    uint256 loanId,
    uint256 repayAmount
  ) public useActor(actorSeed) countCall("repay") {
    if (!activeLoans[currentActor][loanId]) return;
    RebaseGoldilend.Loan memory loan = RebaseGoldilend(address(rebasegoldilend)).getUserLoan(currentActor, loanId);
    if (loan.borrowedAmount == 0 || loan.repaid || loan.liquidated) return;
    uint256 actorHoney = honey.balanceOf(currentActor);
    if (actorHoney == 0) {
      sendHoney(currentActor, loan.borrowedAmount);
      actorHoney = loan.borrowedAmount;
    }
    repayAmount = bound(repayAmount, 0, loan.borrowedAmount);
    repayAmount = bound(repayAmount, 0, actorHoney);
    vm.startPrank(currentActor);
    honey.approve(address(rebasegoldilend), repayAmount);
    try RebaseGoldilend(address(rebasegoldilend)).repay(repayAmount, loanId) {
      userTotalRepaid[currentActor] += repayAmount;
      ghost_repaySum += repayAmount;
      RebaseGoldilend.Loan memory updatedLoan = RebaseGoldilend(address(rebasegoldilend)).getUserLoan(currentActor, loanId);
      if (updatedLoan.repaid) {
        activeLoans[currentActor][loanId] = false;
        ghost_collateralReturned++;
      }
    } catch {
      // Repay failed, continue
    }
    vm.stopPrank();
  }

  function approve(
    uint256 actorSeed,
    uint256 spenderSeed,
    uint256 amount
  ) public useActor(actorSeed) countCall("approve") {
    address spender = randomActor(spenderSeed);

    vm.prank(currentActor);
    ghoney.approve(spender, amount);
  }

  function transfer(
    uint256 actorSeed,
    uint256 toSeed,
    uint256 amount
  ) public useActor(actorSeed) countCall("transfer") {
    address to = randomActor(toSeed);
    amount = bound(amount, 0, ghoney.balanceOf(currentActor));

    vm.prank(currentActor);
    ghoney.transfer(to, amount);
  }

  function transferFrom(
    uint256 actorSeed,
    uint256 fromSeed,
    uint256 toSeed,
    bool _approve,
    uint256 amount
  ) public useActor(actorSeed) countCall("transferFrom")
  {
    address from = randomActor(fromSeed);
    address to = randomActor(toSeed);

    amount = bound(amount, 0, ghoney.balanceOf(from));

    if(_approve) {
      vm.prank(from);
      ghoney.approve(currentActor, amount);
    }
    else {
      amount = bound(amount, 0, ghoney.allowance(currentActor, from));
    }  

    vm.prank(currentActor);
    ghoney.transferFrom(from, to, amount);
  }

  function sendHoney(address actor, uint256 amount) internal {
    SafeTransferLib.safeTransfer(address(honey), actor, amount);
  }

  function getRandomNFTForActor(address actor, uint256 seed) internal view returns (uint256) {
    if (userNFTCount[actor] == 0) return 0;
    return userNFTs[actor][seed % userNFTCount[actor]];
  }

  // Helper functions for invariant testing
  function getTotalActiveLoans() external view returns (uint256) {
    uint256 total = 0;
    for (uint256 i = 0; i < actors().length; i++) {
      address actor = actors()[i];
      for (uint256 j = 1; j <= userLoanCount[actor]; j++) {
        if (activeLoans[actor][j]) {
          total++;
        }
      }
    }
    return total;
  }

  function getTotalBorrowed() external view returns (uint256) {
    uint256 total = 0;
    for (uint256 i = 0; i < actors().length; i++) {
      total += userTotalBorrowed[actors()[i]];
    }
    return total;
  }

  function getTotalRepaid() external view returns (uint256) {
    uint256 total = 0;
    for (uint256 i = 0; i < actors().length; i++) {
      total += userTotalRepaid[actors()[i]];
    }
    return total;
  }

}