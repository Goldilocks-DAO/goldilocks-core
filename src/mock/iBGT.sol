//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import { ERC20 } from "./../../lib/solady/src/tokens/ERC20.sol";

contract iBGT is ERC20 {
  function name() public pure override returns (string memory) {
    return "Infrared Berachain Governance Token";
  }
  function symbol() public pure override returns (string memory) {
    return "iBGT";
  }
}