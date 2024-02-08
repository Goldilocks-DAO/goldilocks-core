//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IBGTVault {
  function stake(uint256 amount) external;
  function getReward() external;
}