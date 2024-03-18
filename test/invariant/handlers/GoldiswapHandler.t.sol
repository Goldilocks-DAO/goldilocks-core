//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../../lib/forge-std/src/Test.sol";
import { BaseHandler } from "../../base/BaseHandler.t.sol";
import { SafeTransferLib } from "../../../lib/solady/src/utils/SafeTransferLib.sol";
import { Goldilocked } from "../../../src/core/goldiswap/Goldilocked.sol";
import { Goldiswap } from "../../../src/core/goldiswap/Goldiswap.sol";
import { GovLocks } from "../../../src/core/goldigovernance/GovLocks.sol";

contract GoldiswapHandler is BaseHandler {

  Goldiswap public goldiswap;

  constructor(Goldiswap _goldiswap) {
    goldiswap = _goldiswap;
  }

}