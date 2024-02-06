//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;


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


import { FixedPointMathLib } from "../../lib/solady/src/utils/FixedPointMathLib.sol";
import { SafeTransferLib } from "../../lib/solady/src/utils/SafeTransferLib.sol";
import { ERC20 } from "../../lib/solady/src/tokens/ERC20.sol";


/// @title Goldiswap
/// @notice Novel AMM & Facilitator of $LOCKS token 
/// @author geeb
/// @author ampnoob
contract Goldiswap is ERC20 {


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                      STATE VARIABLES                       */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  
  uint256 public immutable DAYS_SECONDS = 86400;
  uint256 public immutable MAX_FLOOR_REDUCE = 5e18;
  uint256 public immutable MAX_RATIO = 45e16;

  uint256 public fsl;
  uint256 public psl;
  uint256 public targetRatio = 36e16;

  uint256 public lastFloorRaise;
  uint256 public lastFloorDecrease;

  address public multisig;
  address public porridge;
  address public borrow;  
  address public honey;


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                          CONSTRUCTOR                       */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @notice Constructor of this contract
  /// @param _fsl Initial value of FSL
  /// @param _psl Initial value of PSL
  /// @param _multisig Address of the GoldilocksDAO multisig
  /// @param _porridge Address of Porridge
  /// @param _borrow Address of Borrow
  /// @param _honey Address of $HONEY
  constructor(
    uint256 _fsl,
    uint256 _psl,
    address _multisig,
    address _porridge,
    address _borrow,
    address _honey
  ) {
    fsl = _fsl;
    psl = _psl;
    multisig = _multisig;
    porridge = _porridge;
    borrow = _borrow;
    honey = _honey;
    lastFloorRaise = block.timestamp;
    lastFloorDecrease = block.timestamp;
    _mint(msg.sender, 100000000e18);
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


  error NotMultisig();
  error NotPorridge();
  error NotBorrow();
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
    uint256 _supply = totalSupply();
    uint256 _fsl = fsl;
    uint256 _psl = psl;
    (
      uint256 __psl, 
      uint256 __fsl, 
      uint256 __buyPrice
    ) = _buyLoop(_psl, _fsl, _supply, amount);
    uint256 tax = (__buyPrice / 1000) * 3;
    if(__buyPrice + tax > maxAmount) revert ExcessiveSlippage();
    fsl = __fsl;
    psl = __psl;
    _floorRaise();
    SafeTransferLib.safeTransferFrom(honey, msg.sender, address(this), __buyPrice);
    SafeTransferLib.safeTransferFrom(honey, msg.sender, multisig, tax);
    _mint(msg.sender, amount);
    emit Buy(msg.sender, amount);
  }

  /// @notice Sells $LOCKS tokens for $HONEY tokens
  /// @param amount Amount of $LOCKS to sell
  /// @param minAmount Minimum amount of $HONEY to receive
  function sell(uint256 amount, uint256 minAmount) external {
    uint256 _supply = totalSupply();
    uint256 _fsl = fsl;
    uint256 _psl = psl;
    (
      uint256 __psl,
      uint256 __fsl,
      uint256 __saleAmount
    ) = _sellLoop(_psl, _fsl, _supply, amount);
    uint256 tax = (__saleAmount / 1000) * 53;
    if(__saleAmount - tax < minAmount) revert ExcessiveSlippage();
    fsl = __fsl + FixedPointMathLib.divWad(FixedPointMathLib.mulWad(tax, __fsl), (__fsl + __psl));
    psl = __psl + FixedPointMathLib.divWad(FixedPointMathLib.mulWad(tax, __psl), (__fsl + __psl));
    _floorReduce();
    _burn(msg.sender, amount);
    SafeTransferLib.safeTransfer(honey, msg.sender, __saleAmount - tax);
    emit Sale(msg.sender, amount);
  }

  /// @notice Redeems $LOCKS tokens for floor value
  /// @param amount Amount of $LOCKS to redeem
  function redeem(uint256 amount) public {
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
  /// @param _psl Temporary variable for PSL
  /// @param _fsl Temporary variable for FSL
  /// @param _supply Temporary variable for Supply
  /// @param _leftover Temporary variable for amount of $LOCKS tokens
  /// @return (PSL, FSL, supply and buy price)
  function _buyLoop(uint256 _psl, uint256 _fsl, uint256 _supply, uint256 _leftover) internal pure returns (uint256, uint256, uint256) {
    uint256 _market;
    uint256 _floor;
    uint256 _buyPrice;
    uint256 increment = FixedPointMathLib.divWad(_supply, 100000e18);
    uint256 incrementUnit = increment / 1e18;
    if(increment == 0 || incrementUnit == 0) {
      increment = 1000e18;
      incrementUnit = 1000;
    }
    while(_leftover >= increment) {
      _market = _marketPrice(_fsl, _psl, _supply);
      _floor = _floorPrice(_fsl, _supply);
      _buyPrice += _market * incrementUnit;
      _supply += increment;
      if (_psl * 100 >= _fsl * 50) {
        _fsl += _market * incrementUnit;
      }
      else {
        _psl += (_market - _floor) * incrementUnit;
        _fsl += _floor * incrementUnit;
      }
      _leftover -= increment;
    }
    if (_leftover > 0) {
      _market = _marketPrice(_fsl, _psl, _supply);
      _floor = _floorPrice(_fsl, _supply);
      _buyPrice += FixedPointMathLib.mulWad(_market, _leftover);
      _supply += _leftover;
      if (_psl * 100 >= _fsl * 50) {
        _fsl += FixedPointMathLib.mulWad(_market, _leftover);
      }
      else {
        _psl += FixedPointMathLib.mulWad((_market - _floor), _leftover);
        _fsl += FixedPointMathLib.mulWad(_floor, _leftover);
      }
    }
    return (_psl, _fsl, _buyPrice);
  }

  /// @notice Loops through the amount of $LOCKS tokens to sell and calculates sale amount
  /// @param _psl Temporary variable for PSL
  /// @param _fsl Temporary variable for FSL
  /// @param _supply Temporary variable for Supply
  /// @param _leftover Temporary variable for amount of $LOCKS tokens to sell
  /// @return (PSL, FSL, supply and sale amount)
  function _sellLoop(uint256 _psl, uint256 _fsl, uint256 _supply, uint256 _leftover) internal pure returns (uint256, uint256, uint256) {
    uint256 _market;
    uint256 _floor;
    uint256 _saleAmount;
    uint256 increment = FixedPointMathLib.divWad(_supply, 100000e18);
    uint256 incrementUnit = increment / 1e18;
    if(increment == 0 || incrementUnit == 0) {
      increment = 1000e18;
      incrementUnit = 1000;
    }
    while(_leftover >= increment) {
      _market = _marketPrice(_fsl, _psl, _supply);
      _floor = _floorPrice(_fsl, _supply);
      _saleAmount += _market * incrementUnit;
      _psl -= (_market - _floor) * incrementUnit;
      _fsl -= _floor * incrementUnit;
      _supply -= increment;
      _leftover -= increment;
    }
    if (_leftover > 0) {
      _market = _marketPrice(_fsl, _psl, _supply);
      _floor = _floorPrice(_fsl, _supply);
      _saleAmount += FixedPointMathLib.mulWad(_market, _leftover);
      _psl -= FixedPointMathLib.mulWad((_market - _floor), _leftover);
      _fsl -= FixedPointMathLib.mulWad(_floor, _leftover); 
      _supply -= _leftover;
    }
    return (_psl, _fsl, _saleAmount);
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

  /// @notice If targetRatio of PSL and FSL is exceeded, increases the FSL and target ratio and decrease the PSL
  /// @dev raiseAmount = (psl / fsl) * (psl / 32)
  /// @dev targetRatio increases by targetRatio / 50
  function _floorRaise() internal {
    uint256 currentRatio = FixedPointMathLib.divWad(psl, fsl);
    if(currentRatio >= targetRatio && currentRatio < MAX_RATIO) {
      uint256 raiseAmount = FixedPointMathLib.mulWad(currentRatio, psl / 32);
      psl -= raiseAmount;
      fsl += raiseAmount;
      targetRatio += targetRatio / 50;
      lastFloorRaise = block.timestamp;
    }
  }

  /// @notice If a day has elapsed since the last floor increase and decrease, decrease the target ratio
  /// @dev decreaseFactor is days since last floor increase
  /// @dev max floor reduce is 5%
  function _floorReduce() internal {
    uint256 elapsedRaise = block.timestamp - lastFloorRaise;
    uint256 elapsedDrop = block.timestamp - lastFloorDecrease;
    if (elapsedRaise >= DAYS_SECONDS && elapsedDrop >= DAYS_SECONDS) {
      uint256 decreaseFactor = FixedPointMathLib.divWad(elapsedRaise, DAYS_SECONDS);
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
    if(msg.sender != borrow) revert NotBorrow();
    SafeTransferLib.safeTransfer(honey, to, amount - fee);
    SafeTransferLib.safeTransfer(honey, multisig, fee);
  }

  /// @notice Mints $PRG tokens from $PRG token stirring
  /// @dev Only Porridge contract can call this function
  /// @param to Recipient of minted $LOCKS tokens
  /// @param amount Amount of minted $LOCKS tokens
  function porridgeMint(address to, uint256 amount) external {
    if(msg.sender != porridge) revert NotPorridge();
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