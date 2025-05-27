//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../lib/forge-std/src/Test.sol";
import { LibRLP } from "../../lib/solady/src/utils/LibRLP.sol";
import { ERC20 } from "../../lib/solady/src/tokens/ERC20.sol";
import { IERC721Receiver } from "../../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import { ERC1967Proxy } from "../../lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { Goldiswap } from "../../src/core/goldiswap/Goldiswap.sol";
import { Goldilocked } from "../../src/core/goldiswap/Goldilocked.sol";
import { Goldilend } from "../../src/core/goldilend/Goldilend.sol";
import { GLWBera } from "../../src/core/goldilend/GLWBera.sol";
import { GLDWBera } from "../../src/core/goldilend/GLDWBera.sol";
import { Goldivault } from "../../src/core/goldivault/Goldivault.sol";
import { Goldivault4626 } from "../../src/core/goldivault/Goldivault4626.sol";
import { OwnershipToken } from "../../src/core/goldivault/OwnershipToken.sol";
import { YieldToken } from "../../src/core/goldivault/YieldToken.sol";
import { Goldigovernor } from "../../src/core/goldigovernance/Goldigovernor.sol";
import { Timelock } from "../../src/core/goldigovernance/Timelock.sol";
import { GovLocks } from "../../src/core/goldigovernance/GovLocks.sol";
import { Honey } from "../../src/mock/Honey.sol";
import { WBERA } from "../../src/mock/WBERA.sol";
import { BGT } from "../../src/mock/BGT.sol";
import { iBGT } from "../../src/mock/iBGT.sol";
import { oriBGT } from "../../src/mock/oriBGT.sol";
import { BondBear } from "../../src/mock/BondBear.sol";
import { BandBear } from "../../src/mock/BandBear.sol";
import { iBGTVault } from "../../src/mock/iBGTVault.sol";
import { BexLPVault } from "../../src/mock/BexLPVault.sol";

contract InfraredBexLPGoldivault is Goldivault {
  constructor(
    address _ot,
    address _yt,
    address _multisig,
    address _timelock,
    address _depositToken,
    address _depositVault,
    address _ibgt,
    address _ibgtVault
  ) Goldivault(
    _ot,
    _yt,
    _multisig,
    _timelock,
    _depositToken,
    _depositVault,
    _ibgt,
    _ibgtVault
  ) {}
}
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

