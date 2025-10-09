//SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "../../lib/forge-std/src/Test.sol";
import { console } from "../../lib/forge-std/src/console.sol";
import { LibRLP } from "../../lib/solady/src/utils/LibRLP.sol";
import { IERC721 } from "../../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import { ERC20 } from "../../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import { ERC1967Proxy } from "../../lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { RebaseGoldilend } from "../../src/core/goldilend/RebaseGoldilend.sol";
import { IRebaseGoldilend } from "../../src/interfaces/IRebaseGoldilend.sol";
import { GoldilendDebtAsset } from "../../src/core/goldilend/GoldilendDebtAsset.sol";

contract IntegrationRebaseGoldilendTest is Test {

    using LibRLP for address;

    RebaseGoldilend rebasegoldilend;
    ERC1967Proxy rebaseproxy;
    GoldilendDebtAsset ghoney;

    address rawdog = 0x8FE7E03B5b2E49E3386BE79f0834B4B6D08E095c;
    address honey = 0xFCBD14DC51f0A4d49d5E53C2E0950e0bC26d0Dce;

    function setUp() public {
        GoldilendDebtAsset ghoneyComputed = GoldilendDebtAsset(rawdog.computeAddress(98));
        uint256 berachainFork = vm.createFork("https://rpc.berachain.com");
        vm.selectFork(berachainFork);
        vm.startPrank(rawdog);

        // deploy rebasegoldilend
        rebasegoldilend = new RebaseGoldilend();

        // initialization of rebasegoldilend
        bytes memory rebasedata = abi.encodeWithSelector(
            RebaseGoldilend.initialize.selector,
            rawdog,
            honey,
            address(ghoneyComputed)
        );
        rebaseproxy = new ERC1967Proxy(address(rebasegoldilend), rebasedata);
        ghoney = new GoldilendDebtAsset("Goldilend Honey", "gHONEY", address(rebaseproxy));
        assert(RebaseGoldilend(address(rebaseproxy)).glDebtAsset() == address(ghoney));
        RebaseGoldilend(address(rebaseproxy)).initializeParameters(
            2e17,
            1 days,
            365 days,
            7 days,
            30 days,
            2e18,
            90
        );
        address[] memory rebasenfts = new address[](1);
        rebasenfts[0] = address(bandbear);
        uint256[] memory rebasevalues = new uint256[](1);
        rebasevalues[0] = 50e18;
        RebaseGoldilend(address(rebaseproxy)).initializeBeras(rebasenfts, rebasevalues);
        vm.stopPrank();
    }

    function testFairValue() public view {
        uint256 fairValueNum = RebaseGoldilend(address(rebaseproxy)).calculateFairValue();

        console.log(fairValueNum);
    }

}