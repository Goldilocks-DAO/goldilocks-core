// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Script } from "../lib/forge-std/src/Script.sol";
import { iBGTGoldivault } from "./../src/core/iBGTGoldivault.sol";
import { OwnershipToken } from "./../src/core/OwnershipToken.sol";
import { YieldToken } from "./../src/core/YieldToken.sol";

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

contract DeployTestnetScript is Script {

  iBGTGoldivault ibgtgoldivault;
  yiBGT yt;
  uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

  function run() external {
    vm.startBroadcast(deployerPrivateKey);

    yt = new yiBGT("yiBGT", "yiBGT", address(0x69));
   
    vm.stopBroadcast();
  }

}