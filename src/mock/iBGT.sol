//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import { ERC20 } from "./../../lib/solady/src/tokens/ERC20.sol";

contract iBGT is ERC20 {
  function name() public pure override returns (string memory) {
    return "Infrared Berachain Governance Token";
  }
  function symbol() public pure override returns (string memory) {
    return "iBGT";
  }
  function mint(address _to, uint256 _amount) external {
    _mint(_to, _amount);
  }
  function burn(address _to, uint256 _amount) external {
    _burn(_to, _amount);
  }
}