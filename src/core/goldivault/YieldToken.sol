//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


// |============================================================================================|
// |    ______      _____    __      _____    __   __       _____     _____   __  __   ______   |
// |   /_/\___\    ) ___ (  /\_\    /\ __/\  /\_\ /\_\     ) ___ (   /\ __/\ /\_\\  /\/ ____/\  |
// |   ) ) ___/   / /\_/\ \( ( (    ) )  \ \ \/_/( ( (    / /\_/\ \  ) )__\/( ( (/ / /) ) __\/  |
// |  /_/ /  ___ / /_/ (_\ \\ \_\  / / /\ \ \ /\_\\ \_\  / /_/ (_\ \/ / /    \ \_ / /  \ \ \    |
// |  \ \ \_/\__\\ \ )_/ / // / /__\ \ \/ / // / // / /__\ \ )_/ / /\ \ \_   / /  \ \  _\ \ \   |
// |   )_)  \/ _/ \ \/_\/ /( (_____() )__/ /( (_(( (_____(\ \/_\/ /  ) )__/\( (_(\ \ \)____) )  |
// |   \_\____/    )_____(  \/_____/\/___\/  \/_/ \/_____/ )_____(   \/___\/ \/_//__\/\____\/   |
// |                                                                                            |
// |============================================================================================|
// ==============================================================================================
// ======================================== YieldToken ==========================================
// ==============================================================================================


import { ERC20 } from "../../../lib/solady/src/tokens/ERC20.sol";


/// @title YieldToken
/// @notice Tokenized yield token for use in Goldivaults
abstract contract YieldToken is ERC20 {

  string private tokenName;
  string private tokenSymbol;

  address public immutable vault;

  error NotVault();


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                         CONSTRUCTOR                        */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
  

  /// @notice Constructor of this contract
  /// @param _tokenName Name of token
  /// @param _tokenSymbol Symbol of token
  /// @param _vault Address of Goldivault
  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    address _vault
  ) {
    tokenName = _tokenName;
    tokenSymbol = _tokenSymbol;
    vault = _vault;
  }

  /// @notice Returns the name of yield token
  function name() public view override returns (string memory) {
    return tokenName;
  }

  /// @notice Returns the symbol of yield token
  function symbol() public view override returns (string memory) {
    return tokenSymbol;
  }

  /// @notice Mints yield tokens
  /// @dev Callable only by Goldivault
  /// @param to Address to mint to
  /// @param amount Amount of yield tokens to mint
  function mintYT(address to, uint256 amount) external {
    if(msg.sender != vault) revert NotVault();
    _mint(to, amount);
  }

  /// @notice Burns yield tokens
  /// @dev Callable only by Goldivault
  /// @param to Address to burn from
  /// @param amount Amount of yield tokens to burn
  function burnYT(address to, uint256 amount) external {
    if(msg.sender != vault) revert NotVault();
    _burn(to, amount);
  }

}