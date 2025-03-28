//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ERC4626 } from "../../lib/solady/src/tokens/ERC4626.sol";

contract oriBGT is ERC4626 {

  address depositToken;

  constructor(address _depositToken) {
    depositToken = _depositToken;
  }

  function name() public pure override returns (string memory) {
    return "oriBGT";
  }

  function symbol() public pure override returns (string memory) {
    return "oriBGT";
  }

  function asset() public view override returns (address) {
    return depositToken;
  }

  function _underlyingDecimals() internal pure override returns (uint8) {
    return 18;
  }

  function _beforeWithdraw(uint256 assets, uint256 shares) internal override {}
  function _afterDeposit(uint256 assets, uint256 shares) internal override {}
}