//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../lib/forge-std/src/Test.sol";
import { OwnershipToken } from "../../src/core/OwnershipToken.sol";

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

contract FuzzOwnershipTokenTest is Test {

  oiBGT ot;

  function setUp() public {
    ot = new oiBGT("oiBGT", "oiBGT", address(0x69));
  }

  function testFuzzMint(uint256 mintAmount) public {
    vm.prank(address(0x69));
    ot.mintOT(address(0x69), mintAmount);

    assertEq(ot.balanceOf(address(0x69)), mintAmount);
  }

  function testFuzzMintFailVault(uint256 mintAmount) public {
    vm.expectRevert(abi.encodeWithSelector(OwnershipToken.NotVault.selector));
    ot.mintOT(address(0x69), mintAmount);
  }

  function testFuzzBurn(uint256 burnAmount) public {
    vm.prank(address(0x69));
    ot.mintOT(address(0x69), burnAmount);
    vm.prank(address(0x69));
    ot.burnOT(address(0x69), burnAmount);

    assertEq(ot.balanceOf(address(0x69)), 0);
  }

  function testFuzzBurnFailVault(uint256 burnAmount) public {
    vm.expectRevert(abi.encodeWithSelector(OwnershipToken.NotVault.selector));
    ot.burnOT(address(0x69), burnAmount);
  }

}