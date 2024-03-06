//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../lib/forge-std/src/Test.sol";
import { TestBase } from "../TestBase.t.sol";

contract GoldigovernorTest is TestBase {

  address user = address(0x69);

  function testAss() public {
    deal(address(goldiswap), user, 69);
    vm.startPrank(user);
    goldiswap.approve(address(goldilocked), 69);
    goldilocked.stake(69);
    govlocks.delegate(user);
    vm.stopPrank();
    vm.prank(address(goldilocked));
    govlocks.delegate(address(goldilocked));
    vm.roll(69);

    console.log("user govlocks balance: ", govlocks.balanceOf(user));
    console.log("user govlocks votes: ", govlocks.getVotes(user));

    console.log("goldilocked govlocks balance: ", govlocks.balanceOf(address(goldilocked)));
    console.log("goldilocked govlocks votes: ", govlocks.getVotes(address(goldilocked)));
  }

}