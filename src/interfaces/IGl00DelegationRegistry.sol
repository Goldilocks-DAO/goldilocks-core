//SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface IGl00DelegationRegistry {
  error OwnableInvalidOwner(address owner);
  error OwnableUnauthorizedAccount(address account);

  event AllDelegationsCleared(address indexed tba);
  event DelegationRevoked(address indexed tba);
  event DelegationSet(address indexed tba, address indexed delegatee, uint256 expiration, uint256 permissions);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function PERMISSION_CLAIM() external view returns (uint256);
  function PERMISSION_TRANSFER() external view returns (uint256);
  function PERMISSION_VOTE() external view returns (uint256);
  function authorizeContract(address nftContract) external;
  function checkDelegation(address tba, address delegatee, uint256 permission) external view returns (bool);
  function clearAllDelegations(address tba) external;
  function getDelegatedTBAs(address delegatee) external view returns (address[] memory);
  function getDelegatee(address tba) external view returns (address);
  function owner() external view returns (address);
  function renounceOwnership() external;
  function revokeAuthorization(address nftContract) external;
  function revokeDelegation(address payable tba) external;
  function setDelegation(address payable tba, address delegatee, uint256 permissions, uint256 duration) external;
  function transferOwnership(address newOwner) external;
}