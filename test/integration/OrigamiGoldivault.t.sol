//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../lib/forge-std/src/Test.sol";
import { console } from "../../lib/forge-std/src/console.sol";
import { LibRLP } from "../../lib/solady/src/utils/LibRLP.sol";
import { ERC20 } from "../../lib/solady/src/tokens/ERC20.sol";
import { Goldivault4626 } from "../../src/core/goldivault/Goldivault4626.sol";
import { OwnershipToken } from "../../src/core/goldivault/OwnershipToken.sol";
import { YieldToken } from "../../src/core/goldivault/YieldToken.sol";

contract OrigamisUSDSOT is OwnershipToken {
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

contract OrigamisUSDSYT is YieldToken {
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
  OrigamisUSDSOT oot;
  OrigamisUSDSYT oyt;

  address multisig = 0x6FD990680deB2e5DCcb2FFEfC3307Dd34138Ac7F;
  address ibgt = 0xac03CABA51e17c86c921E1f6CBFBdC91F8BB2E6b;
  address router = 0xe301E48F77963D3F7DbD2a4796962Bd7f3867Fb4;
  address depositToken = 0xF961a8f6d8c69E7321e78d254ecAfBcc3A637621; // usdc-honey LP token
  address depositVault = 0x1419515d3703d8F2cc72Fa6A341685E4f8e7e8e1; // usdc-honey LP infrared vault

  address user1 = address(0xabc);
  address user2 = address(0xcba);
  address user3 = address(0xddd);

  uint256 depositNum = 100e18;
  uint256 depositLength = 12 hours;

  // forks starts at block 1936029
  function setUp() public {
    Goldivault4626 origamigoldivaultComputed = Goldivault4626(address(this).computeAddress(3));

    // deploy usdchoneyinfraredlpgoldivault
    oot = new OrigamisUSDSOT("Origami sUSDS OT", "OOT", address(origamigoldivaultComputed));
    oyt = new OrigamisUSDSYT("Origami sUSDS OT", "OYT", address(origamigoldivaultComputed));
    origamigoldivault = new Goldivault4626(
      address(oot),
      address(oyt),
      multisig,
      depositToken,
      depositVault,
      router,
      5,
      1e18,
      30 days
    );
  }



}