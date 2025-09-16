//SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "../../lib/forge-std/src/Test.sol";
import { console } from "../../lib/forge-std/src/console.sol";
import { LibRLP } from "../../lib/solady/src/utils/LibRLP.sol";
import { IERC721 } from "../../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import { ERC1967Proxy } from "../../lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { BeraBondGoldilend } from "../../src/core/goldilend/BeraBondGoldilend.sol";
import { GoldilendDebtAsset } from "../../src/core/goldilend/GoldilendDebtAsset.sol";


contract IntegrationBeraBondGoldilendTest is Test {

    using LibRLP for address;

    BeraBondGoldilend berabondgoldilend;
    ERC1967Proxy berabondproxy;
    GoldilendDebtAsset glbera;

    address rawdog = 0x8FE7E03B5b2E49E3386BE79f0834B4B6D08E095c;
    address bgt = 0x656b95E550C07a9ffe548bd4085c72418Ceb1dba;
    address berabond = 0x90413D2167EDEFfcd1E7245600E55Dd9442C8b96;
    address registry = 0xF5AD796cad75E2da15d62377cC4Ac97EBBC73AF8;

    function setUp() public {
        uint256 berachainFork = vm.createFork("https://rpc.berachain.com");
        vm.selectFork(berachainFork);
        vm.startPrank(rawdog);
        GoldilendDebtAsset glberaComputed = GoldilendDebtAsset(rawdog.computeAddress(97));

        // deploy berabondgoldilend
        berabondgoldilend = new BeraBondGoldilend();

        // initialization of berabondgoldilend
        bytes memory berabonddata = abi.encodeWithSelector(
            BeraBondGoldilend.initialize.selector,
            rawdog,
            address(glberaComputed),
            bgt,
            berabond,
            registry
        );
        berabondproxy = new ERC1967Proxy(address(berabondgoldilend), berabonddata);
        address payable berabondproxyaddy = payable(address(berabondproxy));
        glbera = new GoldilendDebtAsset("Goldilend Bera", "glBERA", address(berabondproxy));
        assert(BeraBondGoldilend(berabondproxyaddy).glDebtAsset() == address(glbera));
        BeraBondGoldilend(berabondproxyaddy).initializeParameters(
            2e17,
            1 days,
            365 days,
            2e18,
            90,
            80
        );
        vm.stopPrank();
    }

    function testBeraBondBorrow() public {
        deal(rawdog, 5_000e18);
        vm.startPrank(rawdog);
        BeraBondGoldilend(payable(address(berabondproxy))).deposit{value: 5_000e18}();
        IERC721(berabond).setApprovalForAll(address(berabondproxy), true);
        BeraBondGoldilend(payable(address(berabondproxy))).borrow(83e16, 1_000e18, 2 days, berabond, 6);
        vm.stopPrank();
    }

    function testBeraBondBorrowArray() public {
        deal(rawdog, 5_000e18);
        vm.startPrank(rawdog);
        BeraBondGoldilend(payable(address(berabondproxy))).deposit{value: 5_000e18}();
        IERC721(berabond).setApprovalForAll(address(berabondproxy), true);
        BeraBondGoldilend(payable(address(berabondproxy))).borrow(83e16, 1_000e18, 2 days, berabond, 6);
        vm.stopPrank();
        
        assertEq(BeraBondGoldilend(payable(address(berabondproxy))).depositedBeraBondIDs(rawdog, 0), 6);
    }

    function testBeraBondRepayArray() public {
        deal(rawdog, 5_000e18);
        vm.startPrank(rawdog);
        BeraBondGoldilend(payable(address(berabondproxy))).deposit{value: 5_000e18}();
        IERC721(berabond).setApprovalForAll(address(berabondproxy), true);
        BeraBondGoldilend(payable(address(berabondproxy))).borrow(83e16, 1_000e18, 2 days, berabond, 6);
        BeraBondGoldilend(payable(address(berabondproxy))).repay{value: 83e16}(1);
        vm.stopPrank();
        
        vm.expectRevert();
        uint256 id = BeraBondGoldilend(payable(address(berabondproxy))).depositedBeraBondIDs(rawdog, 0);
    }

    // function testBeraBondClaimYield() public {
    //     address[] memory rewardVaults = new address[](1);
    //     rewardVaults[0] = 0x124ca134dd2CD67362E259fb33A2c762d8BAF961;
    //     deal(rawdog, 5_000e18);
    //     vm.startPrank(rawdog);
    //     BeraBondGoldilend(payable(address(berabondproxy))).deposit{value: 5_000e18}();
    //     IERC721(berabond).setApprovalForAll(address(berabondproxy), true);
    //     BeraBondGoldilend(payable(address(berabondproxy))).borrow(83e16, 0, 2 days, berabond, 6);
    //     vm.stopPrank();

    //     vm.prank(rawdog);
    //     BeraBondGoldilend(payable(address(berabondproxy))).claimYield(rewardVaults);
    // }


}