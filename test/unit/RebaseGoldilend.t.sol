//SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { console } from "../../lib/forge-std/src/console.sol";
import { ERC20 } from "../../lib/solady/src/tokens/ERC20.sol";
import { BaseUnitTest } from "../base/BaseUnitTest.t.sol";
import { GoldilendBase } from "../../src/core/goldilend/GoldilendBase.sol";
import { RebaseGoldilend } from "../../src/core/goldilend/RebaseGoldilend.sol";
import { GoldilendDebtAsset } from "../../src/core/goldilend/GoldilendDebtAsset.sol";

contract UnitRebaseGoldilendTest is BaseUnitTest {

    function testGoldilendDebtAssetName() public view {
        assertEq(glhoney.name(), "Goldilend Honey");
    }

    function testGoldilendDebtAssetSymbol() public view {
        assertEq(glhoney.symbol(), "glHONEY");
    }

    function testMintglDebtAssetFailGoldilend() public {
        vm.expectRevert(abi.encodeWithSelector(GoldilendDebtAsset.NotGoldilend.selector));
        glhoney.mintglDebtAsset(address(0x69), 69);
    }

    function testBurnglDebtAssetFailGoldilend() public {
        vm.expectRevert(abi.encodeWithSelector(GoldilendDebtAsset.NotGoldilend.selector));
        glhoney.burnglDebtAsset(address(0x69), 69);
    }

    function testDepositSuccess() public dealGoldilendHoney {
        honey.approve(address(rebaseproxy), txAmount);
        GoldilendBase(address(rebaseproxy)).deposit(txAmount);

        assertEq(honey.balanceOf(address(this)), dealAmt - txAmount);
        assertEq(glhoney.balanceOf(address(this)), txAmount);
        assertEq(honey.balanceOf(address(rebaseproxy)), txAmount);
        assertEq(GoldilendBase(address(rebaseproxy)).poolSize(), txAmount);
    }

    function testWithdrawSuccess() public dealGoldilendHoney {
        honey.approve(address(rebaseproxy), txAmount);
        GoldilendBase(address(rebaseproxy)).deposit(txAmount);
        GoldilendBase(address(rebaseproxy)).withdraw(txAmount);

        assertEq(honey.balanceOf(address(this)), dealAmt);
        assertEq(glhoney.balanceOf(address(this)), 0);
        assertEq(honey.balanceOf(address(rebaseproxy)), 0);
        assertEq(GoldilendBase(address(rebaseproxy)).poolSize(), 0);
    }

    
}