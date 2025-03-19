//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../lib/forge-std/src/Test.sol";
import { console } from "../../lib/forge-std/src/console.sol";
import { LibRLP } from "../../lib/solady/src/utils/LibRLP.sol";
import { ERC20 } from "../../lib/solady/src/tokens/ERC20.sol";
import { ERC4626 } from "../../lib/solady/src/tokens/ERC4626.sol";
import { Goldivault4626 } from "../../src/core/goldivault/Goldivault4626.sol";
import { OwnershipToken } from "../../src/core/goldivault/OwnershipToken.sol";
import { YieldToken } from "../../src/core/goldivault/YieldToken.sol";

contract BeraborrowWberaHoneyOT is OwnershipToken {
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

contract BeraborrowWberaHoneyYT is YieldToken {
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

contract IntegrationBeraborrowGoldivaultTest is Test {

  using LibRLP for address;

  Goldivault4626 beraborrowgoldivault;
  BeraborrowWberaHoneyOT bbwhot;
  BeraborrowWberaHoneyYT bbwhyt;

  address deployer = 0x895614c89beC7D11454312f740854d08CbF57A78;
  address multisig = 0x6FD990680deB2e5DCcb2FFEfC3307Dd34138Ac7F;
  address router = 0xe301E48F77963D3F7DbD2a4796962Bd7f3867Fb4;
  address depositToken = 0x2c4a603A2aA5596287A06886862dc29d56DbC354; // WBERA-HONEY LP token
  address depositVault = 0x955386Aff3F42C86F304c3EC9fe053D27EC429a6; // beraborrow WBERA-HONEY vault

  address user1 = address(0xabc);
  address user2 = address(0xcba);
  address user3 = address(0xddd);

  uint256 depositNum = 100e18;
  uint256 depositLength = 5 hours;
  uint256 dailySeconds = 86400;
  uint256 dailyBlocks = dailySeconds / 3;

  uint256 startingBlock = 2233720;
  // uint256 startingBlock = 1934595;
  uint256 currentBlock = 2253639;

  // forks starts at block 1934595 # 3-5-25 6am
  // forks starts at block 2233720 # 3-12-25 5am
  function setUp() public {

  }

  function testDtRewards() public {
    // create fork
    uint256 mainnetFork = vm.createFork("https://rpc.berachain.com");
    vm.selectFork(mainnetFork);
    Goldivault4626 beraborrowgoldivaultComputed = Goldivault4626(deployer.computeAddress(146));
    vm.roll(startingBlock);
    vm.startPrank(deployer);
    // deploy beraborrowgoldivault
    bbwhot = new BeraborrowWberaHoneyOT("Beraborrow WBERA-HONEY LP OT", "BBWHOT", address(beraborrowgoldivaultComputed));
    bbwhyt = new BeraborrowWberaHoneyYT("Beraborrow WBERA-HONEY LP YT", "BBWHYT", address(beraborrowgoldivaultComputed));
    beraborrowgoldivault = new Goldivault4626(
      address(bbwhot),
      address(bbwhyt),
      multisig,
      depositToken,
      depositVault,
      router,
      5,
      3,
      1e18,
      30 days
    );
    vm.stopPrank();

    deal(depositToken, user1, depositNum);
    vm.startPrank(user1);
    ERC20(depositToken).approve(address(beraborrowgoldivault), depositNum);
    bbwhyt.approve(address(beraborrowgoldivault), depositNum);
    beraborrowgoldivault.deposit(depositNum);
    vm.stopPrank();

    uint256 beforeRatio = ERC4626(depositVault).convertToAssets(1e18);
    vm.roll(startingBlock + dailyBlocks);
    uint256 afterRatio = ERC4626(depositVault).convertToAssets(1e18);


    vm.prank(user1);
    beraborrowgoldivault.redeemOwnership(depositNum);

    assert(beforeRatio < afterRatio);
    assertEq(bbwhot.balanceOf(user1), 0);
    assertEq(bbwhyt.balanceOf(user1), 0);
  }

  function testRatios() public {
    // create fork
    uint256 mainnetFork = vm.createFork("https://rpc.berachain.com");
    vm.selectFork(mainnetFork);
    vm.rollFork(startingBlock);
    uint256 ratio1 = ERC4626(depositVault).convertToAssets(1e18);
    uint256 ratio2 = ERC4626(depositVault).convertToShares(1e18);

    vm.roll(block.number + dailyBlocks);

    uint256 ratio3 = ERC4626(depositVault).convertToAssets(1e18);
    uint256 ratio4 = ERC4626(depositVault).convertToShares(1e18);

    assert(ratio3 > ratio1);
    assert(ratio4 < ratio2);
  }

  function testBBRedeem() public {
    deal(depositToken, user1, depositNum);
    vm.startPrank(user1);
    ERC20(depositToken).approve(address(beraborrowgoldivault), depositNum);
    bbwhyt.approve(address(beraborrowgoldivault), depositNum);
    beraborrowgoldivault.deposit(depositNum);
    vm.stopPrank();

    vm.roll(block.number + 10);

    vm.prank(user1);
    beraborrowgoldivault.redeemOwnership(depositNum);
    uint256 endingDtBalance = ERC20(depositToken).balanceOf(user1);

    assertEq(endingDtBalance, depositNum - (depositNum / 1000) - 1);
    assertEq(bbwhot.balanceOf(user1), 0);
    assertEq(bbwhyt.balanceOf(user1), 0);
  }

  function testSanity() public {
    // create fork
    uint256 mainnetFork = vm.createFork("https://rpc.berachain.com");
    vm.selectFork(mainnetFork);
    vm.rollFork(startingBlock);
    (bool success, bytes memory data) = 0xa686DC84330b1B3787816de2DaCa485D305c8589.call(
      abi.encodeWithSignature(
        "fetchPrice(address)",
        0xac03CABA51e17c86c921E1f6CBFBdC91F8BB2E6b
      )
    );
    require(success, "deposit failed");

    vm.rollFork(startingBlock + dailyBlocks);
    (bool success1, bytes memory data1) = 0xa686DC84330b1B3787816de2DaCa485D305c8589.call(
      abi.encodeWithSignature(
        "fetchPrice(address)",
        0xac03CABA51e17c86c921E1f6CBFBdC91F8BB2E6b
      )
    );
    require(success1, "deposit failed");
  }

  function testUnderlyingDeposit() public {
    // create fork
    uint256 mainnetFork = vm.createFork("https://rpc.berachain.com");
    vm.selectFork(mainnetFork);
    vm.rollFork(startingBlock);

    deal(depositToken, user1, depositNum);
    vm.startPrank(user1);
    ERC20(depositToken).approve(depositVault, depositNum);
    ERC4626(depositVault).deposit(depositNum, user1);
    vm.stopPrank();

    // vm.rollFork(block.number + dailyBlocks);
    vm.roll(block.number + dailyBlocks);
    
    uint256 maxRedeem1 = ERC4626(depositVault).maxRedeem(user1);
    uint256 balance1 = ERC4626(depositVault).balanceOf(user1);
    
    // vm.prank(user1);
    // beraborrowgoldivault.redeemOwnership(depositNum);
  }

}