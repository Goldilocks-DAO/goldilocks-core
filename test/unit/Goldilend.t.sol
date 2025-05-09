//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { BaseUnitTest } from "../base/BaseUnitTest.t.sol";
import { IERC721 } from "../../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import { INFT } from "../../src/mock/INFT.sol";
import { Goldilend } from "../../src/core/goldilend/Goldilend.sol";
import { IGoldilend } from "../../src/interfaces/IGoldilend.sol";

contract UnitGoldilendTest is BaseUnitTest {

  function testLookupLoan() public dealUserBeras {
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 1);
    Goldilend.Loan memory userLoan = goldilend.lookupLoan(address(this), 1);

    assertEq(userLoan.collateralNFTs[0], address(bondbear));
    assertEq(userLoan.collateralNFTIds[0], 1);
    assertEq(userLoan.borrowedAmount, 1e18 + singleBorrowInterest);
  }

  function testGetGPRGRatio() public {
    deal(address(goldilocked), address(this), txAmount);
    goldilocked.approve(address(goldilend), txAmount);
    goldilend.lock(txAmount);

    assertEq(goldilend.getGPRGRatio(), 1e18);
  }

  function testLockSuccess() public {
    deal(address(goldilocked), address(this), txAmount);
    goldilocked.approve(address(goldilend), txAmount);
    goldilend.lock(txAmount);

    assertEq(gprg.balanceOf(address(this)), 1000e18 + txAmount);
    assertEq(goldilocked.balanceOf(address(this)), 0);
    assertEq(goldilocked.balanceOf(address(goldilend)), 0);
    assertEq(goldilocked.balanceOf(address(ibgtvault)), (type(uint256).max / 2) + txAmount);
    assertEq(goldilend.poolSize(), 1000e18 + txAmount);
  }

  function testLockLock() public {
    deal(address(goldilocked), address(this), txAmount);
    goldilocked.approve(address(goldilend), txAmount);
    goldilend.lock(txAmount);
    deal(address(goldilocked), address(0xabc), txAmount);
    vm.prank(address(0xabc));
    goldilocked.approve(address(goldilend), txAmount);
    vm.prank(address(0xabc));
    goldilend.lock(txAmount);

    assertEq(gprg.balanceOf(address(this)), 1000e18 + txAmount);
    assertEq(gprg.balanceOf(address(0xabc)), txAmount);
    assertEq(goldilocked.balanceOf(address(this)), 0);
    assertEq(goldilocked.balanceOf(address(goldilend)), 0);
    assertEq(goldilocked.balanceOf(address(ibgtvault)), (type(uint256).max / 2) + txAmount+txAmount);
    assertEq(goldilend.poolSize(), 1000e18 + txAmount+txAmount);
  }

  function testLockHalf() public {
    vm.store(address(goldilend), bytes32(uint256(4)), bytes32(uint256(100e18)));
    vm.store(address(goldilend), bytes32(uint256(0x05345cdf77eb68f44c)), bytes32(uint256(50e18)));
    deal(address(goldilocked), address(this), txAmount);
    goldilocked.approve(address(goldilend), txAmount);
    goldilend.lock(txAmount);

    assertEq(gprg.balanceOf(address(this)), 1000e18 + (txAmount / 2));
    assertEq(goldilocked.balanceOf(address(this)), 0);
    assertEq(goldilocked.balanceOf(address(goldilend)), 0);
    assertEq(goldilocked.balanceOf(address(ibgtvault)), (type(uint256).max / 2) + txAmount);
    assertEq(goldilend.poolSize(), 100e18 + txAmount);
  }

  function testLockDouble() public {
    vm.store(address(goldilend), bytes32(uint256(4)), bytes32(uint256(50e18)));
    vm.store(address(goldilend), bytes32(uint256(0x05345cdf77eb68f44c)), bytes32(uint256(100e18)));
    deal(address(goldilocked), address(this), txAmount);
    goldilocked.approve(address(goldilend), txAmount);
    goldilend.lock(txAmount);

    assertEq(gprg.balanceOf(address(this)), 1000e18 + (txAmount * 2));
    assertEq(goldilocked.balanceOf(address(this)), 0);
    assertEq(goldilocked.balanceOf(address(goldilend)), 0);
    assertEq(goldilocked.balanceOf(address(ibgtvault)), (type(uint256).max / 2) + txAmount);
    assertEq(goldilend.poolSize(), 50e18 + txAmount);
  }

  function testSingleBorrowFailActive() public {
    goldilend.changeBorrowingActive(false);
    vm.expectRevert(abi.encodeWithSelector(IGoldilend.NotActive.selector));
    goldilend.borrow(69, 69, address(0x69), 69);
  }

  function testSingleBorrowFailDuration() public {
    vm.expectRevert(abi.encodeWithSelector(IGoldilend.InvalidDuration.selector));
    goldilend.borrow(69, 69, address(0x69), 69);
  }

  function testSingleBorrowFailAmount() public {
    vm.expectRevert(abi.encodeWithSelector(IGoldilend.InvalidLoanAmount.selector));
    goldilend.borrow(690000e18, 8 days, address(0x69), 69);
  }

  function testSingleBorrowFailCollateral() public {
    vm.expectRevert(abi.encodeWithSelector(IGoldilend.InvalidCollateral.selector));
    goldilend.borrow(69, 8 days, address(0x69), 69);
  }

  function testSingleBorrowFailLimit() public {
    vm.expectRevert(abi.encodeWithSelector(IGoldilend.BorrowLimitExceeded.selector));
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

  function testRepayFailExpired() public dealUserBeras {
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 1);
    vm.warp(69e18);
    vm.expectRevert(abi.encodeWithSelector(IGoldilend.LoanExpired.selector));
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

  function testRepayHalfSuccess() public dealUseriBGT dealUserBeras {
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 1);
    Goldilend.Loan memory userLoanBefore = goldilend.lookupLoan(address(this), 1);
    goldilend.repay((1e18+userLoanBefore.interest) / 2, 1);
    Goldilend.Loan memory userLoan = goldilend.lookupLoan(address(this), 1);

    assertEq(IERC721(address(bondbear)).balanceOf(address(goldilend)), 1);
    assertEq(IERC721(address(bondbear)).balanceOf(address(this)), 0);
    assertEq(userLoan.collateralNFTs[0], address(bondbear));
    assertEq(userLoan.collateralNFTIds[0], 1);
    assertEq(userLoan.borrowedAmount, ((1e18+userLoanBefore.interest) / 2));
    assertEq(userLoan.interest, userLoanBefore.interest / 2);
    assertEq(userLoan.duration, goldilendDuration);
    assertEq(userLoan.endDate, block.timestamp + goldilendDuration);
    assertEq(userLoan.loanId, 1);
    assertEq(userLoan.liquidated, false);
    assertEq(goldilend.outstandingDebt(), 5e17);
  }
  
  function testLiquidateSuccess() public dealUseriBGT dealUserBeras {
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 1);
    vm.warp(1209602 + 86401);
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

  function testChangeValueFailMultisig() public {
    address[] memory nfts = new address[](2);
    nfts[0] = address(bondbear);
    nfts[1] = address(bandbear);
    uint256[] memory values = new uint256[](2);
    values[0] = 50;
    values[1] = 50;
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(IGoldilend.NotMultisig.selector));
    goldilend.changeValue(nfts, values);
  }

  function testChangeValueSuccess() public {
    address[] memory nfts = new address[](2);
    nfts[0] = address(bondbear);
    nfts[1] = address(bandbear);
    uint256[] memory values = new uint256[](2);
    values[0] = 50;
    values[1] = 50;
    goldilend.changeValue(nfts, values);    

    assertEq(goldilend.nftFairValues(address(bondbear)), 50);
    assertEq(goldilend.nftFairValues(address(bandbear)), 50);
  }

  function testChangeProtocolInterestRateFailTimelock() public {
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(IGoldilend.NotTimelock.selector));
    goldilend.changeProtocolInterestRate(69);
  }

  function testChangeProtocolInterestRateSuccess() public {
    bytes memory _calldata = abi.encodeWithSignature("changeProtocolInterestRate(uint256)", 69);
    address[] memory targets = new address[](1);
    targets[0] = address(goldilend);
    string[] memory signatures = new string[](1);
    signatures[0] = "";
    bytes[] memory calldatas = new bytes[](1);
    calldatas[0] = _calldata;
    uint256[] memory valuess = new uint256[](1);
    valuess[0] = 0;
    deal(address(goldiswap), address(this), quorumVotesNum);
    goldiswap.approve(address(govlocks), quorumVotesNum);
    govlocks.deposit(quorumVotesNum);
    govlocks.delegate(address(this));
    vm.roll(2);
    goldigov.propose(targets, valuess, signatures, calldatas, "");
    vm.roll(52600);
    goldigov.castVote(1, 1);
    vm.roll(200000);
    goldigov.queue(1);
    vm.warp(6 days);
    goldigov.execute(1);
    (, , , , , , , , , bool executed) = goldigov.proposals(1);

    assertEq(executed, true);
    assertEq(goldilend.protocolInterestRate(), 69);
  }

  function testChangeSlopeFailTimelock() public {
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(IGoldilend.NotTimelock.selector));
    goldilend.changeSlope(69);
  }

  function testChangeSlopeSuccess() public {
    bytes memory _calldata = abi.encodeWithSignature("changeSlope(uint256)", 69);
    address[] memory targets = new address[](1);
    targets[0] = address(goldilend);
    string[] memory signatures = new string[](1);
    signatures[0] = "";
    bytes[] memory calldatas = new bytes[](1);
    calldatas[0] = _calldata;
    uint256[] memory valuess = new uint256[](1);
    valuess[0] = 0;
    deal(address(goldiswap), address(this), quorumVotesNum);
    goldiswap.approve(address(govlocks), quorumVotesNum);
    govlocks.deposit(quorumVotesNum);
    govlocks.delegate(address(this));
    vm.roll(2);
    goldigov.propose(targets, valuess, signatures, calldatas, "");
    vm.roll(52600);
    goldigov.castVote(1, 1);
    vm.roll(200000);
    goldigov.queue(1);
    vm.warp(6 days);
    goldigov.execute(1);
    (, , , , , , , , , bool executed) = goldigov.proposals(1);

    assertEq(executed, true);
    assertEq(goldilend.slope(), 69);
  }

  function testChangeDurationsFailTimelock() public {
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(IGoldilend.NotTimelock.selector));
    goldilend.changeDurations(69, 69);
  }

  function testChangeDurationsSuccess() public {
    bytes memory _calldata = abi.encodeWithSignature("changeDurations(uint256,uint256)", 69, 69);
    address[] memory targets = new address[](1);
    targets[0] = address(goldilend);
    string[] memory signatures = new string[](1);
    signatures[0] = "";
    bytes[] memory calldatas = new bytes[](1);
    calldatas[0] = _calldata;
    uint256[] memory valuess = new uint256[](1);
    valuess[0] = 0;
    deal(address(goldiswap), address(this), quorumVotesNum);
    goldiswap.approve(address(govlocks), quorumVotesNum);
    govlocks.deposit(quorumVotesNum);
    govlocks.delegate(address(this));
    vm.roll(2);
    goldigov.propose(targets, valuess, signatures, calldatas, "");
    vm.roll(52600);
    goldigov.castVote(1, 1);
    vm.roll(200000);
    goldigov.queue(1);
    vm.warp(6 days);
    goldigov.execute(1);
    (, , , , , , , , , bool executed) = goldigov.proposals(1);

    assertEq(executed, true);
    assertEq(goldilend.minDuration(), 69);
    assertEq(goldilend.maxDuration(), 69);
  }

  function testChangeBorrowingActiveFailMultisig() public {
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(IGoldilend.NotMultisig.selector));
    goldilend.changeBorrowingActive(false);
  }

  function testChangeBorrowingActiveSuccess() public {
    goldilend.changeBorrowingActive(false);
    
    assertEq(goldilend.borrowingActive(), false);
  }

  function testInitializeParametersFailMultisig() public {
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(IGoldilend.NotMultisig.selector)); 
    goldilend.initializeParameters(
      45,
      5,
      7 days, 
      21 days,
      1e17,
      10
    );
  }

  function testInitalizeParametersFailAlready() public {
    vm.expectRevert(abi.encodeWithSelector(IGoldilend.AlreadyInitialized.selector)); 
    goldilend.initializeParameters(
      45,
      5,
      7 days, 
      21 days,
      1e17,
      10
    );
  }

  function testInitializeParametersSuccess() public {
    assertEq(goldilend.minDuration(), 7 days);
    assertEq(goldilend.maxDuration(), 365 days);
    assertEq(goldilend.poolSize(), 1000e18);
    assertEq(goldilend.protocolInterestRate(), 10e18);
    assertEq(goldilend.slope(), 10e18);
  }

  function testInitializeBerasFailMultisig() public {
    address[] memory nfts = new address[](2);
    nfts[0] = address(bondbear);
    nfts[1] = address(bandbear);
    uint256[] memory values = new uint256[](2);
    values[0] = 50;
    values[1] = 50;
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(IGoldilend.NotMultisig.selector)); 
    goldilend.initializeBeras(
      nfts,
      values
    );
  }

  function testInitializeBerasFailAlready() public {
    address[] memory nfts = new address[](2);
    nfts[0] = address(bondbear);
    nfts[1] = address(bandbear);
    uint256[] memory values = new uint256[](2);
    values[0] = 50;
    values[1] = 50;
    vm.expectRevert(abi.encodeWithSelector(IGoldilend.AlreadyInitialized.selector)); 
    goldilend.initializeBeras(
      nfts,
      values
    );
  }

  function testInitializeBerasSuccess() public {
    assertEq(goldilend.nftFairValues(address(bondbear)), 50);
    assertEq(goldilend.nftFairValues(address(bandbear)), 50);
  }

  function testNoFirstLockAdvantage() public {
    address alice = address(0xabcabc);
    address bob = address(0xabcabcabc);
    address carol = address(0xcbacba);
    vm.startPrank(alice);
    deal(address(goldilocked), alice, txAmount);
    goldilocked.approve(address(goldilend), txAmount);
    goldilend.lock(txAmount);
    vm.startPrank(bob);
    deal(address(goldilocked), bob, txAmount);
    goldilocked.approve(address(goldilend), txAmount);
    goldilend.lock(txAmount);
    vm.startPrank(carol);
    deal(address(goldilocked), carol, txAmount);
    goldilocked.approve(address(goldilend), txAmount);
    goldilend.lock(txAmount);

    assertEq(gprg.balanceOf(alice), txAmount);
    assertEq(gprg.balanceOf(bob), txAmount);
    assertEq(gprg.balanceOf(carol), txAmount);
  }

  function testBorrowAboveFairValue() public dealUseriBGT dealUserBeras {
    address[] memory nfts = new address[](1);
    nfts[0] = address(bondbear);
    uint256 maxDuration = goldilend.maxDuration();
    vm.expectRevert(abi.encodeWithSelector(IGoldilend.BorrowLimitExceeded.selector));
    goldilend.borrow(50e18, maxDuration, address(bondbear), 1);
  }

  function testBorrowFailTooManyLoans() public {
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    IERC721(bondbear).setApprovalForAll(address(goldilend), true);
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 1);
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 2);
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 3);
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 4);
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 5);
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 6);
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 7);
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 8);
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 9);
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 10);
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 11);
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 12);
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 13);
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 14);
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 15);
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 16);
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 17);
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 18);
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 19);
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 20);
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 21);
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 22);
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 23);
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 24);
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 25);
    vm.expectRevert(abi.encodeWithSelector(IGoldilend.TooManyLoans.selector));
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 26);
  }

  function testRepayLoanNumberTwoAndTwenty() public dealUseriBGT {
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    IERC721(bondbear).setApprovalForAll(address(goldilend), true);
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 1);
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 2);
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 3);
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 4);
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 5);
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 6);
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 7);
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 8);
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 9);
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 10);
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 11);
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 12);
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 13);
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 14);
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 15);
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 16);
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 17);
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 18);
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 19);
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 20);
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 21);
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 22);
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 23);
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 24);
    goldilend.borrow(1e18, goldilendDuration, address(bondbear), 25);
    goldilend.repay(10e18, 2);
    goldilend.repay(10e18, 20);
    Goldilend.Loan memory userLoanTwo = goldilend.lookupLoan(address(this), 2);
    Goldilend.Loan memory userLoanTwenty = goldilend.lookupLoan(address(this), 20);

    assertEq(IERC721(address(bondbear)).balanceOf(address(goldilend)), 23);
    assertEq(IERC721(address(bondbear)).balanceOf(address(this)), 2);
    assertEq(userLoanTwo.collateralNFTs[0], address(bondbear));
    assertEq(userLoanTwenty.collateralNFTs[0], address(bondbear));
    assertEq(userLoanTwo.collateralNFTIds[0], 2);
    assertEq(userLoanTwenty.collateralNFTIds[0], 20);
    assertEq(userLoanTwo.borrowedAmount, 0);
    assertEq(userLoanTwenty.borrowedAmount, 0);
    assertEq(userLoanTwo.interest, 0);
    assertEq(userLoanTwenty.interest, 0);
    assertEq(userLoanTwo.duration, goldilendDuration);
    assertEq(userLoanTwenty.duration, goldilendDuration);
    assertEq(userLoanTwo.endDate, block.timestamp + goldilendDuration);
    assertEq(userLoanTwenty.endDate, block.timestamp + goldilendDuration);
    assertEq(userLoanTwo.loanId, 2);
    assertEq(userLoanTwenty.loanId, 20);
  }

}