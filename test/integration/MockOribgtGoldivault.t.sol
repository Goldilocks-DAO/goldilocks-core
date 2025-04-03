//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../lib/forge-std/src/Test.sol";
import { LibRLP } from "../../lib/solady/src/utils/LibRLP.sol";
import { ERC20 } from "../../lib/solady/src/tokens/ERC20.sol";
import { ERC4626 } from "../../lib/solady/src/tokens/ERC4626.sol";
import { Goldivault4626 } from "../../src/core/goldivault/Goldivault4626.sol";
import { OwnershipToken } from "../../src/core/goldivault/OwnershipToken.sol";
import { YieldToken } from "../../src/core/goldivault/YieldToken.sol";

contract oriBGTOT is OwnershipToken {
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

contract oriBGTYT is YieldToken {
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

contract IntegrationMockOribgtGoldivaultTest is Test {

  using LibRLP for address;

  ERC20 ibgt;
  ERC4626 oribgt;
  oriBGTOT oribgtot;
  oriBGTYT oribgtyt;
  Goldivault4626 oribgtgoldivault;

  address deployer = 0x895614c89beC7D11454312f740854d08CbF57A78;
  address testuser = 0x70047102dE159aBd76b8D583cEabc24BCd7A5d0d;
  address testuser2 = 0x369557E0DeF5643Ef8c1ab376AF8fc7BdAF0E08A;

  address ibgtaddy = 0xac03CABA51e17c86c921E1f6CBFBdC91F8BB2E6b;
  address oribgtaddy = 0x69f1E971257419B1E9C405A553f252c64A29A30a;

  address oribgtotaddy = 0xc0c088Bf14fe151C8AfEd52a8bFD3ef82d84280C;
  address oribgtytaddy = 0x10C2BBaCECC5ed3e61198Ec4a4a6b199A2f48826;
  address oribgtgoldivaultaddy = 0xdAfAE06A4D32f44Ec395d2664eB18432D39bd358;

  address user = address(0xabc123);
  uint256 testAmt = 25e15;

  function setUp() public {
    uint256 berachainFork = vm.createFork("https://rpc.berachain.com");
    vm.selectFork(berachainFork);
    
    ibgt = ERC20(ibgtaddy);
    oribgt = ERC4626(oribgtaddy);
    oribgtot = oriBGTOT(oribgtotaddy);
    oribgtyt = oriBGTYT(oribgtytaddy);
    oribgtgoldivault = Goldivault4626(oribgtgoldivaultaddy);
  }

  function testShareAssetBacking() public {
    vm.startPrank(deployer);
    oribgtgoldivault.claim();
    vm.stopPrank();

    vm.startPrank(testuser);
    oribgtgoldivault.claim();
    vm.stopPrank();

    vm.startPrank(testuser2);
    oribgtgoldivault.claim();
    vm.stopPrank();

    assert(oribgt.convertToAssets(oribgt.balanceOf(address(oribgtgoldivault))) >= oribgtot.totalSupply());
  }

}