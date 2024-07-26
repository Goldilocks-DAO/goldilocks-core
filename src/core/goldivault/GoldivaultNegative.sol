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
// ================================== GoldivaultNegative ========================================
// ==============================================================================================


import { FixedPointMathLib } from "../../../lib/solady/src/utils/FixedPointMathLib.sol";
import { SafeTransferLib } from "../../../lib/solady/src/utils/SafeTransferLib.sol";
import { ReentrancyGuard } from "../../../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import { ERC20 } from "../../../lib/solady/src/tokens/ERC20.sol";
import { IGoldivaultNegative } from "../../interfaces/IGoldivaultNegative.sol";
import { OwnershipToken } from "./OwnershipToken.sol";
import { YieldToken } from "./YieldToken.sol";


/// @title Goldivaults
/// @notice Splits deposited assets into ownership tokens representing
/// deposited assets and yield tokens representing future yield of those assets
abstract contract GoldivaultNegative is IGoldivaultNegative, ReentrancyGuard {


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                      STATE VARIABLES                       */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @notice Address of ownership token
  address public immutable ot;

  /// @notice Address of yield token
  address public immutable yt;

  /// @notice Address of deposit token
  address public immutable depositToken;

  /// @notice Address of deposit vault
  address public immutable depositVault;

  /// @notice Address of iBGT
  address public immutable ibgt;

  /// @notice Address of iBGT vault
  address public immutable ibgtVault;

  /// @notice Address of multisig
  address public immutable multisig;

  /// @notice Address of Timelock
  address public immutable timelock;

  /// @notice Timestamp of vault start time
  uint256 public startTime;

  /// @notice Timestamp of vault end time
  uint256 public endTime;

  /// @notice Timestamp of vault conclude time
  uint256 public concludeTime;

  /// @notice Fee charged for early withdrawal
  uint256 public earlyWithdrawalFee;

  /// @notice Fee charged for yield
  uint256 public yieldFee;

  /// @notice Delay period after vault concludes before redemption is allowed
  uint256 public delay;

  /// @notice Duration of vault
  uint256 public duration;

  /// @notice Amount of deposit token in vault
  uint256 public depositTokenAmount;

  /// @notice Addresses of yield tokens
  address[] public yieldTokens;

  /// @notice Indicates if contract is initialized
  bool public initialized;


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                          CONSTRUCTOR                       */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @notice Constructor of this contract
  /// @param _ot Address of ownership token
  /// @param _yt Address of yield token
  /// @param _multisig Address of multisig
  /// @param _timelock Address of Timelock
  /// @param _depositToken Address of deposit token
  /// @param _depositVault Address of deposit token vault
  /// @param _ibgt Address of ibgt
  /// @param _ibgtVault Address of ibgt vault
  constructor(
    address _ot,
    address _yt,
    address _multisig,
    address _timelock,
    address _depositToken,
    address _depositVault,
    address _ibgt,
    address _ibgtVault
  ) {
    ot = _ot;
    yt = _yt;
    multisig = _multisig;
    timelock = _timelock;
    depositToken = _depositToken;
    depositVault = _depositVault;
    ibgt = _ibgt;
    ibgtVault = _ibgtVault;
    ERC20(_depositToken).approve(_depositVault, type(uint256).max);
    ERC20(_ibgt).approve(_ibgtVault, type(uint256).max);
  }


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                    EXTERNAL FUNCTIONS                      */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @inheritdoc IGoldivaultNegative
  function deposit(uint256 amount) external {
    uint256 remainingTime = block.timestamp > endTime ? 0 : endTime - block.timestamp;
    if(remainingTime < 1 days) revert InsufficientTime();
    uint256 timeshare = FixedPointMathLib.divWad(remainingTime, duration);
    SafeTransferLib.safeTransferFrom(depositToken, msg.sender, address(this), amount);
    _vaultDeposit(amount);
    depositTokenAmount += amount;
    OwnershipToken(ot).mintOT(msg.sender, amount);
    YieldToken(yt).mintYT(msg.sender, FixedPointMathLib.mulWad(amount, timeshare));
    emit Deposit(msg.sender, amount);
  }

  /// @inheritdoc IGoldivaultNegative
  function redeemOwnership(uint256 amount) external {
    if(block.timestamp < concludeTime + delay || concludeTime == 0) revert NotConcluded();
    if(amount == 0) revert InvalidRedemption();
    uint256 claimable;
    if(ERC20(depositToken).balanceOf(address(this)) >= depositTokenAmount) {
      claimable = amount;
    }
    else {
      claimable = FixedPointMathLib.mulWad(FixedPointMathLib.divWad(ERC20(depositToken).balanceOf(address(this)), depositTokenAmount), amount);
    }
    OwnershipToken(ot).burnOT(msg.sender, amount);
    depositTokenAmount -= amount;
    SafeTransferLib.safeTransfer(depositToken, msg.sender, claimable);
    emit OwnershipTokenRedemption(msg.sender, claimable);
  }

  /// @inheritdoc IGoldivaultNegative
  function redeemYield(uint256 amount) external nonReentrant {
    if(amount == 0) revert InvalidRedemption();
    if(block.timestamp < concludeTime + delay || concludeTime == 0) revert NotConcluded();
    uint256 yieldShare = FixedPointMathLib.divWad(amount, ERC20(yt).totalSupply());
    YieldToken(yt).burnYT(msg.sender, amount);
    uint256 yieldTokensLength = yieldTokens.length;
    for(uint256 i; i < yieldTokensLength;) {
      uint256 finalYield;
      if(yieldTokens[i] == depositToken) {
        if(ERC20(yieldTokens[i]).balanceOf(address(this)) > depositTokenAmount) {
          finalYield = ERC20(yieldTokens[i]).balanceOf(address(this)) - depositTokenAmount;
        }
        else{
          finalYield = 0;
        }
      }
      else {
        finalYield = ERC20(yieldTokens[i]).balanceOf(address(this));
      }
      uint256 claimable = FixedPointMathLib.mulWad(finalYield, yieldShare);
      SafeTransferLib.safeTransfer(yieldTokens[i], msg.sender, claimable);
      unchecked {
        ++i;
      }
    }
    emit YieldTokenRedemption(msg.sender, amount);
  }

  /// @inheritdoc IGoldivaultNegative
  function conclude() external {
    if(block.timestamp < endTime) revert NotExpired();
    if(concludeTime != 0) revert AlreadyConcluded();
    concludeTime = block.timestamp;
    _concludeVaultRewards();
    emit Conclude(block.timestamp);
  }

  /// @inheritdoc IGoldivaultNegative
  function compound() external {
    _compoundVaultRewards();
  }


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                    PERMISSIONED FUNCTIONS                  */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @inheritdoc IGoldivaultNegative
  function renew() external {
    if(msg.sender != timelock) revert NotTimelock();
    if(concludeTime == 0) revert NotConcluded();
    startTime = block.timestamp;
    endTime = block.timestamp + duration;
    concludeTime = 0;
    emit Renew(block.timestamp, block.timestamp + duration);
  }

  /// @inheritdoc IGoldivaultNegative
  function addYieldTokens(address[] calldata _yieldTokens) external {
    if(msg.sender != multisig) revert NotMultisig();
    uint256 yieldTokensLength = _yieldTokens.length;
    if(yieldTokensLength > 20) revert TooManyTokens();
    for(uint256 i; i < yieldTokensLength;) {
      yieldTokens.push(_yieldTokens[i]);
      unchecked {
        ++i;
      }
    }
    emit NewYieldTokens(_yieldTokens);
  }

  /// @inheritdoc IGoldivaultNegative
  function changeProtocolParameters(
    uint256 _yieldFee,
    uint256 _delay,
    uint256 _duration
  ) external {
    if(msg.sender != timelock) revert NotTimelock();
    yieldFee = _yieldFee;
    delay = _delay;
    duration = _duration;
    emit NewNegativeProtocolParameters(_yieldFee, _delay, _duration);
  }

  /// @inheritdoc IGoldivaultNegative
  function initializeProtocol(
    uint256 _yieldFee,
    uint256 _delay,
    uint256 _duration,
    address[] memory _yieldTokens
  ) external {
    if(msg.sender != multisig) revert NotMultisig();
    if(initialized) revert AlreadyInitialized();
    initialized = true;
    yieldFee = _yieldFee;
    delay = _delay;
    duration = _duration;
    startTime = block.timestamp;
    endTime = block.timestamp + _duration;
    uint256 yieldTokensLength = _yieldTokens.length;
    if(yieldTokensLength > 20) revert TooManyTokens();
    for(uint256 i; i < yieldTokensLength;) {
      yieldTokens.push(_yieldTokens[i]);
      unchecked {
        ++i;
      }
    }
  }


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                   INHERITABLE FUNCTIONS                    */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  function _vaultDeposit(uint256 amount) internal virtual {}
  function _concludeVaultRewards() internal virtual {}
  function _compoundVaultRewards() internal virtual {}
  function _unstakeDepositToken(uint256 amount) internal virtual {}

}