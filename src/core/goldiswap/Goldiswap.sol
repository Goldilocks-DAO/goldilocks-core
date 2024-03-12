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
// ========================================== Goldiswap =========================================
// ==============================================================================================


import { FixedPointMathLib } from "../../../lib/solady/src/utils/FixedPointMathLib.sol";
import { SafeTransferLib } from "../../../lib/solady/src/utils/SafeTransferLib.sol";
import { ERC20 } from "../../../lib/solady/src/tokens/ERC20.sol";


/// @title Goldiswap
/// @notice Novel AMM & Facilitator of $LOCKS token 
/// @author geeb
/// @author ampnoob
contract Goldiswap is ERC20 {


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                      STATE VARIABLES                       */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  
  uint256 public immutable MAX_FLOOR_REDUCE = 5e18;
  uint256 public immutable MAX_RATIO = 45e16;

  uint256 public fsl;
  uint256 public psl;
  uint256 public targetRatio = 32e16;

  uint256 public lastFloorRaise;
  uint256 public lastFloorDecrease;

  address public immutable goldilocked;
  address public immutable honey;
  address public multisig;


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                          CONSTRUCTOR                       */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @notice Constructor of this contract
  /// @param _fsl Initial value of FSL
  /// @param _psl Initial value of PSL
  /// @param _goldilocked Address of Goldilocked
  /// @param _honey Address of $HONEY
  /// @param _multisig Address of the GoldilocksDAO multisig
  /// @param initialSupply Initial supply of the $LOCKS token
  constructor(
    uint256 _fsl,
    uint256 _psl,
    address _goldilocked,
    address _honey,
    address _multisig,
    uint256 initialSupply
  ) {
    fsl = _fsl;
    psl = _psl;
    goldilocked = _goldilocked;
    honey = _honey;
    multisig = _multisig;
    lastFloorRaise = block.timestamp;
    lastFloorDecrease = block.timestamp;
    _mint(goldilocked, initialSupply);
  }

  /// @notice Returns the name of the $LOCKS token
  function name() public pure override returns (string memory) {
    return "Locks Token";
  }

  /// @notice Returns the symbol of the $LOCKS token
  function symbol() public pure override returns (string memory) {
    return "LOCKS";
  }


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                           ERRORS                           */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  error NotGoldilocked();
  error NotMultisig();
  error ExcessiveSlippage();


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                           EVENTS                           */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  event Buy(address indexed user, uint256 amount);
  event Sale(address indexed user, uint256 amount);
  event Redeem(address indexed user, uint256 amount);


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                       VIEW FUNCTIONS                       */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @notice Returns the $LOCKS floor price
  /// @return $LOCKS floor price
  function floorPrice() external view returns (uint256) {
    return _floorPrice(fsl, totalSupply());
  }

  /// @notice Returns the $LOCKS market price
  /// @return $LOCKS market price
  function marketPrice() external view returns (uint256) {
    return _marketPrice(fsl, psl, totalSupply());
  }


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                    EXTERNAL FUNCTIONS                      */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @notice Buys $LOCKS tokens with $HONEY tokens
  /// @param amount Amount of $LOCKS to buy
  /// @param maxAmount Maximum amount of $HONEY to spend
  function buy(uint256 amount, uint256 maxAmount) external {
    (
      uint256 _fsl, 
      uint256 _psl, 
      uint256 price
    ) = _buyLoop(fsl, psl, totalSupply(), amount);
    uint256 tax = price * 3 / 1000;
    if(price + tax > maxAmount) revert ExcessiveSlippage();
    fsl = _fsl;
    psl = _psl;
    _floorRaise();
    SafeTransferLib.safeTransferFrom(honey, msg.sender, address(this), price);
    SafeTransferLib.safeTransferFrom(honey, msg.sender, multisig, tax);
    _mint(msg.sender, amount);
    emit Buy(msg.sender, amount);
  }

  /// @notice Sells $LOCKS tokens for $HONEY tokens
  /// @param amount Amount of $LOCKS to sell
  /// @param minAmount Minimum amount of $HONEY to receive
  function sell(uint256 amount, uint256 minAmount) external {
    (
      uint256 _fsl,
      uint256 _psl,
      uint256 proceeds
    ) = _sellLoop(fsl, psl, totalSupply(), amount);
    uint256 tax = proceeds * 5 / 100;    
    if(proceeds - tax < minAmount) revert ExcessiveSlippage();
    fsl = _fsl + FixedPointMathLib.divWad(FixedPointMathLib.mulWad(tax, _fsl), (_fsl + _psl));
    psl = _psl + FixedPointMathLib.divWad(FixedPointMathLib.mulWad(tax, _psl), (_fsl + _psl));
    _floorDecrease();
    _burn(msg.sender, amount);
    SafeTransferLib.safeTransfer(honey, msg.sender, proceeds - tax);
    emit Sale(msg.sender, amount);
  }

  /// @notice Redeems $LOCKS tokens for floor value
  /// @param amount Amount of $LOCKS to redeem
  function redeem(uint256 amount) external {
    uint256 _rawTotal = FixedPointMathLib.mulWad(amount, _floorPrice(fsl, totalSupply()));
    fsl -= _rawTotal;
    _floorRaise();
    _burn(msg.sender, amount);
    SafeTransferLib.safeTransfer(honey, msg.sender, _rawTotal);
    emit Redeem(msg.sender, amount);
  }


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                      INTERNAL FUNCTIONS                    */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @notice Calculates floor price of $LOCKS
  /// @dev fsl / supply
  /// @param _fsl Current fsl
  /// @param _supply Current supply
  /// @return floor $LOCKS floor price
  function _floorPrice(uint256 _fsl, uint256 _supply) internal pure returns (uint256 floor) {
    floor = FixedPointMathLib.divWad(_fsl, _supply);
  }
  
  /// @notice Calculates market price of $LOCKS
  /// @dev (fsl / supply) + ((psl / supply) * ((psl + fsl) / fsl)**6)
  /// @param _fsl Current fsl
  /// @param _psl Current psl
  /// @param _supply Current supply
  /// @return market $LOCKS market price
  function _marketPrice(uint256 _fsl, uint256 _psl, uint256 _supply) internal pure returns (uint256 market) {
    market = FixedPointMathLib.divWad(_fsl, _supply) + FixedPointMathLib.mulWad(FixedPointMathLib.divWad(_psl, _supply), _pow(FixedPointMathLib.divWad(_psl + _fsl, _fsl), 6));
  }

  /// @notice Loops through the amount of $LOCKS tokens to buy and calculates total price
  /// @param _fsl Temporary variable for FSL
  /// @param _psl Temporary variable for PSL
  /// @param _supply Temporary variable for Supply
  /// @param leftover Temporary variable for amount of $LOCKS tokens
  /// @return (FSL, PSL, supply and price)
  function _buyLoop(uint256 _fsl, uint256 _psl, uint256 _supply, uint256 leftover) internal pure returns (uint256, uint256, uint256) {
    uint256 market;
    uint256 floor;
    uint256 _buyPrice;
    uint256 increment = FixedPointMathLib.divWad(_supply, 100_000e18);
    while(leftover >= increment) {
      market = _marketPrice(_fsl, _psl, _supply);
      floor = _floorPrice(_fsl, _supply);
      _buyPrice += FixedPointMathLib.mulWad(market, increment);
      _supply += increment;
      if (_psl * 100 >= _fsl * 50) {
        _fsl += FixedPointMathLib.mulWad(market, increment);
      }
      else {
        _psl += FixedPointMathLib.mulWad((market - floor), increment);
        _fsl += FixedPointMathLib.mulWad(floor, increment);
      }
      leftover -= increment;
    }
    if (leftover > 0) {
      market = _marketPrice(_fsl, _psl, _supply);
      floor = _floorPrice(_fsl, _supply);
      _buyPrice += FixedPointMathLib.mulWad(market, leftover);
      _supply += leftover;
      if (_psl * 100 >= _fsl * 50) {
        _fsl += FixedPointMathLib.mulWad(market, leftover);
      }
      else {
        _psl += FixedPointMathLib.mulWad((market - floor), leftover);
        _fsl += FixedPointMathLib.mulWad(floor, leftover);
      }
    }
    return (_fsl, _psl, _buyPrice);
  }

  /// @notice Loops through the amount of $LOCKS tokens to sell and calculates sale amount
  /// @param _fsl Temporary variable for FSL
  /// @param _psl Temporary variable for PSL
  /// @param _supply Temporary variable for Supply
  /// @param leftover Temporary variable for amount of $LOCKS tokens to sell
  /// @return (FSL, PSL, supply and proceeds)
  function _sellLoop(uint256 _fsl, uint256 _psl, uint256 _supply, uint256 leftover) internal pure returns (uint256, uint256, uint256) {
    uint256 market;
    uint256 floor;
    uint256 proceeds;
    uint256 increment = FixedPointMathLib.divWad(_supply, 100_000e18);
    while(leftover >= increment) {
      market = _marketPrice(_fsl, _psl, _supply);
      floor = _floorPrice(_fsl, _supply);
      proceeds += FixedPointMathLib.mulWad(market, increment);
      _psl -= FixedPointMathLib.mulWad((market - floor), increment);
      _fsl -= FixedPointMathLib.mulWad(floor, increment);
      _supply -= increment;
      leftover -= increment;
    }
    if (leftover > 0) {
      market = _marketPrice(_fsl, _psl, _supply);
      floor = _floorPrice(_fsl, _supply);
      proceeds += FixedPointMathLib.mulWad(market, leftover);
      _psl -= FixedPointMathLib.mulWad((market - floor), leftover);
      _fsl -= FixedPointMathLib.mulWad(floor, leftover); 
      _supply -= leftover;
    }
    return (_fsl, _psl, proceeds);
  }

  /// @notice from PRBMath (https://github.com/PaulRBerg/prb-math) by @PaulRBerg
  /// @notice Raises x to the power of y
  /// @param x Base number
  /// @param y Exponent
  /// @return result Calculated value
  function _pow(uint256 x, uint256 y) internal pure returns (uint256 result) {
    result = y & 1 > 0 ? x : 1e18;
    for (y >>= 1; y > 0; y >>= 1) {
      x = FixedPointMathLib.mulWad(x, x);
      if (y & 1 > 0) {
        result = FixedPointMathLib.mulWad(result, x);
      }
    }
  }

  /// @notice If target ratio of the PSL and FSL is exceeded, increases the FSL and target ratio and decreases the PSL
  /// @dev raiseAmount = (psl / fsl) * (psl / 32)
  /// @dev targetRatio increases by targetRatio / 50
  function _floorRaise() internal {
    uint256 currentRatio = FixedPointMathLib.divWad(psl, fsl);
    if(currentRatio > targetRatio) {
      uint256 raiseAmount = FixedPointMathLib.mulWad(currentRatio, psl / 32);
      psl -= raiseAmount;
      fsl += raiseAmount;
      lastFloorRaise = block.timestamp;
      if(currentRatio < MAX_RATIO) {
        targetRatio += targetRatio / 50;
      }
    }
  }

  /// @notice If a day has elapsed since the last floor increase and decrease, decrease the target ratio
  /// @dev decreaseFactor is days since last floor increase
  /// @dev max floor reduce is 5%
  function _floorDecrease() internal {
    uint256 elapsedRaise = block.timestamp - lastFloorRaise;
    uint256 elapsedDrop = block.timestamp - lastFloorDecrease;
    if (elapsedRaise >= 1 days && elapsedDrop >= 1 days) {
      uint256 decreaseFactor = FixedPointMathLib.divWad(elapsedRaise, 1 days);
      if(decreaseFactor > MAX_FLOOR_REDUCE) {
        targetRatio = FixedPointMathLib.mulWad(targetRatio / 100, 100e18 - MAX_FLOOR_REDUCE);
      }
      else {
        targetRatio = FixedPointMathLib.mulWad(targetRatio / 100, 100e18 - decreaseFactor);
      }
      lastFloorDecrease = block.timestamp;
    }
  }


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                   PERMISSIONED FUNCTIONS                   */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @notice Transfers $HONEY to user who is borrowing against their locks
  /// @dev Only Borrow contract can call this function
  /// @param to Address to transfer $HONEY to
  /// @param amount Amount of $HONEY to transfer
  /// @param fee Fee that is sent to treasury
  function borrowTransfer(address to, uint256 amount, uint256 fee) external {
    if(msg.sender != goldilocked) revert NotGoldilocked();
    SafeTransferLib.safeTransfer(honey, to, amount - fee);
    SafeTransferLib.safeTransfer(honey, multisig, fee);
  }

  /// @notice Mints $PRG tokens from $PRG token stirring
  /// @dev Only Porridge contract can call this function
  /// @param to Recipient of minted $LOCKS tokens
  /// @param amount Amount of minted $LOCKS tokens
  function porridgeMint(address to, uint256 amount) external {
    if(msg.sender != goldilocked) revert NotGoldilocked();
    _mint(to, amount);
  }

  /// @notice Allows the DAO to inject liquidity into the contract
  /// @param fslLiq Liquidity added to FSL
  /// @param pslLiq Liquidity added to PSL
  function injectLiquidity(uint256 fslLiq, uint256 pslLiq) external {
    if(msg.sender != multisig) revert NotMultisig();
    fsl += fslLiq;
    psl += pslLiq;
    SafeTransferLib.safeTransferFrom(honey, msg.sender, address(this), fslLiq + pslLiq);
  }

  /// @notice Changes the address of the multisig address
  /// @dev Used after deployment by deployment address
  /// @param _multisig Address of the multisig
  function setMultisig(address _multisig) external {
    if(msg.sender != multisig) revert NotMultisig();
    multisig = _multisig;
  }

}