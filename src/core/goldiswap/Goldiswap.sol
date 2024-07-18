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
// ======================================== Goldiswap ===========================================
// ==============================================================================================


import { FixedPointMathLib } from "../../../lib/solady/src/utils/FixedPointMathLib.sol";
import { SafeTransferLib } from "../../../lib/solady/src/utils/SafeTransferLib.sol";
import { ERC20 } from "../../../lib/solady/src/tokens/ERC20.sol";
import { IGoldiswap } from "../../interfaces/IGoldiswap.sol";


/// @title Goldiswap
/// @notice Novel AMM and facilitator of Locks token
contract Goldiswap is IGoldiswap, ERC20 {


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                      STATE VARIABLES                       */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  
  /// @notice Maximum percentage decrease in target ratio
  uint256 public immutable MAX_FLOOR_REDUCE = 5e18;

  /// @notice Maximum ratio between PSL and FSL
  uint256 public immutable MAX_RATIO = 45e16;

  /// @notice Address of Goldilocked
  address public immutable goldilocked;
  
  /// @notice Address of Honey
  address public immutable honey;

  /// @notice Address of multisig
  address public immutable multisig;

  /// @notice Address of Timelock
  address public immutable timelock;

  /// @notice Floor supporting liquidity
  uint256 public fsl;

  /// @notice Price supporting liquidity
  uint256 public psl;

  /// @notice Target ratio between PSL and FSL
  uint256 public targetRatio = 38e16;

  /// @notice Timestamp of last floor increase
  uint256 public lastFloorIncrease;

  /// @notice Timestamp of last floor decrease
  uint256 public lastFloorDecrease;

  /// @notice Indicates if trading is active
  bool public tradingActive;

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                          CONSTRUCTOR                       */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @notice Constructor of this contract
  /// @param _fsl Initial value of FSL
  /// @param _psl Initial value of PSL
  /// @param _goldilocked Address of Goldilocked
  /// @param _honey Address of Honey
  /// @param _multisig Address of multisig
  /// @param initialSupply Initial supply of Locks token
  constructor(
    uint256 _fsl,
    uint256 _psl,
    address _goldilocked,
    address _honey,
    address _multisig,
    address _timelock,
    uint256 initialSupply
  ) {
    fsl = _fsl;
    psl = _psl;
    goldilocked = _goldilocked;
    honey = _honey;
    multisig = _multisig;
    timelock = _timelock;
    lastFloorIncrease = block.timestamp;
    lastFloorDecrease = block.timestamp;
    _mint(goldilocked, initialSupply);
  }

  /// @notice Returns the name of Locks token
  function name() public pure override returns (string memory) {
    return "Locks";
  }

  /// @notice Returns the symbol of Locks token
  function symbol() public pure override returns (string memory) {
    return "LOCKS";
  }


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                       VIEW FUNCTIONS                       */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @inheritdoc IGoldiswap
  function floorPrice() external view returns (uint256) {
    return _floorPrice(fsl, totalSupply());
  }

  /// @inheritdoc IGoldiswap
  function marketPrice() external view returns (uint256) {
    return _marketPrice(fsl, psl, totalSupply());
  }


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                    EXTERNAL FUNCTIONS                      */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @inheritdoc IGoldiswap
  function buy(uint256 amount, uint256 maxAmount) external {
    if(!tradingActive) revert NotActive();
    (
      uint256 _fsl, 
      uint256 _psl, 
      uint256 price
    ) = _buyLoop(fsl, psl, totalSupply(), amount);
    uint256 tax = price * 3 / 1000;
    if(price + tax > maxAmount) revert ExcessiveSlippage();
    fsl = _fsl;
    psl = _psl;
    _floorIncrease();
    SafeTransferLib.safeTransferFrom(honey, msg.sender, address(this), price + tax);
    SafeTransferLib.safeTransfer(honey, multisig, tax);
    _mint(msg.sender, amount);
    emit Buy(msg.sender, amount);
  }

  /// @inheritdoc IGoldiswap
  function sell(uint256 amount, uint256 minAmount) external {
    if(!tradingActive) revert NotActive();
    (
      uint256 _fsl,
      uint256 _psl,
      uint256 proceeds
    ) = _sellLoop(fsl, psl, totalSupply(), amount);
    uint256 tax = proceeds * 5 / 100;    
    if(proceeds - tax < minAmount) revert ExcessiveSlippage();
    uint256 additionalPsl = FixedPointMathLib.divWad(FixedPointMathLib.mulWad(tax, _psl), (_fsl + _psl));
    psl = _psl + additionalPsl;
    fsl = _fsl + tax - additionalPsl;
    _floorDecrease();
    _burn(msg.sender, amount);
    SafeTransferLib.safeTransfer(honey, msg.sender, proceeds - tax);
    emit Sale(msg.sender, amount);
  }

  /// @inheritdoc IGoldiswap
  function redeem(uint256 amount) external {
    uint256 redemption = FixedPointMathLib.mulWad(amount, _floorPrice(fsl, totalSupply()));
    fsl -= redemption;
    _floorIncrease();
    _burn(msg.sender, amount);
    SafeTransferLib.safeTransfer(honey, msg.sender, redemption);
    emit Redeem(msg.sender, amount);
  }

  /// @inheritdoc IGoldiswap
  function injectLiquidity(uint256 liquidity) external {
    uint256 _fsl = fsl;
    uint256 _psl = psl;
    uint256 additionalPsl = FixedPointMathLib.divWad(FixedPointMathLib.mulWad(liquidity, _psl), (_fsl + _psl));
    psl = _psl + additionalPsl;
    fsl = _fsl + liquidity - additionalPsl;
    SafeTransferLib.safeTransferFrom(honey, msg.sender, address(this), liquidity);
  }


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                   INTERNAL VIEW FUNCTIONS                  */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @notice Calculates Locks floor price
  /// @dev floor = fsl / supply
  /// @param _fsl Current fsl
  /// @param _supply Current supply
  function _floorPrice(uint256 _fsl, uint256 _supply) internal pure returns (uint256) {
    return FixedPointMathLib.divWad(_fsl, _supply);
  }
  
  /// @notice Calculates Locks market
  /// @dev market = (fsl / supply) + ((psl / supply) * ((psl + fsl) / fsl)**6)
  /// @param _fsl Current fsl
  /// @param _psl Current psl
  /// @param _supply Current supply
  function _marketPrice(uint256 _fsl, uint256 _psl, uint256 _supply) internal pure returns (uint256) {
    return FixedPointMathLib.divWad(_fsl, _supply) + FixedPointMathLib.mulWad(FixedPointMathLib.divWad(_psl, _supply), _pow(FixedPointMathLib.divWad(_psl + _fsl, _fsl), 6));
  }

  /// @notice Loops through amount of Locks tokens to buy and calculates total price
  /// @param _fsl Temporary variable for fsl
  /// @param _psl Temporary variable for psl
  /// @param _supply Temporary variable for supply
  /// @param leftover Temporary variable for amount of Locks tokens
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

  /// @notice Loops through amount of Locks tokens to sell and calculates sale amount
  /// @param _fsl Temporary variable for fsl
  /// @param _psl Temporary variable for psl
  /// @param _supply Temporary variable for supply
  /// @param leftover Temporary variable for amount of Locks tokens to sell
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


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                      INTERNAL FUNCTIONS                    */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @notice If target ratio is exceeded, increase fsl and target ratio and decrease psl
  /// @dev increaseAmount = (psl / fsl) * (psl / 32)
  /// @dev targetRatio increases by targetRatio / 50
  function _floorIncrease() internal {
    uint256 currentRatio = FixedPointMathLib.divWad(psl, fsl);
    if(currentRatio > targetRatio) {
      uint256 increaseAmount = FixedPointMathLib.mulWad(currentRatio, psl / 32);
      psl -= increaseAmount;
      fsl += increaseAmount;
      lastFloorIncrease = block.timestamp;
      if(currentRatio < MAX_RATIO) {
        targetRatio += targetRatio / 50;
      }
    }
  }

  /// @notice If day has elapsed since last floor increase and decrease, decrease the target ratio
  /// @dev decreaseFactor is days since last floor increase
  function _floorDecrease() internal {
    uint256 elapsedIncrease = block.timestamp - lastFloorIncrease;
    uint256 elapsedDecrease = block.timestamp - lastFloorDecrease;
    if (elapsedIncrease >= 1 days && elapsedDecrease >= 1 days) {
      uint256 decreaseFactor = FixedPointMathLib.divWad(elapsedIncrease, 1 days);
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


  /// @inheritdoc IGoldiswap
  function borrowTransfer(address to, uint256 amount, uint256 fee) external {
    if(msg.sender != goldilocked) revert NotGoldilocked();
    SafeTransferLib.safeTransfer(honey, to, amount - fee);
    SafeTransferLib.safeTransfer(honey, multisig, fee);
  }

  /// @inheritdoc IGoldiswap
  function porridgeMint(address to, uint256 amount, uint256 cost) external {
    if(msg.sender != goldilocked) revert NotGoldilocked();
    uint256 marketPriceBefore = _marketPrice(fsl, psl, totalSupply());
    fsl += cost;
    _mint(to, amount);
    uint256 marketPriceAfter = _marketPrice(fsl, psl, totalSupply());
    if(marketPriceAfter < marketPriceBefore * 95 / 100) revert ExcessiveSlippage();
  }

  /// @inheritdoc IGoldiswap
  function initializeProtocol(uint256 amount) external {
    if(msg.sender != multisig) revert NotMultisig();
    tradingActive = true;
    SafeTransferLib.safeTransferFrom(honey, msg.sender, address(this), amount);
  }

}