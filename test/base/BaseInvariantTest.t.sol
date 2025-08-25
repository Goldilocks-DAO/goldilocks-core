//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { BaseTest } from "./BaseTest.t.sol";
import { ERC20 } from "../../lib/solady/src/tokens/ERC20.sol";
import { GoldiswapHandler } from "../invariant/handlers/GoldiswapHandler.t.sol";
import { GoldilockedHandler } from "../invariant/handlers/GoldilockedHandler.t.sol";
import { GovLocksHandler } from "../invariant/handlers/GovLocksHandler.t.sol";
import { RebaseGoldilendHandler } from "../invariant/handlers/RebaseGoldilendHandler.t.sol";
import { Goldivault4626Handler } from "../invariant/handlers/Goldivault4626Handler.t.sol";

abstract contract BaseInvariantTest is BaseTest {

  GoldilockedHandler public goldilockedHandler;
  GovLocksHandler public govlocksHandler;
  GoldiswapHandler public goldiswapHandler;
  RebaseGoldilendHandler public rebasegoldilendHandler;
  Goldivault4626Handler public goldivault4626Handler;

  function setUp() public virtual override {}

  // govlocks
  function accumulateGovLocksBalance(uint256 balance, address caller) external view returns (uint256) {
    return balance + ERC20(govlocks).balanceOf(caller);
  }
  function accumulateGovLocksVotes(uint256 votes, address caller) external view returns (uint256) {
    return votes + govlocks.getVotes(caller);
  }
  function assertGovlocksBalanceLteTotalSupply(address account) external returns (address[] memory) {
    assertLe(govlocks.balanceOf(account), govlocks.totalSupply());
    return new address[](0);
  }

  // goldilocked
  function accumulateStakedLocks(uint256 staked, address caller) external view returns (uint256) {
    return staked + goldilocked.stakedLocks(caller);
  }
  function assertStakedLocksBalanceLteTotalSupply(address account) external returns (address[] memory) {
    assertLe(goldilocked.stakedLocks(account), goldiswap.totalSupply());
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

  // goldivault4626
  function accumulateClaimableYield(uint256 claimable, address caller) external view returns (uint256) {
    return claimable + oribgtgoldivault.userClaimableUnderlying(caller);
  }
  function assertOribgtotBalanceLteTotalSupply(address account) external returns (address[] memory) {
    assertLe(oribgtot.balanceOf(account), oribgtot.totalSupply());
    return new address[](0);
  }

  function assertOribgtotBalanceLteInitialDeal(address account) external returns (address[] memory) {
    assertLe(oribgtot.balanceOf(account), 100_000e18);
    return new address[](0);
  }

  // goldilend
  function accumulateMintedGlhoney(uint256 minted, address caller) external view returns (uint256) {
    return minted + glhoney.balanceOf(caller);
  }
  function assertMintedGlhoneyLtePoolSize(address account) external returns (address[] memory) {
    assertLe(glhoney.balanceOf(account), rebasegoldilend.poolSize());
    return new address[](0);
  }

}