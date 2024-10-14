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
// ===================================== BHoneyGoldivault =======================================
// ==============================================================================================


import { ERC20 } from "../../../lib/solady/src/tokens/ERC20.sol";
import { SafeTransferLib } from "../../../lib/solady/src/utils/SafeTransferLib.sol";
import { GoldivaultNegative } from "./GoldivaultNegative.sol";
import { IBHoneyVault } from "../../interfaces/IBHoneyVault.sol";
import { BHoneyVault } from "../../interfaces/BHoneyVault.sol";
import { IiBGTVault } from "../../interfaces/IiBGTVault.sol";


contract BHoneyGoldivault is GoldivaultNegative {

  bool public emissions;
  address public bhoney;
  address public ibhoneyVault;
  error EmissionsNotLive();

  constructor(
    address _ot,
    address _yt,
    address _multisig,
    address _timelock,
    address _depositToken,
    address _depositVault,
    address _ibgt,
    address _ibgtVault,
    address _bhoney
  ) GoldivaultNegative(
    _ot,
    _yt,
    _multisig,
    _timelock,
    _depositToken,
    _depositVault,
    _ibgt,
    _ibgtVault
  ) {
    bhoney = _bhoney;
  }

  function beginEmissions(address _ibhoneyVault) external {
    if(msg.sender != multisig) revert NotMultisig();
    emissions = true;
    ibhoneyVault = _ibhoneyVault;
    ERC20(bhoney).approve(_ibhoneyVault, type(uint256).max);
    IBHoneyVault(_ibhoneyVault).stake(ERC20(bhoney).balanceOf(address(this)));
  }

  function finalExit(uint256 withdrawAmout) external {
    if(msg.sender != multisig) revert NotMultisig();
    BHoneyVault(depositVault).withdraw(withdrawAmout, address(this), address(this));
  }

  function redoWithdrawalRequest() external {
    if(msg.sender != multisig) revert NotMultisig();
    BHoneyVault(depositVault).makeWithdrawRequest(ERC20(bhoney).balanceOf(address(this)));
  }

  function _vaultDeposit(uint256 amount) internal override {
    BHoneyVault(depositVault).deposit(amount, address(this));
    if(emissions) {
      IBHoneyVault(ibhoneyVault).stake(ERC20(bhoney).balanceOf(address(this)));
    }
  }

  function _concludeVaultRewards() internal override {
    if(emissions) {
      IBHoneyVault(ibhoneyVault).exit();
    }
    BHoneyVault(depositVault).makeWithdrawRequest(ERC20(bhoney).balanceOf(address(this)));
  }

  function _compoundVaultRewards() internal override {
    if(!emissions) revert EmissionsNotLive();
    IBHoneyVault(ibhoneyVault).getReward();
    IiBGTVault(ibgtVault).getReward();
    uint256 ibgtrewards = ERC20(ibgt).balanceOf(address(this));
    uint256 yieldTokensLength = yieldTokens.length;
    for(uint8 i; i < yieldTokensLength; ++i) {
      SafeTransferLib.safeTransfer(yieldTokens[i], multisig, ERC20(yieldTokens[i]).balanceOf(address(this)) * yieldFee / 1000);
    }
    IiBGTVault(ibgtVault).stake(ibgtrewards * (1000 - yieldFee) / 1000);
  }

}