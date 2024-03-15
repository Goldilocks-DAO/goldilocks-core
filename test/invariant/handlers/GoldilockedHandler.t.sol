//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../../lib/forge-std/src/Test.sol";
import { Goldilocked } from "../../../src/core/goldiswap/Goldilocked.sol";
import { Goldiswap } from "../../../src/core/goldiswap/Goldiswap.sol";

contract GoldilockedHandler is Test {

  Goldilocked public goldilocked;
  Goldiswap public goldiswap;

  constructor(Goldilocked _goldilocked, Goldiswap _goldiswap) {
    goldilocked = _goldilocked;
    goldiswap = _goldiswap;
    deal(address(goldiswap), address(this), 10e18);
    goldiswap.approve(address(goldilocked), 10e18);
  }

  function stake(uint256 amount) public {
    goldilocked.stake(amount);
  }
}