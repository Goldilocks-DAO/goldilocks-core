//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../lib/forge-std/src/Test.sol";
import { LibRLP } from "../../lib/solady/src/utils/LibRLP.sol";
import { ERC20 } from "../../lib/solady/src/tokens/ERC20.sol";
import { IERC721Receiver } from "../../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import { Goldiswap } from "../../src/core/goldiswap/Goldiswap.sol";
import { Goldilocked } from "../../src/core/goldiswap/Goldilocked.sol";
import { Goldilend } from "../../src/core/goldilend/Goldilend.sol";
import { Goldivault } from "../../src/core/goldivault/Goldivault.sol";
import { InfraredBexLPGoldivault } from "../../src/core/goldivault/InfraredBexLPGoldivault.sol";
import { OwnershipToken } from "../../src/core/goldivault/OwnershipToken.sol";
import { YieldToken } from "../../src/core/goldivault/YieldToken.sol";
import { Goldigovernor } from "../../src/core/goldigovernance/Goldigovernor.sol";
import { Timelock } from "../../src/core/goldigovernance/Timelock.sol";
import { GovLocks } from "../../src/core/goldigovernance/GovLocks.sol";
import { Honey } from "../../src/mock/Honey.sol";
import { iBGT } from "../../src/mock/iBGT.sol";
import { HoneyComb } from "../../src/mock/HoneyComb.sol";
import { Beradrome } from "../../src/mock/Beradrome.sol";
import { BondBear } from "../../src/mock/BondBear.sol";
import { BandBear } from "../../src/mock/BandBear.sol";
import { iBGTVault } from "../../src/mock/iBGTVault.sol";
import { BexLPVault } from "../../src/mock/BexLPVault.sol";

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
  GovLocks govlocks;
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

  uint256 initialFSL = 1_140_000e18;
  uint256 initialPSL = 400_000e18;
  uint256 locksMintAmount = 190_000_000e18;
  uint256 quorumVotesNum = 9_500_001e18;
  uint256 prgMintAmount = 200_000_000e18;
  uint256 txAmount = 10e18;
  uint256 locksAmount = 100_000e18;
  address apdao = address(0xdddd);

  function setUp() public virtual {}

  function deployProtocol() public {
    
    // precompute addresses
    Goldigovernor goldigovComputed = Goldigovernor(address(this).computeAddress(13));
    Goldilocked goldilockedComputed = Goldilocked(address(this).computeAddress(14));
    Goldilend goldilendComputed = Goldilend(address(this).computeAddress(15));
    InfraredBexLPGoldivault goldivaultComputed = InfraredBexLPGoldivault(address(this).computeAddress(18));

    // deploy mock contracts
    bexlp = new BexLPToken();
    honey = new Honey();
    ibgt = new iBGT();
    honeycomb = new HoneyComb();
    beradrome = new Beradrome();
    bondbear = new BondBear();
    bandbear = new BandBear();
    ibgtvault = new iBGTVault(address(ibgt), address(ibgt), address(honey));
    bexvault = new BexLPVault(address(bexlp), address(ibgt));

    // deploy timelock
    timelock = new Timelock(address(goldigovComputed), address(this), 5 days);

    // deploy goldiswap
    goldiswap = new Goldiswap(
      initialFSL,
      initialPSL,
      address(goldilockedComputed),
      address(honey),
      address(this),
      address(timelock),
      locksMintAmount
    );

    // deploy govlocks
    govlocks = new GovLocks(
      address(goldiswap),
      address(goldilockedComputed),
      apdao,
      locksMintAmount / 20
    );

    // deploy goldigov
    goldigov = new Goldigovernor(
      address(timelock),
      address(govlocks),
      address(goldiswap),
      address(this),
      5761,
      69,
      4e18
    );

    // deploy golidlocked
    address[] memory allocationsAddress = new address[](30);
    allocationsAddress[0] = address(0x69);
    allocationsAddress[1] = address(0x420);
    allocationsAddress[2] = address(0x42069);
    allocationsAddress[3] = address(0x69420);
    allocationsAddress[4] = address(0x6969696969);
    allocationsAddress[5] = address(0x6969696969);
    allocationsAddress[6] = address(0x6969696969);
    allocationsAddress[7] = address(0x6969696969);
    allocationsAddress[8] = address(0x6969696969);
    allocationsAddress[9] = address(0x6969696969);
    allocationsAddress[10] = address(0x6969696969);
    allocationsAddress[11] = address(0x6969696969);
    allocationsAddress[12] = address(0x6969696969);
    allocationsAddress[13] = address(0x6969696969);
    allocationsAddress[14] = address(0x6969696969);
    allocationsAddress[15] = address(0x6969696969);
    allocationsAddress[16] = address(0x6969696969);
    allocationsAddress[17] = address(0x6969696969);
    allocationsAddress[18] = address(0x6969696969);
    allocationsAddress[19] = address(0x6969696969);
    allocationsAddress[20] = address(0x6969696969);
    allocationsAddress[21] = address(0x6969696969);
    allocationsAddress[22] = address(0x6969696969);
    allocationsAddress[23] = address(0x6969696969);
    allocationsAddress[24] = address(0x6969696969);
    allocationsAddress[25] = address(0x6969696969);
    allocationsAddress[26] = address(0x6969696969);
    allocationsAddress[27] = address(0x6969696969);
    allocationsAddress[28] = address(0x6969696969);
    allocationsAddress[29] = address(0x696969696969);
    uint256[] memory allocationsAmt = new uint256[](30);
    allocationsAmt[0] = 12_000_000e18;
    allocationsAmt[1] = 12_000_000e18;
    allocationsAmt[2] = 10_000_000e18;
    allocationsAmt[3] = 7_000_000e18;
    allocationsAmt[4] = 7_000_000e18;
    allocationsAmt[5] = 7_000_000e18;
    allocationsAmt[6] = 7_000_000e18;
    allocationsAmt[7] = 7_000_000e18;
    allocationsAmt[8] = 7_000_000e18;
    allocationsAmt[9] = 7_000_000e18;
    allocationsAmt[10] = 7_000_000e18;
    allocationsAmt[11] = 7_000_000e18;
    allocationsAmt[12] = 7_000_000e18;
    allocationsAmt[13] = 7_000_000e18;
    allocationsAmt[14] = 7_000_000e18;
    allocationsAmt[15] = 7_000_000e18;
    allocationsAmt[16] = 7_000_000e18;
    allocationsAmt[17] = 7_000_000e18;
    allocationsAmt[18] = 7_000_000e18;
    allocationsAmt[19] = 7_000_000e18;
    allocationsAmt[20] = 7_000_000e18;
    allocationsAmt[21] = 7_000_000e18;
    allocationsAmt[22] = 7_000_000e18;
    allocationsAmt[23] = 7_000_000e18;
    allocationsAmt[24] = 7_000_000e18;
    allocationsAmt[25] = 7_000_000e18;
    allocationsAmt[26] = 7_000_000e18;
    allocationsAmt[27] = 7_000_000e18;
    allocationsAmt[28] = 7_000_000e18;
    allocationsAmt[29] = 7_000_000e18;
    goldilocked = new Goldilocked(
      address(goldiswap),
      address(goldilendComputed),
      address(govlocks),
      address(honey),
      address(timelock),
      prgMintAmount,
      5e17,
      allocationsAddress,
      allocationsAmt
    );

    // deploy goldilend
    address[] memory rewardTokens = new address[](1);
    rewardTokens[0] = address(honey);
    goldilend = new Goldilend(
      address(goldilocked),
      address(timelock),
      address(this),
      apdao,
      address(ibgt),
      address(ibgtvault),
      rewardTokens
    );

    // initialization of goldilend
    address[] memory nfts = new address[](2);
    nfts[0] = address(bondbear);
    nfts[1] = address(bandbear);
    uint256[] memory values = new uint256[](2);
    values[0] = 50;
    values[1] = 50;
    address[] memory boostNfts = new address[](2);
    boostNfts[0] = address(honeycomb);
    boostNfts[1] = address(beradrome);
    uint8[] memory boosts = new uint8[](2);
    boosts[0] = 6;
    boosts[1] = 9;
    goldilend.initializeParameters(
      45,
      5,
      7 days,
      365 days,
      1000e18,
      10e18,
      10e18,
      5e17,
      30 days
    );
    goldilend.initializeBeras(100e18, nfts, values);
    goldilend.initializePartners(boostNfts, boosts);
    deal(address(ibgt), address(goldilend), 1000e18);
    deal(address(ibgt), address(ibgtvault), type(uint256).max / 2);

    // deploy goldivault
    address[] memory yieldTokens = new address[](1);
    yieldTokens[0] = address(ibgt);
    ot = new oBexLPToken("oBexLPToken", "oBEXLP", address(goldivaultComputed));
    yt = new yBexLPToken("yBexLPToken", "yBEXLP", address(goldivaultComputed));
    goldivault = new InfraredBexLPGoldivault(
      address(ot),
      address(yt),
      address(this),
      address(timelock)
    );
    goldivault.initializeProtocol(
      address(bexlp),
      address(bexvault),
      address(ibgt),
      address(ibgtvault),
      address(ibgt),
      address(ibgtvault),
      30,
      20,
      1 days,
      365 days,
      yieldTokens
    );
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