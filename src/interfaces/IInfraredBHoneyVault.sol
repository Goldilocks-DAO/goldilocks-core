//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title IInfraredBHoneyVault
interface IInfraredBHoneyVault {

  function stake(uint256 amount) external;
  function withdraw(uint256 amount) external;
  function getReward() external;
  function exit() external;
  function paused() external view returns (bool);   
  function earned(address account, address _rewardsToken) external view returns (uint256);

}