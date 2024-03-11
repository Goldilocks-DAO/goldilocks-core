// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Script } from "../lib/forge-std/src/Script.sol";
import { HoneyWethLPGoldivault } from "./../src/mock/HoneyWethLPGoldivault.sol";
import { OwnershipToken } from "./../src/core/OwnershipToken.sol";
import { YieldToken } from "./../src/core/YieldToken.sol";

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

contract DeployTestnetScript is Script {

  HoneyWethLPGoldivault honeywethlpgoldivault;
  yHWLP yt;
  uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

  function run() external {
    vm.startBroadcast(deployerPrivateKey);

    yt = new yHWLP("yHWLP", "yHWLP", address(0x69));
   
    vm.stopBroadcast();
  }

}