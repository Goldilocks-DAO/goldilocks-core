// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "../../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "../../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Votes.sol";
import { SafeTransferLib } from "../../lib/solady/src/utils/SafeTransferLib.sol";

contract GovernanceLocks is ERC20, ERC20Permit, ERC20Votes {

  address public locks;
  address public goldilocked;
  mapping(address => uint256) public deposits;
  error Stealing();

  constructor(address _locks, address _goldilocked)
    ERC20("GovernanceLocks", "govLOCKS")
    ERC20Permit("GovernanceLocks")
  {
    locks = _locks;
    goldilocked = _goldilocked;
  }

  //todo: work with staking too

  function deposit(uint256 amount) external {
    deposits[msg.sender] += amount;
    SafeTransferLib.safeTransferFrom(locks, msg.sender, address(this), amount);
    _mint(msg.sender, amount);
  }
  
  function withdraw(uint256 amount) external {
    if(amount > deposits[msg.sender]) revert Stealing();
    deposits[msg.sender] -= amount;
    _burn(msg.sender, amount);
    SafeTransferLib.safeTransfer(locks, msg.sender, amount);
  }

  function updateStakedBalance(address from, address to, uint256 amount) external {
    if(msg.sender != goldilocked) revert Stealing();
    _mint(to, amount);
  }

  function _update(address from, address to, uint256 value)
    internal
    override(ERC20, ERC20Votes)
  {
    super._update(from, to, value);
  }

  function nonces(address owner)
    public
    view
    override(ERC20Permit, Nonces)
    returns (uint256)
  {
    return super.nonces(owner);
  }
}