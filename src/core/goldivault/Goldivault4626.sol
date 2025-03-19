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
// ===================================== Goldivault4626 =========================================
// ==============================================================================================


import { FixedPointMathLib } from "../../../lib/solady/src/utils/FixedPointMathLib.sol";
import { SafeTransferLib } from "../../../lib/solady/src/utils/SafeTransferLib.sol";
import { ReentrancyGuard } from "../../../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import { ERC20 } from "../../../lib/solady/src/tokens/ERC20.sol";
import { ERC4626 } from "../../../lib/solady/src/tokens/ERC4626.sol";
import { IV3SwapRouter } from "../../interfaces/IV3SwapRouter.sol";
import { IGoldivault4626 } from "../../interfaces/IGoldivault4626.sol";
import { OwnershipToken } from "./OwnershipToken.sol";
import { YieldToken } from "./YieldToken.sol";


/// @title Goldivaults
/// @notice Splits deposited assets into ownership tokens representing
/// deposited assets and yield tokens representing future yield of those assets
///This vault is for streaming the yield continuously to users. Staking mechanism for YT copied from Goldilend
contract Goldivault4626 is IGoldivault4626, ReentrancyGuard {


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                      STATE VARIABLES                       */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @notice Address of ownership token
  address public immutable ot;

  /// @notice Address of yield token
  address public immutable yt;

  /// @notice Address of deposit token
  address public immutable depositToken;
  
  /// @notice Address of erc4626 deposit vault
  address public immutable depositVault;

  /// @notice Address of multisig
  address public immutable multisig;

  /// @notice Address of Kodiak SwapRouter02
  address router;

  /// @notice YT trade fee
  uint256 tradeFee;

  /// @notice Fee charged for yield
  uint256 public yieldFee;

  /// @notice Timestamp of vault start time
  uint256 public startTime;

  /// @notice Timestamp of vault end time
  uint256 public endTime;

  /// @notice Amount of deposit token in vault
  uint256 public depositTokenAmount;

  /// @notice Decimals of underlying asset
  uint256 public tokenDecimals;

  /// @notice Claimable underlying per staked YT
  uint256 public claimableUnderlyingPerYTStored;

  /// @notice Assets/shares ratio at last claim update
  uint256 public lastRatio;

  /// @notice Amount of yield tokens staked in contract
  uint256 public totalYtStaked;

  /// @notice Amount of YT staked per user
  mapping(address => uint256) public ytStaked;

  /// @notice Maps user to amount of claimable Underlying
  mapping(address => uint256) public claimableUnderlying;

  /// @notice Maps user to amount of Underlying reward debt
  mapping(address => uint256) public underlyingPerTokenDebt;


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                          CONSTRUCTOR                       */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @notice Constructor of this contract
  /// @param _ot Address of ownership token
  /// @param _yt Address of yield token
  /// @param _multisig Address of multisig
  /// @param _depositToken Address of deposit token
  /// @param _depositVault Address of deposit token vault
  /// @param _router Address of Kodiak SwapRouter02
  /// @param _tradeFee Fee charged on YT trades
  /// @param _yieldFee Fee charged for yield
  /// @param _tokenDecimals Decimals of underlying asset
  /// @param _duration Duration of vault
  constructor(
    address _ot,
    address _yt,
    address _multisig,
    address _depositToken,
    address _depositVault,
    address _router,
    uint256 _tradeFee,
    uint256 _yieldFee,
    uint256 _tokenDecimals,
    uint256 _duration
  ) {
    ot = _ot;
    yt = _yt;
    multisig = _multisig;
    depositToken = _depositToken;
    depositVault = _depositVault;
    router = _router;
    tradeFee = _tradeFee;
    yieldFee = _yieldFee;
    tokenDecimals = _tokenDecimals;
    lastRatio = ERC4626(depositVault).convertToAssets(tokenDecimals);
    startTime = block.timestamp;
    endTime = block.timestamp + _duration;
  }


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                    EXTERNAL FUNCTIONS                      */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @inheritdoc IGoldivault4626
  function deposit(uint256 amount) external nonReentrant {
    if(amount == 0) revert InvalidDeposit();
    SafeTransferLib.safeTransferFrom(depositToken, msg.sender, address(this), amount);
    ERC20(depositToken).approve(depositVault, amount);
    ERC4626(depositVault).deposit(amount, address(this));
    depositTokenAmount += amount;
    OwnershipToken(ot).mintOT(msg.sender, amount);
    YieldToken(yt).mintYT(msg.sender, amount);
    _updateClaimableUnderlying(msg.sender);
    _stakeYT(amount);
    emit Deposit(msg.sender, amount);
  }

  /// @inheritdoc IGoldivault4626
  function redeemOwnership(uint256 amount) external nonReentrant {
    if(amount == 0) revert InvalidRedemption();
    uint256 remainingTime = block.timestamp > endTime ? 0 : endTime - block.timestamp;
    _updateClaimableUnderlying(msg.sender);
    uint256 unstakableAmount = _unstakableYT(msg.sender, amount);
    _unstakeYT(unstakableAmount);
    OwnershipToken(ot).burnOT(msg.sender, amount);
    if(remainingTime > 0) {
      YieldToken(yt).burnYT(msg.sender, amount);
    }
    ERC4626(depositVault).redeem(ERC4626(depositVault).convertToShares(amount), msg.sender, address(this));
    depositTokenAmount -= amount;
    emit OwnershipTokenRedemption(msg.sender, amount);
  }

  /// @notice Buys YT using the vault and kodiak pool
  /// @dev These parameters cannot be 0
  /// @param ytAmount Amount of YT for user to buy
  /// @param dtAmountMax Maximum amount of deposit token that user wishes to pay
  /// @param amountOutMin Minimum amount of tokens to receive out from the kodiak pool swap
  function buyYT (uint256 ytAmount, uint256 dtAmountMax, uint256 amountOutMin) external nonReentrant {
    if(ytAmount == 0 || dtAmountMax == 0 || amountOutMin == 0) revert InvalidTrade();
    uint256 remainingTime = block.timestamp > endTime ? 0 : endTime - block.timestamp;
    if(remainingTime == 0) revert AlreadyConcluded();
    uint256 startingBalance = ERC20(depositToken).balanceOf(msg.sender);
    uint256 dtNeeded = dtAmountMax > ytAmount ? 0 : ytAmount - dtAmountMax;
    uint256 depositAmount = dtAmountMax + dtNeeded;
    if(dtNeeded == 0) dtAmountMax = ytAmount;
    if(ERC4626(depositVault).convertToAssets(ERC20(depositVault).balanceOf(address(this))) < dtNeeded) revert FlashLoanFailed();
    if(dtNeeded > 0) ERC4626(depositVault).redeem(ERC4626(depositVault).convertToShares(dtNeeded), msg.sender, address(this));
    _deposit(depositAmount);
    SafeTransferLib.safeTransferFrom(ot, msg.sender, address(this), depositAmount);
    ERC20(ot).approve(router, type(uint256).max);
    IV3SwapRouter.ExactInputSingleParams memory params = IV3SwapRouter.ExactInputSingleParams({
      tokenIn: ot,
      tokenOut: depositVault,
      fee: 500,
      recipient: msg.sender,
      amountIn: depositAmount,
      amountOutMinimum: amountOutMin,
      sqrtPriceLimitX96: 0
    });
    IV3SwapRouter(router).exactInputSingle(params);
    ERC20(ot).approve(router, 0);
    if(dtNeeded > 0) SafeTransferLib.safeTransferFrom(depositVault, msg.sender, address(this), ERC4626(depositVault).convertToShares(dtNeeded));
    uint256 endingBalance = ERC20(depositToken).balanceOf(msg.sender);
    if(endingBalance > startingBalance) revert ReceivedTooMuch();
    uint256 spentDt = startingBalance - endingBalance;
    uint256 fee = tradeFee * spentDt / 1000;
    if(spentDt + fee > dtAmountMax) revert SpentTooMuch();
    SafeTransferLib.safeTransferFrom(depositToken, msg.sender, multisig, fee);
    emit YTBuy(msg.sender, ytAmount, spentDt);
  }
  
  /// @notice Sells YT using the vault and kodiak pool
  /// @dev These parameters cannot be 0
  /// @param ytAmount Amount of YT for user to sell
  /// @param dtAmountMin Minimum amount of deposit token that user wishes to receive
  /// @param amountInMax Maximum amount of tokens to spend from the kodiak pool swap
  function sellYT (uint256 ytAmount, uint256 dtAmountMin, uint256 amountInMax) external nonReentrant {
    if(ytAmount == 0 || dtAmountMin == 0 || amountInMax == 0) revert InvalidTrade();
    uint256 remainingTime = block.timestamp > endTime ? 0 : endTime - block.timestamp;
    if(remainingTime == 0) revert AlreadyConcluded();
    uint256 startingBalance = ERC20(depositToken).balanceOf(msg.sender);
    _redeemOwnership(ytAmount);
    uint256 startingVaultBalance = ERC20(depositVault).balanceOf(address(this));
    ERC20(depositVault).approve(router, type(uint256).max);
    IV3SwapRouter.ExactOutputSingleParams memory params = IV3SwapRouter.ExactOutputSingleParams({
      tokenIn: depositVault,
      tokenOut: ot,
      fee: 500,
      recipient: address(this),
      amountOut: ytAmount,
      amountInMaximum: amountInMax,
      sqrtPriceLimitX96: 0
    });
    IV3SwapRouter(router).exactOutputSingle(params);
    ERC20(depositVault).approve(router, 0);
    OwnershipToken(ot).burnOT(address(this), ytAmount);
    uint256 vaultSpend = startingVaultBalance - ERC20(depositVault).balanceOf(address(this));
    uint256 repayAmount = ERC4626(depositVault).convertToAssets(vaultSpend);
    SafeTransferLib.safeTransferFrom(depositToken, msg.sender, address(this), repayAmount);
    ERC20(depositToken).approve(depositVault, repayAmount);
    ERC4626(depositVault).deposit(repayAmount, address(this));
    uint256 endingBalance = ERC20(depositToken).balanceOf(msg.sender);
    if(endingBalance < startingBalance) revert ReceivedTooLitte(); 
    uint256 receivedDt = endingBalance - startingBalance;
    uint256 fee = tradeFee * receivedDt / 1000;
    if(receivedDt - fee < dtAmountMin) revert ReceivedTooLitte();
    SafeTransferLib.safeTransferFrom(depositToken, msg.sender, multisig, fee);
    emit YTSell(msg.sender, ytAmount, receivedDt - fee);
  }

  /// @notice Stakes YT
  function stakeYT(uint256 amount) external {
    _updateClaimableUnderlying(msg.sender);
    _stakeYT(amount);
  }

  /// @notice Unstakes YT
  function unstakeYT(uint256 amount) external {
    _updateClaimableUnderlying(msg.sender);
    uint256 unstakableAmount = _unstakableYT(msg.sender, amount);
    _unstakeYT(unstakableAmount);
  }

  /// @notice Claims rewards for YT stakers
  function claim() public nonReentrant {
    _updateClaimableUnderlying(msg.sender);
    _claim(msg.sender, claimableUnderlying[msg.sender]);
  }


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                 EXTERNAL VIEW FUNCTIONS                    */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  function userClaimableUnderlying(address user) external view returns (uint256) {
    return _calculateClaimableUnderlying(user);
  }


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                    INTERNAL FUNCTIONS                      */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @notice Updates claimable Underlying
  /// @param user Address of user
  function _updateClaimableUnderlying(address user) internal {
    claimableUnderlyingPerYTStored = _claimableUnderlyingPerYT();
    lastRatio = ERC4626(depositVault).convertToAssets(tokenDecimals);
    if(user != address(0)) {
      claimableUnderlying[user] = _calculateClaimableUnderlying(user);
      underlyingPerTokenDebt[user] = claimableUnderlyingPerYTStored;
    }
  }

  /// @notice Internal function for claiming underlying
  function _claim(address claimer, uint256 claimable) internal {
    if(claimable > 0) {
      claimableUnderlying[claimer] = 0;
      uint256 beforeBal = ERC20(depositToken).balanceOf(address(this));
      ERC4626(depositVault).redeem(ERC4626(depositVault).convertToShares(claimable), address(this), address(this));
      uint256 afterBal = ERC20(depositToken).balanceOf(address(this));
      uint256 fee = (afterBal - beforeBal) * yieldFee / 100;
      SafeTransferLib.safeTransfer(depositToken, msg.sender, (afterBal - beforeBal) - fee);
      SafeTransferLib.safeTransfer(depositToken, multisig, fee);
      emit Claim(claimer, claimable);
    }
  }

  /// @notice Internal deposit function for buy and sell functions
  function _deposit(uint256 amount) internal {
    if(amount == 0) revert InvalidDeposit();
    SafeTransferLib.safeTransferFrom(depositToken, msg.sender, address(this), amount);
    ERC20(depositToken).approve(depositVault, amount);
    ERC4626(depositVault).deposit(amount, address(this));
    depositTokenAmount += amount;
    OwnershipToken(ot).mintOT(msg.sender, amount);
    YieldToken(yt).mintYT(msg.sender, amount);
    _updateClaimableUnderlying(msg.sender);
    _stakeYT(amount);
    emit Deposit(msg.sender, amount);
  }

  /// @notice Internal redeem function for buy and sell functions
  function _redeemOwnership(uint256 amount) internal {
    if(amount == 0) revert InvalidRedemption();
    _updateClaimableUnderlying(msg.sender);
    uint256 unstakableAmount = _unstakableYT(msg.sender, amount);
    _unstakeYT(unstakableAmount);
    YieldToken(yt).burnYT(msg.sender, amount);
    ERC4626(depositVault).redeem(ERC4626(depositVault).convertToShares(amount), msg.sender, address(this));
    depositTokenAmount -= amount; 
    emit OwnershipTokenRedemption(msg.sender, amount);
  }

  /// @notice Stakes YT into contract
  function _stakeYT(uint256 amount) internal {
    ytStaked[msg.sender] += amount;
    totalYtStaked += amount;
    SafeTransferLib.safeTransferFrom(yt, msg.sender, address(this), amount);
    emit YTStake(msg.sender, amount);
  }

  /// @notice Unstakes YT from contract
  function _unstakeYT(uint256 amount) internal {
    if(amount > ytStaked[msg.sender]) revert InvalidUnstake();
    ytStaked[msg.sender] -= amount;
    totalYtStaked -= amount;
    SafeTransferLib.safeTransfer(yt, msg.sender, amount);
    emit YTUnstake(msg.sender, amount);
  }


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                   INTERNAL VIEW FUNCTIONS                  */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @notice Calculates claimable underlying
  function _calculateClaimableUnderlying(address user) internal view returns (uint256) {
    return FixedPointMathLib.mulWad(ytStaked[user], _claimableUnderlyingPerYT() - underlyingPerTokenDebt[user]) + claimableUnderlying[user];
  }

  /// @notice Calculates claimable underlying per YT
  function _claimableUnderlyingPerYT() internal view returns (uint256) {
    uint256 oldRatio = lastRatio;
    uint256 newRatio = ERC4626(depositVault).convertToAssets(tokenDecimals);
    uint256 ratioDiff = newRatio - oldRatio;
    if(ratioDiff == 0 || totalYtStaked == 0) {
      return claimableUnderlyingPerYTStored;
    }
    return claimableUnderlyingPerYTStored + FixedPointMathLib.divWad(ratioDiff, totalYtStaked);
  }

  /// @notice Calculates if the user has unstaked YT
  function _unstakableYT(address user, uint256 unstakeAmount) internal view returns (uint256) {
    uint256 _ytStaked = ytStaked[user];
    if(_ytStaked == 0) {
      return 0;
    }
    else if(unstakeAmount > _ytStaked) {
      return unstakeAmount - _ytStaked;
    }
    else {
      return unstakeAmount;      
    }
  }

}