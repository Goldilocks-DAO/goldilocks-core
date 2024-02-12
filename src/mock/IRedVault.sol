//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IRedVault {
  function stake(uint256 amount) external;
  function getReward() external;
  function withdraw(uint256 amount) external;
  function exit() external;
}