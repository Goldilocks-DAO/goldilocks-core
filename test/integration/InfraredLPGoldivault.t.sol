//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../lib/forge-std/src/Test.sol";
import { console } from "../../lib/forge-std/src/console.sol";
import { LibRLP } from "../../lib/solady/src/utils/LibRLP.sol";
import { ERC20 } from "../../lib/solady/src/tokens/ERC20.sol";
import { INonfungiblePositionManager } from "../../src/interfaces/INonfungiblePositionManager.sol";
import { GoldivaultStaking } from "../../src/core/goldivault/GoldivaultStaking.sol";
import { OwnershipToken } from "../../src/core/goldivault/OwnershipToken.sol";
import { YieldToken } from "../../src/core/goldivault/YieldToken.sol";

contract USDCHoneyInfraredOT is OwnershipToken {
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

contract USDCHoneyInfraredYT is YieldToken {
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

interface IERC721Receiver {
  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external returns (bytes4);
}

interface UniswapV3Factory {
  function createPool(address tokenA,address tokenB,uint24 fee) external;
}

contract IntegrationUSDCHoneyInfraredLPGoldivaultTest is Test {

  using LibRLP for address;

  GoldivaultStaking usdchoneyinfraredvault;
  USDCHoneyInfraredOT uhiot;
  USDCHoneyInfraredYT uhiyt;

  address multisig = 0x6FD990680deB2e5DCcb2FFEfC3307Dd34138Ac7F;
  address ibgt = 0xac03CABA51e17c86c921E1f6CBFBdC91F8BB2E6b;
  address router = 0xe301E48F77963D3F7DbD2a4796962Bd7f3867Fb4;
  // address positionManager = 0xFE5E8C83FFE4d9627A75EaA7Fee864768dB989bD;
  // address factory = 0xD84CBf0B02636E7f53dB9E5e45A616E05d710990;
  address depositToken = 0xF961a8f6d8c69E7321e78d254ecAfBcc3A637621; // usdc-honey LP token
  address depositVault = 0x1419515d3703d8F2cc72Fa6A341685E4f8e7e8e1; // usdc-honey LP infrared vault

  address user1 = address(0xabc);
  address user2 = address(0xcba);
  address user3 = address(0xddd);

  uint256 depositNum = 100e18;
  uint256 depositLength = 12 hours;
  // int24 private constant MIN_TICK = -887272;
  // int24 private constant MAX_TICK = -MIN_TICK;
  // int24 private constant TICK_SPACING = 60;

  // forks starts at block 1936029
  function setUp() public {
    GoldivaultStaking usdchoneyinfraredvaultComputed = GoldivaultStaking(address(this).computeAddress(3));

    // deploy usdchoneyinfraredlpgoldivault
    address[] memory yieldTokens = new address[](1);
    yieldTokens[0] = ibgt;
    uhiot = new USDCHoneyInfraredOT("USDC/Honey Infrared LP OT", "UHIOT", address(usdchoneyinfraredvaultComputed));
    uhiyt = new USDCHoneyInfraredYT("USDC/Honey Infrared LP YT", "UHIYT", address(usdchoneyinfraredvaultComputed));
    usdchoneyinfraredvault = new GoldivaultStaking(
      address(uhiot),
      address(uhiyt),
      multisig,
      depositToken,
      depositVault,
      router,
      5,
      30,
      30 days,
      yieldTokens
    );
  }

  modifier seedPool() {
    // UniswapV3Factory(factory).createPool(depositToken, address(uhiot), 3000);
    // address seeder = address(0x6969);
    // deal(depositToken, seeder, depositNum);
    // deal(address(uhiot), seeder, depositNum);
    // INonfungiblePositionManager.MintParams memory params = 
    // INonfungiblePositionManager.MintParams({
    //   token0: depositToken,
    //   token1: address(uhiot),
    //   fee: 3000,
    //   tickLower: (MIN_TICK / TICK_SPACING) * TICK_SPACING,
    //   tickUpper: (MAX_TICK / TICK_SPACING) * TICK_SPACING,
    //   amount0Desired: depositNum,
    //   amount1Desired: depositNum,
    //   amount0Min: 0,
    //   amount1Min: 0,
    //   recipient: seeder,
    //   deadline: block.timestamp + 1 days
    // });
    // vm.startPrank(seeder);
    // ERC20(depositToken).approve(positionManager, depositNum);
    // uhiot.approve(positionManager, depositNum);
    // INonfungiblePositionManager(positionManager).mint(params);
    // vm.stopPrank();
    _;
  }

  // Staking different amounts of YT over the same time period and checking that they receive rewards proportional to stake size
  function testCorrectRewards() public {
    deal(depositToken, user1, depositNum);
    vm.startPrank(user1);
    ERC20(depositToken).approve(address(usdchoneyinfraredvault), depositNum);
    uhiyt.approve(address(usdchoneyinfraredvault), depositNum);
    usdchoneyinfraredvault.deposit(depositNum);
    vm.stopPrank();

    deal(depositToken, user2, depositNum * 2);
    vm.startPrank(user2);
    ERC20(depositToken).approve(address(usdchoneyinfraredvault), depositNum * 2);
    uhiyt.approve(address(usdchoneyinfraredvault), depositNum * 2);
    usdchoneyinfraredvault.deposit(depositNum * 2);
    vm.stopPrank();

    deal(depositToken, user3, depositNum / 2);
    vm.startPrank(user3);
    ERC20(depositToken).approve(address(usdchoneyinfraredvault), depositNum / 2);
    uhiyt.approve(address(usdchoneyinfraredvault), depositNum / 2);
    usdchoneyinfraredvault.deposit(depositNum / 2);
    vm.stopPrank();

    vm.warp(block.timestamp + depositLength);

    vm.prank(user1);
    usdchoneyinfraredvault.claim();
    vm.prank(user2);
    usdchoneyinfraredvault.claim();
    vm.prank(user3);
    usdchoneyinfraredvault.claim();

    uint256 user1Balance = ERC20(ibgt).balanceOf(user1);
    uint256 user2Balance = ERC20(ibgt).balanceOf(user2);
    uint256 user3Balance = ERC20(ibgt).balanceOf(user3);
  
    assertEq(user1Balance * 2, user2Balance);
    assertEq(user1Balance / 2, user3Balance);
  }

  // Repeat 1 with cases where other users are staking/unstaking/claiming in during the staking period.
  function testCorrectRewardsDiffPeriods() public {
    deal(depositToken, user1, depositNum);
    vm.startPrank(user1);
    ERC20(depositToken).approve(address(usdchoneyinfraredvault), depositNum);
    uhiyt.approve(address(usdchoneyinfraredvault), depositNum);
    usdchoneyinfraredvault.deposit(depositNum);
    vm.stopPrank();

    deal(depositToken, user2, depositNum * 2);
    vm.startPrank(user2);
    ERC20(depositToken).approve(address(usdchoneyinfraredvault), depositNum * 2);
    uhiyt.approve(address(usdchoneyinfraredvault), depositNum * 2);
    usdchoneyinfraredvault.deposit(depositNum * 2);
    vm.stopPrank();

    vm.warp(block.timestamp + (depositLength / 2));

    vm.prank(user1);
    usdchoneyinfraredvault.claim();
    vm.prank(user2);
    usdchoneyinfraredvault.claim();
    deal(depositToken, user3, depositNum / 2);
    vm.startPrank(user3);
    ERC20(depositToken).approve(address(usdchoneyinfraredvault), depositNum / 2);
    uhiyt.approve(address(usdchoneyinfraredvault), depositNum / 2);
    usdchoneyinfraredvault.deposit(depositNum / 2);
    vm.stopPrank();

    vm.warp(block.timestamp + (depositLength / 2));

    vm.prank(user3);
    usdchoneyinfraredvault.claim();

    uint256 user1Balance = ERC20(ibgt).balanceOf(user1);
    uint256 user2Balance = ERC20(ibgt).balanceOf(user2);
    uint256 user3Balance = ERC20(ibgt).balanceOf(user3);
  
    assertEq(user1Balance * 2, user2Balance);
    assertEq(user1Balance, user3Balance);
  }

  // Redeeming before and after maturity, checking the YT burning works correctly
  function testBeforeMaturityRedeeming() public {
    deal(depositToken, user1, depositNum);
    vm.startPrank(user1);
    ERC20(depositToken).approve(address(usdchoneyinfraredvault), depositNum);
    uhiyt.approve(address(usdchoneyinfraredvault), depositNum);
    usdchoneyinfraredvault.deposit(depositNum);
    vm.stopPrank();

    vm.warp(block.timestamp + 15 days);
    
    vm.prank(user1);
    usdchoneyinfraredvault.redeemOwnership(depositNum);

    assertEq(ERC20(depositToken).balanceOf(user1), depositNum);
    assertEq(uhiot.balanceOf(user1), 0);
    assertEq(uhiyt.balanceOf(user1), 0);
  }
  function testAfterMaturityRedeeming() public {
    deal(depositToken, user1, depositNum);
    vm.startPrank(user1);
    ERC20(depositToken).approve(address(usdchoneyinfraredvault), depositNum);
    uhiyt.approve(address(usdchoneyinfraredvault), depositNum);
    usdchoneyinfraredvault.deposit(depositNum);
    vm.stopPrank();

    vm.warp(block.timestamp + 50 days);
    
    vm.prank(user1);
    usdchoneyinfraredvault.redeemOwnership(depositNum);

    assertEq(ERC20(depositToken).balanceOf(user1), depositNum);
    assertEq(uhiot.balanceOf(user1), 0);
    assertEq(uhiyt.balanceOf(user1), depositNum);
  }

  // Adding in new reward tokens and claiming them once vault is already live and users are already staked.
  // Test buy and sell and check they don’t mess up staking rewards
  // Check that unstaking YT, transferring to another wallet, staking and then selling works as expected

  // Check that unstaked selling works
  function testUnstakedSellingHalf() public {

  }
  function testUnstakedSellingFull() public {
    deal(depositToken, user1, depositNum);
    vm.startPrank(user1);
    ERC20(depositToken).approve(address(usdchoneyinfraredvault), depositNum);
    uhiyt.approve(address(usdchoneyinfraredvault), depositNum);
    usdchoneyinfraredvault.deposit(depositNum);
    usdchoneyinfraredvault.unstakeYT(depositNum);
    usdchoneyinfraredvault.sellYT(depositNum, 1, type(uint256).max);
    vm.stopPrank();
    
  }

}