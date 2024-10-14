//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../lib/forge-std/src/Test.sol";
import { LibRLP } from "../../lib/solady/src/utils/LibRLP.sol";
import { ERC20 } from "../../lib/solady/src/tokens/ERC20.sol";
import { BHoneyVault } from "../../src/interfaces/BHoneyVault.sol";
import { BHoneyGoldivault } from "../../src/core/goldivault/BHoneyGoldivault.sol";
import { OwnershipToken } from "../../src/core/goldivault/OwnershipToken.sol";
import { YieldToken } from "../../src/core/goldivault/YieldToken.sol";

contract BHoneyOT is OwnershipToken {
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

contract BHoneyYT is YieldToken {
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

contract IntegrationBHoneyGoldivaultTest is Test {

  using LibRLP for address;

  BHoneyGoldivault bhoneygoldivault;
  BHoneyOT bhot;
  BHoneyYT bhyt;
  address ibgt = 0x46eFC86F0D7455F135CC9df501673739d513E982;
  address ibgtVault = 0x31E6458C83C4184A23c761fDAffb61941665E012;
  address honey = 0x0E4aaF1351de4c0264C5c7056Ef3777b41BD8e03;
  address bhoney = 0x1306D3c36eC7E38dd2c128fBe3097C2C2449af64;
  address ibhoneyvault = 0x7d91Bf5851B3A8bCf8C39A69AF2F0F98A4e2202A;
  address user1 = address(0xabc);
  address user2 = address(0xcba);

  function setUp() public {
    BHoneyGoldivault bhoneygoldivaultComputed = BHoneyGoldivault(address(this).computeAddress(3));

    // deploy bhoneygoldivault
    address[] memory yieldTokens = new address[](2);
    yieldTokens[0] = ibgt;
    yieldTokens[1] = honey;
    bhot = new BHoneyOT("BHoneyOT", "BHOT", address(bhoneygoldivaultComputed));
    bhyt = new BHoneyYT("BHoneyYT", "BHYT", address(bhoneygoldivaultComputed));
    bhoneygoldivault = new BHoneyGoldivault(
      address(bhot),
      address(bhyt),
      address(this),
      address(this),
      honey,
      bhoney,
      ibgt,
      ibgtVault,
      bhoney
    );

    // initialization of goldivault
    bhoneygoldivault.initializeProtocol(
      20,
      36 hours,
      7 days,
      1 days,
      yieldTokens
    );
  }

  function testBHoneyWithdraw() public {
    deal(address(honey), user1, 80e18);
    vm.startPrank(user1);
    ERC20(address(honey)).approve(address(bhoneygoldivault), 80e18);
    bhoneygoldivault.deposit(80e18);
    vm.stopPrank();
    
    bhoneygoldivault.beginEmissions(ibhoneyvault);

    deal(address(honey), user2, 20e18);
    vm.startPrank(user2);
    ERC20(address(honey)).approve(address(bhoneygoldivault), 20e18);
    bhoneygoldivault.deposit(20e18);
    vm.stopPrank();

    vm.warp(block.timestamp + 604800);
    bhoneygoldivault.conclude();

    vm.warp(block.timestamp + 9 hours);
    BHoneyVault(bhoney).forceNewEpoch();
    vm.warp(block.timestamp + 13 hours);
    BHoneyVault(bhoney).forceNewEpoch();
    vm.warp(block.timestamp + 13 hours);
    BHoneyVault(bhoney).forceNewEpoch();

    uint256 maxWithdraw = BHoneyVault(bhoney).maxWithdraw(address(bhoneygoldivault));
    bhoneygoldivault.finalExit(maxWithdraw);

    vm.warp(block.timestamp + 3 hours);

    vm.prank(user1);
    bhoneygoldivault.redeemYield(80e18);
    vm.prank(user1);
    bhoneygoldivault.redeemOwnership(80e18);

    vm.prank(user2);
    bhoneygoldivault.redeemYield(20e18);
    vm.prank(user2);
    bhoneygoldivault.redeemOwnership(20e18);
  }

  function testNoEmissionsConclude() public {
    deal(address(honey), user1, 80e18);
    vm.startPrank(user1);
    ERC20(address(honey)).approve(address(bhoneygoldivault), 80e18);
    bhoneygoldivault.deposit(80e18);
    vm.stopPrank();

    deal(address(honey), user2, 20e18);
    vm.startPrank(user2);
    ERC20(address(honey)).approve(address(bhoneygoldivault), 20e18);
    bhoneygoldivault.deposit(20e18);
    vm.stopPrank();

    vm.warp(block.timestamp + 604800);
    bhoneygoldivault.conclude();

    vm.warp(block.timestamp + 9 hours);
    BHoneyVault(bhoney).forceNewEpoch();
    vm.warp(block.timestamp + 13 hours);
    BHoneyVault(bhoney).forceNewEpoch();
    vm.warp(block.timestamp + 13 hours);
    BHoneyVault(bhoney).forceNewEpoch();

    uint256 maxWithdraw = BHoneyVault(bhoney).maxWithdraw(address(bhoneygoldivault));
    bhoneygoldivault.finalExit(maxWithdraw);

    vm.warp(block.timestamp + 3 hours);

    vm.prank(user1);
    bhoneygoldivault.redeemYield(80e18);
    vm.prank(user1);
    bhoneygoldivault.redeemOwnership(80e18);

    vm.prank(user2);
    bhoneygoldivault.redeemYield(20e18);
    vm.prank(user2);
    bhoneygoldivault.redeemOwnership(20e18);
  }

  function testImmediateBeginEmissions() public {
    bhoneygoldivault.beginEmissions(ibhoneyvault);
  }

  function testEmptyBeginEmissionsAndCompound() public {
    deal(address(honey), user1, 80e18);
    vm.startPrank(user1);
    ERC20(address(honey)).approve(address(bhoneygoldivault), 80e18);
    bhoneygoldivault.deposit(80e18);
    vm.stopPrank();

    deal(address(honey), user2, 20e18);
    vm.startPrank(user2);
    ERC20(address(honey)).approve(address(bhoneygoldivault), 20e18);
    bhoneygoldivault.deposit(20e18);
    vm.stopPrank();

    bhoneygoldivault.beginEmissions(ibhoneyvault);
    bhoneygoldivault.compound();
  }

}