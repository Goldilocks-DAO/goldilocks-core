//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../lib/forge-std/src/Test.sol";
import { YieldToken } from "../../src/core/YieldToken.sol";

contract yiBGT is YieldToken {
  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    address _vault
  ) YieldToken(
    _tokenName,
    _tokenSymbol,
    _vault
  ) {}
}

contract FuzzYieldTokenTest is Test {

  yiBGT yt;

  function setUp() public {
    yt = new yiBGT("yiBGT", "yiBGT", address(0x69));
  }

  function testFuzzMint(uint256 mintAmount) public {
    vm.prank(address(0x69));
    yt.mintYT(address(0x69), mintAmount);

    assertEq(yt.balanceOf(address(0x69)), mintAmount);
  }

  function testFuzzMintFailVault(uint256 mintAmount) public {
    vm.expectRevert(abi.encodeWithSelector(YieldToken.NotVault.selector));
    yt.mintYT(address(0x69), mintAmount);
  }

  function testFuzzBurn(uint256 burnAmount) public {
    vm.prank(address(0x69));
    yt.mintYT(address(0x69), burnAmount);
    vm.prank(address(0x69));
    yt.burnYT(address(0x69), burnAmount);

    assertEq(yt.balanceOf(address(0x69)), 0);
  }

  function testFuzzBurnFailVault(uint256 burnAmount) public {
    vm.expectRevert(abi.encodeWithSelector(YieldToken.NotVault.selector));
    yt.burnYT(address(0x69), burnAmount);
  }

}