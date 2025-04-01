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
  uint256 txAmt = 10e18;

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
    uint256 ytAmt = 15413847991370307;
    uint256 dtAmountMax = 1e14;
    deal(address(ibgt), user, txAmt);
    vm.startPrank(user);
    ibgt.approve(address(oribgtgoldivault), txAmt);
    oribgtyt.approve(address(oribgtgoldivault), txAmt);
    oribgtgoldivault.buyYT(ytAmt, dtAmountMax, 14611297191257916);
    vm.stopPrank();

    assertEq(oribgtgoldivault.ytStaked(user), ytAmt);
    assert(ibgt.balanceOf(user) >= txAmt - dtAmountMax);
  }

  function testSellYTFailInvalid() public {
    vm.expectRevert(abi.encodeWithSelector(IGoldivault4626.InvalidTrade.selector));
    vm.prank(user);
    oribgtgoldivault.sellYT(0, 0, 0);
  }

  function testSellYTSuccess() public {
    uint256 ytAmt = 1e16;
    uint256 dtAmountMin = 14816756545257;
    deal(address(oribgtyt), user, txAmt);
    vm.startPrank(user);
    ibgt.approve(address(oribgtgoldivault), txAmt);
    oribgtyt.approve(address(oribgtgoldivault), txAmt);
    oribgtgoldivault.stakeYT(txAmt);
    oribgtgoldivault.sellYT(ytAmt, dtAmountMin, 9552006660243499);
    vm.stopPrank();

    assertEq(oribgtgoldivault.ytStaked(user), txAmt - ytAmt);
    assert(ibgt.balanceOf(user) >= dtAmountMin);
  }

  function testSellYTNeverDecrease() public {
    uint256 ytAmt = 1e16;
    uint256 dtAmountMin = 14816756545257;
    deal(address(oribgtyt), user, txAmt);
    uint256 shareBal = oribgt.balanceOf(user);
    uint256 dtBal = ibgt.balanceOf(user);
    vm.startPrank(user);
    ibgt.approve(address(oribgtgoldivault), txAmt);
    oribgtyt.approve(address(oribgtgoldivault), txAmt);
    oribgtgoldivault.stakeYT(txAmt);
    oribgtgoldivault.sellYT(ytAmt, dtAmountMin, 9552006660243499);
    vm.stopPrank();

    assert(oribgt.balanceOf(user) >= shareBal);
    assert(ibgt.balanceOf(user) >= dtBal);
  }

  function testSupplyRatios() public {
    address user2 = address(0x123abc);
    deal(address(ibgt), user2, txAmt);
    vm.startPrank(user2);
    ibgt.approve(address(oribgtgoldivault), txAmt);
    oribgtyt.approve(address(oribgtgoldivault), txAmt);
    oribgtgoldivault.deposit(txAmt);
    vm.stopPrank();

    address user3 = address(0x123abccc);
    deal(address(ibgt), user3, 20e18);
    vm.startPrank(user3);
    ibgt.approve(address(oribgtgoldivault), 20e18);
    oribgtyt.approve(address(oribgtgoldivault), 20e18);
    oribgtgoldivault.deposit(20e18);
    vm.stopPrank();

    deal(address(ibgt), user, txAmt);
    vm.startPrank(user);
    ibgt.approve(address(oribgtgoldivault), txAmt);
    oribgtyt.approve(address(oribgtgoldivault), txAmt);
    oribgtgoldivault.buyYT(15413847991370307, 1e14, 14611297191257916);
    vm.stopPrank();

    vm.prank(user3);
    oribgtgoldivault.unstakeYT(20e18);

    assertEq(oribgtot.totalSupply(), oribgtyt.totalSupply());
    assertEq(oribgtot.totalSupply(), oribgtgoldivault.depositTokenAmount());
    assert(oribgt.convertToAssets(oribgt.balanceOf(address(oribgtgoldivault))) >= oribgtot.totalSupply());
  }
}