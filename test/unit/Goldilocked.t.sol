//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../lib/forge-std/src/console.sol";
import { BaseUnitTest } from "../base/BaseUnitTest.t.sol";
import { Goldilocked } from "../../src/core/goldiswap/Goldilocked.sol";
import { IGoldilocked } from "../../src/interfaces/IGoldilocked.sol";
import { IGoldiswap } from "../../src/interfaces/IGoldiswap.sol";

contract UnitGoldilockedTest is BaseUnitTest {

  function testPRGName() public {
    assertEq(goldilocked.name(), "Porridge");
  }

  function testPRGSymbol() public {
    assertEq(goldilocked.symbol(), "PRG");
  }

  function testUserStakedLocksView() public dealStakeLocks {
    assertEq(goldilocked.userStakedLocks(address(this)), locksAmount);
  }

  function testUserClaimablePrgView() public dealStakeLocks {
    vm.warp(block.timestamp + 1 days);

    assertEq(goldilocked.userClaimablePrg(address(this)), oneDayPrg);
  }

  function testUserClaimablePrgInitialZero() public {
    assertEq(goldilocked.userClaimablePrg(address(0x42069420694206942069)), 0);
  }

  function testUserLockedLocksView() public dealStakeLocks dealGoldiswapMaxHoney {
    goldilocked.borrow(borrowAmount);

    assertEq(goldilocked.userLockedLocks(address(this)), locksAmount);
  }

  function testUserBorrowedHoneyView() public dealStakeLocks dealGoldiswapMaxHoney {
    goldilocked.borrow(borrowAmount);

    assertEq(goldilocked.userBorrowedHoney(address(this)), borrowAmount);
  }

  function testUserBorrowLimitView() public dealStakeLocks {
    assertEq(goldilocked.userBorrowLimit(address(this)), borrowAmount);
  }

  function testStakeLocksFailVesting() public {
    vm.prank(address(0x42042069));
    vm.expectRevert(abi.encodeWithSelector(IGoldilocked.Vesting.selector));
    goldilocked.stake(1);
  }

  function testStakeLocksSuccess() public {
    deal(address(goldiswap), address(this), locksAmount);
    goldiswap.approve(address(goldilocked), locksAmount);
    goldilocked.stake(locksAmount);
    govlocks.delegate(address(this));

    assertEq(goldilocked.userStakedLocks(address(this)), locksAmount);
    assertEq(goldiswap.balanceOf(address(goldilocked)), locksAmount + locksMintAmount);
    assertEq(goldiswap.balanceOf(address(this)), 0);
    assertEq(goldilocked.prgPerTokenDebt(address(this)), 0);
    assertEq(govlocks.getVotes(address(this)), locksAmount);
  }

  function testDoubleStakeSuccess() public dealStakeLocks {
    vm.warp(1 days + 1);
    deal(address(goldiswap), address(this), locksAmount);
    goldiswap.approve(address(goldilocked), locksAmount);
    goldilocked.stake(locksAmount);
    govlocks.delegate(address(this));

    assertEq(goldilocked.userStakedLocks(address(this)), locksAmount + locksAmount);
    assertEq(goldiswap.balanceOf(address(goldilocked)), locksAmount + locksAmount + locksMintAmount);
    assertEq(goldiswap.balanceOf(address(this)), 0);
    assertEq(goldilocked.prgPerTokenDebt(address(this)), dayOfPrgDebt);
    assertEq(govlocks.getVotes(address(this)), locksAmount + locksAmount);
  }

  function testUnstakeFailVest() public {
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(IGoldilocked.NotVested.selector));
    goldilocked.unstake(1);
  }

  function testUnstakeFailInvalid() public dealStakeLocks {
    vm.expectRevert(abi.encodeWithSelector(IGoldilocked.InvalidUnstake.selector));
    goldilocked.unstake(locksAmount + 1);
  }

  function testUnstakeFailBorrowed() public dealStakeLocks dealGoldiswapMaxHoney {
    goldilocked.borrow(borrowAmount);
    vm.expectRevert(abi.encodeWithSelector(IGoldilocked.LocksBorrowedAgainst.selector));
    goldilocked.unstake(1);
  }

  function testUnstakeSuccess() public dealStakeLocks {
    vm.warp(1 days + 1);
    goldilocked.unstake(locksAmount);

    assertEq(goldilocked.userStakedLocks(address(this)), 0);
    assertEq(govlocks.getVotes(address(this)), 0);
    assertEq(goldiswap.balanceOf(address(goldilocked)), locksMintAmount);
    assertEq(goldiswap.balanceOf(address(this)), locksAmount);
    assertEq(goldilocked.balanceOf(address(this)), prgMintAmount);
    assertEq(goldilocked.prgPerTokenDebt(address(this)), dayOfPrgDebt);
  }

  function testDelegateOtherUnstakeSuccess() public dealStakeLocks {
    govlocks.delegate(address(0xacb));
    vm.warp(1 days + 1);
    goldilocked.unstake(locksAmount);

    assertEq(goldilocked.userStakedLocks(address(this)), 0);
    assertEq(govlocks.getVotes(address(this)), 0);
    assertEq(govlocks.getVotes(address(0xacb)), 0);
    assertEq(goldiswap.balanceOf(address(goldilocked)), locksMintAmount);
    assertEq(goldiswap.balanceOf(address(this)), locksAmount);
    assertEq(goldilocked.balanceOf(address(this)), prgMintAmount);
    assertEq(goldilocked.prgPerTokenDebt(address(this)), dayOfPrgDebt);
  }

  function testDelegateSelfUnstakeSuccess() public dealStakeLocks {
    govlocks.delegate(address(this));
    vm.warp(1 days + 1);
    goldilocked.unstake(locksAmount);

    assertEq(goldilocked.userStakedLocks(address(this)), 0);
    assertEq(govlocks.getVotes(address(this)), 0);
    assertEq(goldiswap.balanceOf(address(goldilocked)), locksMintAmount);
    assertEq(goldiswap.balanceOf(address(this)), locksAmount);
    assertEq(goldilocked.balanceOf(address(this)), prgMintAmount);
    assertEq(goldilocked.prgPerTokenDebt(address(this)), dayOfPrgDebt);
  }

  function testStirSuccess() public dealStakeLocks {
    uint256 oneDayPrgCost = 821917808219178000;
    uint256 oneDayLocksProceeds = 136986301369863000000;
    deal(address(honey), address(this), oneDayPrgCost);
    honey.approve(address(goldilocked), oneDayPrgCost);
    vm.warp(1 days + 1);
    goldilocked.unstake(locksAmount);
    goldilocked.stir(oneDayPrg);

    assertEq(goldiswap.balanceOf(address(this)), oneDayLocksProceeds + locksAmount);
    assertEq(goldilocked.balanceOf(address(this)), prgMintAmount - oneDayPrg);
    assertEq(honey.balanceOf(address(this)), 0);
    assertEq(honey.balanceOf(address(goldiswap)), oneDayPrgCost + initialPSL);
  }

  function testYieldHalfDay() public dealStakeLocks {
    vm.warp((1 days / 2) + 1);
    goldilocked.claim();
    
    assertEq(goldilocked.balanceOf(address(this)), halfDayPrg + prgMintAmount);
  }

  function testYieldDay() public dealStakeLocks {
    vm.warp(1 days + 1);
    goldilocked.claim();

    assertEq(goldilocked.balanceOf(address(this)), oneDayPrg + prgMintAmount);
  }

  function testYieldDayHalf() public dealStakeLocks {
    vm.warp(1 days + (1 days / 2) + 1);
    goldilocked.claim();
    
    assertEq(goldilocked.balanceOf(address(this)), oneDayHalfPrg + prgMintAmount);
  }

  function testYieldTwoDays() public dealStakeLocks {
    vm.warp(2 days + 1);
    goldilocked.claim();

    assertEq(goldilocked.balanceOf(address(this)), twoDaysPrg + prgMintAmount);
  }

  function testYieldOneYear() public {
    deal(address(goldiswap), address(this), 1e18);
    goldiswap.approve(address(goldilocked), 1e18);
    goldilocked.stake(1e18);
    vm.warp(365 days + 1);
    goldilocked.claim();

    assertEq(goldilocked.balanceOf(address(this)), 5e17 + prgMintAmount);
  }

  function testDoubleClaimFail() public dealStakeLocks {
    vm.warp(2 days + 1);
    goldilocked.claim();
    goldilocked.claim();
    goldilocked.claim();

    assertEq(goldilocked.balanceOf(address(this)), twoDaysPrg + prgMintAmount);
  }

  function testStakeUnstakeHalf() public dealStakeLocks {
    goldilocked.unstake(locksAmount / 2);
    vm.warp((1 days * 2) + 1);
    goldilocked.claim();

    assertEq(goldilocked.balanceOf(address(this)), oneDayPrg + prgMintAmount);
  }

  function testStakeWaitUnstakeHalf() public dealStakeLocks {
    vm.warp(1 days + 1);
    goldilocked.unstake(locksAmount / 2);
    vm.warp(1 days + block.timestamp);
    goldilocked.claim();
    goldilocked.claim();
    
    assertEq(goldilocked.balanceOf(address(this)), oneDayHalfPrg + prgMintAmount);
  }

  function testStakeStake() public {
    vm.warp(2 days + 1);
    deal(address(goldiswap), address(this), locksAmount*2);
    goldiswap.approve(address(goldilocked), locksAmount*2);
    goldilocked.stake(locksAmount);
    vm.warp((1 days / 2) + block.timestamp);
    goldilocked.stake(locksAmount);
    vm.warp(1 days + block.timestamp);
    goldilocked.claim();

    assertEq(goldilocked.balanceOf(address(this)), twoDaysPrg + halfDayPrg + prgMintAmount);
  }

  function testRandomStaking() public {
    deal(address(goldiswap), address(this), locksAmount*2);
    goldiswap.approve(address(goldilocked), locksAmount*2);
    goldilocked.stake(locksAmount / 2);
    vm.warp(4 days + 1);
    goldilocked.stake(locksAmount / 2);
    vm.warp(1 days + block.timestamp);
    goldilocked.stake(locksAmount);
    vm.warp(2 days + block.timestamp);
    goldilocked.unstake(locksAmount);
    vm.warp(1 days + block.timestamp);
    goldilocked.claim();

    assertEq(goldilocked.balanceOf(address(this)), (oneDayPrg * 8)  + prgMintAmount);
  }

  function testMultipleUnstaking() public {
    vm.warp(1 days + 1);
    deal(address(goldiswap), address(this), locksAmount*2);
    goldiswap.approve(address(goldilocked), locksAmount*2);
    goldilocked.stake(locksAmount * 2);
    vm.warp(1 days + block.timestamp);
    goldilocked.unstake(locksAmount / 2);
    vm.warp(1 days + block.timestamp);
    goldilocked.unstake(locksAmount / 2);
    vm.warp(1 days + block.timestamp);
    goldilocked.unstake(locksAmount);
    goldilocked.claim();

    assertEq(goldilocked.balanceOf(address(this)), (oneDayPrg * 4) + halfDayPrg + prgMintAmount);
    assertEq(goldiswap.balanceOf(address(this)), locksAmount*2);
  }

  function testBorrowHoneyFailLimit() public dealStakeLocks dealGoldiswapMaxHoney {
    vm.expectRevert(abi.encodeWithSelector(IGoldilocked.InsufficientBorrowLimit.selector));
    goldilocked.borrow(borrowAmount + 1);
  }

  function testBorrowHoneySuccess() public dealStakeLocks dealGoldiswapMaxHoney {
    goldilocked.borrow(borrowAmount);

    assertEq(goldilocked.userLockedLocks(address(this)), locksAmount);
    assertEq(goldilocked.userBorrowedHoney(address(this)), borrowAmount);
    assertEq(honey.balanceOf(address(this)), borrowAmount);
    assertEq(honey.balanceOf(address(goldiswap)), (type(uint256).max / 2) - borrowAmount);
  }

  function testRepayHoneySuccess() public dealStakeLocks dealGoldiswapMaxHoney {
    goldilocked.borrow(borrowAmount);
    honey.approve(address(goldilocked), borrowAmount);
    goldilocked.repay(borrowAmount);

    assertEq(goldilocked.userLockedLocks(address(this)), 0);
    assertEq(goldilocked.borrowedHoney(address(this)), 0);
    assertEq(goldilocked.stakedLocks(address(this)), locksAmount);
    assertEq(honey.balanceOf(address(this)), 0);
    assertEq(honey.balanceOf(address(goldiswap)), (type(uint256).max / 2));
  }

  function testHalfRepayHoneySuccess() public dealStakeLocks dealGoldiswapMaxHoney {
    goldilocked.borrow(borrowAmount);
    honey.approve(address(goldilocked), borrowAmount);
    goldilocked.repay(borrowAmount / 2);

    assertEq(goldilocked.userLockedLocks(address(this)), locksAmount / 2);
    assertEq(goldilocked.borrowedHoney(address(this)), borrowAmount / 2);
    assertEq(goldilocked.stakedLocks(address(this)), locksAmount);
    assertEq(honey.balanceOf(address(this)), borrowAmount / 2);
    assertEq(honey.balanceOf(address(goldiswap)), (type(uint256).max / 2) - (borrowAmount / 2));
  }

  function testTeamVest() public {    
    assertEq(goldilocked.userVestingCheck(address(0x69)), 0);
  }

  function testNonTeamVest() public {
    assertEq(goldilocked.userVestingCheck(address(0xaaa)), type(uint256).max);
  }

  function testSeedRoundNoVest() public {
    assertEq(goldilocked.userVestingCheck(address(0x42042069)), 0);
  }

  function testSeedRoundFullVest() public {
    vm.warp(90 days + 365 days + 1);
    assertEq(goldilocked.userVestingCheck(address(0x42042069)), 7_000_000e18);
  }

  function testGoldilendMintFailGoldilend() public {
    vm.expectRevert(abi.encodeWithSelector(IGoldilocked.NotGoldilend.selector));
    goldilocked.goldilendMint(address(this), 69);
  }

  function testChangePorridgeEmissionsFailTimelock() public {
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(IGoldilocked.NotTimelock.selector));
    goldilocked.changePrgEmissions(69);
  }

  function testChangePorridgeEmissionsSuccess() public {
    bytes memory _calldata = abi.encodeWithSignature("changePrgEmissions(uint256)", 69);
    address[] memory targets = new address[](1);
    targets[0] = address(goldilocked);
    string[] memory signatures = new string[](1);
    signatures[0] = "";
    bytes[] memory calldatas = new bytes[](1);
    calldatas[0] = _calldata;
    uint256[] memory values = new uint256[](1);
    values[0] = 0;
    deal(address(goldiswap), address(this), quorumVotesNum);
    goldiswap.approve(address(govlocks), quorumVotesNum);
    govlocks.deposit(quorumVotesNum);
    govlocks.delegate(address(this));
    vm.roll(2);
    goldigov.propose(targets, values, signatures, calldatas, "");
    vm.roll(52600);
    goldigov.castVote(1, 1);
    vm.roll(200000);
    goldigov.queue(1);
    vm.warp(6 days);
    goldigov.execute(1);
    (, , , , , , , , , bool executed) = goldigov.proposals(1);

    assertEq(executed, true);
    assertEq(goldilocked.annualPrgEmissions(), 69);
  }

  function testMintPorridgeFailTimelock() public {
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(IGoldilocked.NotTimelock.selector));
    goldilocked.mintPorridge(69);
  }

  function testMintPorridgeSuccess() public {
    bytes memory _calldata = abi.encodeWithSignature("mintPorridge(uint256)", 69);
    address[] memory targets = new address[](1);
    targets[0] = address(goldilocked);
    string[] memory signatures = new string[](1);
    signatures[0] = "";
    bytes[] memory calldatas = new bytes[](1);
    calldatas[0] = _calldata;
    uint256[] memory values = new uint256[](1);
    values[0] = 0;
    deal(address(goldiswap), address(this), quorumVotesNum);
    goldiswap.approve(address(govlocks), quorumVotesNum);
    govlocks.deposit(quorumVotesNum);
    govlocks.delegate(address(this));
    vm.roll(2);
    goldigov.propose(targets, values, signatures, calldatas, "");
    vm.roll(52600);
    goldigov.castVote(1, 1);
    vm.roll(200000);
    goldigov.queue(1);
    vm.warp(6 days);
    goldigov.execute(1);
    (, , , , , , , , , bool executed) = goldigov.proposals(1);

    assertEq(executed, true);
    assertEq(goldilocked.balanceOf(address(this)), 69 + prgMintAmount);
  }

  function testSetGoldilendAddressFailMultisig() public {
    vm.prank(address(0x69));
    vm.expectRevert(abi.encodeWithSelector(IGoldilocked.NotMultisig.selector));
    goldilocked.setGoldilendAddress(address(0x69));
  }

  function testSetGoldilendAddressSuccess() public {
    goldilocked.setGoldilendAddress(address(0x69));

    assertEq(goldilocked.goldilend(), address(0x69));
  }

  function testUnstakeAfterFloorIncreaseFail() public {
    deal(address(honey), address(goldiswap), type(uint256).max);
    deal(address(goldiswap), address(this), locksAmount);
    goldiswap.approve(address(goldilocked), locksAmount);
    goldilocked.stake(locksAmount);
    goldilocked.borrow(borrowAmount);
    vm.store(address(goldiswap), bytes32(uint256(0)), bytes32(uint256(2_280_000e18)));
    vm.expectRevert(abi.encodeWithSelector(IGoldilocked.LocksBorrowedAgainst.selector));
    goldilocked.unstake((locksAmount/2) + 1);
  }

  function testUnstakeAfterFloorIncreaseSuccess() public {
    deal(address(honey), address(goldiswap), type(uint256).max / 2);
    deal(address(goldiswap), address(this), locksAmount);
    goldiswap.approve(address(goldilocked), locksAmount);
    goldilocked.stake(locksAmount);
    goldilocked.borrow(borrowAmount);
    vm.store(address(goldiswap), bytes32(uint256(0)), bytes32(uint256(2_280_000e18)));
    goldilocked.unstake(locksAmount/2);

    assertEq(goldiswap.balanceOf(address(this)), locksAmount/2);
    assertEq(goldilocked.userStakedLocks(address(this)), locksAmount/2);
    assertEq(goldilocked.userLockedLocks(address(this)), locksAmount/2);
    assertEq(honey.balanceOf(address(this)), borrowAmount);
    assertEq(honey.balanceOf(address(goldiswap)), (type(uint256).max / 2) - borrowAmount);
  }

  function testBorrowFurtherBorrowFail() public {
    deal(address(honey), address(goldiswap), type(uint256).max);
    deal(address(goldiswap), address(this), locksAmount);
    goldiswap.approve(address(goldilocked), locksAmount);
    goldilocked.stake(locksAmount);
    goldilocked.borrow(borrowAmount);
    vm.store(address(goldiswap), bytes32(uint256(0)), bytes32(uint256(2_280_000e18)));
    vm.expectRevert(abi.encodeWithSelector(IGoldilocked.InsufficientBorrowLimit.selector));
    goldilocked.borrow(borrowAmount+1);
  }

  function testBorrowFurtherBorrowSuccess() public {
    deal(address(honey), address(goldiswap), type(uint256).max / 2);
    deal(address(goldiswap), address(this), locksAmount);
    goldiswap.approve(address(goldilocked), locksAmount);
    goldilocked.stake(locksAmount);
    goldilocked.borrow(borrowAmount);
    vm.store(address(goldiswap), bytes32(uint256(0)), bytes32(uint256(2_280_000e18)));
    goldilocked.borrow(borrowAmount);

    assertEq(goldilocked.userStakedLocks(address(this)), locksAmount);
    assertEq(goldilocked.userLockedLocks(address(this)), locksAmount);
    assertEq(goldilocked.userBorrowedHoney(address(this)), borrowAmount*2);
    assertEq(honey.balanceOf(address(this)), borrowAmount*2);
    assertEq(honey.balanceOf(address(goldiswap)), (type(uint256).max / 2) - (borrowAmount*2));
  }

  function testChangePrgEmissionsDoubleAfterHalfYear() public {
    deal(address(goldiswap), address(this), 1e18);
    goldiswap.approve(address(goldilocked), 1e18);
    goldilocked.stake(1e18);
    vm.warp(15768000 + 1);
    bytes memory _calldata = abi.encodeWithSignature("changePrgEmissions(uint256)", 1e18);
    address[] memory targets = new address[](1);
    targets[0] = address(goldilocked);
    string[] memory signatures = new string[](1);
    signatures[0] = "";
    bytes[] memory calldatas = new bytes[](1);
    calldatas[0] = _calldata;
    uint256[] memory values = new uint256[](1);
    values[0] = 0;
    deal(address(goldiswap), address(this), quorumVotesNum);
    goldiswap.approve(address(govlocks), quorumVotesNum);
    govlocks.deposit(quorumVotesNum);
    govlocks.delegate(address(this));
    vm.roll(2);
    goldigov.propose(targets, values, signatures, calldatas, "");
    vm.roll(52600);
    goldigov.castVote(1, 1);
    vm.roll(200000);
    goldigov.queue(1);
    vm.warp(6 days + block.timestamp);
    goldigov.execute(1);
    vm.warp(block.timestamp + 15768000);
    goldilocked.claim();
    uint256 extraGovTimeYield = 8219178082191780;

    assertEq(goldilocked.balanceOf(address(this)) - prgMintAmount, 75e16 + extraGovTimeYield);
  }

  function testChangePrgEmissionsDoubleAfterDay() public {
    deal(address(goldiswap), address(this), locksAmount);
    goldiswap.approve(address(goldilocked), locksAmount);
    goldilocked.stake(locksAmount);
    vm.warp(1 days + 1);
    bytes memory _calldata = abi.encodeWithSignature("changePrgEmissions(uint256)", 1e18);
    address[] memory targets = new address[](1);
    targets[0] = address(goldilocked);
    string[] memory signatures = new string[](1);
    signatures[0] = "";
    bytes[] memory calldatas = new bytes[](1);
    calldatas[0] = _calldata;
    uint256[] memory values = new uint256[](1);
    values[0] = 0;
    deal(address(goldiswap), address(this), quorumVotesNum);
    goldiswap.approve(address(govlocks), quorumVotesNum);
    govlocks.deposit(quorumVotesNum);
    govlocks.delegate(address(this));
    vm.roll(2);
    goldigov.propose(targets, values, signatures, calldatas, "");
    vm.roll(52600);
    goldigov.castVote(1, 1);
    vm.roll(200000);
    goldigov.queue(1);
    vm.warp(6 days + block.timestamp);
    goldigov.execute(1);
    vm.warp(block.timestamp + 1 days);
    goldilocked.claim();

    assertEq(goldilocked.balanceOf(address(this)) - prgMintAmount, oneDayPrg + twoDaysPrg + govTimeYield);
  }

  function testChangePrgEmissionsHalfAfterDay() public {
    deal(address(goldiswap), address(this), locksAmount);
    goldiswap.approve(address(goldilocked), locksAmount);
    goldilocked.stake(locksAmount);
    vm.warp(1 days + 1);
    bytes memory _calldata = abi.encodeWithSignature("changePrgEmissions(uint256)", 25e16);
    address[] memory targets = new address[](1);
    targets[0] = address(goldilocked);
    string[] memory signatures = new string[](1);
    signatures[0] = "";
    bytes[] memory calldatas = new bytes[](1);
    calldatas[0] = _calldata;
    uint256[] memory values = new uint256[](1);
    values[0] = 0;
    deal(address(goldiswap), address(this), quorumVotesNum);
    goldiswap.approve(address(govlocks), quorumVotesNum);
    govlocks.deposit(quorumVotesNum);
    govlocks.delegate(address(this));
    vm.roll(2);
    goldigov.propose(targets, values, signatures, calldatas, "");
    vm.roll(52600);
    goldigov.castVote(1, 1);
    vm.roll(200000);
    goldigov.queue(1);
    vm.warp(6 days + block.timestamp);
    goldigov.execute(1);
    vm.warp(block.timestamp + 1 days);
    goldilocked.claim();

    assertEq(goldilocked.balanceOf(address(this)) - prgMintAmount, oneDayPrg + halfDayPrg + govTimeYield);
  }

  function testTeamUnstakeFail() public {
    vm.prank(address(0x42069));
    vm.expectRevert(abi.encodeWithSelector(IGoldilocked.NotVested.selector));
    goldilocked.unstake(1);
  }

  function testSeedUnstakeFail() public {
    vm.prank(address(0x42042069));
    vm.expectRevert(abi.encodeWithSelector(IGoldilocked.NotVested.selector));
    goldilocked.unstake(1);
  }

  function testSeedUnstakeWaitFail() public {
    vm.warp(7776000 + 15768000 + 1);
    deal(address(honey), address(0x42042069), 36750e18);
    vm.prank(address(0x42042069));
    honey.approve(address(goldilocked), 36750e18);
    vm.prank(address(0x42042069));
    goldilocked.repay(36750e18);
    vm.prank(address(0x42042069));
    vm.expectRevert(abi.encodeWithSelector(IGoldilocked.NotVested.selector));
    goldilocked.unstake(3_500_001e18);
  }

  function testSeedUnstakeSuccess() public {
    vm.warp(7776000 + 15768000 + 1);
    deal(address(honey), address(0x42042069), 36750e18);
    vm.startPrank(address(0x42042069));
    honey.approve(address(goldilocked), 36750e18);
    goldilocked.repay(36750e18);
    goldilocked.unstake(3_500_000e18);
    vm.stopPrank();
  }

  function testSeedUnstakeFailBeforeVest() public {
    vm.warp(7776000 + 15768000 + 1);
    deal(address(honey), address(0x42042069), 42000e18);
    vm.startPrank(address(0x42042069));
    honey.approve(address(goldilocked), 42000e18);
    goldilocked.repay(42000e18);
    goldilocked.unstake(3_500_000e18);
    vm.expectRevert(abi.encodeWithSelector(IGoldilocked.NotVested.selector));
    goldilocked.unstake(3_500_000e18);
    vm.stopPrank();
  }

  function testSeedUnstakeFullVestSuccess() public {
    vm.warp(90 days + 365 days + 1);
    deal(address(honey), address(0x42042069), 42000e18);
    vm.startPrank(address(0x42042069));
    honey.approve(address(goldilocked), 42000e18);
    goldilocked.repay(42000e18);
    goldilocked.unstake(7_000_000e18);
    vm.stopPrank();
    
    assertEq(goldilocked.userStakedLocks(address(0x42042069)), 0);
    assertEq(goldilocked.seedAllocations(address(0x42042069)), 7_000_000e18);
    assertEq(goldilocked.borrowedHoney(address(0x42042069)), 0);
    assertEq(goldiswap.balanceOf(address(0x42042069)), 7_000_000e18);
  }

  function testSeedUnstakeRestakeFail() public {
    vm.warp(7776000 + 15768000 + 1);
    deal(address(honey), address(0x42042069), 42000e18);
    deal(address(goldiswap), address(0x42042069), 1e18);
    vm.startPrank(address(0x42042069));
    honey.approve(address(goldilocked), 42000e18);
    goldiswap.approve(address(goldilocked), 1e18);
    goldilocked.repay(42000e18);
    goldilocked.unstake(3_500_000e18);
    vm.stopPrank();
    vm.warp(block.timestamp + 15768000);

    assertEq(goldilocked.userVestingCheck(address(0x42042069)), 3_500_000e18);
  }

  function testNoStirSandwich() public dealStakeLocks {
    address attacker = makeAddr("attacker");
    address user = makeAddr("user");
    uint256 amount = 1_000_000 ether;
    deal(address(honey), user, type(uint256).max);
    deal(address(goldilocked), user, type(uint256).max);
    deal(address(goldiswap), attacker, amount);
    vm.startPrank(attacker);
    honey.approve(address(goldiswap), type(uint256).max);
    goldiswap.approve(address(goldiswap), type(uint256).max);
    vm.startPrank(user);
    honey.approve(address(goldilocked), type(uint256).max);
    goldiswap.approve(address(goldiswap), type(uint256).max);
    vm.startPrank(attacker);
    goldiswap.sell(amount, 0);
    vm.startPrank(user);
    vm.expectRevert(abi.encodeWithSelector(IGoldiswap.ExcessiveSlippage.selector));
    goldilocked.stir(amount * 6);
  }

  function testClaimingCheckFailVesting() public {
    address seedor = address(0x696969696969);
    vm.prank(seedor);
    vm.expectRevert(abi.encodeWithSelector(IGoldilocked.NotVested.selector));
    goldilocked.claim();
  }

  function testClaimingCheckSuccess() public {
    address seedor = address(0x696969696969);
    vm.warp(block.timestamp + 90 days + 1);    
    vm.prank(seedor);
    goldilocked.claim();

    assert(goldilocked.balanceOf(seedor) > 0);
  }

  function testClaimingCheckSuccessNonSeedor() public {
    address nonseedor = address(0xabcabcabcabcabccbacba);
    deal(address(goldiswap), nonseedor, 69e18);
    vm.startPrank(nonseedor);
    goldiswap.approve(address(goldilocked), 69e18);
    goldilocked.stake(69e18);
    vm.stopPrank();
    vm.warp(block.timestamp + 1 days);
    vm.prank(nonseedor);
    goldilocked.claim();

    assert(goldilocked.balanceOf(nonseedor) > 0);
  }

}