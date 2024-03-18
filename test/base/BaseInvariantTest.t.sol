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

  function setUp() public override {
    deployProtocol();

    goldiswapHandler = new GoldiswapHandler(goldiswap);
    bytes4[] memory goldiswapSelectors = new bytes4[](3);
    goldiswapSelectors[0] = goldiswapHandler.approve.selector;
    goldiswapSelectors[1] = goldiswapHandler.transfer.selector;
    goldiswapSelectors[2] = goldiswapHandler.transferFrom.selector;
    targetSelector(FuzzSelector({
      addr: address(goldiswapHandler),
      selectors: goldiswapSelectors
    }));
    targetContract(address(goldiswapHandler));

    goldilockedHandler = new GoldilockedHandler(goldilocked, goldiswap);
    bytes4[] memory goldilockedSelectors = new bytes4[](5);
    goldilockedSelectors[0] = goldilockedHandler.stake.selector;
    goldilockedSelectors[1] = goldilockedHandler.unstake.selector;
    goldilockedSelectors[2] = govlocksHandler.approve.selector;
    goldilockedSelectors[3] = govlocksHandler.transfer.selector;
    goldilockedSelectors[4] = govlocksHandler.transferFrom.selector;
    targetSelector(FuzzSelector({
      addr: address(goldilockedHandler),
      selectors: goldilockedSelectors
    }));
    targetContract(address(goldilockedHandler));

    govlocksHandler = new GovLocksHandler(govlocks, goldilocked, goldiswap);
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

    goldilendHandler = new GoldilendHandler(goldilend);
    bytes4[] memory goldilendSelectors = new bytes4[](3);
    goldilendSelectors[0] = goldilendHandler.approve.selector;
    goldilendSelectors[1] = goldilendHandler.transfer.selector;
    goldilendSelectors[2] = goldilendHandler.transferFrom.selector;
    targetSelector(FuzzSelector({
      addr: address(goldilendHandler),
      selectors: goldilendSelectors
    }));
    targetContract(address(goldilendHandler));
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

}