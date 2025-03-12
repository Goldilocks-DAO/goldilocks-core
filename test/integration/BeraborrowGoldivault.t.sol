//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../lib/forge-std/src/Test.sol";
import { console } from "../../lib/forge-std/src/console.sol";
import { LibRLP } from "../../lib/solady/src/utils/LibRLP.sol";
import { ERC20 } from "../../lib/solady/src/tokens/ERC20.sol";
import { ERC4626 } from "../../lib/solady/src/tokens/ERC4626.sol";
import { Goldivault4626 } from "../../src/core/goldivault/Goldivault4626.sol";
import { OwnershipToken } from "../../src/core/goldivault/OwnershipToken.sol";
import { YieldToken } from "../../src/core/goldivault/YieldToken.sol";

contract BeraborrowWberaHoneyOT is OwnershipToken {
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

contract BeraborrowWberaHoneyYT is YieldToken {
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

contract IntegrationBeraborrowGoldivaultTest is Test {

  using LibRLP for address;

  Goldivault4626 beraborrowgoldivault;
  BeraborrowWberaHoneyOT bbwhot;
  BeraborrowWberaHoneyYT bbwhyt;

  address deployer = 0x895614c89beC7D11454312f740854d08CbF57A78;
  address multisig = 0x6FD990680deB2e5DCcb2FFEfC3307Dd34138Ac7F;
  address router = 0xe301E48F77963D3F7DbD2a4796962Bd7f3867Fb4;
  address depositToken = 0x2c4a603A2aA5596287A06886862dc29d56DbC354; // WBERA-HONEY LP token
  address depositVault = 0x955386Aff3F42C86F304c3EC9fe053D27EC429a6; // beraborrow WBERA-HONEY vault

  address user1 = address(0xabc);
  address user2 = address(0xcba);
  address user3 = address(0xddd);

  uint256 depositNum = 100e18;
  uint256 depositLength = 5 hours;

  // forks starts at block 2233720 # 3-12-25 5am
  function setUp() public {
    Goldivault4626 beraborrowgoldivaultComputed = Goldivault4626(deployer.computeAddress(146));

    vm.startPrank(deployer);
    // deploy beraborrowgoldivault
    bbwhot = new BeraborrowWberaHoneyOT("Beraborrow WBERA-HONEY LP OT", "BBWHOT", address(beraborrowgoldivaultComputed));
    bbwhyt = new BeraborrowWberaHoneyYT("Beraborrow WBERA-HONEY LP YT", "BBWHYT", address(beraborrowgoldivaultComputed));
    beraborrowgoldivault = new Goldivault4626(
      address(bbwhot),
      address(bbwhyt),
      multisig,
      depositToken,
      depositVault,
      router,
      5,
      1e18,
      30 days
    );
    vm.stopPrank();
  }

  // Staking different amounts of YT over the same time period and checking that they receive rewards proportional to stake size
  function testCorrectClaiming() public {
    deal(depositToken, user1, depositNum);
    vm.startPrank(user1);
    ERC20(depositToken).approve(address(beraborrowgoldivault), depositNum);
    bbwhyt.approve(address(beraborrowgoldivault), depositNum);
    beraborrowgoldivault.deposit(depositNum);
    vm.stopPrank();

    deal(depositToken, user2, depositNum * 2);
    vm.startPrank(user2);
    ERC20(depositToken).approve(address(beraborrowgoldivault), depositNum * 2);
    bbwhyt.approve(address(beraborrowgoldivault), depositNum * 2);
    beraborrowgoldivault.deposit(depositNum * 2);
    vm.stopPrank();

    deal(depositToken, user3, depositNum / 2);
    vm.startPrank(user3);
    ERC20(depositToken).approve(address(beraborrowgoldivault), depositNum / 2);
    bbwhyt.approve(address(beraborrowgoldivault), depositNum / 2);
    beraborrowgoldivault.deposit(depositNum / 2);
    vm.stopPrank();

    vm.warp(block.timestamp + depositLength);

    vm.prank(user1);
    beraborrowgoldivault.claim();
    vm.prank(user2);
    beraborrowgoldivault.claim();
    vm.prank(user3);
    beraborrowgoldivault.claim();

    uint256 user1Balance = ERC20(depositToken).balanceOf(user1);
    uint256 user2Balance = ERC20(depositToken).balanceOf(user2);
    uint256 user3Balance = ERC20(depositToken).balanceOf(user3);
  
    assertEq(user1Balance * 2, user2Balance);
    assertEq(user1Balance / 2, user3Balance);
  }

  function testRatios() public {
    uint256 ratio1 = ERC4626(depositVault).convertToAssets(1e18);
    uint256 ratio2 = ERC4626(depositVault).convertToShares(1e18);

    vm.warp(block.timestamp + depositLength);

    uint256 ratio3 = ERC4626(depositVault).convertToAssets(1e18);
    uint256 ratio4 = ERC4626(depositVault).convertToShares(1e18);
  }

  function testDepositRedeem() public {
    deal(depositToken, user1, depositNum);
    vm.startPrank(user1);
    ERC20(depositToken).approve(address(beraborrowgoldivault), depositNum);
    bbwhyt.approve(address(beraborrowgoldivault), depositNum);
    beraborrowgoldivault.deposit(depositNum);
    vm.stopPrank();

    vm.roll(block.number + 1);

    vm.prank(user1);
    beraborrowgoldivault.redeemOwnership(depositNum);
  }


}