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
// ======================================== Goldivault ==========================================
// ==============================================================================================


import { FixedPointMathLib } from "../../lib/solady/src/utils/FixedPointMathLib.sol";
import { SafeTransferLib } from "../../lib/solady/src/utils/SafeTransferLib.sol";
import { ERC20 } from "../../lib/solady/src/tokens/ERC20.sol";
import { OwnershipToken } from "./OwnershipToken.sol";
import { YieldToken } from "./YieldToken.sol";


/// @title Goldivaults
/// @notice Splits yield bearing tokens in yield and principal tokens
/// @author ampnoob
/// @author geeb
abstract contract Goldivault {


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                      STATE VARIABLES                       */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  uint256 public startTime;
  uint256 public endTime;
  uint256 public concludeTime;
  uint256 public fee;
  uint256 public delay;
  uint256 public duration;
  address public ot;
  address public yt;
  address public ibgt;
  address[] public yieldAssets;
  address public vault;
  address public ibgtvault;
  address public ired;
  address public multisig;
  bool concluded;



  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                          CONSTRUCTOR                       */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  constructor(
    address _ot,
    address _yt,
    address _ibgt,
    address[] memory _yieldAssets,
    address _vault,
    address _ibgtvault,
    address _ired,
    address _multisig
  ) {
    ot = _ot;
    yt = _yt;
    ibgt = _ibgt;
    vault = _vault;
    ibgtvault = _ibgtvault;
    ired = _ired;
    multisig = _multisig;
    concluded = false;
    startTime = block.timestamp;
    endTime = block.timestamp + duration;
    for(uint8 i; i < _yieldAssets.length; ++i) {
      yieldAssets.push(_yieldAssets[i]);
    }
  }


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                           ERRORS                           */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  error InsufficientTime();
  error NotExpired();
  error NotConcluded();
  error NotMultisig();
  error AlreadyConcluded();
  error ExcessiveRedeem();


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                    EXTERNAL FUNCTIONS                      */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @notice Deposits asset into vault to receive ownership and yield tokens
  /// @param amount Amount of tokens to deposit
  function deposit(uint256 amount) external {
    uint256 remainingTime = endTime - block.timestamp;
    if(remainingTime < 1 days) revert InsufficientTime();
    uint256 timeshare = FixedPointMathLib.divWad(remainingTime, duration);
    SafeTransferLib.safeTransferFrom(ibgt, msg.sender, address(this), amount);
    _vaultDeposit(amount);
    OwnershipToken(ot).mint(msg.sender, amount);
    YieldToken(yt).mint(msg.sender, FixedPointMathLib.mulWad(amount, timeshare));
  }

  /// @notice Redeems yield tokens for share of yield accrued to vault
  /// @param amount Amount of tokens to redeem
  function redeemYield(uint256 amount) external {
    if(block.timestamp < concludeTime + delay || !concluded) revert NotConcluded();
    uint256 yieldShare = FixedPointMathLib.divWad(amount, ERC20(yt).totalSupply());
    YieldToken(yt).burn(msg.sender, amount);
    uint256 yieldAssetsLength = yieldAssets.length;
    for(uint8 i; i < yieldAssetsLength; ++i) {
      uint256 finalYield = ERC20(yieldAssets[i]).balanceOf(address(this));
      uint256 claimable = FixedPointMathLib.mulWad(finalYield, yieldShare);
      SafeTransferLib.safeTransfer(yieldAssets[i], msg.sender, claimable);
    }
  }

  /// @notice Withdraws assets from the vault 
  /// @param amount Amount of tokens to redeem
  function redeemOwnership(uint256 amount) external {
    uint256 remainingTime = block.timestamp > endTime ? 0 : endTime - block.timestamp;
    uint256 timeshare = FixedPointMathLib.divWad(remainingTime, duration);
    OwnershipToken(ot).burn(msg.sender, amount);
    YieldToken(yt).burn(msg.sender, FixedPointMathLib.mulWad(amount, timeshare));
    _unstakeDepositToken();
    uint256 _fee = fee;
    if(remainingTime > 0) {
      SafeTransferLib.safeTransfer(ibgt, msg.sender, (amount / 1000) * (1000 - _fee));
      SafeTransferLib.safeTransfer(ibgt, multisig, (amount / 1000) * _fee);
    }
    else {
      SafeTransferLib.safeTransfer(ibgt, msg.sender, amount);
    }
  }

  /// @notice Concludes the vault at expiry
  function conclude() external {
    if(block.timestamp < endTime) revert NotExpired();
    if(concluded) revert AlreadyConcluded();
    concluded = true;
    concludeTime = block.timestamp;
    _concludeVaultRewards();
  }

  /// @notice Compounds yield from vault and restakes it
  function compound() external {
    _compoundVaultRewards();
  }

  /// @notice Allows DAO to add yield assets to vault
  function addYieldAssets(address[] calldata _yieldAssets) external {
    if(msg.sender != multisig) revert NotMultisig();
    for(uint8 i; i < _yieldAssets.length; ++i) {
      yieldAssets.push(_yieldAssets[i]);
    }
  }

  /// @notice Allows DAO to set early withdrawal fee
  function setEarlyWithdrawalFee(uint256 _fee) external {
    if(msg.sender != multisig) revert NotMultisig();
    fee = _fee;
  }

  /// @notice Allows DAO to set protocol parameters
  function setParameters(uint256 _fee, uint256 _delay, uint256 _duration) external {
    if(msg.sender != multisig) revert NotMultisig();
    fee = _fee;
    delay = _delay;
    duration = _duration;
  }


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                   INHERITABLE FUNCTIONS                    */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  function directBGTEmissions() external virtual {}
  function directIREDEmissions() external virtual {}
  function _vaultDeposit(uint256 amount) internal virtual {}
  function _concludeVaultRewards() internal virtual {}
  function _compoundVaultRewards() internal virtual {}
  function _unstakeDepositToken() internal virtual {}

}