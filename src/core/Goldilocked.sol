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
// ======================================= Goldilocked ==========================================
// ==============================================================================================


//todo: fix unweighted stake bug
//    could have a variable in struct that is claimable, add current claimable balance to it when staking on a staked position. will solve reentrancy and unweighted stake bug 
//todo: add checkpoints
import { ERC20 } from "../../lib/solady/src/tokens/ERC20.sol";
import { SafeTransferLib } from "../../lib/solady/src/utils/SafeTransferLib.sol";
import { FixedPointMathLib } from "../../lib/solady/src/utils/FixedPointMathLib.sol";
import { IBorrow } from "../interfaces/IBorrow.sol";
import { IGoldiswap } from "../interfaces/IGoldiswap.sol";


/// @title Goldilocked
/// @author geeb
/// @author ampnoob
contract Goldilocked {
  
}