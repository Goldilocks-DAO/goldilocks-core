//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { BaseTest } from "./BaseTest.t.sol";
import { ERC20 } from "../../lib/solady/src/tokens/ERC20.sol";
import { GoldiswapHandler } from "../invariant/handlers/GoldiswapHandler.t.sol";
import { GoldilockedHandler } from "../invariant/handlers/GoldilockedHandler.t.sol";
import { GovLocksHandler } from "../invariant/handlers/GovLocksHandler.t.sol";
import { GoldilendHandler } from "../invariant/handlers/GoldilendHandler.t.sol";

abstract contract BaseInvariantTest is BaseTest {

  GoldilockedHandler public goldilockedHandler;
  GovLocksHandler public govlocksHandler;
  GoldiswapHandler public goldiswapHandler;
  GoldilendHandler public goldilendHandler;

  function setUp() public virtual override {}

  function accumulateGovLocksBalance(uint256 balance, address caller) external view returns (uint256) {
    return balance + ERC20(govlocks).balanceOf(caller);
  }

  function accumulateGovLocksVotes(uint256 votes, address caller) external view returns (uint256) {
    return votes + govlocks.getVotes(caller);
  }

  function accumulateStakedLocks(uint256 staked, address caller) external view returns (uint256) {
    return staked + goldilocked.stakedLocks(caller);
  }

  function assertGovlocksBalanceLteTotalSupply(address account) external returns (address[] memory) {
    assertLe(govlocks.balanceOf(account), govlocks.totalSupply());
    return new address[](0);
  }

  function assertStakedLocksBalanceLteTotalSupply(address account) external returns (address[] memory) {
    assertLe(goldilocked.stakedLocks(account), goldiswap.totalSupply());
    return new address[](0);
  }

  function assertGoldilendBalanceLteTotalSupply(address account) external returns (address[] memory) {
    assertLe(goldilend.balanceOf(account), goldilend.totalSupply());
    return new address[](0);
  }

  function assertLocksBalanceLteTotalSupply(address account) external returns (address[] memory) {
    assertLe(goldiswap.balanceOf(account), goldiswap.totalSupply());
    return new address[](0);
  }

  function assertHoneyBalanceLteInitalDeal(address account) external returns (address[] memory) {
    assertLe(honey.balanceOf(account), 100_000e18);
    return new address[](0);
  }

}