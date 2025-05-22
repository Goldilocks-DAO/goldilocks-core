//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { BaseUnitTest } from "../base/BaseUnitTest.t.sol";
import { GLDWBera } from "../../src/core/goldilend/GLDWBera.sol";

contract UnitgldWBERATest is BaseUnitTest {

  function testgldWBERAName() public {
    assertEq(gldwbera.name(), "Goldilend Debt Wrapped Bera");
  }

  function testgldWBERASymbol() public {
    assertEq(gldwbera.symbol(), "gldWBERA");
  }

  function testMintgldWBERAFailGoldilend() public {
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(GLDWBera.NotGoldilend.selector));
    gldwbera.mintgldWBERA(address(0x69), 69);
  }

  function testBurngldWBERAFailGoldilend() public {
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(GLDWBera.NotGoldilend.selector));
    gldwbera.burngldWBERA(address(0x69), 69);
  }

}