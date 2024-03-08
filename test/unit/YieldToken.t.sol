//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../lib/forge-std/src/Test.sol";
import { YieldToken } from "./../../src/core/YieldToken.sol";

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

contract UnitYieldTokenTest is Test {

  yiBGT yt;

  function setUp() public {
    yt = new yiBGT("yiBGT", "yiBGT", address(0x69));
  }

  function testYTName() public {
    assertEq(yt.name(), "yiBGT");
  }

  function testYTSymbol() public {
    assertEq(yt.symbol(), "yiBGT");
  }

  function testMintSuccess() public {
    vm.prank(address(0x69));
    yt.mintYT(address(this), 69);

    assertEq(yt.balanceOf(address(this)), 69);
  }

  function testMintFailCaller() public {
    vm.expectRevert(abi.encodeWithSelector(YieldToken.NotVault.selector));

    yt.mintYT(address(this), 69);
  }

  function testBurnSuccess() public {
    vm.prank(address(0x69));
    yt.mintYT(address(this), 69);
    vm.prank(address(0x69));
    yt.burnYT(address(this), 69);

    assertEq(yt.balanceOf(address(this)), 0);

  }

  function testBurnFailCaller() public {
    vm.expectRevert(abi.encodeWithSelector(YieldToken.NotVault.selector));

    yt.burnYT(address(this), 69);
  }

}