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
// ======================================== Goldivaults =========================================
// ==============================================================================================


import { FixedPointMathLib } from "../../lib/solady/src/utils/FixedPointMathLib.sol";
import { SafeTransferLib } from "../../lib/solady/src/utils/SafeTransferLib.sol";
import { ERC20 } from "../../lib/solady/src/tokens/ERC20.sol";
import { OwnershipToken } from "./OwnershipToken.sol";
import { YieldToken } from "./YieldToken.sol";
import { IBGTVault } from "../mock/IBGTVault.sol";
import { IRedVault } from "../mock/IRedVault.sol";


/// @title Goldivaults
/// @notice Splits yield bearing tokens in yield and principal tokens
/// @author ampnoob
/// @author geeb
abstract contract Goldivault {


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                      STATE VARIABLES                       */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  uint256 startTime;
  uint256 endTime;
  uint256 concludeTime;
  uint256 finalYield;
  uint256 fee;
  uint256 delay;
  address ot;
  address yt;
  address depositAsset;
  address yieldAsset;
  address vault;
  address ired;
  address treasury;
  bool concluded;


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                          CONSTRUCTOR                       */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  constructor(
    uint256 _fee,
    uint256 _delay,
    address _ot,
    address _yt,
    address _depositAsset,
    address _yieldAsset,
    address _vault,
    address _ired,
    address _treasury
  ) {
    concluded = false;
    startTime = block.timestamp;
    endTime = block.timestamp + 365 days;
    fee = _fee;
    delay = _delay;
    ot = _ot;
    yt = _yt;
    depositAsset = _depositAsset;
    yieldAsset = _yieldAsset;
    vault = _vault;
    ired = _ired;
    treasury = _treasury;
  }


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                           ERRORS                           */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  error InsufficientTime();
  error NotExpired();
  error NotConcluded();
  error AlreadyConcluded();
  error ExcessiveRedeem();


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                    EXTERNAL FUNCTIONS                      */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @notice Deposits asset into vault to receive ownership and yield tokens
  /// @param amount Amount of tokens to deposit
  function deposit(uint256 amount) external {
    uint256 remainingTime = endTime - block.timestamp;
    if(remainingTime < 30 days) revert InsufficientTime();
    uint256 timeshare = FixedPointMathLib.divWad(remainingTime, 365 days);
    SafeTransferLib.safeTransferFrom(depositAsset, msg.sender, address(this), amount);
    _vaultDeposit();
    OwnershipToken(ot).mint(msg.sender, amount);
    YieldToken(yt).mint(msg.sender, FixedPointMathLib.mulWad(amount, timeshare));
  }

  /// @notice Redeems yield tokens for share of yield accrued to vault
  /// @param amount Amount of tokens to redeem
  function redeemYield(uint256 amount) external {
    if(block.timestamp < concludeTime + delay || !concluded) revert NotConcluded();
    uint256 yieldShare = FixedPointMathLib.divWad(amount, ERC20(yt).totalSupply());
    uint256 claimable = FixedPointMathLib.mulWad(finalYield, yieldShare);
    YieldToken(yt).burn(msg.sender, amount);
    SafeTransferLib.safeTransferFrom(yieldAsset, address(this), msg.sender, claimable);
  }

  /// @notice Withdraws assets from the vault 
  /// @param amount Amount of tokens to redeem
  function redeemOwnership(uint256 amount) external {
    uint256 remainingTime = block.timestamp > endTime ? 0 : endTime - block.timestamp;
    uint256 totalTimeDurationRatio = FixedPointMathLib.divWad(remainingTime, endTime - startTime);
    OwnershipToken(ot).burn(msg.sender, amount);
    YieldToken(yt).burn(msg.sender, FixedPointMathLib.mulWad(amount, totalTimeDurationRatio));
    if(remainingTime > 0) {
      SafeTransferLib.safeTransfer(depositAsset, msg.sender, (amount / 1000) * 995);
      SafeTransferLib.safeTransfer(depositAsset, treasury, (amount / 1000) * 5);
    }
    else {
      SafeTransferLib.safeTransfer(depositAsset, msg.sender, amount);
    }
  }

  /// @notice Concludes the vault at expiry
  function conclude() external {
    if(block.timestamp < endTime) revert NotExpired();
    if(concluded) revert AlreadyConcluded();
    concluded = true;
    concludeTime = block.timestamp;
    SafeTransferLib.safeTransfer(yieldAsset, treasury, (ERC20(yieldAsset).balanceOf(address(this)) / 100) * fee);
    _concludeVaultRewards();
    finalYield = ERC20(yieldAsset).balanceOf(address(this));
  }

  /// @notice Compounds yield from vault and restakes it
  function compound() external {
    _compoundVaultRewards();
  }


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                   INHERITABLE FUNCTIONS                    */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  function directBGTEmissions() external virtual {}
  function directIREDEmissions() external virtual {}
  function _vaultDeposit() internal virtual {}
  function _concludeVaultRewards() internal virtual {
    IBGTVault(vault).exit();
    //code to unstake all honey from the vault (and, if not done automatically, claim outstanding yield and convert it to IBGT)
    //code to unstake all the contract's IBGT (and send any outstanding IBGT staking rewards to treasury)
  }
  function _compoundVaultRewards() internal virtual {
    // IRedVault(ired).getReward();
    // uint256 iredRewards = ERC20(ired).balanceOf(address(this));
    // IRedVault(ired).stake(iredRewards);
    // IBGTVault(ibgt).getReward();
    // uint256 ibgtRewards = ERC20(ibgt).balanceOf(address(this));
    // IBGTVault(ibgt).stake(ibgtRewards);
  }

}