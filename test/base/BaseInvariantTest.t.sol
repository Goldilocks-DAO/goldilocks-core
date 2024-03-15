//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { BaseTest } from "./BaseTest.t.sol";
import { ERC20 } from "../../lib/solady/src/tokens/ERC20.sol";
import { GoldilockedHandler } from "../invariant/handlers/GoldilockedHandler.t.sol";
import { govLocksHandler } from "../invariant/handlers/govLocksHandler.t.sol";

abstract contract BaseInvariantTest is BaseTest {

  GoldilockedHandler public goldilockedHandler;
  govLocksHandler public govlocksHandler;

  function setUp() public override {
    deployProtocol();

    goldilockedHandler = new GoldilockedHandler(goldilocked, goldiswap);
    targetContract(address(goldilockedHandler));

    govlocksHandler = new govLocksHandler(govlocks, goldilocked, goldiswap);
    bytes4[] memory selectors = new bytes4[](6);
    selectors[0] = govLocksHandler.deposit.selector;
    selectors[1] = govLocksHandler.withdraw.selector;
    selectors[2] = govLocksHandler.delegate.selector;
    selectors[3] = govLocksHandler.approve.selector;
    selectors[4] = govLocksHandler.transfer.selector;
    selectors[5] = govLocksHandler.transferFrom.selector;
    targetSelector(FuzzSelector({
      addr: address(govlocksHandler),
      selectors: selectors
    }));
    targetContract(address(govlocksHandler));
  }

  function accumulategovLocksBalance(uint256 balance, address caller) external view returns (uint256) {
    return balance + ERC20(govlocks).balanceOf(caller);
  }

  function accumulategovLocksVotes(uint256 votes, address caller) external view returns (uint256) {
    return votes + govlocks.getVotes(caller);
  }

  function accumulateStakedLocks(uint256 staked, address caller) external view returns (uint256) {
    return staked + goldilocked.stakedLocks(caller);
  }

  function assertgovlocksBalanceLteTotalSupply(address account) external returns (address[] memory) {
    assertLe(govlocks.balanceOf(account), govlocks.totalSupply());
    return new address[](0);
  }

}