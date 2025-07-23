//SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;


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
// ===================================== GLDebtAsset ============================================
// ==============================================================================================


import { ERC20 } from "../../../lib/solady/src/tokens/ERC20.sol";


/// @title GoldilendDebtAsset
/// @notice Goldilend Debt Asset token representing debt asset tokens locked in Goldilend
contract GoldilendDebtAsset is ERC20 {

  string private tokenName;
  string private tokenSymbol;

  address public immutable goldilend;

  error NotGoldilend();


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                         CONSTRUCTOR                        */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @notice Constructor of this contract
  /// @param _tokenName Name of token
  /// @param _tokenSymbol Symbol of token
  /// @param _goldilend Address of Goldilend
  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    address _goldilend
  ) {
    tokenName = _tokenName;
    tokenSymbol = _tokenSymbol;
    goldilend = _goldilend;
  }

  /// @notice Returns the name of yield token
  function name() public view override returns (string memory) {
    return tokenName;
  }

  /// @notice Returns the symbol of yield token
  function symbol() public view override returns (string memory) {
    return tokenSymbol;
  }

  /// @notice Mints glDebtAsset tokens
  /// @dev Callable only by Goldilend
  /// @param to Address to mint to
  /// @param amount Amount of glDebtAsset tokens to mint
  function mintglDebtAsset(address to, uint256 amount) external {
    if(msg.sender != goldilend) revert NotGoldilend();
    _mint(to, amount);
  }

  /// @notice Burns glDebtAsset tokens
  /// @dev Callable only by Goldilend
  /// @param from Address to burn from
  /// @param amount Amount of glDebtAsset tokens to burn
  function burnglDebtAsset(address from, uint256 amount) external {
    if(msg.sender != goldilend) revert NotGoldilend();
    _burn(from, amount);
  }

}