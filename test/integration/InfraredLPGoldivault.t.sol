//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../lib/forge-std/src/Test.sol";
import { LibRLP } from "../../lib/solady/src/utils/LibRLP.sol";
import { ERC20 } from "../../lib/solady/src/tokens/ERC20.sol";
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

contract IntegrationUSDCHoneyInfraredLPGoldivaultTest is Test {

  using LibRLP for address;

  GoldivaultStaking usdchoneyinfraredvault;
  USDCHoneyInfraredOT uhiot;
  USDCHoneyInfraredYT uhiyt;

  address ibgt = 0xac03CABA51e17c86c921E1f6CBFBdC91F8BB2E6b;
  address depositToken = 0xF961a8f6d8c69E7321e78d254ecAfBcc3A637621; // usdc-honey LP token
  address depositVault = 0x1419515d3703d8F2cc72Fa6A341685E4f8e7e8e1; // usdc-honey LP infrared vault

  address user1 = address(0xabc);
  address user2 = address(0xcba);
  address user3 = address(0xddd);

  function setUp() public {
    GoldivaultStaking usdchoneyinfraredvaultComputed = GoldivaultStaking(address(this).computeAddress(3));

    // deploy usdchoneyinfraredlpgoldivault
    address[] memory yieldTokens = new address[](1);
    yieldTokens[0] = ibgt;
    uhiot = new USDCHoneyInfraredOT("USDC/Honey Infrared LP OT", "UHIOT", address(usdchoneyinfraredvaultComputed));
    uhiyt = new USDCHoneyInfraredYT("USDC/Honey Infrared LP YT", "UHIYT", address(usdchoneyinfraredvaultComputed));
    usdchoneyinfraredvault = new GoldivaultStaking(
      address(bhot),
      address(bhyt),
      address(this),
      address(this),
      honey,
      bhoney,
      ibgt,
      ibgtVault,
      bhoney
    );
  }

}