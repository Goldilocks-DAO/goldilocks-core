//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ERC20 } from "../../lib/solady/src/tokens/ERC20.sol";
import { SafeTransferLib } from "../../lib/solady/src/utils/SafeTransferLib.sol";
import { FixedPointMathLib } from "./../../lib/solady/src/utils/FixedPointMathLib.sol";
import { iBGT } from "./iBGT.sol";

contract BexLPToken is ERC20 {
  function name() public pure override returns (string memory) {
    return "BexLPToken";
  }
  function symbol() public pure override returns (string memory) {
    return "BEXLP";
  }
}

contract BexLPVault {

  mapping(address => uint256) public deposits;
  mapping(address => uint256) public startTime;

  address bexlp;
  address ibgt;

  error Stealing();

  constructor(
    address _bexlp,
    address _ibgt
  ) { 
    bexlp = _bexlp;
    ibgt = _ibgt;
  }

  function stake(uint256 amount) external {
    deposits[msg.sender] += amount;
    startTime[msg.sender] = block.timestamp;
    SafeTransferLib.safeTransferFrom(bexlp, msg.sender, address(this), amount);
  }

  function withdraw(uint256 amount) external {
    if(deposits[msg.sender] < amount) revert Stealing();
    deposits[msg.sender] -= amount;
    SafeTransferLib.safeTransfer(bexlp, msg.sender, amount);
  }
  
  function getReward() external {
    uint256 daysStaked = FixedPointMathLib.divWad(startTime[msg.sender], 1 days);
    uint256 tokens = FixedPointMathLib.mulWad(deposits[msg.sender], 100e18);
    uint256 yield = FixedPointMathLib.mulWad(daysStaked, tokens);
    iBGT(ibgt).mint(msg.sender, yield);
  }

  function exit() external {
    uint256 daysStaked = FixedPointMathLib.divWad(startTime[msg.sender], 1 days);
    uint256 tokens = FixedPointMathLib.mulWad(deposits[msg.sender], 100e18);
    uint256 yield = FixedPointMathLib.mulWad(daysStaked, tokens);
    iBGT(ibgt).mint(msg.sender, yield);
    SafeTransferLib.safeTransfer(bexlp, msg.sender, deposits[msg.sender]);
  }
}