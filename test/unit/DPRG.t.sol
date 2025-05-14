//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { BaseUnitTest } from "../base/BaseUnitTest.t.sol";
import { DPRG } from "../../src/core/goldilend/DPRG.sol";
import { Goldilend } from "../../src/core/goldilend/Goldilend.sol";

contract UnitDPRGTest is BaseUnitTest {

  function testDPRGName() public {
    assertEq(dprg.name(), "Debt Porridge");
  }

  function testDPRGSymbol() public {
    assertEq(dprg.symbol(), "DPRG");
  }

  function testMintDprgFailGoldilend() public {
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(DPRG.NotGoldilend.selector));
    dprg.mintDPRG(address(0x69), 69);
  }

  function testBurnDprgFailGoldilend() public {
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(DPRG.NotGoldilend.selector));
    dprg.burnDPRG(address(0x69), 69);
  }

}