//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../lib/forge-std/src/Test.sol";
import { OwnershipToken } from "./../../src/core/OwnershipToken.sol";

contract oiBGT is OwnershipToken {
  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    address _vault
  ) OwnershipToken(
    _tokenName,
    _tokenSymbol,
    _vault
  ) {}
}

contract UnitOwnershipTokenTest is Test {

  oiBGT ot;

  function setUp() public {
    ot = new oiBGT("oiBGT", "oiBGT", address(0x69));
  }

  function testOTName() public {
    assertEq(ot.name(), "oiBGT");
  }

  function testOTSymbol() public {
    assertEq(ot.symbol(), "oiBGT");
  }

  function testOTMintSuccess() public {
    vm.prank(address(0x69));
    ot.mintOT(address(this), 69);

    assertEq(ot.balanceOf(address(this)), 69);
  }

  function testOTMintFailCaller() public {
    vm.expectRevert(abi.encodeWithSelector(OwnershipToken.NotVault.selector));

    ot.mintOT(address(this), 69);
  }

  function testOTBurnSuccess() public {
    vm.prank(address(0x69));
    ot.mintOT(address(this), 69);
    vm.prank(address(0x69));
    ot.burnOT(address(this), 69);

    assertEq(ot.balanceOf(address(this)), 0);

  }

  function testOTBurnFailCaller() public {
    vm.expectRevert(abi.encodeWithSelector(OwnershipToken.NotVault.selector));

    ot.burnOT(address(this), 69);
  }

}