//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { BaseTest } from "./BaseTest.t.sol";
import { IERC721 } from "../../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import { INFT } from "../../src/mock/INFT.sol";
import { BeraBondNFT } from "../../lib/PoC-00Bera/src/BeraBondNFT.sol";

abstract contract BaseUnitTest is BaseTest {

  uint256 costOf10Locks = 187938603930731900;
  uint256 taxof10Locks = 563815811792195;
  uint256 proceedsof10Locks = 178541673734195305;
  uint256 startingFloorPrice = 6e15;
  uint256 randomFloorPrice = 5362996113397347965249;
  uint256 startingMarketPrice = 18793860393073190;
  uint256 randomMarketPrice = 17195479260432920174524;
  uint256 decreasedTargetRatio = 372400043981481481;
  uint256 maxDecreasedTargetRatio = 361000000000000000;

  uint256 borrowAmount = 600e18;
  uint256 oneDayPrg = 136986301369863000000;
  uint256 halfDayPrg = 68493150684931500000;
  uint256 oneDayHalfPrg = 205479452054794500000;
  uint256 twoDaysPrg = 273972602739726000000;
  uint256 initialPrgDebt = 15854895991;
  uint256 dayOfPrgDebt = 1369863013698630;
  uint256 oneDayPrgBoosted = 137808219178082178000;
  uint256 oneDayPrgMaxBoosted = 143972602739726013000;
  uint256 govTimeYield = twoDaysPrg + twoDaysPrg + twoDaysPrg;

  uint256 goldilendDuration = 1209600;
  uint256 borrowInterest = 4572685306811784;
  uint256 singleBorrowInterestBoosted = 4545249194970913;
  uint256 singleBorrowInterestMaxBoost = 4339478356164383;
  uint256 interestCalculation1 = 8849690373428410538;

  uint256 yearMockBexLPYield = 11574074074074000;  
  uint256 govLocksAmt = 5_000_001e18;

  function setUp() public override {
    deployProtocol();
  }

  modifier dealandApproveUserHoney() {
    deal(address(honey), address(this), type(uint256).max / 2);
    honey.approve(address(goldiswap), type(uint256).max / 2);
    _;
  }

  modifier dealUserLocks() {
    deal(address(goldiswap), address(this), type(uint256).max / 2);
    _;
  }

  modifier dealLocks() {
    deal(address(goldiswap), address(this), txAmount);
    _;
  }

  modifier dealGoldiswapHoney() {
    deal(address(honey), address(goldiswap), type(uint256).max / 2);
    _;
  }

  modifier dealStakeLocks() {
    deal(address(goldiswap), address(this), locksAmount);
    goldiswap.approve(address(goldilocked), locksAmount);
    goldilocked.stake(locksAmount);
    _;
  }

  modifier dealGoldiswapMaxHoney() {
    deal(address(honey), address(goldiswap), type(uint256).max / 2);
    _;
  }

  modifier dealUserWBERA() {
    deal(address(wbera), address(this), type(uint256).max / 2);
    wbera.approve(address(proxy), type(uint256).max / 2);
    _;
  }

  modifier dealUserBeras() {
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bandbear)).mint(address(this));
    IERC721(bondbear).setApprovalForAll(address(proxy), true);
    IERC721(bandbear).setApprovalForAll(address(proxy), true);
    _;
  }

  modifier dealUserABunchOfBeras() {
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bandbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bandbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bandbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bandbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bandbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bandbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bandbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bandbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bandbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bandbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bandbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bandbear)).mint(address(this));
    INFT(address(bondbear)).mint(address(this));
    INFT(address(bandbear)).mint(address(this));
    IERC721(bondbear).setApprovalForAll(address(proxy), true);
    IERC721(bandbear).setApprovalForAll(address(proxy), true);
    _;
  }

  function proposySame() public pure returns (address[] memory, string[] memory, bytes[] memory, uint256[] memory) {
    address[] memory targets = new address[](2);
    targets[0] = address(0x69);
    targets[1] = address(0x69);
    string[] memory signatures = new string[](2);
    signatures[0] = "hello";
    signatures[1] = "hello";
    bytes[] memory calldatas = new bytes[](2);
    calldatas[0] = hex"8eed55d1";
    calldatas[1] = hex"8eed55d1";
    uint256[] memory values = new uint256[](2);
    values[0] = 69;
    values[1] = 69;

    return (targets, signatures, calldatas, values);
  }

  function proposySamePropose() public returns (address[] memory, string[] memory, bytes[] memory, uint256[] memory) {
    address[] memory targets = new address[](2);
    targets[0] = address(0x69);
    targets[1] = address(0x69);
    string[] memory signatures = new string[](2);
    signatures[0] = "hello";
    signatures[1] = "hello";
    bytes[] memory calldatas = new bytes[](2);
    calldatas[0] = hex"8eed55d1";
    calldatas[1] = hex"8eed55d1";
    uint256[] memory values = new uint256[](2);
    values[0] = 69;
    values[1] = 69;
    deal(address(goldiswap), address(this), 5_000_001e18);
    goldiswap.approve(address(govlocks), 5_000_001e18);
    govlocks.deposit(5_000_001e18);
    govlocks.delegate(address(this));
    vm.roll(2);
    goldigov.propose(targets, values, signatures, calldatas, "");

    return (targets, signatures, calldatas, values);
  }

  function proposyDiffQueue() public returns (address[] memory, string[] memory, bytes[] memory, uint256[] memory) {
    address[] memory targets = new address[](2);
    targets[0] = address(0x69);
    targets[1] = address(0x69);
    string[] memory signatures = new string[](2);
    signatures[0] = "hello";
    signatures[1] = "helloagain";
    bytes[] memory calldatas = new bytes[](2);
    calldatas[0] = hex"8eed55d1";
    calldatas[1] = hex"8eed55d1";
    uint256[] memory values = new uint256[](2);
    values[0] = 0;
    values[1] = 0;
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

    return (targets, signatures, calldatas, values);
  }

  function proposyDiff() public pure returns (address[] memory, string[] memory, bytes[] memory, uint256[] memory) {
    address[] memory targets = new address[](2);
    targets[0] = address(0x69);
    targets[1] = address(0x69);
    string[] memory signatures = new string[](2);
    signatures[0] = "hello";
    signatures[1] = "helloagain";
    bytes[] memory calldatas = new bytes[](2);
    calldatas[0] = hex"8eed55d1";
    calldatas[1] = hex"8eed55d1";
    uint256[] memory values = new uint256[](2);
    values[0] = 0;
    values[1] = 0;

    return (targets, signatures, calldatas, values);
  }

  function depositBexLP() public {
    deal(address(bexlp), address(this), txAmount);
    bexlp.approve(address(goldivault), txAmount);
    goldivault.deposit(txAmount);
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

  function deployBerabond() public returns (BeraBondNFT berabond) {
    
  }

}