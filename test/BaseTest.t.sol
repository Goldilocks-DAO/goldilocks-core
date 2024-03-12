//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/forge-std/src/Test.sol";
import { LibRLP } from "../lib/solady/src/utils/LibRLP.sol";
import { ERC20 } from "../lib/solady/src/tokens/ERC20.sol";
import { IERC721Receiver } from "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import { IERC721 } from "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import { INFT } from "../src/mock/INFT.sol";
import { Goldiswap } from "../src/core/goldiswap/Goldiswap.sol";
import { Goldilocked } from "../src/core/goldiswap/Goldilocked.sol";
import { Goldilend } from "../src/core/goldilend/Goldilend.sol";
import { Goldivault } from "../src/core/goldivault/Goldivault.sol";
import { InfraredBexLPGoldivault } from "../src/core/goldivault/InfraredBexLPGoldivault.sol";
import { OwnershipToken } from "../src/core/goldivault/OwnershipToken.sol";
import { YieldToken } from "../src/core/goldivault/YieldToken.sol";
import { Goldigovernor } from "../src/core/goldigovernance/Goldigovernor.sol";
import { Timelock } from "../src/core/goldigovernance/Timelock.sol";
import { govLocks } from "../src/core/goldigovernance/govLocks.sol";
import { Honey } from "../src/mock/Honey.sol";
import { iBGT } from "../src/mock/iBGT.sol";
import { HoneyComb } from "../src/mock/HoneyComb.sol";
import { Beradrome } from "../src/mock/Beradrome.sol";
import { BondBear } from "../src/mock/BondBear.sol";
import { BandBear } from "../src/mock/BandBear.sol";
import { iBGTVault } from "../src/mock/iBGTVault.sol";
import { BexLPVault } from "../src/mock/BexLPVault.sol";

contract oBexLPToken is OwnershipToken {
  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    address _vault
  ) OwnershipToken(
    _tokenName,
    _tokenSymbol,
    _vault
  ) {}
}
contract yBexLPToken is YieldToken {
  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    address _vault
  ) YieldToken(
    _tokenName,
    _tokenSymbol,
    _vault
  ) {}
}
contract BexLPToken is ERC20 {
  function name() public pure override returns (string memory) {
    return "BexLPToken";
  }
  function symbol() public pure override returns (string memory) {
    return "BEXLP";
  }
}

