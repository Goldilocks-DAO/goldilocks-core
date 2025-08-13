//SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { console } from "../../lib/forge-std/src/console.sol";
import { ERC20 } from "../../lib/solady/src/tokens/ERC20.sol";
import { BaseUnitTest } from "../base/BaseUnitTest.t.sol";
import { GoldilendBase } from "../../src/core/goldilend/GoldilendBase.sol";
import { RebaseGoldilend } from "../../src/core/goldilend/RebaseGoldilend.sol";

contract UnitRebaseGoldilendTest is BaseUnitTest {

    function testDepositSuccess() public dealGoldilendHoney {
        honey.approve(address(rebaseproxy), txAmount);
        GoldilendBase(address(rebaseproxy)).deposit(txAmount);

        assertEq(honey.balanceOf(address(this)), dealAmt - txAmount);
        assertEq(honey.balanceOf(address(rebaseproxy)), txAmount);
        assertEq(GoldilendBase(address(rebaseproxy)).poolSize(), txAmount);
    }
}