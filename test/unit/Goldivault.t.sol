//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { BaseUnitTest } from "../base/BaseUnitTest.t.sol";
import { Goldivault } from "../../src/core/goldivault/Goldivault.sol";
import { IGoldivault } from "../../src/interfaces/IGoldivault.sol";
import { OwnershipToken } from "../../src/core/goldivault/OwnershipToken.sol";
import { YieldToken } from "../../src/core/goldivault/YieldToken.sol";

contract UnitGoldivaultTest is BaseUnitTest {

  function testOTName() public {
    assertEq(ot.name(), "oBexLPToken");
  }

  function testOTSymbol() public {
    assertEq(ot.symbol(), "oBEXLP");
  }

  function testYTName() public {
    assertEq(yt.name(), "yBexLPToken");
  }

  function testYTSymbol() public {
    assertEq(yt.symbol(), "yBEXLP");
  }

  function testMintOTFailVault() public {
    vm.prank(address(0xdddd));
    vm.expectRevert(abi.encodeWithSelector(OwnershipToken.NotVault.selector));
    ot.mintOT(address(this), 69);
  }

  function testBurnOTFailVault() public {
    vm.prank(address(0xdddd));
    vm.expectRevert(abi.encodeWithSelector(OwnershipToken.NotVault.selector));
    ot.burnOT(address(this), 69);
  }

  function testMintYTFailVault() public {
    vm.prank(address(0xdddd));
    vm.expectRevert(abi.encodeWithSelector(YieldToken.NotVault.selector));
    yt.mintYT(address(this), 69);
  }

  function testBurnYTFailVault() public {
    vm.prank(address(0xdddd));
    vm.expectRevert(abi.encodeWithSelector(YieldToken.NotVault.selector));
    yt.burnYT(address(this), 69);
  }

  function testDepositFailTime() public {
    vm.warp(1 + 364 days + 69);
    vm.expectRevert(abi.encodeWithSelector(IGoldivault.InsufficientTime.selector));
    goldivault.deposit(69);
  }

  function testDepositSuccess() public {
    depositBexLP();

    assertEq(ot.balanceOf(address(this)), txAmount);
    assertEq(yt.balanceOf(address(this)), txAmount);
    assertEq(bexlp.balanceOf(address(this)), 0);
    assertEq(bexlp.balanceOf(address(bexvault)), 0);
  }

  function testRedeemYieldFailInvalid() public {
    vm.expectRevert(abi.encodeWithSelector(IGoldivault.InvalidRedemption.selector));
    goldivault.redeemYield(0);
  }

  function testRedeemYieldFailConcluded() public {
    vm.expectRevert(abi.encodeWithSelector(IGoldivault.NotConcluded.selector));
    goldivault.redeemYield(txAmount);
  }

  function testRedeemYieldDistribute() public {
    depositBexLP();    
    vm.warp(366 days);
    goldivault.conclude();
    vm.warp(block.timestamp + 1 days + 1);
    goldivault.redeemYield(txAmount);

    assertEq(ibgt.balanceOf(address(this)), 0);
    assertEq(yt.balanceOf(address(this)), 0);
  }

  function testRedeemYieldSuccess() public {
    depositBexLP();
    vm.warp(366 days);
    goldivault.conclude();
    vm.warp(block.timestamp + 1 days + 1);
    goldivault.redeemYield(txAmount);

    assertEq(yt.balanceOf(address(this)), 0);
  }

  function testRedeemOwnershipFailInvalid() public {
    vm.expectRevert(abi.encodeWithSelector(IGoldivault.InvalidRedemption.selector));
    goldivault.redeemOwnership(0);
  }

  function testRedeemOwnershipRemainingTime() public {
    depositBexLP();
    vm.warp(180 days);
    goldivault.redeemOwnership(txAmount);

    assertEq(ot.balanceOf(address(this)), 0);
    assertEq(bexlp.balanceOf(address(this)), txAmount);
  }

  function testRedeemOwnershipRemainingTimeNonMultisig() public {
    deal(address(bexlp), address(0xbbb), txAmount);
    vm.startPrank(address(0xbbb));
    bexlp.approve(address(goldivault), txAmount);
    goldivault.deposit(txAmount);
    vm.stopPrank();
    vm.warp(180 days);
    vm.prank(address(0xbbb));
    goldivault.redeemOwnership(txAmount);

    assertEq(ot.balanceOf(address(this)), 0);
    assertEq(bexlp.balanceOf(address(0xbbb)), 97e17);
    assertEq(bexlp.balanceOf(address(this)), 3e17);
  }

  function testRedeemOwnershipSuccess() public {
    depositBexLP();
    vm.warp(366 days);
    goldivault.redeemOwnership(txAmount);

    assertEq(ot.balanceOf(address(this)), 0);
    assertEq(yt.balanceOf(address(this)), txAmount);
    assertEq(bexlp.balanceOf(address(this)), txAmount);
    assertEq(bexlp.balanceOf(address(bexvault)), 0);
  }

  function testRedeemOwnershipSuccessHalf() public {
    depositBexLP();
    vm.warp(1 + (365 days / 2));
    goldivault.redeemOwnership(txAmount);

    assertEq(ot.balanceOf(address(this)), 0);
    assertEq(yt.balanceOf(address(this)), txAmount / 2);
    assertEq(bexlp.balanceOf(address(this)), txAmount);
    assertEq(bexlp.balanceOf(address(bexvault)), 0);
  }

  function testConcludeFailExpired() public {
    vm.expectRevert(abi.encodeWithSelector(IGoldivault.NotExpired.selector));
    goldivault.conclude();
  }

  function testConcludeFailAlready() public {
    vm.warp(366 days);
    goldivault.conclude();
    vm.expectRevert(abi.encodeWithSelector(IGoldivault.AlreadyConcluded.selector));
    goldivault.conclude();
  }

  function testConcludeSuccess() public {
    vm.warp(366 days);
    goldivault.conclude();

    assertEq(goldivault.concludeTime(), block.timestamp);
  }

  function testCompoundSuccess() public {
    goldivault.compound();
  }

  function testRenewFailTimelock() public {
    vm.prank(address(0xbbbb));
    vm.expectRevert(abi.encodeWithSelector(IGoldivault.NotTimelock.selector));
    goldivault.renew();
  }

  function testRenewFailConcluded() public {
    vm.prank(address(timelock));
    vm.expectRevert(abi.encodeWithSelector(IGoldivault.NotConcluded.selector));
    goldivault.renew();
  }

  function testRenewSuccess() public {
    vm.warp(366 days);
    goldivault.conclude();
    bytes memory _calldata = abi.encodeWithSignature("renew()");
    address[] memory targets = new address[](1);
    targets[0] = address(goldivault);
    string[] memory signatures = new string[](1);
    signatures[0] = "";
    bytes[] memory calldatas = new bytes[](1);
    calldatas[0] = _calldata;
    uint256[] memory valuess = new uint256[](1);
    valuess[0] = 0;
    deal(address(goldiswap), address(this), quorumVotesNum);
    goldiswap.approve(address(govlocks), quorumVotesNum);
    govlocks.deposit(quorumVotesNum);
    govlocks.delegate(address(this));
    vm.roll(2);
    goldigov.propose(targets, valuess, signatures, calldatas, "");
    vm.roll(72);
    goldigov.castVote(1, 1);
    vm.roll(18000);
    goldigov.queue(1);
    vm.warp(block.timestamp + 6 days);
    goldigov.execute(1);
    (, , , , , , , , , bool executed) = goldigov.proposals(1);

    assertEq(executed, true);
    assertEq(goldivault.concludeTime(), 0);
    assertEq(goldivault.startTime(), block.timestamp);
    assertEq(goldivault.endTime(), block.timestamp + 365 days);
  }

  function testChangeProtocolParametersFailTimelock() public {
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(IGoldivault.NotTimelock.selector));
    goldivault.changeProtocolParameters(69, 69, 69, 69);
  }

  function testChangeProtocolParametersSuccess() public {
    bytes memory _calldata = abi.encodeWithSignature("changeProtocolParameters(uint256,uint256,uint256,uint256)", 69, 69, 69, 69);
    address[] memory targets = new address[](1);
    targets[0] = address(goldivault);
    string[] memory signatures = new string[](1);
    signatures[0] = "";
    bytes[] memory calldatas = new bytes[](1);
    calldatas[0] = _calldata;
    uint256[] memory valuess = new uint256[](1);
    valuess[0] = 0;
    deal(address(goldiswap), address(this), quorumVotesNum);
    goldiswap.approve(address(govlocks), quorumVotesNum);
    govlocks.deposit(quorumVotesNum);
    govlocks.delegate(address(this));
    vm.roll(2);
    goldigov.propose(targets, valuess, signatures, calldatas, "");
    vm.roll(72);
    goldigov.castVote(1, 1);
    vm.roll(18000);
    goldigov.queue(1);
    vm.warp(block.timestamp + 6 days);
    goldigov.execute(1);
    (, , , , , , , , , bool executed) = goldigov.proposals(1);

    assertEq(executed, true);
    assertEq(goldivault.earlyWithdrawalFee(), 69);
    assertEq(goldivault.yieldFee(), 69);
    assertEq(goldivault.delay(), 69);
    assertEq(goldivault.duration(), 69);
  }

  function testAddYieldTokensFailMultisig() public {
    address[] memory yieldTokens = new address[](0);
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(IGoldivault.NotMultisig.selector));
    goldivault.addYieldTokens(yieldTokens);
  }

  function testAddYieldTokensSuccess() public {
    address[] memory yieldTokens = new address[](1);
    yieldTokens[0] = address(0x69);
    goldivault.addYieldTokens(yieldTokens);
    
    assertEq(goldivault.yieldTokens(1), address(0x69));
  }

  function testInitializeProtocolFailMultisig() public {
    address[] memory yieldTokens = new address[](0);
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(IGoldivault.NotMultisig.selector));
    goldivault.initializeProtocol(
      30,
      20,
      1 days,
      365 days,
      1 days,
      yieldTokens
    );
  }

  function testInitializeProtocolFailAlready() public {
    address[] memory yieldTokens = new address[](0);
    vm.expectRevert(abi.encodeWithSelector(IGoldivault.AlreadyInitialized.selector));
    goldivault.initializeProtocol(
      30,
      20,
      1 days,
      365 days,
      1 days,
      yieldTokens
    );
  }

  function testInitializeProtocolSuccess() public {
    assertEq(goldivault.earlyWithdrawalFee(), 30);
    assertEq(goldivault.yieldFee(), 20);
    assertEq(goldivault.delay(), 1 days);
    assertEq(goldivault.duration(), 365 days);
    assertEq(goldivault.yieldTokens(0), address(ibgt));
  }

}