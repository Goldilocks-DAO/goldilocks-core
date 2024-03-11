//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Test } from "../../lib/forge-std/src/Test.sol";
import { LibRLP } from "../../lib/solady/src/utils/LibRLP.sol";
import { ERC20 } from "../../lib/solady/src/tokens/ERC20.sol";
import { Goldivault } from "../../src/core/Goldivault.sol";
import { OwnershipToken } from "../../src/core/OwnershipToken.sol";
import { YieldToken } from "../../src/core/YieldToken.sol";
import { iBGT } from "../../src/mock/iBGT.sol";
import { iBGTVault } from "../../src/mock/iBGTVault.sol";


contract UnitGoldivault is Goldivault {
  constructor(
    address _ot,
    address _yt,
    address _depositToken,
    address _depositVault,
    address _ibgt,
    address _ibgtvault,
    address _ired,
    address _iredVault,
    address _multisig,
    address[] memory _yieldTokens
  ) Goldivault(
    _ot,
    _yt,
    _depositToken,
    _depositVault,
    _ibgt,
    _ibgtvault,
    _ired,
    _iredVault,
    _multisig,
    _yieldTokens
  ) {}
}
contract oUnit is OwnershipToken {
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
contract yUnit is YieldToken {
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
contract Unit is ERC20 {
  function name() public pure override returns (string memory) {
    return "Unit";
  }
  function symbol() public pure override returns (string memory) {
    return "Unit";
  }
}

contract InvariantOwnershipTokenTest is Test {

  using LibRLP for address;

  iBGT ibgt;
  iBGTVault ibgtvault;
  UnitGoldivault goldivault;
  oUnit ot;
  yUnit yt;
  Unit unit;

  address[] public actors;
  address internal currentActor;

  function setUp() public {
    // precompute address
    UnitGoldivault goldivaultComputed = UnitGoldivault(address(this).computeAddress(18));

    // deploy mock contracts
    unit = new Unit();
    ibgt = new iBGT();
    ibgtvault = new iBGTVault(address(ibgt), address(ibgt));

    // deploy goldivault
    address[] memory yieldTokens = new address[](1);
    yieldTokens[0] = address(ibgt);
    ot = new oUnit("oUnit", "oUnit", address(goldivaultComputed));
    yt = new yUnit("yUnit", "yUnit", address(goldivaultComputed));
    goldivault = new UnitGoldivault(
      address(ot),
      address(yt),
      address(unit),
      address(ibgtvault),
      address(ibgt),
      address(ibgtvault),
      address(ibgt),
      address(ibgtvault),
      address(this),
      yieldTokens
    );
    goldivault.setEarlyWithdrawalFee(30);
    goldivault.setParameters(20, 1 days, 365 days);

    // exclude mock contracts from invariant testing
    excludeContract(address(unit));
    excludeContract(address(ibgt));
    excludeContract(address(ibgtvault));

    // create actors
    actors = new address[](3);
    actors[0] = address(0xabcdabcd);
    actors[1] = address(0xdcbadcba);
    actors[2] = address(0xaabbccdd);

    // exclude admin from being msg.sender
    excludeSender(address(this));
  }

  function invariantSupply() public {
    assertEq(ot.balanceOf(actors[0]), ot.totalSupply());
  }

}