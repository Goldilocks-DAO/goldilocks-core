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

contract OrigamiUSDSOT is OwnershipToken {
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

contract OrigamiUSDSYT is YieldToken {
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

contract IntegrationOrigamiGoldivaultTest is Test {

  using LibRLP for address;

  Goldivault4626 origamigoldivault;
  OrigamiUSDSOT ousdsot;
  OrigamiUSDSYT ousdsyt;

  address geeb = 0xcBf203F2ee13702Ec41404856f75357e0872484e;
  address multisig = 0x6FD990680deB2e5DCcb2FFEfC3307Dd34138Ac7F; // wrong chain
  address router = 0xe301E48F77963D3F7DbD2a4796962Bd7f3867Fb4; // wrong chain
  address depositToken = 0xdC035D45d973E3EC169d2276DDab16f1e407384F; // USDS token
  address depositVault = 0x0f90a6962e86b5587b4c11bA2B9697dC3bA84800; // origami USDS vault

  address user1 = address(0xabc);
  address user2 = address(0xcba);
  address user3 = address(0xddd);

  uint256 depositNum = 100e18;
  uint256 dailySeconds = 86400;
  uint256 dailyBlocks = dailySeconds / 12;

  uint256 startingBlock = 21038019;

  // forks starts at block 21038019 # 10-24-24
  function setUp() public {

  }

  function testRewards() public {
    // create fork
    uint256 mainnetFork = vm.createFork("https://rpc.ankr.com/eth");
    vm.selectFork(mainnetFork);
    Goldivault4626 origamigoldivaultComputed = Goldivault4626(geeb.computeAddress(265));
    vm.rollFork(startingBlock);
    vm.startPrank(geeb);
    // deploy origamigoldivault
    ousdsot = new OrigamiUSDSOT("Origami USDS OT", "OUSDSOT", address(origamigoldivaultComputed));
    ousdsyt = new OrigamiUSDSYT("Origami USDS YT", "OUSDSYT", address(origamigoldivaultComputed));
    origamigoldivault = new Goldivault4626(
      address(ousdsot),
      address(ousdsyt),
      multisig,
      depositToken,
      depositVault,
      router,
      5,
      3,
      1e18,
      365 days
    );
    vm.stopPrank();
    assert(ousdsot.vault() == address(origamigoldivault));

    deal(depositToken, user1, depositNum);
    vm.startPrank(user1);
    ERC20(depositToken).approve(address(origamigoldivault), depositNum);
    ousdsyt.approve(address(origamigoldivault), depositNum);
    origamigoldivault.deposit(depositNum);
    vm.stopPrank();

    vm.roll(block.number + dailyBlocks);

    deal(depositToken, user2, depositNum);
    vm.startPrank(user2);
    ERC20(depositToken).approve(address(origamigoldivault), depositNum);
    ousdsyt.approve(address(origamigoldivault), depositNum);
    origamigoldivault.deposit(depositNum);
    vm.stopPrank();

    vm.roll(block.number + dailyBlocks);

    vm.prank(user1);
    origamigoldivault.redeemOwnership(depositNum);

    assertEq(ousdsot.balanceOf(user1), 0);
    assertEq(ousdsyt.balanceOf(user1), 0);
    assertEq(ERC20(depositToken).balanceOf(user1), depositNum - 1);
  }

  function testOrigamiRatios() public {
    // create fork
    uint256 mainnetFork = vm.createFork("https://rpc.ankr.com/eth");
    vm.selectFork(mainnetFork);
    vm.rollFork(startingBlock);
    uint256 ratio1 = ERC4626(depositVault).convertToAssets(1e18);
    uint256 ratio2 = ERC4626(depositVault).convertToShares(1e18);

    vm.rollFork(block.number + dailyBlocks);

    uint256 ratio3 = ERC4626(depositVault).convertToAssets(1e18);
    uint256 ratio4 = ERC4626(depositVault).convertToShares(1e18);

    assert(ratio3 > ratio1);
    assert(ratio4 < ratio2);
  }

  function testOrigamiVault() public {
    // create fork
    uint256 mainnetFork = vm.createFork("https://rpc.ankr.com/eth");
    vm.selectFork(mainnetFork);
    vm.rollFork(startingBlock);

    deal(depositToken, user1, depositNum);
    vm.startPrank(user1);
    ERC20(depositToken).approve(depositVault, depositNum);
    ERC4626(depositVault).deposit(depositNum, user1);
    vm.stopPrank();

    ERC4626(depositVault).balanceOf(user1);
    vm.roll(startingBlock + dailyBlocks);
    ERC4626(depositVault).balanceOf(user1);
  }





}