//SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface IBeraBondNFT {
  error BeraBondNFT__BGTExists();
  error BeraBondNFT__BGTLockedForTransfer();
  error BeraBondNFT__InsufficientBGTForApproval();
  error BeraBondNFT__InsufficientBGTForTransfer();
  error BeraBondNFT__NotOwnerOrApproved();
  error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);
  error ERC721InsufficientApproval(address operator, uint256 tokenId);
  error ERC721InvalidApprover(address approver);
  error ERC721InvalidOperator(address operator);
  error ERC721InvalidOwner(address owner);
  error ERC721InvalidReceiver(address receiver);
  error ERC721InvalidSender(address sender);
  error ERC721NonexistentToken(uint256 tokenId);
  error OwnableInvalidOwner(address owner);
  error OwnableUnauthorizedAccount(address account);

  event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
  event BeraBondMinted(address indexed owner, uint256 indexed tokenId, address indexed tba);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

  function ERC6551_SALT() external view returns (bytes32);
  function approve(address to, uint256 tokenId) external;
  function balanceOf(address owner) external view returns (uint256);
  function batchRedeemBgtAndBurn(uint256[] memory tokenIds) external;
  function bgtToken() external view returns (address);
  function burn(uint256 tokenId) external;
  function delegationRegistry() external view returns (address);
  function getApproved(uint256 tokenId) external view returns (address);
  function getNextTokenId() external view returns (uint256);
  function getTokenBoundAccount(uint256 tokenId) external view returns (address payable);
  function implementation() external view returns (address);
  function isApprovedForAll(address owner, address operator) external view returns (bool);
  function isApprovedOrOwner(address spender, uint256 tokenId) external view returns (bool);
  function isBGTLocked(uint256 tokenId) external view returns (bool);
  function minBGTThreshold() external view returns (uint256);
  function mint() external returns (uint256 tokenId_, address tbaAddress_);
  function name() external view returns (string memory);
  function owner() external view returns (address);
  function ownerOf(uint256 tokenId) external view returns (address);
  function registry() external view returns (address);
  function renounceOwnership() external;
  function safeTransferFrom(address from, address to, uint256 tokenId) external;
  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) external;
  function setApprovalForAll(address operator, bool approved) external;
  function setDelegationRegistry(address _delegationRegistry) external;
  function setERC6551Implementation(address _implementation) external;
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
  function symbol() external view returns (string memory);
  function tokenURI(uint256 tokenId) external view returns (string memory);
  function totalSupply() external view returns (uint256);
  function transferFrom(address from, address to, uint256 tokenId) external;
  function transferOwnership(address newOwner) external;
}