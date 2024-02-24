//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Goldivault } from "./../core/Goldivault.sol";
import { TestVault } from "./TestVault.sol";
import { TestiBGTVault } from "./TestiBGTVault.sol";

contract TestGoldivault is Goldivault {

  constructor(
    address _ot,
    address _yt,
    address _depositToken,
    address[] memory _yieldTokens,
    address _depositVault,
    address _iBGTVault,
    address _ibgt,
    address _ired,
    address _multisig
  ) Goldivault(
    _ot,
    _yt,
    _depositToken,
    _yieldTokens,
    _depositVault,
    _iBGTVault,
    _ibgt,
    _ired,
    _multisig
  ) {}

}