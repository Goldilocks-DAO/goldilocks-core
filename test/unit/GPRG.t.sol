//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { BaseUnitTest } from "../base/BaseUnitTest.t.sol";
import { GPRG } from "../../src/core/goldilend/GPRG.sol";
import { Goldilend } from "../../src/core/goldilend/Goldilend.sol";

contract UnitGPRGTest is BaseUnitTest {

  function testGPRGName() public {
    assertEq(gprg.name(), "Goldilend Porridge");
  }

  function testGPRGSymbol() public {
    assertEq(gprg.symbol(), "gPRG");
  }

  function testMintGprgFailGoldilend() public {
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(GPRG.NotGoldilend.selector));
    gprg.mintGPRG(address(0x69), 69);
  }

  function testBurnGprgFailGoldilend() public {
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(GPRG.NotGoldilend.selector));
    gprg.burnGPRG(address(0x69), 69);
  }

}