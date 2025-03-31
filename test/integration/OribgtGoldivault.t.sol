//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../lib/forge-std/src/Test.sol";
import { LibRLP } from "../../lib/solady/src/utils/LibRLP.sol";
import { ERC20 } from "../../lib/solady/src/tokens/ERC20.sol";
import { ERC4626 } from "../../lib/solady/src/tokens/ERC4626.sol";
import { Goldivault4626 } from "../../src/core/goldivault/Goldivault4626.sol";
import { IGoldivault4626 } from "../../src/interfaces/IGoldivault4626.sol";
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

contract IntegrationOribgtGoldivaultTest is Test {

  using LibRLP for address;

  ERC20 ibgt;
  ERC4626 oribgt;
  oriBGTOT oribgtot;
  oriBGTYT oribgtyt;
  Goldivault4626 oribgtgoldivault;

  address deployer = 0x895614c89beC7D11454312f740854d08CbF57A78;
  address ibgtaddy = 0xac03CABA51e17c86c921E1f6CBFBdC91F8BB2E6b;
  address oribgtaddy = 0x69f1E971257419B1E9C405A553f252c64A29A30a;
  address oribgtotaddy = 0xfC1a50C704CA748316AD919212b771ea1E4f8d71;
  address oribgtytaddy = 0x1086e9562E5d9588AEbC7b1B35eB96f7AB35805F;
  address oribgtvaultaddy = 0xE5e4B198c115f59bde4a3740381284EA13103EB7;

  address user = address(0xabc123);

  function setUp() public {
    uint256 berachainFork = vm.createFork("https://rpc.berachain.com", 3090200);
    vm.selectFork(berachainFork);
    
    ibgt = ERC20(ibgtaddy);
    oribgt = ERC4626(oribgtaddy);
    oribgtot = oriBGTOT(oribgtotaddy);
    oribgtyt = oriBGTYT(oribgtytaddy);
    oribgtgoldivault = Goldivault4626(oribgtvaultaddy);
  }

  function testBuyYTFailInvalid() public {
    vm.expectRevert(abi.encodeWithSelector(IGoldivault4626.InvalidTrade.selector));
    vm.prank(user);
    oribgtgoldivault.buyYT(0, 0, 0);
  }

  function testBuyYTFailConcluded() public {
    vm.warp(block.timestamp + 400 days);
    vm.expectRevert(abi.encodeWithSelector(IGoldivault4626.AlreadyConcluded.selector));
    vm.prank(user);
    oribgtgoldivault.buyYT(1, 1, 1);
  }

  function testBuyYTSuccess() public {
    uint256 txAmt = 10e18;
    deal(address(ibgt), user, txAmt);
    vm.startPrank(user);
    ibgt.approve(address(oribgtgoldivault), txAmt);
    oribgtyt.approve(address(oribgtgoldivault), txAmt);
    oribgtgoldivault.buyYT(15413847991370307, 1e14, 14611297191257916);
    vm.stopPrank();
  }

  function testSellYTFailInvalid() public {
    vm.expectRevert(abi.encodeWithSelector(IGoldivault4626.InvalidTrade.selector));
    vm.prank(user);
    oribgtgoldivault.sellYT(0, 0, 0);
  }

  function testSellYTSuccess() public {
    uint256 txAmt = 10e18;
    deal(address(oribgtyt), user, txAmt);
    vm.startPrank(user);
    ibgt.approve(address(oribgtgoldivault), txAmt);
    oribgtyt.approve(address(oribgtgoldivault), txAmt);
    oribgtgoldivault.stakeYT(txAmt);
    oribgtgoldivault.sellYT(1e16, 14816756545257, 9552006660243499);
    vm.stopPrank();
  }

}