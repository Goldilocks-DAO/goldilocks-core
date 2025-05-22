//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import { ERC20 } from "./../../lib/solady/src/tokens/ERC20.sol";

contract WBERA is ERC20 {
  function name() public pure override returns (string memory) {
    return "Wrapped Bera";
  }
  function symbol() public pure override returns (string memory) {
    return "WBERA";
  }
  function mint(address _to, uint256 _amount) external {
    _mint(_to, _amount);
  }
  function burn(address _to, uint256 _amount) external {
    _burn(_to, _amount);
  }
}