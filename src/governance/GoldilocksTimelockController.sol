// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import { TimelockController } from "../../lib/openzeppelin-contracts/contracts/governance/TimelockController.sol";

contract GoldilocksTimelockController is TimelockController {
  constructor(
    uint256 minDelay,
    address[] memory proposers,
    address[] memory executors,
    address admin
  ) TimelockController(
    minDelay,
    proposers,
    executors,
    admin
  ) {}
}