contract oriBGTOT is OwnershipToken {
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
contract oriBGTYT is YieldToken {
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
  BGT bgt;
  WBERA wbera;
  BondBear bondbear;
  BandBear bandbear;
  iBGTVault ibgtvault;
  InfraredBexLPGoldivault goldivault;
  oBexLPToken ot;
  yBexLPToken yt;
  BexLPToken bexlp;
  BexLPVault bexvault;
  oriBGT oribgt;
  Goldivault4626 oribgtgoldivault;
  oriBGTOT oribgtot;
  oriBGTYT oribgtyt;
  GLWBera glwbera;
  GLDWBera gldwbera;
  ERC1967Proxy proxy;

  uint256 initialFSL = 1_140_000e18;
  uint256 initialPSL = 400_000e18;
  uint256 locksMintAmount = 190_000_000e18;
  uint256 quorumVotesNum = 50_000_001e18;
  uint256 prgMintAmount = 200_000_000e18;
  uint256 txAmount = 10e18;
  uint256 locksAmount = 100_000e18;
  address apdao = 0xAe8b5e58E423750a68BbB37ccaaD399deF93D24D;

  function setUp() public virtual {}

  function deployProtocol() public {
    
    // precompute addresses
    Goldigovernor goldigovComputed = Goldigovernor(address(this).computeAddress(14));
    Goldilocked goldilockedComputed = Goldilocked(address(this).computeAddress(15));
    Goldilend goldilendComputed = Goldilend(address(this).computeAddress(16));
    GLWBera glwberaComputed = GLWBera(address(this).computeAddress(18));
    GLDWBera gldwberaComputed = GLDWBera(address(this).computeAddress(19));
    InfraredBexLPGoldivault goldivaultComputed = InfraredBexLPGoldivault(address(this).computeAddress(22));
    Goldivault4626 oribgtgoldivaultComputed = Goldivault4626(address(this).computeAddress(25));

    // deploy mock contracts
    bexlp = new BexLPToken();
    honey = new Honey();
    ibgt = new iBGT();
    bgt = new BGT();
    wbera = new WBERA();
    bondbear = new BondBear();
    bandbear = new BandBear();
    ibgtvault = new iBGTVault(address(ibgt), address(ibgt), address(honey));
    bexvault = new BexLPVault(address(bexlp), address(ibgt));
    oribgt = new oriBGT(address(ibgt));

    // deploy timelock
    timelock = new Timelock(address(goldigovComputed), address(this), 2 days);

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
      address(this),
      144_000,
      52_560,
      5_000_000e18
    );

    // deploy golidlocked
    address[] memory allocationsAddress = new address[](31);
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
    allocationsAddress[25] = address(0x42069420694206942069);
    allocationsAddress[26] = address(0x6969696969);
    allocationsAddress[27] = address(0x6969696969);
    allocationsAddress[28] = address(0x6969696969);
    allocationsAddress[29] = address(0x696969696969);
    allocationsAddress[30] = address(0x42042069);
    uint256[] memory allocationsAmt = new uint256[](31);
    allocationsAmt[0] = 12_000_000e18;
    allocationsAmt[1] = 5_000_000e18;
    allocationsAmt[2] = 10_000_000e18;
    allocationsAmt[3] = 7_000_000e18;
    allocationsAmt[4] = 113_000_000e18;
    allocationsAmt[5] = 1_000_000e18;
    allocationsAmt[6] = 1_000_000e18;
    allocationsAmt[7] = 1_000_000e18;
    allocationsAmt[8] = 1_000_000e18;
    allocationsAmt[9] = 1_000_000e18;
    allocationsAmt[10] = 1_000_000e18;
    allocationsAmt[11] = 1_000_000e18;
    allocationsAmt[12] = 1_000_000e18;
    allocationsAmt[13] = 1_000_000e18;
    allocationsAmt[14] = 1_000_000e18;
    allocationsAmt[15] = 1_000_000e18;
    allocationsAmt[16] = 1_000_000e18;
    allocationsAmt[17] = 1_000_000e18;
    allocationsAmt[18] = 1_000_000e18;
    allocationsAmt[19] = 1_000_000e18;
    allocationsAmt[20] = 1_000_000e18;
    allocationsAmt[21] = 1_000_000e18;
    allocationsAmt[22] = 1_000_000e18;
    allocationsAmt[23] = 1_000_000e18;
    allocationsAmt[24] = 1_000_000e18;
    allocationsAmt[25] = 12_000_000e18;
    allocationsAmt[26] = 1_000_000e18;
    allocationsAmt[27] = 1_000_000e18;
    allocationsAmt[28] = 1_000_000e18;
    allocationsAmt[29] = 1_000_000e18;
    allocationsAmt[30] = 7_000_000e18;
    goldilocked = new Goldilocked(
      address(goldiswap),
      address(goldilendComputed),
      address(govlocks),
      address(honey),
      address(timelock),
      address(this),
      prgMintAmount,
      5e17,
      allocationsAddress,
      allocationsAmt
    );

    // initialization of goldiswap
    deal(address(honey), address(this), initialPSL);
    honey.approve(address(goldiswap), initialPSL);
    goldiswap.initializeProtocol(initialPSL);

    // deploy goldilend
    goldilend = new Goldilend();

    // initialization of goldilend
    bytes memory data = abi.encodeWithSelector(
      Goldilend.initialize.selector,
      address(timelock),
      address(this),
      apdao,
      address(wbera),
      address(bgt),
      address(glwberaComputed),
      address(gldwberaComputed)
    );
    proxy = new ERC1967Proxy(address(goldilend), data);
    glwbera = new GLWBera("Goldilend Wrapped Bera" , "glWBERA", address(proxy));
    gldwbera = new GLDWBera("Goldilend Debt Wrapped Bera", "gldWBERA", address(proxy));
    assert(glwbera.goldilend() == address(proxy));
    assert(gldwbera.goldilend() == address(proxy));
    address[] memory nfts = new address[](2);
    nfts[0] = address(bondbear);
    nfts[1] = address(bandbear);
    uint256[] memory values = new uint256[](2);
    values[0] = 50e18;
    values[1] = 50e18;
    Goldilend(address(proxy)).initializeParameters(
      45,
      5,
      7 days,
      365 days,
      10e18,
      10e18,
      69
    );
    Goldilend(address(proxy)).initializeBeras(nfts, values);
    deal(address(wbera), address(this), 1000e18);
    wbera.approve(address(proxy), 1000e18);
    Goldilend(address(proxy)).lock(1000e18);
    // goldilocked.setGoldilendAddress(address(proxy));

    // deploy goldivault
    address[] memory yieldTokens = new address[](1);
    yieldTokens[0] = address(ibgt);
    ot = new oBexLPToken("oBexLPToken", "oBEXLP", address(goldivaultComputed));
    yt = new yBexLPToken("yBexLPToken", "yBEXLP", address(goldivaultComputed));
    goldivault = new InfraredBexLPGoldivault(
      address(ot),
      address(yt),
      address(this),
      address(timelock),
      address(bexlp),
      address(bexvault),
      address(ibgt),
      address(ibgtvault)
    );
    assert(ot.vault() == address(goldivault));
    assert(ot.decimals() == ERC20(bexlp).decimals());

    // initialization of goldivault
    goldivault.initializeProtocol(
      30,
      20,
      1 days,
      365 days,
      1 days,
      yieldTokens
    );

    // deploy oribgtgoldivault
    oribgtot = new oriBGTOT("oriBGT-OT", "oriBGTOT", address(oribgtgoldivaultComputed));
    oribgtyt = new oriBGTYT("oriBGT-YT", "oriBGTYT", address(oribgtgoldivaultComputed));
    oribgtgoldivault = new Goldivault4626(
      address(oribgtot),
      address(oribgtyt),
      address(this),
      address(ibgt),
      address(oribgt),
      address(0),
      5,
      3,
      1e18,
      365 days
    );
    assert(oribgtot.vault() == address(oribgtgoldivault));
    assert(oribgtot.decimals() == ERC20(ibgt).decimals());
    
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