abstract contract BaseTest is Test, IERC721Receiver {

  using LibRLP for address;

  Goldiswap goldiswap;
  Goldilend goldilend;
  govLocks govlocks;
  Timelock timelock;
  Goldilocked goldilocked;
  Goldigovernor goldigov;
  Honey honey;
  iBGT ibgt;
  HoneyComb honeycomb;
  Beradrome beradrome;
  BondBear bondbear;
  BandBear bandbear;
  iBGTVault ibgtvault;
  InfraredBexLPGoldivault goldivault;
  oBexLPToken ot;
  yBexLPToken yt;
  BexLPToken bexlp;
  BexLPVault bexvault;

  uint256 initialFSL = 1_050_000e18;
  uint256 initialPSL = 320_000e18;
  uint256 prgMintAmount = 200_000_000e18;

  uint256 txAmount = 10e18;
  uint256 locksMintAmount = 100_000_000e18;
  uint256 costOf10Locks = 262883805905681940;
  uint256 taxof10Locks = 788651417717045;
  uint256 proceedsof10Locks = 249739615610397843;
  uint256 startingFloorPrice = 10500000000000000;
  uint256 randomFloorPrice = 5362996113397347965249;
  uint256 startingMarketPrice = 26288380590568194;
  uint256 randomMarketPrice = 17195479260432920174524;
  uint256 decreasedTargetRatio = 313600037037037037;
  uint256 maxDecreasedTargetRatio = 304000000000000000;

  uint256 locksAmount = 100_000e18;
  uint256 borrowAmount = 1_050e18;
  uint256 oneDayPrg = 136986301369863000000;
  uint256 halfDayPrg = 68493150684931500000;
  uint256 oneDayHalfPrg = 205479452054794500000;
  uint256 twoDaysPrg = 273972602739726000000;
  uint256 initialPrgDebt = 15854895991;
  uint256 dayOfPrgDebt = 1369878868594621;
  uint256 oneDayPrgBoosted = 137808219178082178000;
  uint256 oneDayPrgMaxBoosted = 143835616438356150000;

  uint256 goldilendDuration = 1209600;
  uint256 singleBorrowInterest = 45726853068117;
  uint256 singleBorrowInterestBoosted = 45452491949708;
  uint256 singleBorrowInterestMaxBoost = 2286342653405;
  address honeyjar = address(0xdddd);

  uint256 govLocksAmt = 5e18;

  uint256 yearMockBexLPYield = 11574074074074000;  

  function setUp() public virtual {
    
    // precompute addresses
    Timelock timelockComputed = Timelock(address(this).computeAddress(13));
    Goldilocked goldilockedComputed = Goldilocked(address(this).computeAddress(14));
    Goldigovernor goldigovComputed = Goldigovernor(address(this).computeAddress(15));
    InfraredBexLPGoldivault goldivaultComputed = InfraredBexLPGoldivault(address(this).computeAddress(18));

    // deploy mock contracts
    bexlp = new BexLPToken();
    honey = new Honey();
    ibgt = new iBGT();
    honeycomb = new HoneyComb();
    beradrome = new Beradrome();
    bondbear = new BondBear();
    bandbear = new BandBear();
    ibgtvault = new iBGTVault(address(ibgt), address(ibgt));
    bexvault = new BexLPVault(address(bexlp), address(ibgt));

    // deploy goldiswap
    goldiswap = new Goldiswap(initialFSL, initialPSL, address(goldilockedComputed), address(honey), address(this), address(timelockComputed), locksMintAmount);

    // deploy goldilend
    address[] memory boostNfts = new address[](2);
    boostNfts[0] = address(honeycomb);
    boostNfts[1] = address(beradrome);
    uint8[] memory boosts = new uint8[](2);
    boosts[0] = 6;
    boosts[1] = 9;
    goldilend = new Goldilend(
      1000e18,
      1e17,
      1e13,
      10,
      address(goldilockedComputed),
      address(this),
      honeyjar,
      address(ibgt),
      address(ibgtvault),
      boostNfts,
      boosts
    );

    // initial configuration of goldilend
    address[] memory nfts = new address[](2);
    nfts[0] = address(bondbear);
    nfts[1] = address(bandbear);
    uint256[] memory values = new uint256[](2);
    values[0] = 50;
    values[1] = 50;
    goldilend.setValue(100e18, nfts, values);
    goldilend.setShareRates(45, 5);
    goldilend.setDurations(7 days, 21 days);
    goldilend.setBorrowingActive(true);
    deal(address(ibgt), address(goldilend), 1000e18);
    deal(address(ibgt), address(ibgtvault), type(uint256).max / 2);

    // deploy govlocks and timelock
    govlocks = new govLocks(address(goldiswap), address(goldigovComputed), address(goldilockedComputed), honeyjar, locksMintAmount / 20);
    timelock = new Timelock(address(goldigovComputed), 5 days);

    // deploy golidlocked
    address[] memory allocationsAddress = new address[](4);
    allocationsAddress[0] = address(0x69);
    allocationsAddress[1] = address(0x420);
    allocationsAddress[2] = address(0x42069);
    allocationsAddress[3] = address(0x69420);
    uint256[] memory allocationsAmt = new uint256[](4);
    allocationsAmt[0] = 12_000_000e18;
    allocationsAmt[1] = 12_000_000e18;
    allocationsAmt[2] = 10_000_000e18;
    allocationsAmt[3] = 7_000_000e18;
    goldilocked = new Goldilocked(address(goldiswap), address(goldilend), address(govlocks), address(honey), allocationsAddress, allocationsAmt, prgMintAmount);

    // deploy goldigovernor
    goldigov = new Goldigovernor(address(timelock), address(govlocks), address(this), 5761, 69, 4e18);

    // deploy goldivault
    address[] memory yieldTokens = new address[](1);
    yieldTokens[0] = address(ibgt);
    ot = new oBexLPToken("oBexLPToken", "oBEXLP", address(goldivaultComputed));
    yt = new yBexLPToken("yBexLPToken", "yBEXLP", address(goldivaultComputed));
    goldivault = new InfraredBexLPGoldivault(
      address(ot),
      address(yt),
      address(bexlp),
      address(bexvault),
      address(ibgt),
      address(ibgtvault),
      address(ibgt),
      address(ibgtvault),
      address(this),
      yieldTokens
    );
    goldivault.setEarlyWithdrawalFee(30);
    goldivault.setParameters(20, 1 days, 365 days);
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
    deal(address(honey), address(goldiswap), type(uint256).max);
    _;
  }

  modifier dealStakeLocks() {
    deal(address(goldiswap), address(this), locksAmount);
    goldiswap.approve(address(goldilocked), locksAmount);
    goldilocked.stake(locksAmount);
    _;
  }

  modifier dealGoldiswapMaxHoney() {
    deal(address(honey), address(goldiswap), type(uint256).max);
    _;
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

  modifier dealUserPartnerNFTs() {
    INFT(address(honeycomb)).mint(address(this));
    INFT(address(beradrome)).mint(address(this));
    IERC721(honeycomb).setApprovalForAll(address(goldilend), true);
    IERC721(beradrome).setApprovalForAll(address(goldilend), true);
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
    deal(address(goldiswap), address(this), 5e18);
    goldiswap.approve(address(govlocks), 5e18);
    govlocks.deposit(5e18);
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
    deal(address(goldiswap), address(this), 401e18);
    goldiswap.approve(address(govlocks), 401e18);
    govlocks.deposit(401e18);
    govlocks.delegate(address(this));
    vm.roll(2);
    goldigov.propose(targets, values, signatures, calldatas, "");
    vm.roll(72);
    goldigov.castVote(1, 1);
    vm.roll(5900);
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

  function boosty() public view returns (address[] memory, uint256[] memory) {
    address[] memory nfts = new address[](2);
    nfts[0] = address(honeycomb);
    nfts[1] = address(beradrome);
    uint256[] memory ids = new uint256[](2);
    ids[0] = 1;
    ids[1] = 1;
    return (nfts, ids);
  }

  function maxBoosty() public returns (address[] memory, uint256[] memory) {
    INFT(address(honeycomb)).mint(address(this));
    INFT(address(beradrome)).mint(address(this));
    INFT(address(beradrome)).mint(address(this));
    INFT(address(beradrome)).mint(address(this));
    INFT(address(beradrome)).mint(address(this));
    INFT(address(beradrome)).mint(address(this));
    address[] memory nfts = new address[](6);
    nfts[0] = address(honeycomb);
    nfts[1] = address(beradrome);
    nfts[2] = address(beradrome);
    nfts[3] = address(beradrome);
    nfts[4] = address(beradrome);
    nfts[5] = address(beradrome);
    uint256[] memory ids = new uint256[](6);
    ids[0] = 1;
    ids[1] = 1;
    ids[2] = 2;
    ids[3] = 3;
    ids[4] = 4;
    ids[5] = 5;
    IERC721(honeycomb).setApprovalForAll(address(goldilend), true);
    IERC721(beradrome).setApprovalForAll(address(goldilend), true);
    return (nfts, ids);
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

  function withinVariance(uint256 num1, uint256 num2) public pure returns (bool) {
    uint256 variance = num1 / 1000;
    return (num1 + variance > num2 && num1 - variance < num2) || (num1 == num2);
  }

  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) external virtual returns (bytes4) {
    return IERC721Receiver.onERC721Received.selector;
  }
}