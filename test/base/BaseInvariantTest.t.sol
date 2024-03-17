//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { BaseTest } from "./BaseTest.t.sol";
import { ERC20 } from "../../lib/solady/src/tokens/ERC20.sol";
import { GoldilockedHandler } from "../invariant/handlers/GoldilockedHandler.t.sol";
import { GovLocksHandler } from "../invariant/handlers/GovLocksHandler.t.sol";

abstract contract BaseInvariantTest is BaseTest {

  GoldilockedHandler public goldilockedHandler;
  GovLocksHandler public govlocksHandler;

  function setUp() public override {
    deployProtocol();

    goldilockedHandler = new GoldilockedHandler(goldilocked, goldiswap);
    targetContract(address(goldilockedHandler));

    govlocksHandler = new GovLocksHandler(govlocks, goldilocked, goldiswap);
    bytes4[] memory selectors = new bytes4[](6);
    selectors[0] = govlocksHandler.deposit.selector;
    selectors[1] = govlocksHandler.withdraw.selector;
    selectors[2] = govlocksHandler.delegate.selector;
    selectors[3] = govlocksHandler.approve.selector;
    selectors[4] = govlocksHandler.transfer.selector;
    selectors[5] = govlocksHandler.transferFrom.selector;
    targetSelector(FuzzSelector({
      addr: address(govlocksHandler),
      selectors: selectors
    }));
    targetContract(address(govlocksHandler));
  }

  function accumulateGovLocksBalance(uint256 balance, address caller) external view returns (uint256) {
    return balance + ERC20(govlocks).balanceOf(caller);
  }

  function accumulateGovLocksVotes(uint256 votes, address caller) external view returns (uint256) {
    return votes + govlocks.getVotes(caller);
  }

  function accumulateStakedLocks(uint256 staked, address caller) external view returns (uint256) {
    return staked + goldilocked.stakedLocks(caller);
  }

  function assertgovlocksBalanceLteTotalSupply(address account) external returns (address[] memory) {
    assertLe(govlocks.balanceOf(account), govlocks.totalSupply());
    return new address[](0);
  }

  function assertStakedLocksBalanceLteTotalSupply(address account) external returns (address[] memory) {
    assertLe(goldilocked.stakedLocks(account), goldiswap.totalSupply());
    return new address[](0);
  }

}