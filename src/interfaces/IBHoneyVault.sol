//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title IBHoneyVault
interface IBHoneyVault {

  function forceNewEpoch() external;
  function maxWithdraw(address owner) external view returns (uint256);
  function deposit(uint256 assets, address receiver) external returns (uint256);
  function makeWithdrawRequest(uint256 shares) external;
  function withdraw(uint256 assets, address receiver, address owner) external returns (uint256);

}