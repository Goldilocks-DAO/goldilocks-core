//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../lib/forge-std/src/Test.sol";
import { LibRLP } from "../../lib/solady/src/utils/LibRLP.sol";
import { SafeTransferLib } from "../../lib/solady/src/utils/SafeTransferLib.sol";
import { Goldivault } from "./../../src/core/Goldivault.sol";
import { iBGTGoldivault } from "./../../src/core/iBGTGoldivault.sol";
import { OwnershipToken } from "./../../src/core/OwnershipToken.sol";
import { YieldToken } from "./../../src/core/YieldToken.sol";
import { iBGT } from "./../../src/mock/iBGT.sol";

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

contract Vault {
  mapping(address => uint256) public deposits;
  address ibgt;
  constructor(address _ibgt) { ibgt = _ibgt; }
  function stake(uint256 amount) external {
    deposits[msg.sender] += amount;
    SafeTransferLib.safeTransferFrom(ibgt, msg.sender, address(this), amount);
  }
}

contract iBGTGoldivaultTest is Test {

  using LibRLP for address;

  iBGTGoldivault ibgtgoldivault;
  oiBGT ot;
  yiBGT yt;
  iBGT ibgt;
  Vault vault;

  function setUp() public {
    iBGTGoldivault ibgtgoldivaultComputed = iBGTGoldivault(address(this).computeAddress(5));

    ot = new oiBGT("oiBGT", "oiBGT", address(ibgtgoldivaultComputed));
    yt = new yiBGT("yiBGT", "yiBGT", address(ibgtgoldivaultComputed));
    ibgt = new iBGT();
    vault = new Vault(address(ibgt));
    address[] memory yieldAssets = new address[](2);
    yieldAssets[0] = address(0x69);
    yieldAssets[0] = address(0x69);
    ibgtgoldivault = new iBGTGoldivault(
      address(ot),
      address(yt),
      address(ibgt),
      yieldAssets,
      address(vault),
      address(69),
      address(69),
      address(this)
    );
    ibgtgoldivault.setParameters(2, 2 days, 365 days);
  }

  function testsetEarlyWithdrawalFeeSuccess() public {
    ibgtgoldivault.setEarlyWithdrawalFee(69);

    assertEq(ibgtgoldivault.fee(), 69);
  }

  function testSetEarlyWithdrawalFeeFailCaller() public {
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(Goldivault.NotMultisig.selector));

    ibgtgoldivault.setEarlyWithdrawalFee(69);
  }

  function testSetParametersSuccess() public {
    ibgtgoldivault.setParameters(69, 69, 69);
    
    assertEq(ibgtgoldivault.fee(), 69);
    assertEq(ibgtgoldivault.delay(), 69);
    assertEq(ibgtgoldivault.duration(), 69);
  }

  function testSetParametersFailCaller() public {
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(Goldivault.NotMultisig.selector));

    ibgtgoldivault.setParameters(69, 69, 69);
  }

  function testVaultDeposit() public {
    deal(address(ibgt), address(this), 69e18);
    ibgt.approve(address(ibgtgoldivault), 69e18);
    ibgtgoldivault.deposit(69e18);
  }

}