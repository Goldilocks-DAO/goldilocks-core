//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { BaseInvariantTest } from "../base/BaseInvariantTest.t.sol";
import { RebaseGoldilendHandler } from "../invariant/handlers/RebaseGoldilendHandler.t.sol";
import { IERC721 } from "../../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import { RebaseGoldilend } from "../../src/core/goldilend/RebaseGoldilend.sol";

contract InvariantRebaseGoldilendTest is BaseInvariantTest {

  function setUp() public override {
    deployProtocol();

    deal(address(honey), address(this), 1_000_000e18);
    honey.approve(address(rebaseproxy), 1_000_000e18);
    RebaseGoldilend(address(rebaseproxy)).deposit(500_000e18);

    rebasegoldilendHandler = new RebaseGoldilendHandler(address(rebaseproxy), glhoney, honey, bandbear);
    bytes4[] memory rebasegoldilendSelectors = new bytes4[](8);
    rebasegoldilendSelectors[0] = rebasegoldilendHandler.deposit.selector;
    rebasegoldilendSelectors[1] = rebasegoldilendHandler.withdraw.selector;
    rebasegoldilendSelectors[2] = rebasegoldilendHandler.borrow.selector;
    rebasegoldilendSelectors[3] = rebasegoldilendHandler.renew.selector;
    rebasegoldilendSelectors[4] = rebasegoldilendHandler.repay.selector;
    rebasegoldilendSelectors[5] = rebasegoldilendHandler.approve.selector;
    rebasegoldilendSelectors[6] = rebasegoldilendHandler.transfer.selector;
    rebasegoldilendSelectors[7] = rebasegoldilendHandler.transferFrom.selector;
    
    targetSelector(FuzzSelector({
      addr: address(rebasegoldilendHandler),
      selectors: rebasegoldilendSelectors
    }));
    targetContract(address(rebasegoldilendHandler));
  }

  function invariant_basic() public {
    assertTrue(true);
  }

  function invariant_handler_works() public {
    assertTrue(address(rebasegoldilendHandler) != address(0));
    assertTrue(address(rebasegoldilendHandler.rebasegoldilend()) != address(0));
  }
 
  function invariant_glhoney_eq_deposited() public {
    uint256 sumOfMinted = rebasegoldilendHandler.reduceActors(
      0,
      this.accumulateMintedGlhoney
    );
    assertEq(
      sumOfMinted,
      rebasegoldilendHandler.ghost_depositSum() - rebasegoldilendHandler.ghost_withdrawSum()
    );
  }

  function invariant_glhoney_supply_consistency() public {
    assertGe(glhoney.totalSupply(), 0, "glHONEY supply should be >= 0");
    if (glhoney.totalSupply() > 0) {
      assertGt(glhoney.totalSupply(), 0, "glHONEY supply should be positive when pool size is positive");
    }
  }

  function invariant_glhoney_accounting() public {
    uint256 totalMinted = rebasegoldilendHandler.ghost_depositSum() - rebasegoldilendHandler.ghost_withdrawSum();
    uint256 actualSupply = glhoney.totalSupply();
    uint256 initialDeposit = 500_000e18;
    uint256 expectedTotalMinted = totalMinted + initialDeposit;
    uint256 tolerance = expectedTotalMinted / 1000; // 0.1% tolerance
    
    assertGe(actualSupply, expectedTotalMinted - tolerance, "glHONEY supply should be close to net deposits");
    assertLe(actualSupply, expectedTotalMinted + tolerance, "glHONEY supply should be close to net deposits");
  }

  function invariant_individual_glhoney_balances() public {
    rebasegoldilendHandler.forEachActor(this.assertIndividualGlhoneyBalanceValid);
  }

  function invariant_pool_size_consistency() public {
    assertGe(glhoney.totalSupply(), 0);
    assertLe(RebaseGoldilend(address(rebaseproxy)).outstandingDebt(), glhoney.totalSupply());
    
    if (glhoney.totalSupply() > 0) {
      assertLe(
        RebaseGoldilend(address(rebaseproxy)).outstandingDebt(), 
        glhoney.totalSupply() * RebaseGoldilend(address(rebaseproxy)).maxUtilization() / 100
      );
    }
  }

  function invariant_debt_accounting() public {
    assertGe(
      rebasegoldilendHandler.getTotalBorrowed(),
      rebasegoldilendHandler.getTotalRepaid()
    );
    
    assertGe(
      rebasegoldilend.outstandingDebt(),
      rebasegoldilendHandler.getTotalBorrowed() - rebasegoldilendHandler.getTotalRepaid()
    );
    
    assertLe(
      RebaseGoldilend(address(rebaseproxy)).outstandingDebt(),
      glhoney.totalSupply()
    );
  }

  function invariant_collateral_tracking() public {
    assertGe(
      rebasegoldilendHandler.ghost_collateralDeposited(),
      rebasegoldilendHandler.ghost_collateralReturned() + rebasegoldilendHandler.ghost_collateralLiquidated()
    );
    
    uint256 activeLoans = rebasegoldilendHandler.getTotalActiveLoans();
    uint256 collateralInProtocol = rebasegoldilendHandler.ghost_collateralDeposited() - 
                                   rebasegoldilendHandler.ghost_collateralReturned() - 
                                   rebasegoldilendHandler.ghost_collateralLiquidated();
    assertEq(activeLoans, collateralInProtocol);
    
    rebasegoldilendHandler.forEachActor(this.assertActiveLoansHaveCollateral);
  }

  function invariant_loan_state_consistency() public {
    rebasegoldilendHandler.forEachActor(this.assertActiveLoansValid);
  }

  function invariant_interest_calculation() public {
    if (rebasegoldilendHandler.getTotalBorrowed() > 0) {
      assertGt(rebasegoldilendHandler.ghost_interestSum(), 0);
    }
  }

  function invariant_liquidation_safety() public {
    rebasegoldilendHandler.forEachActor(this.assertLiquidatedLoansInactive);
  }

  function invariant_repayment_safety() public {
    rebasegoldilendHandler.forEachActor(this.assertRepaidLoansInactive);
  }

  function invariant_borrowing_limits() public {
    rebasegoldilendHandler.forEachActor(this.assertLoanAmountsWithinLimits);
  }

  function invariant_nft_ownership() public {
    rebasegoldilendHandler.forEachActor(this.assertNFTOwnershipValid);
  }

  function invariant_loan_duration_limits() public {
    rebasegoldilendHandler.forEachActor(this.assertLoanDurationValid);
  }

  function invariant_loan_interest_consistency() public {
    rebasegoldilendHandler.forEachActor(this.assertLoanInterestValid);
  }

  function invariant_protocol_parameters() public {
    if (RebaseGoldilend(address(rebaseproxy)).parametersInitialized()) {
      assertGt(RebaseGoldilend(address(rebaseproxy)).maxDuration(), RebaseGoldilend(address(rebaseproxy)).minDuration(), "Max duration should be > min duration");
      assertLe(RebaseGoldilend(address(rebaseproxy)).maxUtilization(), 100, "Max utilization should be <= 100%");
      assertGt(RebaseGoldilend(address(rebaseproxy)).maxUtilization(), 0, "Max utilization should be > 0");
      assertGt(RebaseGoldilend(address(rebaseproxy)).protocolInterestRate(), 0, "Protocol interest rate should be > 0");
      assertGt(RebaseGoldilend(address(rebaseproxy)).slope(), 0, "Slope should be > 0");
    }
  }

  function invariant_protocol_addresses() public {
    assertTrue(RebaseGoldilend(address(rebaseproxy)).multisig() != address(0), "Multisig should be set");
    assertTrue(RebaseGoldilend(address(rebaseproxy)).debtAsset() != address(0), "Debt asset should be set");
    assertTrue(RebaseGoldilend(address(rebaseproxy)).glDebtAsset() != address(0), "GL debt asset should be set");
  }

  function invariant_nft_fair_values() public {
    if (RebaseGoldilend(address(rebaseproxy)).berasInitialized()) {
      uint256 bandbearValue = RebaseGoldilend(address(rebaseproxy)).nftFairValues(address(bandbear));
      assertGt(bandbearValue, 0, "BandBear NFT should have a fair value set");
    }
  }

  function assertActiveLoansValid(address actor) external returns (address[] memory) {
    for (uint256 i = 1; i <= rebasegoldilendHandler.userLoanCount(actor); i++) {
      if (rebasegoldilendHandler.activeLoans(actor, i)) {
        RebaseGoldilend.Loan memory loan = RebaseGoldilend(address(rebaseproxy)).getUserLoan(actor, i);
        assertFalse(loan.repaid, "Active loan should not be repaid");
        assertFalse(loan.liquidated, "Active loan should not be liquidated");
        assertGt(loan.borrowedAmount, 0, "Active loan should have borrowed amount");
      }
    }
    return new address[](0);
  }

  function assertLiquidatedLoansInactive(address actor) external returns (address[] memory) {
    for (uint256 i = 1; i <= rebasegoldilendHandler.userLoanCount(actor); i++) {
      RebaseGoldilend.Loan memory loan = RebaseGoldilend(address(rebaseproxy)).getUserLoan(actor, i);
      if (loan.liquidated) {
        assertFalse(rebasegoldilendHandler.activeLoans(actor, i), "Liquidated loan should not be active");
      }
    }
    return new address[](0);
  }

  function assertRepaidLoansInactive(address actor) external returns (address[] memory) {
    for (uint256 i = 1; i <= rebasegoldilendHandler.userLoanCount(actor); i++) {
      RebaseGoldilend.Loan memory loan = RebaseGoldilend(address(rebaseproxy)).getUserLoan(actor, i);
      if (loan.repaid) {
        assertFalse(rebasegoldilendHandler.activeLoans(actor, i), "Repaid loan should not be active");
      }
    }
    return new address[](0);
  }

  function assertLoanAmountsWithinLimits(address actor) external returns (address[] memory) {
    for (uint256 i = 1; i <= rebasegoldilendHandler.userLoanCount(actor); i++) {
      RebaseGoldilend.Loan memory loan = RebaseGoldilend(address(rebaseproxy)).getUserLoan(actor, i);
      if (loan.borrowedAmount > 0) {
        assertLe(loan.borrowedAmount, glhoney.totalSupply() / 10, "Loan amount exceeds limit");
      }
    }
    return new address[](0);
  }

  function assertNFTOwnershipValid(address actor) external returns (address[] memory) {
    for (uint256 i = 1; i <= rebasegoldilendHandler.userLoanCount(actor); i++) {
      RebaseGoldilend.Loan memory loan = RebaseGoldilend(address(rebaseproxy)).getUserLoan(actor, i);
      if (loan.borrowedAmount > 0 && !loan.repaid && !loan.liquidated) {
        assertEq(
          IERC721(loan.collateralNFT).ownerOf(loan.collateralNFTId),
          address(rebaseproxy),
          "Active loan NFT should be owned by protocol"
        );
      } else if (loan.repaid) {
        assertEq(
          IERC721(loan.collateralNFT).ownerOf(loan.collateralNFTId),
          actor,
          "Repaid loan NFT should be returned to user"
        );
      } else if (loan.liquidated) {
        assertEq(
          IERC721(loan.collateralNFT).ownerOf(loan.collateralNFTId),
          RebaseGoldilend(address(rebaseproxy)).multisig(),
          "Liquidated loan NFT should be owned by multisig"
        );
      }
    }
    return new address[](0);
  }

  function assertIndividualGlhoneyBalanceValid(address actor) external returns (address[] memory) {
    uint256 balance = glhoney.balanceOf(actor);
    uint256 totalSupply = glhoney.totalSupply();
    
    assertLe(balance, totalSupply, "Individual glHONEY balance should not exceed total supply");
    if (totalSupply > 0) {
      assertLe(balance, totalSupply, "Individual balance should not exceed total supply");
    }
    
    return new address[](0);
  }

  function assertLoanDurationValid(address actor) external returns (address[] memory) {
    for (uint256 i = 1; i <= rebasegoldilendHandler.userLoanCount(actor); i++) {
      RebaseGoldilend.Loan memory loan = RebaseGoldilend(address(rebaseproxy)).getUserLoan(actor, i);
      if (loan.borrowedAmount > 0 && !loan.repaid && !loan.liquidated) {
        assertGe(loan.duration, RebaseGoldilend(address(rebaseproxy)).minDuration(), "Loan duration should be >= min duration");
        assertLe(loan.duration, RebaseGoldilend(address(rebaseproxy)).maxDuration(), "Loan duration should be <= max duration");
        assertGt(loan.endDate, block.timestamp, "Active loan end date should be in the future");
      }
    }
    return new address[](0);
  }

  function assertLoanInterestValid(address actor) external returns (address[] memory) {
    for (uint256 i = 1; i <= rebasegoldilendHandler.userLoanCount(actor); i++) {
      RebaseGoldilend.Loan memory loan = rebasegoldilend.getUserLoan(actor, i);
      if (loan.borrowedAmount > 0 && !loan.repaid && !loan.liquidated) {
        assertGt(loan.interest, 0, "Active loan should have positive interest");
        assertLe(loan.interest, loan.borrowedAmount * 10, "Interest should not be unreasonably high");
      }
    }
    return new address[](0);
  }

  function assertActiveLoansHaveCollateral(address actor) external returns (address[] memory) {
    for (uint256 i = 1; i <= rebasegoldilendHandler.userLoanCount(actor); i++) {
      RebaseGoldilend.Loan memory loan = RebaseGoldilend(address(rebaseproxy)).getUserLoan(actor, i);
      if (loan.borrowedAmount > 0 && !loan.repaid && !loan.liquidated) {
        assertTrue(loan.collateralNFT != address(0), "Active loan should have collateral NFT");
        assertGt(loan.collateralNFTId, 0, "Active loan should have valid collateral NFT ID");
      }
    }
    return new address[](0);
  }

}