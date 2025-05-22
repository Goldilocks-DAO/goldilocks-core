//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { BaseUnitTest } from "../base/BaseUnitTest.t.sol";
import { GLWBera } from "../../src/core/goldilend/GLWBera.sol";
import { Goldilend } from "../../src/core/goldilend/Goldilend.sol";

contract UnitGLWBeraTest is BaseUnitTest {

  function testGLWBeraName() public {
    assertEq(glwbera.name(), "Goldilend Wrapped Bera");
  }

  function testGLWBeraSymbol() public {
    assertEq(glwbera.symbol(), "glWBERA");
  }

  function testMintglWBERAFailGoldilend() public {
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(GLWBera.NotGoldilend.selector));
    glwbera.mintglWBERA(address(0x69), 69);
  }

  function testBurnglWBERAFailGoldilend() public {
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(GLWBera.NotGoldilend.selector));
    glwbera.burnglWBERA(address(0x69), 69);
  }

}