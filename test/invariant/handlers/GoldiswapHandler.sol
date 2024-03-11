//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Test } from "../../../lib/forge-std/src/Test.sol";
import { Goldiswap } from "../../../src/core/Goldiswap.sol";
import { Honey } from "../../../src/mock/Honey.sol";

contract GoldiswapHandler is Test {

  Goldiswap goldiswap;
  Honey honey;
  address[] public actors;
  address internal currentActor;

  constructor(address _goldiswap, address _honey) {
    goldiswap = Goldiswap(_goldiswap);
    honey = Honey(_honey);

    actors = new address[](3);
    actors[0] = address(0xabcdabcd);
    actors[1] = address(0xdcbadcba);
    actors[2] = address(0xaabbccdd);
    // for(uint8 i; i < actors.length; i++) {
    //   deal(_honey, address(actors[i]), 100e18);
    // }
  }

  modifier useActor(uint256 actorIndexSeed) {
    currentActor = actors[bound(actorIndexSeed, 0, actors.length - 1)];
    vm.startPrank(currentActor);
    _;
    vm.stopPrank();
  }






}