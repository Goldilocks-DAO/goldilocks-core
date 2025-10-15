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

    address bitbears = 0x72D876D9cdf4001b836f8E47254d0551EdA2eebB;
    address bandbears = 0x7711B2Eb2451259dbF211e30157ceB7CFeb79a19;
    address babybears = 0xDDeAf391c4be2d01ca52aBb8C159a06820ef078C;
    address boobears = 0xf49ec5db255854C4a567de5AB3826c9AAbaFc7cF;
    address bondbears = 0xA0CF472E6132F6B822a944f6F31aA7b261c7c375;
    address bongbears = 0x141De07E5D4C4759EC9301DA106115D4841f66cD;

    address bitStreaming = 0x979EFC29797884c3342143eA7b91E55342F2f408;
    address bandStreaming = 0xaf30baa667Ce52c1fE5702A0F8CE9A31f0d751B6;
    address babyStreaming = 0x14E5930aD47Bfc9E7977547e263D5C3A090b777f;
    address booStreaming = 0x1229414CFEE4dEC0B488377B62e96B4094B6258C;
    address bondStreaming = 0xa63b5bc4Bab6593ACc78ef103fcb44A191BAe836;
    address bongStreaming = 0x1E54B85B3632F75E96Cc8d4FcB11BA7f0Ca69213;

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
        address[] memory rebasenfts = new address[](6);
        rebasenfts[0] = address(bitbears);
        rebasenfts[1] = address(bandbears);
        rebasenfts[2] = address(babybears);
        rebasenfts[3] = address(boobears);
        rebasenfts[4] = address(bondbears);
        rebasenfts[5] = address(bongbears);
        uint256[] memory rebasevalues = new uint256[](6);
        rebasevalues[0] = 30;
        rebasevalues[1] = 20;
        rebasevalues[2] = 20;
        rebasevalues[3] = 20;
        rebasevalues[4] = 20;
        rebasevalues[5] = 20;
        address[] memory rebasestreams = new address[](6);
        rebasestreams[0] = bitStreaming;
        rebasestreams[1] = bandStreaming;
        rebasestreams[2] = babyStreaming;
        rebasestreams[3] = booStreaming;
        rebasestreams[4] = bondStreaming;
        rebasestreams[5] = bongStreaming;
        RebaseGoldilend(address(rebaseproxy)).initializeBeras(rebasenfts, rebasevalues, rebasestreams);
        vm.stopPrank();
    }

    function testFairValue() public {
        console.log(block.timestamp);
        vm.warp(1770386400 + 365 days);
        uint256 fairValueNum = RebaseGoldilend(address(rebaseproxy)).calculateFairValue(bitbears);

        console.log(fairValueNum);
    }

}