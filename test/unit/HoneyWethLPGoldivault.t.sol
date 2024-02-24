//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../lib/forge-std/src/Test.sol";
import { LibRLP } from "../../lib/solady/src/utils/LibRLP.sol";
import { SafeTransferLib } from "../../lib/solady/src/utils/SafeTransferLib.sol";
import { Goldivault } from "./../../src/core/Goldivault.sol";
import { HoneyWethLPGoldivault } from "./../../src/core/HoneyWethLPGoldivault.sol";
import { OwnershipToken } from "./../../src/core/OwnershipToken.sol";
import { YieldToken } from "./../../src/core/YieldToken.sol";
import { iBGT } from "./../../src/mock/iBGT.sol";

contract oHWLP is OwnershipToken {
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

contract yHWLP is YieldToken {
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

contract HoneyWethLPGoldivaultTest is Test {

  using LibRLP for address;

  HoneyWethLPGoldivault honeywethlpgoldivault;
  oHWLP ot;
  yHWLP yt;
  iBGT ibgt;
  Vault vault;

  function setUp() public {
    HoneyWethLPGoldivault honeywethlpgoldivaultComputed = HoneyWethLPGoldivault(address(this).computeAddress(5));

    ot = new oHWLP("oHWLP", "oHWLP", address(honeywethlpgoldivaultComputed));
    yt = new yHWLP("yHWLP", "yHWLP", address(honeywethlpgoldivaultComputed));
    ibgt = new iBGT();
    vault = new Vault(address(ibgt));
    address[] memory yieldTokens = new address[](2);
    yieldTokens[0] = address(0x69);
    yieldTokens[0] = address(0x69);
    honeywethlpgoldivault = new HoneyWethLPGoldivault(
      address(ot),
      address(yt),
      address(ibgt),
      yieldTokens,
      address(vault),
      address(69),
      address(69),
      address(this)
    );
    honeywethlpgoldivault.setParameters(2, 2 days, 365 days);
  }

  function testsetEarlyWithdrawalFeeSuccess() public {
    honeywethlpgoldivault.setEarlyWithdrawalFee(69);

    assertEq(honeywethlpgoldivault.fee(), 69);
  }

  function testSetEarlyWithdrawalFeeFailCaller() public {
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(Goldivault.NotMultisig.selector));

    honeywethlpgoldivault.setEarlyWithdrawalFee(69);
  }

  function testSetParametersSuccess() public {
    honeywethlpgoldivault.setParameters(69, 69, 69);
    
    assertEq(honeywethlpgoldivault.fee(), 69);
    assertEq(honeywethlpgoldivault.delay(), 69);
    assertEq(honeywethlpgoldivault.duration(), 69);
  }

  function testSetParametersFailCaller() public {
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(Goldivault.NotMultisig.selector));

    honeywethlpgoldivault.setParameters(69, 69, 69);
  }

  function testVaultDeposit() public {
    deal(address(ibgt), address(this), 69e18);
    ibgt.approve(address(honeywethlpgoldivault), 69e18);
    honeywethlpgoldivault.deposit(69e18);
  }

}