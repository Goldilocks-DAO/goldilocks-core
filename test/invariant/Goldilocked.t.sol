//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { BaseInvariantTest } from "../base/BaseInvariantTest.t.sol";
import { GoldilockedHandler } from "../invariant/handlers/GoldilockedHandler.t.sol";

contract InvariantGoldilockedTest is BaseInvariantTest {

  function setUp() public override {
    deployProtocol();

    goldilockedHandler = new GoldilockedHandler(goldilocked, goldiswap);
    bytes4[] memory goldilockedSelectors = new bytes4[](5);
    goldilockedSelectors[0] = goldilockedHandler.stake.selector;
    goldilockedSelectors[1] = goldilockedHandler.unstake.selector;
    goldilockedSelectors[2] = goldilockedHandler.approve.selector;
    goldilockedSelectors[3] = goldilockedHandler.transfer.selector;
    goldilockedSelectors[4] = goldilockedHandler.transferFrom.selector;
    targetSelector(FuzzSelector({
      addr: address(goldilockedHandler),
      selectors: goldilockedSelectors
    }));
    targetContract(address(goldilockedHandler));
  }

  function invariant_conservationOfLocks() public {
    uint256 sumOfStaked = goldilockedHandler.reduceActors(
      0,
      this.accumulateStakedLocks
    );
    assertEq(
      goldiswap.balanceOf(address(goldilockedHandler)) + sumOfStaked,
      goldilockedHandler.locksMintAmount()
    );
  }

  function invariant_solvencyStakes() public {
    uint256 sumOfStaked = goldilockedHandler.reduceActors(
      0,
      this.accumulateStakedLocks
    );
    assertEq(
      sumOfStaked,
      goldilockedHandler.ghost_stakeSum() - goldilockedHandler.ghost_unstakeSum()
    );
  }

  function invariant_depositorBalances() public {
    goldilockedHandler.forEachActor(this.assertStakedLocksBalanceLteTotalSupply);
  }

}