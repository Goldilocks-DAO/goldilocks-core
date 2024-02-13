//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../lib/forge-std/src/Test.sol";
import { LibRLP } from "../../lib/solady/src/utils/LibRLP.sol";
import { BerpsVault } from "../../src/mock/BerpsVault.sol";
import { OwnershipToken } from "../../src/core/OwnershipToken.sol";
import { YieldToken } from "../../src/core/YieldToken.sol";
import { Honey } from "../../src/mock/Honey.sol";

contract Vault {
  function deposit(uint256 assets, address receiver) public returns (uint256) {}
  function withdraw(uint256 assets, address receiver, address owner) public returns (uint256) {}
  function makeWithdrawRequest(uint256 shares, address owner) external {}
  function claimBGT(uint256 amount, address recipient) external {}
}

contract BerpsOwnershipToken is OwnershipToken {
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

contract BerpsYieldToken is YieldToken {
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

contract BerpsVaultTest is Test {

  using LibRLP for address;

  BerpsVault berpsvault;
  BerpsOwnershipToken ot;
  BerpsYieldToken yt;
  Honey honey;
  Vault vault;

  function setUp() public {
    BerpsVault berpsvaultComputed = BerpsVault(address(this).computeAddress(5));
    vault = new Vault();
    honey = new Honey();
    ot = new BerpsOwnershipToken("ot-bHONEY", "ot-bHONEY", address(berpsvaultComputed));
    yt = new BerpsYieldToken("yt-bHONEY", "yt-bHONEY", address(berpsvaultComputed));
    berpsvault = new BerpsVault(
      3,
      30 days,
      365 days,
      address(ot),
      address(yt),
      address(honey),
      address(honey),
      address(vault),
      address(vault),
      address(0x420),
      address(this)
    );
  }

  function testFee() public {
    uint256 num = berpsvault.fee();
    console.log(num);
  }

  function testBerpsVaultDeposit() public {
    uint256 txamt = 5e18;
    deal(address(honey), address(this), txamt);
    honey.approve(address(berpsvault), txamt);
    berpsvault.deposit(txamt);
  }

}