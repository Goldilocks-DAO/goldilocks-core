//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../lib/forge-std/src/Test.sol";
import { BaseTest } from "../BaseTest.t.sol";
import { Timelock } from "../../src/governance/Timelock.sol";

contract TimelockTest is BaseTest {

  // function testEmptySignatures() public {
  //   address[] memory targets = new address[](2);
  //   targets[0] = address(0x69);
  //   targets[1] = address(0x69);
  //   string[] memory signatures = new string[](2);
  //   signatures[0] = "";
  //   signatures[1] = "";
  //   bytes[] memory calldatas = new bytes[](2);
  //   calldatas[0] = hex"8eed55d1";
  //   calldatas[1] = hex"8eed55d2";
  //   uint256[] memory values = new uint256[](2);
  //   values[0] = 0;
  //   values[1] = 0;
  //   deal(address(goldiswap), address(this), 401e18);
  //   goldiswap.approve(address(govlocks), 401e18);
  //   govlocks.deposit(401e18);
  //   vm.roll(2);
  //   goldigov.propose(targets, signatures, calldatas, values, "");
  //   vm.roll(72);
  //   goldigov.castVote(1, 1);
  //   vm.roll(5900);
  //   goldigov.queue(1);
  //   vm.warp(6 days);
  //   goldigov.execute(1);
  // }

  // function testSetAdminFail() public {
  //   vm.prank(address(0x69));
  //   vm.expectRevert(abi.encodeWithSelector(Timelock.NotAdmin.selector));
  //   timelock.setAdmin(address(0x69));
  // }

  // function testSetAdmin() public {
  //   vm.prank(address(goldigov));
  //   timelock.setAdmin(address(0x69));
    
  //   assertEq(timelock.admin(), address(0x69));
  // }

  // function testSetDelayFailAdmin() public {
  //   vm.prank(address(0x69));
  //   vm.expectRevert(NotAdminSelector);
  //   timelock.setDelay(69);
  // }

  // function testSetDelayFailDelay() public {
  //   vm.prank(address(goldigov));
  //   vm.expectRevert(InvalidDelaySelector);
  //   timelock.setDelay(1 days);
  // }

  // function testSetDelaySuccess() public {
  //   uint256 delay = 3 days;
  //   vm.prank(address(goldigov));
  //   timelock.setDelay(delay);

  //   assertEq(timelock.delay(), delay);
  // }

  // function testExecuteTxAdminFail() public {
  //   vm.prank(address(0x69));
  //   vm.expectRevert(NotAdminSelector);
  //   timelock.executeTransaction(address(0x69), 69, 69, "69", "69");
  // }

  // function testExecuteTxNotQueuedFail() public {
  //   vm.prank(address(goldigov));
  //   vm.expectRevert(TxNotQueuedSelector);
  //   timelock.executeTransaction(address(0x69), 69, 69, "69", "69");
  // }

  // function testExecuteLockedFail() public {
  //   address[] memory targets = new address[](2);
  //   targets[0] = address(0x69);
  //   targets[1] = address(0x69);
  //   string[] memory signatures = new string[](2);
  //   signatures[0] = "hello";
  //   signatures[1] = "helloagain";
  //   bytes[] memory calldatas = new bytes[](2);
  //   calldatas[0] = hex"8eed55d1";
  //   calldatas[1] = hex"8eed55d1";
  //   uint256[] memory values = new uint256[](2);
  //   values[0] = 0;
  //   values[1] = 0;
  //   deal(address(goldiswap), address(this), 401e18);
  //   goldiswap.approve(address(govlocks), 401e18);
  //   govlocks.deposit(401e18);
  //   vm.roll(2);
  //   goldigov.propose(targets, signatures, calldatas, values, "");
  //   vm.roll(72);
  //   goldigov.castVote(1, 1);
  //   vm.roll(5900);
  //   goldigov.queue(1);
  //   vm.expectRevert(TxLockedSelector);
  //   goldigov.execute(1);
  // }

  // function testExecuteStaleFail() public {
  //   address[] memory targets = new address[](2);
  //   targets[0] = address(0x69);
  //   targets[1] = address(0x69);
  //   string[] memory signatures = new string[](2);
  //   signatures[0] = "hello";
  //   signatures[1] = "helloagain";
  //   bytes[] memory calldatas = new bytes[](2);
  //   calldatas[0] = hex"8eed55d1";
  //   calldatas[1] = hex"8eed55d1";
  //   uint256[] memory values = new uint256[](2);
  //   values[0] = 0;
  //   values[1] = 0;
  //   deal(address(goldiswap), address(this), 401e18);
  //   goldiswap.approve(address(govlocks), 401e18);
  //   govlocks.deposit(401e18);
  //   vm.roll(2);
  //   goldigov.propose(targets, signatures, calldatas, values, "");
  //   vm.roll(72);
  //   goldigov.castVote(1, 1);
  //   vm.roll(5900);
  //   goldigov.queue(1);
  //   vm.warp(690 days);
  //   vm.prank(address(goldigov));
  //   vm.expectRevert(TxStaleSelector);
  //   timelock.executeTransaction(targets[0], 432001, values[0], calldatas[0], signatures[0]);
  // }

  // function testExecuteRevertFail() public {
  //   // deal(address(goldigov), 1 ether);
  //   address[] memory targets = new address[](2);
  //   targets[0] = address(0x69);
  //   targets[1] = address(0x69);
  //   string[] memory signatures = new string[](2);
  //   signatures[0] = "hello";
  //   signatures[1] = "helloagain";
  //   bytes[] memory calldatas = new bytes[](2);
  //   calldatas[0] = hex"8eed55d1";
  //   calldatas[1] = hex"8eed55d1";
  //   uint256[] memory values = new uint256[](2);
  //   values[0] = 69;
  //   values[1] = 0;
  //   deal(address(goldiswap), address(this), 401e18);
  //   goldiswap.approve(address(govlocks), 401e18);
  //   govlocks.deposit(401e18);
  //   vm.roll(2);
  //   goldigov.propose(targets, signatures, calldatas, values, "");
  //   vm.roll(72);
  //   goldigov.castVote(1, 1);
  //   vm.roll(5900);
  //   goldigov.queue(1);
  //   vm.warp(6 days);
  //   vm.prank(address(goldigov));
  //   vm.expectRevert(TxRevertedSelector);
  //   timelock.executeTransaction(targets[0], 432001, 69, calldatas[0], signatures[0]);
  // }

  // function testCancelAdminFail() public {
  //   vm.expectRevert(NotAdminSelector);
  //   timelock.cancelTransaction(address(0x69), 69, 69, "", "");
  // }

  // function testQueueAdminFail() public {
  //   vm.expectRevert(NotAdminSelector);
  //   timelock.queueTransaction(address(0x69), 69, 69, "", "");
  // }

  // function testQueueETAFail() public {
  //   vm.prank(address(goldigov));
  //   vm.expectRevert(InvalidETASelector);
  //   timelock.queueTransaction(address(0x69), 0, 69, "", "");
  // }

}