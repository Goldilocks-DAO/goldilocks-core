//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { BaseTest } from "./BaseTest.t.sol";
import { GoldilockedHandler } from "../invariant/handlers/GoldilockedHandler.t.sol";

abstract contract BaseInvariantTest is BaseTest {

  GoldilockedHandler public goldilockedHandler;

  function setUp() public override {
    deployProtocol();

    goldilockedHandler = new GoldilockedHandler(goldilocked, goldiswap);
    targetContract(address(goldilockedHandler));
  }

}