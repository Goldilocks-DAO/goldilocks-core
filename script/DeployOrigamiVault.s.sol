// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Script } from "../lib/forge-std/src/Script.sol";
import { LibRLP } from "../lib/solady/src/utils/LibRLP.sol";
import { ERC20 } from "../lib/solady/src/tokens/ERC20.sol";
import { Goldivault4626 } from "../src/core/goldivault/Goldivault4626.sol";
import { OwnershipToken } from "../src/core/goldivault/OwnershipToken.sol";
import { YieldToken } from "../src/core/goldivault/YieldToken.sol";

contract OrigamiiBERAosBGTOT is OwnershipToken {
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

contract OrigamiiBERAosBGTYT is YieldToken {
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

contract DeployOrigamiVaultScript is Script {

  using LibRLP for address;

  Goldivault4626 origamigoldivault;
  OrigamiiBERAosBGTOT origamiot;
  OrigamiiBERAosBGTYT origamiyt;

  address deployer = 0x895614c89beC7D11454312f740854d08CbF57A78;
  address multisig = 0x6FD990680deB2e5DCcb2FFEfC3307Dd34138Ac7F;
  address router = 0xe301E48F77963D3F7DbD2a4796962Bd7f3867Fb4;
  address iberaosbgtisland = 0xaD445256Ff81171043A5e7Cd8831e4371B000176;
  address iberaosbgtvault = 0x7c6e5C5568647b0b90f9f962fCDfFC771D7f44c5;

  function run() external {

    Goldivault4626 origamigoldivaultComputed = Goldivault4626(deployer.computeAddress(612));

    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_BASE");
    vm.startBroadcast(deployerPrivateKey);

    // deploy origamigoldivault
    origamiot = new OrigamiiBERAosBGTOT("Origami iBERA-osBGT LP-OT", "oAC-iBERA-osBGT-aOT", address(origamigoldivaultComputed));
    origamiyt = new OrigamiiBERAosBGTYT("Origami iBERA-osBGT LP-YT", "oAC-iBERA-osBGT-aYT", address(origamigoldivaultComputed));
    origamigoldivault = new Goldivault4626(
      address(origamiot),
      address(origamiyt),
      multisig,
      iberaosbgtisland,
      iberaosbgtvault,
      router,
      5,
      3,
      1e18,
      1 weeks
    );
    assert(origamiot.vault() == address(origamigoldivault));
    assert(origamiot.decimals() == ERC20(iberaosbgtisland).decimals());

    vm.stopBroadcast();
  }
}