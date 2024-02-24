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
  address public depositToken;
  address[] public yieldTokens;
  address public depositVault;
  address public iBGTVault;
  address public ibgt;
  address public ired;
  address public multisig;
  bool public concluded;



  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                          CONSTRUCTOR                       */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  constructor(
    address _ot,
    address _yt,
    address _depositToken,
    address[] memory _yieldTokens,
    address _depositVault,
    address _iBGTVault,
    address _ibgt,
    address _ired,
    address _multisig
  ) {
    ot = _ot;
    yt = _yt;
    depositToken = _depositToken;
    depositVault = _depositVault;
    iBGTVault = _iBGTVault;
    ibgt = _ibgt;
    ired = _ired;
    multisig = _multisig;
    concluded = false;
    startTime = block.timestamp;
    ERC20(_depositToken).approve(_depositVault, type(uint256).max);
    for(uint8 i; i < _yieldTokens.length; ++i) {
      yieldTokens.push(_yieldTokens[i]);
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
    SafeTransferLib.safeTransferFrom(depositToken, msg.sender, address(this), amount);
    _vaultDeposit(amount);
    OwnershipToken(ot).mintOT(msg.sender, amount);
    YieldToken(yt).mintYT(msg.sender, FixedPointMathLib.mulWad(amount, timeshare));
  }

  /// @notice Redeems yield tokens for share of yield accrued to vault
  /// @param amount Amount of tokens to redeem
  function redeemYield(uint256 amount) external {
    if(block.timestamp < concludeTime + delay || !concluded) revert NotConcluded();
    uint256 yieldShare = FixedPointMathLib.divWad(amount, ERC20(yt).totalSupply());
    YieldToken(yt).burnYT(msg.sender, amount);
    uint256 yieldTokensLength = yieldTokens.length;
    for(uint8 i; i < yieldTokensLength; ++i) {
      uint256 finalYield = ERC20(yieldTokens[i]).balanceOf(address(this));
      uint256 claimable = FixedPointMathLib.mulWad(finalYield, yieldShare);
      SafeTransferLib.safeTransfer(yieldTokens[i], msg.sender, claimable);
    }
  }

  /// @notice Withdraws assets from the vault 
  /// @param amount Amount of tokens to redeem
  function redeemOwnership(uint256 amount) external {
    uint256 remainingTime = block.timestamp > endTime ? 0 : endTime - block.timestamp;
    uint256 timeshare = FixedPointMathLib.divWad(remainingTime, duration);
    OwnershipToken(ot).burnOT(msg.sender, amount);
    YieldToken(yt).burnYT(msg.sender, FixedPointMathLib.mulWad(amount, timeshare));
    _unstakeDepositToken(amount);
    uint256 _fee = fee;
    if(remainingTime > 0) {
      SafeTransferLib.safeTransfer(depositToken, msg.sender, (amount / 1000) * (1000 - _fee));
      SafeTransferLib.safeTransfer(depositToken, multisig, (amount / 1000) * _fee);
    }
    else {
      SafeTransferLib.safeTransfer(depositToken, msg.sender, amount);
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
  function addYieldAssets(address[] calldata _yieldTokens) external {
    if(msg.sender != multisig) revert NotMultisig();
    for(uint8 i; i < _yieldTokens.length; ++i) {
      yieldTokens.push(_yieldTokens[i]);
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
    endTime = block.timestamp + _duration;
  }


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                   INHERITABLE FUNCTIONS                    */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  function directBGTEmissions() external virtual {}
  function directIREDEmissions() external virtual {}
  function _vaultDeposit(uint256 amount) internal virtual {}
  function _concludeVaultRewards() internal virtual {}
  function _compoundVaultRewards() internal virtual {}
  function _unstakeDepositToken(uint256 amount) internal virtual {}

}