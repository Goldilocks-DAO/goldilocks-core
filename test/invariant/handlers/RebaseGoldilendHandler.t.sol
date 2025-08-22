//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { BaseHandler } from "../../base/BaseHandler.t.sol";
import { RebaseGoldilend } from "../../../src/core/goldilend/RebaseGoldilend.sol";

contract RebaseGoldilendHandler is BaseHandler {

  RebaseGoldilend public rebasegoldilend;

  constructor(RebaseGoldilend _rebasegoldilend) {
    rebasegoldilend = _rebasegoldilend;
  }

}