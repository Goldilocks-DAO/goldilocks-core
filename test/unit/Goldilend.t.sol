//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { BaseUnitTest } from "../base/BaseUnitTest.t.sol";
import { IERC721 } from "../../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import { OwnableUpgradeable } from "../../lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import { INFT } from "../../src/mock/INFT.sol";
import { Goldilend } from "../../src/core/goldilend/Goldilend.sol";
import { IGoldilend } from "../../src/interfaces/IGoldilend.sol";

contract TestUpgradeableGoldilend is Goldilend {
  uint256 public specialNumber;

  function setSpecialNumber() public {
    specialNumber = 69;
  }
}

contract UnitGoldilendTest is BaseUnitTest {

  function testLookupLoans() public dealUserBeras {
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 1);
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bandbear), 1);
    Goldilend.Loan[] memory userLoans = Goldilend(address(proxy)).lookupLoans(address(this));

    assertEq(userLoans[0].collateralNFTs[0], address(bondbear));
    assertEq(userLoans[0].collateralNFTIds[0], 1);
    assertEq(userLoans[0].borrowedAmount, 1e18 + borrowInterest);
    assertEq(userLoans[1].collateralNFTs[0], address(bandbear));
    assertEq(userLoans[1].collateralNFTIds[0], 1);
    assert(userLoans[1].borrowedAmount > 1e18 + borrowInterest);
  }

  function testLookupLoan() public dealUserBeras {
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 1);
    Goldilend.Loan memory userLoan = Goldilend(address(proxy)).lookupLoan(address(this), 1);

    assertEq(userLoan.collateralNFTs[0], address(bondbear));
    assertEq(userLoan.collateralNFTIds[0], 1);
    assertEq(userLoan.borrowedAmount, 1e18 + borrowInterest);
  }

  function testGetGPRGRatio() public {
    deal(address(goldilocked), address(this), txAmount);
    goldilocked.approve(address(proxy), txAmount);
    Goldilend(address(proxy)).lock(txAmount);

    assertEq(Goldilend(address(proxy)).getGPRGRatio(), 1e18);
  }

  function testCalculateInterestFailDuration() public {
    vm.expectRevert(abi.encodeWithSelector(IGoldilend.InvalidDuration.selector));
    Goldilend(address(proxy)).calculateInterest(1e18, 1, address(bondbear));
  }

  function testCalculateInterestFailAmount() public {
    vm.expectRevert(abi.encodeWithSelector(IGoldilend.InvalidLoanAmount.selector));
    Goldilend(address(proxy)).calculateInterest(1e50, goldilendDuration, address(bondbear));
  }

  function testCalculateInterestFailCollateral() public {
    vm.expectRevert(abi.encodeWithSelector(IGoldilend.InvalidCollateral.selector));
    Goldilend(address(proxy)).calculateInterest(1e18, goldilendDuration, address(0x69));
  }

  function testCalculateInterestFailLimit() public {
    vm.expectRevert(abi.encodeWithSelector(IGoldilend.BorrowLimitExceeded.selector));
    Goldilend(address(proxy)).calculateInterest(51e18, goldilendDuration, address(bondbear));
  }

  function testCalculateInterestSuccess() public {
    uint256 interest = Goldilend(address(proxy)).calculateInterest(1e18, goldilendDuration, address(bondbear));

    assertEq(interest, borrowInterest);
  }

  function testLockSuccess() public {
    deal(address(goldilocked), address(this), txAmount);
    goldilocked.approve(address(proxy), txAmount);
    Goldilend(address(proxy)).lock(txAmount);

    assertEq(gprg.balanceOf(address(this)), 1000e18 + txAmount);
    assertEq(goldilocked.balanceOf(address(this)), 0);
    assertEq(goldilocked.balanceOf(address(proxy)), 1000e18 + txAmount);
    assertEq(Goldilend(address(proxy)).poolSize(), 1000e18 + txAmount);
  }

  function testUnlockFailPRG() public {
    deal(address(goldilocked), address(this), txAmount);
    goldilocked.approve(address(proxy), txAmount);
    Goldilend(address(proxy)).lock(txAmount);
    vm.store(address(proxy), bytes32(uint256(7)), bytes32(Goldilend(address(proxy)).poolSize()));
    vm.expectRevert(abi.encodeWithSelector(IGoldilend.InsufficientPRG.selector));
    Goldilend(address(proxy)).unlock(txAmount);
  }

  function testUnlockSuccess() public {
    deal(address(goldilocked), address(this), txAmount);
    goldilocked.approve(address(proxy), txAmount);
    Goldilend(address(proxy)).lock(txAmount);
    Goldilend(address(proxy)).unlock(txAmount);

    assertEq(gprg.balanceOf(address(this)), 1000e18);
    assertEq(goldilocked.balanceOf(address(this)), txAmount);
    assertEq(goldilocked.balanceOf(address(proxy)), 1000e18);
    assertEq(Goldilend(address(proxy)).poolSize(), 1000e18);
  }

  function testLockLock() public {
    // deal(address(goldilocked), address(this), txAmount);
    // goldilocked.approve(address(proxy), txAmount);
    // Goldilend(address(proxy)).lock(txAmount);
    // deal(address(goldilocked), address(0xabc), txAmount);
    // vm.prank(address(0xabc));
    // goldilocked.approve(address(proxy), txAmount);
    // vm.prank(address(0xabc));
    // Goldilend(address(proxy)).lock(txAmount);

    // assertEq(gprg.balanceOf(address(this)), 1000e18 + txAmount);
    // assertEq(gprg.balanceOf(address(0xabc)), txAmount);
    // assertEq(goldilocked.balanceOf(address(this)), 0);
    // assertEq(goldilocked.balanceOf(address(proxy)), 0);
    // assertEq(goldilocked.balanceOf(address(ibgtvault)), (type(uint256).max / 2) + txAmount+txAmount);
    // assertEq(Goldilend(address(proxy)).poolSize(), 1000e18 + txAmount+txAmount);
  }

  function testLockHalf() public {
    // vm.store(address(proxy), bytes32(uint256(4)), bytes32(uint256(100e18)));
    // vm.store(address(proxy), bytes32(uint256(0x05345cdf77eb68f44c)), bytes32(uint256(50e18)));
    // deal(address(goldilocked), address(this), txAmount);
    // goldilocked.approve(address(proxy), txAmount);
    // Goldilend(address(proxy)).lock(txAmount);

    // assertEq(gprg.balanceOf(address(this)), 1000e18 + (txAmount / 2));
    // assertEq(goldilocked.balanceOf(address(this)), 0);
    // assertEq(goldilocked.balanceOf(address(proxy)), 0);
    // assertEq(goldilocked.balanceOf(address(ibgtvault)), (type(uint256).max / 2) + txAmount);
    // assertEq(Goldilend(address(proxy)).poolSize(), 100e18 + txAmount);
  }

  function testLockDouble() public {
    // vm.store(address(proxy), bytes32(uint256(8)), bytes32(uint256(50e18)));
    // vm.store(address(proxy), bytes32(uint256(0x05345cdf77eb68f44c)), bytes32(uint256(100e18)));
    // deal(address(goldilocked), address(this), txAmount);
    // goldilocked.approve(address(proxy), txAmount);
    // Goldilend(address(proxy)).lock(txAmount);

    // assertEq(gprg.balanceOf(address(this)), 1000e18 + (txAmount * 2));
    // assertEq(goldilocked.balanceOf(address(this)), 0);
    // assertEq(goldilocked.balanceOf(address(proxy)), 0);
    // assertEq(Goldilend(address(proxy)).poolSize(), 50e18 + txAmount);
  }

  function testBorrowFailActive() public {
    Goldilend(address(proxy)).changeBorrowingActive(false);
    vm.expectRevert(abi.encodeWithSelector(IGoldilend.NotActive.selector));
    Goldilend(address(proxy)).borrow(69, 69, address(0x69), 69);
  }

  function testBorrowFailDuration() public {
    vm.expectRevert(abi.encodeWithSelector(IGoldilend.InvalidDuration.selector));
    Goldilend(address(proxy)).borrow(69, 69, address(0x69), 69);
  }

  function testBorrowFailAmount() public {
    vm.expectRevert(abi.encodeWithSelector(IGoldilend.InvalidLoanAmount.selector));
    Goldilend(address(proxy)).borrow(690000e18, 8 days, address(0x69), 69);
  }

  function testBorrowFailCollateral() public {
    vm.expectRevert(abi.encodeWithSelector(IGoldilend.InvalidCollateral.selector));
    Goldilend(address(proxy)).borrow(69, 8 days, address(0x69), 69);
  }

  function testBorrowFailLimit() public {
    vm.expectRevert(abi.encodeWithSelector(IGoldilend.BorrowLimitExceeded.selector));
    Goldilend(address(proxy)).borrow(51e18, 8 days, address(bondbear), 69);
  }

  function testBorrowSuccess() public dealUserBeras {
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 1);
    Goldilend.Loan memory userLoan = Goldilend(address(proxy)).lookupLoan(address(this), 1);

    assertEq(userLoan.collateralNFTs[0], address(bondbear));
    assertEq(userLoan.collateralNFTIds[0], 1);
    assertEq(userLoan.borrowedAmount, 1e18 + borrowInterest);
    assertEq(userLoan.interest, borrowInterest);
    assertEq(userLoan.duration, goldilendDuration);
    assertEq(userLoan.endDate, block.timestamp + goldilendDuration);
    assertEq(userLoan.loanId, 1);
    assertEq(userLoan.liquidated, false);
  }

  function testRepayFailExpired() public dealUserBeras {
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 1);
    vm.warp(69e18);
    vm.expectRevert(abi.encodeWithSelector(IGoldilend.LoanExpired.selector));
    Goldilend(address(proxy)).repay(1e18, 1);
  }

  function testRepayFailLoanNotFound() public {
    vm.expectRevert(abi.encodeWithSelector(IGoldilend.LoanNotFound.selector));
    Goldilend(address(proxy)).repay(1e18, 1);
  }

  function testRepaySuccess() public dealUserPRG dealUserBeras {
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 1);
    Goldilend.Loan memory userLoanBefore = Goldilend(address(proxy)).lookupLoan(address(this), 1);
    Goldilend(address(proxy)).repay(1e18+userLoanBefore.interest, 1);
    Goldilend.Loan memory userLoan = Goldilend(address(proxy)).lookupLoan(address(this), 1);

    assertEq(IERC721(address(bondbear)).balanceOf(address(proxy)), 0);
    assertEq(IERC721(address(bondbear)).balanceOf(address(this)), 1);
    assertEq(userLoan.collateralNFTs[0], address(bondbear));
    assertEq(userLoan.collateralNFTIds[0], 1);
    assertEq(userLoan.borrowedAmount, 0);
    assertEq(userLoan.interest, 0);
    assertEq(userLoan.duration, goldilendDuration);
    assertEq(userLoan.endDate, block.timestamp + goldilendDuration);
    assertEq(userLoan.loanId, 1);
    assertEq(userLoan.liquidated, false);
    assertEq(Goldilend(address(proxy)).outstandingDebt(), 0);
    assertEq(Goldilend(address(proxy)).poolSize(), 1000e18 + (userLoanBefore.interest * 950 / 1000));
  }

  function testRepayHalfSuccess() public dealUserPRG dealUserBeras {
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 1);
    Goldilend.Loan memory userLoanBefore = Goldilend(address(proxy)).lookupLoan(address(this), 1);
    Goldilend(address(proxy)).repay((1e18+userLoanBefore.interest) / 2, 1);
    Goldilend.Loan memory userLoan = Goldilend(address(proxy)).lookupLoan(address(this), 1);

    assertEq(IERC721(address(bondbear)).balanceOf(address(proxy)), 1);
    assertEq(IERC721(address(bondbear)).balanceOf(address(this)), 0);
    assertEq(userLoan.collateralNFTs[0], address(bondbear));
    assertEq(userLoan.collateralNFTIds[0], 1);
    assertEq(userLoan.borrowedAmount, ((1e18+userLoanBefore.interest) / 2));
    assertEq(userLoan.interest, userLoanBefore.interest / 2);
    assertEq(userLoan.duration, goldilendDuration);
    assertEq(userLoan.endDate, block.timestamp + goldilendDuration);
    assertEq(userLoan.loanId, 1);
    assertEq(userLoan.liquidated, false);
    assertEq(Goldilend(address(proxy)).outstandingDebt(), 5e17);
  }

  function testLiquidateFailUnliquidatable() public dealUserPRG dealUserBeras {
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 1);
    vm.warp(1);
    vm.expectRevert(abi.encodeWithSelector(IGoldilend.Unliquidatable.selector));
    Goldilend(address(proxy)).liquidate(address(this), 1);
  }
  
  function testLiquidateSuccess() public dealUserPRG dealUserBeras {
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 1);
    vm.warp(1209602 + 86401);
    Goldilend(address(proxy)).liquidate(address(this), 1);
    Goldilend.Loan memory userLoan = Goldilend(address(proxy)).lookupLoan(address(this), 1);    

    assertEq(userLoan.collateralNFTs[0], address(bondbear));
    assertEq(userLoan.collateralNFTIds[0], 1);
    assertEq(userLoan.borrowedAmount, 0);
    assertEq(userLoan.duration, goldilendDuration);
    assertEq(userLoan.endDate, 1209601);
    assertEq(userLoan.loanId, 1);
    assertEq(userLoan.liquidated, true);
    assertEq(IERC721(address(bondbear)).balanceOf(address(proxy)), 0);
    assertEq(IERC721(address(bondbear)).balanceOf(address(this)), 1);
  }

  function testLiquidateMultisigLiquidate() public dealUserPRG dealUserBeras {
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 1);
    vm.warp(68e18);
    Goldilend(address(proxy)).liquidate(address(this), 1);
    Goldilend.Loan memory userLoan = Goldilend(address(proxy)).lookupLoan(address(this), 1);
    
    assertEq(Goldilend(address(proxy)).poolSize(), 1000e18);
    assertEq(userLoan.collateralNFTs[0], address(bondbear));
    assertEq(userLoan.collateralNFTIds[0], 1);
    assertEq(userLoan.borrowedAmount, 0);
    assertEq(userLoan.duration, goldilendDuration);
    assertEq(userLoan.endDate, 1209601);
    assertEq(userLoan.loanId, 1);
    assertEq(userLoan.liquidated, true);
    assertEq(IERC721(address(bondbear)).balanceOf(address(proxy)), 0);
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
    Goldilend(address(proxy)).changeValue(nfts, values);
  }

  function testChangeValueFailArray() public {
    address[] memory nfts = new address[](2);
    nfts[0] = address(bondbear);
    nfts[1] = address(bandbear);
    uint256[] memory values = new uint256[](1);
    values[0] = 50;
    vm.expectRevert(abi.encodeWithSelector(IGoldilend.ArrayMismatch.selector));
    Goldilend(address(proxy)).changeValue(nfts, values);
  }

  function testChangeValueSuccess() public {
    address[] memory nfts = new address[](2);
    nfts[0] = address(bondbear);
    nfts[1] = address(bandbear);
    uint256[] memory values = new uint256[](2);
    values[0] = 50;
    values[1] = 50;
    Goldilend(address(proxy)).changeValue(nfts, values);    

    assertEq(Goldilend(address(proxy)).nftFairValues(address(bondbear)), 50);
    assertEq(Goldilend(address(proxy)).nftFairValues(address(bandbear)), 50);
  }

  function testChangeProtocolInterestRateFailTimelock() public {
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(IGoldilend.NotTimelock.selector));
    Goldilend(address(proxy)).changeProtocolInterestRate(69);
  }

  function testChangeProtocolInterestRateSuccess() public {
    bytes memory _calldata = abi.encodeWithSignature("changeProtocolInterestRate(uint256)", 69);
    address[] memory targets = new address[](1);
    targets[0] = address(proxy);
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
    assertEq(Goldilend(address(proxy)).protocolInterestRate(), 69);
  }

  function testChangeShareRatesFailTimelock() public {
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(IGoldilend.NotTimelock.selector));
    Goldilend(address(proxy)).changeShareRates(69, 69);
  }

  function testChangeShareRatesSuccess() public {
    bytes memory _calldata = abi.encodeWithSignature("changeShareRates(uint256,uint256)", 69, 69);
    address[] memory targets = new address[](1);
    targets[0] = address(proxy);
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
    assertEq(Goldilend(address(proxy)).multisigShare(), 69);
    assertEq(Goldilend(address(proxy)).apdaoShare(), 69);
  }

  function testChangeSlopeFailTimelock() public {
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(IGoldilend.NotTimelock.selector));
    Goldilend(address(proxy)).changeSlope(69);
  }

  function testChangeSlopeSuccess() public {
    bytes memory _calldata = abi.encodeWithSignature("changeSlope(uint256)", 69);
    address[] memory targets = new address[](1);
    targets[0] = address(proxy);
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
    assertEq(Goldilend(address(proxy)).slope(), 69);
  }

  function testChangeDurationsFailTimelock() public {
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(IGoldilend.NotTimelock.selector));
    Goldilend(address(proxy)).changeDurations(69, 69);
  }

  function testChangeDurationsSuccess() public {
    bytes memory _calldata = abi.encodeWithSignature("changeDurations(uint256,uint256)", 69, 69);
    address[] memory targets = new address[](1);
    targets[0] = address(proxy);
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
    assertEq(Goldilend(address(proxy)).minDuration(), 69);
    assertEq(Goldilend(address(proxy)).maxDuration(), 69);
  }

  function testChangeBorrowingActiveFailMultisig() public {
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(IGoldilend.NotMultisig.selector));
    Goldilend(address(proxy)).changeBorrowingActive(false);
  }

  function testChangeBorrowingActiveSuccess() public {
    Goldilend(address(proxy)).changeBorrowingActive(false);
    
    assertEq(Goldilend(address(proxy)).borrowingActive(), false);
  }

  function testMultisigInterestClaimFailMultisig() public {
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(IGoldilend.NotMultisig.selector));
    Goldilend(address(proxy)).multisigInterestClaim();
  }

  function testMultisigInterestClaimSuccess() public {
    deal(address(goldilocked), address(proxy), 5e18);
    vm.store(address(proxy), bytes32(uint256(12)), bytes32(uint256(5e18)));
    Goldilend(address(proxy)).multisigInterestClaim();

    assertEq(goldilocked.balanceOf(address(this)), 5e18 + prgMintAmount);
    assertEq(goldilocked.balanceOf(address(proxy)), 0);
  }

  function testApdaoInterestClaimFailApdao() public {
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(IGoldilend.NotAPDAO.selector));
    Goldilend(address(proxy)).apdaoInterestClaim();
  }

  function testApdaoInterestClaimSuccess() public {
    deal(address(goldilocked), address(proxy), 5e18);
    vm.store(address(proxy), bytes32(uint256(13)), bytes32(uint256(5e18)));
    vm.prank(apdao);
    Goldilend(address(proxy)).apdaoInterestClaim();

    assertEq(goldilocked.balanceOf(apdao), 5e18);
    assertEq(goldilocked.balanceOf(address(proxy)), 0);
  }

  function testInitializeParametersFailMultisig() public {
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(IGoldilend.NotMultisig.selector)); 
    Goldilend(address(proxy)).initializeParameters(
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
    Goldilend(address(proxy)).initializeParameters(
      45,
      5,
      7 days, 
      21 days,
      1e17,
      10
    );
  }

  function testInitializeParametersSuccess() public {
    assertEq(Goldilend(address(proxy)).minDuration(), 7 days);
    assertEq(Goldilend(address(proxy)).maxDuration(), 365 days);
    assertEq(Goldilend(address(proxy)).poolSize(), 1000e18);
    assertEq(Goldilend(address(proxy)).protocolInterestRate(), 10e18);
    assertEq(Goldilend(address(proxy)).slope(), 10e18);
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
    Goldilend(address(proxy)).initializeBeras(
      nfts,
      values
    );
  }

  function testInitializeBerasFailArray() public {
    address[] memory nfts = new address[](2);
    nfts[0] = address(bondbear);
    nfts[1] = address(bandbear);
    uint256[] memory values = new uint256[](1);
    values[0] = 50;
    vm.expectRevert(abi.encodeWithSelector(IGoldilend.ArrayMismatch.selector)); 
    Goldilend(address(proxy)).initializeBeras(
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
    Goldilend(address(proxy)).initializeBeras(
      nfts,
      values
    );
  }

  function testInitializeBerasSuccess() public {
    assertEq(Goldilend(address(proxy)).nftFairValues(address(bondbear)), 50e18);
    assertEq(Goldilend(address(proxy)).nftFairValues(address(bandbear)), 50e18);
  }

  function testNoFirstLockAdvantage() public {
    address alice = address(0xabcabc);
    address bob = address(0xabcabcabc);
    address carol = address(0xcbacba);
    vm.startPrank(alice);
    deal(address(goldilocked), alice, txAmount);
    goldilocked.approve(address(proxy), txAmount);
    Goldilend(address(proxy)).lock(txAmount);
    vm.startPrank(bob);
    deal(address(goldilocked), bob, txAmount);
    goldilocked.approve(address(proxy), txAmount);
    Goldilend(address(proxy)).lock(txAmount);
    vm.startPrank(carol);
    deal(address(goldilocked), carol, txAmount);
    goldilocked.approve(address(proxy), txAmount);
    Goldilend(address(proxy)).lock(txAmount);

    assertEq(gprg.balanceOf(alice), txAmount);
    assertEq(gprg.balanceOf(bob), txAmount);
    assertEq(gprg.balanceOf(carol), txAmount);
  }

  function testBorrowAboveFairValue() public dealUserPRG dealUserBeras {
    address[] memory nfts = new address[](1);
    nfts[0] = address(bondbear);
    uint256 maxDuration = Goldilend(address(proxy)).maxDuration();
    vm.expectRevert(abi.encodeWithSelector(IGoldilend.BorrowLimitExceeded.selector));
    Goldilend(address(proxy)).borrow(50e18, maxDuration, address(bondbear), 1);
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
    IERC721(bondbear).setApprovalForAll(address(proxy), true);
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 1);
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 2);
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 3);
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 4);
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 5);
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 6);
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 7);
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 8);
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 9);
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 10);
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 11);
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 12);
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 13);
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 14);
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 15);
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 16);
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 17);
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 18);
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 19);
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 20);
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 21);
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 22);
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 23);
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 24);
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 25);
    vm.expectRevert(abi.encodeWithSelector(IGoldilend.TooManyLoans.selector));
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 26);
  }

  function testRepayLoanNumberTwoAndTwenty() public dealUserPRG {
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
    IERC721(bondbear).setApprovalForAll(address(proxy), true);
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 1);
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 2);
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 3);
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 4);
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 5);
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 6);
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 7);
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 8);
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 9);
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 10);
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 11);
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 12);
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 13);
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 14);
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 15);
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 16);
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 17);
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 18);
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 19);
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 20);
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 21);
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 22);
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 23);
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 24);
    Goldilend(address(proxy)).borrow(1e18, goldilendDuration, address(bondbear), 25);
    Goldilend(address(proxy)).repay(10e18, 2);
    Goldilend(address(proxy)).repay(10e18, 20);
    Goldilend.Loan memory userLoanTwo = Goldilend(address(proxy)).lookupLoan(address(this), 2);
    Goldilend.Loan memory userLoanTwenty = Goldilend(address(proxy)).lookupLoan(address(this), 20);

    assertEq(IERC721(address(bondbear)).balanceOf(address(proxy)), 23);
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

  function testRecoverTokensFailMultisig() public {
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(IGoldilend.NotMultisig.selector));
    Goldilend(address(proxy)).recoverTokens(address(0x69));
  }

  function testRecoverTokensSuccess() public {
    deal(address(goldilocked), address(proxy), 5e18);
    Goldilend(address(proxy)).recoverTokens(address(goldilocked));

    assertEq(goldilocked.balanceOf(address(this)), 5e18 + prgMintAmount);
    assertEq(goldilocked.balanceOf(address(proxy)), 0);
  }

  function testOnERC721Received() public {
    INFT(address(bandbear)).mint(address(proxy));

    assert(IERC721(bandbear).balanceOf(address(proxy)) > 0);
  }

  function testUpgradeGoldilendFailOwner() public {
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, address(0x69)));
    Goldilend(address(proxy)).upgradeToAndCall(address(0x69), "");
  }

  function testUpgradeGoldilendSuccess() public {
    TestUpgradeableGoldilend newGoldilend = new TestUpgradeableGoldilend();
    bytes memory data = abi.encodeWithSelector(TestUpgradeableGoldilend.setSpecialNumber.selector);
    Goldilend(address(proxy)).upgradeToAndCall(address(newGoldilend), data);

    assertEq(TestUpgradeableGoldilend(address(proxy)).specialNumber(), 69);
    assertEq(TestUpgradeableGoldilend(address(proxy)).multisig(), address(this));
  }
}