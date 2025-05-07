//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { BaseHandler } from "../../base/BaseHandler.t.sol";
import { Goldilend } from "../../../src/core/goldilend/Goldilend.sol";

contract GoldilendHandler is BaseHandler {

  Goldilend public goldilend;

  constructor(Goldilend _goldilend) {
    goldilend = _goldilend;
  }

}