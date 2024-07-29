//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { BaseInvariantTest } from "../base/BaseInvariantTest.t.sol";
import { GovLocksHandler } from "../invariant/handlers/GovLocksHandler.t.sol";

contract InvariantGovLocksTest is BaseInvariantTest {
  
  function setUp() public override {
    deployProtocol();

    govlocksHandler = new GovLocksHandler(govlocks, goldiswap);
    bytes4[] memory govLocksSelectors = new bytes4[](6);
    govLocksSelectors[0] = govlocksHandler.deposit.selector;
    govLocksSelectors[1] = govlocksHandler.withdraw.selector;
    govLocksSelectors[2] = govlocksHandler.delegate.selector;
    govLocksSelectors[3] = govlocksHandler.approve.selector;
    govLocksSelectors[4] = govlocksHandler.transfer.selector;
    govLocksSelectors[5] = govlocksHandler.transferFrom.selector;
    targetSelector(FuzzSelector({
      addr: address(govlocksHandler),
      selectors: govLocksSelectors
    }));
    targetContract(address(govlocksHandler));
  }

  function invariant_conservationOfLocks() public {
    assertEq(
      goldiswap.balanceOf(address(govlocksHandler)) + govlocks.totalSupply(),
      govlocksHandler.locksMintAmount()
    );
  }

  function invariant_solvencyDeposits() public {
    assertEq(
    goldiswap.balanceOf(address(govlocks)),
    govlocksHandler.ghost_depositSum() - govlocksHandler.ghost_withdrawSum()
    );
  }

  function invariant_solvencyBalances() public {
    uint256 sumOfBalances = govlocksHandler.reduceActors(
      0,
      this.accumulateGovLocksBalance
    );
    assertEq(
      sumOfBalances,
      goldiswap.balanceOf(address(govlocks))
    );
  }

  function invariant_solvencyVotes() public {
    uint256 sumOfVotes = govlocksHandler.reduceActors(
      0,
      this.accumulateGovLocksVotes
    );
    uint256 sumOfStaked = govlocksHandler.reduceActors(
      0,
      this.accumulateStakedLocks
    );
    assertGe(
      goldiswap.balanceOf(address(govlocks)) + sumOfStaked,
      sumOfVotes
    );
  }

  function invariant_depositorBalances() public {
    govlocksHandler.forEachActor(this.assertGovlocksBalanceLteTotalSupply);
  }

}