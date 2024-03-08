//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../lib/forge-std/src/Test.sol";
import { LibRLP } from "../lib/solady/src/utils/LibRLP.sol";
import { SafeTransferLib } from "../lib/solady/src/utils/SafeTransferLib.sol";
import { ERC20 } from "../lib/solady/src/tokens/ERC20.sol";
import { IERC721Receiver } from "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import { IERC721 } from "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import { INFT } from "../src/mock/INFT.sol";
import { Goldiswap } from "../src/core/Goldiswap.sol";
import { Goldilocked } from "../src/core/Goldilocked.sol";
import { Goldilend } from "../src/core/Goldilend.sol";
import { Goldivault } from "../src/core/Goldivault.sol";
import { OwnershipToken } from "../src/core/OwnershipToken.sol";
import { YieldToken } from "../src/core/YieldToken.sol";
import { Goldigovernor } from "../src/governance/Goldigovernor.sol";
import { Timelock } from "../src/governance/Timelock.sol";
import { govLocks } from "../src/governance/govLocks.sol";
import { Honey } from "../src/mock/Honey.sol";
import { iBGT } from "../src/mock/iBGT.sol";
import { HoneyComb } from "../src/mock/HoneyComb.sol";
import { Beradrome } from "../src/mock/Beradrome.sol";
import { BondBear } from "../src/mock/BondBear.sol";
import { BandBear } from "../src/mock/BandBear.sol";
import { iBGTVault } from "../src/mock/iBGTVault.sol";

