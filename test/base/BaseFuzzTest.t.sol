//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { BaseTest } from "./BaseTest.t.sol";
import { IERC721 } from "../../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import { INFT } from "../../src/mock/INFT.sol";

abstract contract BaseFuzzTest is BaseTest {

  uint256 costOf10Locks = 262883805905681940;
  
  uint256 oneDayPrg = 136986301369863000000;
  uint256 dayOfPrgDebt = 1369863013698630;

  function setUp() public override {
    deployProtocol();
  }

  modifier dealUseriBGT() {
    deal(address(ibgt), address(this), type(uint256).max / 2);
    ibgt.approve(address(goldilend), type(uint256).max / 2);
    _;
  }

  modifier dealUserBeras() {
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bandbear)).mint(address(this));
    IERC721(bondbear).setApprovalForAll(address(goldilend), true);
    IERC721(bandbear).setApprovalForAll(address(goldilend), true);
    _;
  }

  function beras() public view returns (address[] memory, uint256[] memory) {
    address[] memory nfts = new address[](2);
    nfts[0] = address(bondbear);
    nfts[1] = address(bandbear);
    uint256[] memory ids = new uint256[](2);
    ids[0] = 1;
    ids[1] = 1;
    return (nfts, ids);
  }

}