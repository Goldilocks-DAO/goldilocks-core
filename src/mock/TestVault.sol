//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { SafeTransferLib } from "../../lib/solady/src/utils/SafeTransferLib.sol";
import { FixedPointMathLib } from "./../../lib/solady/src/utils/FixedPointMathLib.sol";
import { iBGT } from "./iBGT.sol";

contract TestVault {

  mapping(address => uint256) public deposits;
  mapping(address => uint256) public startTime;

  address depositToken;
  address ibgt;

  error Stealing();

  constructor(
    address _depositToken,
    address _ibgt
  ) { 
    depositToken = _depositToken;
    ibgt = _ibgt;
  }

  function stake(uint256 amount) external {
    deposits[msg.sender] += amount;
    SafeTransferLib.safeTransferFrom(depositToken, msg.sender, address(this), amount);
  }

  function getReward() external {
    uint256 daysStaked = FixedPointMathLib.divWad(startTime[msg.sender], 1 days);
    uint256 tokens = FixedPointMathLib.mulWad(deposits[msg.sender], 100e18);
    uint256 yield = FixedPointMathLib.mulWad(daysStaked, tokens);
    iBGT(ibgt).mint(msg.sender, yield);
  }

  function withdraw(uint256 amount) external {
    if(deposits[msg.sender] < amount) revert Stealing();
    SafeTransferLib.safeTransfer(depositToken, msg.sender, amount);
  }

  function exit() external {
    uint256 daysStaked = FixedPointMathLib.divWad(startTime[msg.sender], 1 days);
    uint256 tokens = FixedPointMathLib.mulWad(deposits[msg.sender], 100e18);
    uint256 yield = FixedPointMathLib.mulWad(daysStaked, tokens);
    iBGT(ibgt).mint(msg.sender, yield);
    SafeTransferLib.safeTransfer(depositToken, msg.sender, deposits[msg.sender]);
  }
}