contract UnitGoldivault is Goldivault {
  constructor(
    address _ot,
    address _yt,
    address _depositToken,
    address[] memory _yieldTokens,
    address _depositVault,
    address _ibgtvault,
    address _ibgt,
    address _ired,
    address _multisig
  ) Goldivault(
    _ot,
    _yt,
    _depositToken,
    _yieldTokens,
    _depositVault,
    _ibgtvault,
    _ibgt,
    _ired,
    _multisig
  ) {}
  function _vaultDeposit(uint256 amount) internal override {
    HoneyWethLPVault(depositVault).stake(amount);
  }
  function _unstakeDepositToken(uint256 amount) internal override {
    HoneyWethLPVault(depositVault).withdraw(amount);
  }
  function _concludeVaultRewards() internal override {
    HoneyWethLPVault(depositVault).exit();
    InfraredBGTVault(ibgtvault).exit();
  }
  function _compoundVaultRewards() internal override {
    HoneyWethLPVault(depositVault).getReward();
    InfraredBGTVault(ibgtvault).getReward();
    uint256 ibgtrewards = ERC20(ibgt).balanceOf(address(this));
    uint256 yieldTokensLength = yieldTokens.length;
    for(uint8 i; i < yieldTokensLength; ++i) {
      SafeTransferLib.safeTransfer(yieldTokens[i], multisig, (ERC20(yieldTokens[i]).balanceOf(address(this)) / 100) * yieldFee);
    }
    InfraredBGTVault(ibgtvault).stake(ibgtrewards);
  }
}
contract HoneyWethLPVault {
  function stake(uint256 amount) external {}
  function getReward() external {}
  function withdraw(uint256 amount) external {}
  function exit() external {}
}
contract InfraredBGTVault {
  function stake(uint256 amount) external {}
  function getReward() external {}
  function withdraw(uint256 amount) external {}
  function exit() external {}
}
contract oUnit is OwnershipToken {
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
contract yUnit is YieldToken {
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
contract Unit is ERC20 {
  function name() public pure override returns (string memory) {
    return "Unit";
  }
  function symbol() public pure override returns (string memory) {
    return "Unit";
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
  iBGTVault unitvault;
  UnitGoldivault goldivault;
  oUnit ot;
  yUnit yt;
  Unit unit;

  uint256 initialFSL = 1050000e18;
  uint256 initialPSL = 320000e18;
  uint256 prgMintAmount = 200000000e18;

  uint256 txAmount = 10e18;
  uint256 locksMintAmount = 100000000e18;
  uint256 costOf10Locks = 262883805905681940;
  uint256 proceedsof10Locks = 249739615610397845;

  uint256 locksAmount = 100000e18;
  uint256 borrowAmount = 1050e18;
  uint256 oneDayPrg = 136986301369863000000;
  uint256 halfDayPrg = 68493150684931500000;
  uint256 oneDayHalfPrg = 205479452054794500000;
  uint256 twoDaysPrg = 273972602739726000000;
  uint256 twoMonthsOfGoldilendStakingYield = 34e18;

  uint256 twoMonthsOfYield = 34e18;
  uint256 twoMonthsOfBoostedYield = 43645e15;
  uint256 singleBorrowInterest = 45726853068117;
  uint256 singleBorrowInterestBoosted = 45452491949592;
  uint256 singleBorrowInterestMaxBoost = 2286342653400;

  uint256 govLocksAmt = 5e18;
  
  address honeyjar = address(0x69420);

  function setUp() public {
    Goldilocked goldilockedComputed = Goldilocked(address(this).computeAddress(14));
    Goldigovernor goldigovComputed = Goldigovernor(address(this).computeAddress(15));
    UnitGoldivault goldivaultComputed = UnitGoldivault(address(this).computeAddress(18));

    unit = new Unit();
    honey = new Honey();
    ibgt = new iBGT();
    honeycomb = new HoneyComb();
    beradrome = new Beradrome();
    bondbear = new BondBear();
    bandbear = new BandBear();
    ibgtvault = new iBGTVault(address(ibgt), address(ibgt));
    unitvault = new iBGTVault(address(unit), address(ibgt));

    goldiswap = new Goldiswap(initialFSL, initialPSL, address(goldilockedComputed), address(honey), address(this));

    // amount of porridge earned per gbera per second
    // depends on what we want the initial apr
    // apr will be a function of the bera and porridge prices
    uint256 startingPoolSize = 1000e18;
    uint256 protocolInterestRate = 1e17;
    uint256 porridgeMultiple = 1e13;
    address[] memory boostNfts = new address[](2);
    boostNfts[0] = address(honeycomb);
    boostNfts[1] = address(beradrome);
    uint8[] memory boosts = new uint8[](2);
    boosts[0] = 6;
    boosts[1] = 9;
    goldilend = new Goldilend(
      startingPoolSize,
      protocolInterestRate,
      porridgeMultiple,
      10,
      address(goldilockedComputed),
      address(this),
      honeyjar,
      address(ibgt),
      address(ibgtvault),
      boostNfts,
      boosts
    );
    govlocks = new govLocks(address(goldiswap), address(goldigovComputed), address(goldilockedComputed));
    timelock = new Timelock(address(goldigovComputed), 5 days);
    address[] memory allocationsAddress = new address[](4);
    allocationsAddress[0] = address(0x69);
    allocationsAddress[1] = address(0x420);
    allocationsAddress[2] = address(0x42069);
    allocationsAddress[3] = address(0x69420);
    uint256[] memory allocationsAmt = new uint256[](4);
    allocationsAmt[0] = 12000000e18;
    allocationsAmt[1] = 12000000e18;
    allocationsAmt[2] = 10000000e18;
    allocationsAmt[3] = 7000000e18;
    goldilocked = new Goldilocked(address(goldiswap), address(goldilend), address(govlocks), address(honey), allocationsAddress, allocationsAmt);
    goldigov = new Goldigovernor(address(timelock), address(govlocks), address(this), 5761, 69, 4e18);

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
    deal(address(ibgt), address(goldilend), startingPoolSize);
    deal(address(ibgt), address(ibgtvault), type(uint256).max / 2);

    address[] memory yieldTokens = new address[](1);
    yieldTokens[0] = address(ibgt);
    unit = new Unit();
    ot = new oUnit("oUnit", "oUnit", address(goldivaultComputed));
    yt = new yUnit("yUnit", "yUnit", address(goldivaultComputed));
    goldivault = new UnitGoldivault(
      address(ot),
      address(yt),
      address(unit),
      yieldTokens,
      address(unitvault),
      address(unitvault),
      address(ibgt),
      address(0x69),
      address(this)
    );
    goldivault.setEarlyWithdrawalFee(69);
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

  modifier dealUserBera() {
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

  function depositUnit() public {
    deal(address(unit), address(this), txAmount);
    unit.approve(address(goldivault), txAmount);
    goldivault.deposit(txAmount);
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