// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../lib/foundry-huff/src/HuffDeployer.sol";
import "../../lib/forge-std/src/Test.sol";
import { Goldiswap } from "../../src/core/Goldiswap.sol";
import { Math } from "../../src/mock/Math.sol";

interface Goldihuff {
  function floorPrice(uint256,uint256) external returns (uint256);
  function floorPriceWad(uint256,uint256) external returns (uint256);
}

contract DifferentialGoldihuffTest is Test {

  Goldihuff goldihuff;
  Math math;
  Goldiswap goldiswap;

  function setUp() public {
    goldihuff = Goldihuff(HuffDeployer.deploy("mock/Goldihuff"));
    math = new Math();
    goldiswap = new Goldiswap(69, 69, address(0x69), address(0x69), address(0x69), 100_000_000e18);
  }

  function testDivideHuff() public {
    uint256 result = goldihuff.floorPrice(15, 5);
    console.log(result);
  }

  function testDivideNormal() public {
    uint256 result = math.divide(15, 5);
    console.log(result);
  }

  function testDivideGasHuff() public {
    goldihuff.floorPrice(15, 5);
  }

  function testDivideGasNormal() public {
    math.divide(15, 5);
  }

  function testFloorPriceHuff() public {
    vm.store(address(goldiswap), bytes32(uint256(0)), bytes32(uint256(4827588e17)));
    vm.store(address(goldiswap), bytes32(uint256(0x05345cdf77eb68f44c)), bytes32(uint256(100000000e18)));

    uint256 resultNormal = goldiswap.floorPrice();
    uint256 resultHuff = goldihuff.floorPriceWad(4827588e17, 100000000e18);
    console.log(resultNormal);
    console.log(resultHuff);

    assertEq(resultNormal, resultHuff);
  }

}