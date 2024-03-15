//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../lib/forge-std/src/Test.sol";

library LibAddressSet {
  struct AddressSet {
    address[] addrs;
    mapping(address => bool) saved;
  }
  function add(AddressSet storage s, address addr) internal {
    if (!s.saved[addr]) {
      s.addrs.push(addr);
      s.saved[addr] = true;
    }
  }
  function contains(
    AddressSet storage s,
    address addr
  ) internal view returns (bool) {
    return s.saved[addr];
  }
  function count(
    AddressSet storage s
  ) internal view returns (uint256) {
    return s.addrs.length;
  }
  function forEach(
    AddressSet storage s,
    function(address) external returns (address[] memory) func
  ) internal {
    for (uint256 i; i < s.addrs.length; ++i) {
      func(s.addrs[i]);
    }
  }
  function reduce(
    AddressSet storage s,
    uint256 acc,
    function(uint256,address) external returns (uint256) func
  ) internal returns (uint256) {
    for (uint256 i; i < s.addrs.length; ++i) {
      acc = func(acc, s.addrs[i]);
    }
    return acc;
  }
  function rand(
    AddressSet storage s, 
    uint256 seed
  ) external view returns (address) {
    if (s.addrs.length > 0) {
      return s.addrs[seed % s.addrs.length];
    } else {
      return address(0xc0ffee);
    }
  }
}

contract BaseHandler is Test {

  uint256 public locksMintAmount = 100_000_000e18;

  using LibAddressSet for LibAddressSet.AddressSet;
  LibAddressSet.AddressSet internal _actors;
  address internal currentActor;

  mapping(bytes32 => uint256) public calls;

  modifier createActor() {
    currentActor = msg.sender;
    _actors.add(msg.sender);
    _;
  }

  modifier useActor(uint256 actorIndexSeed) {
    currentActor = randomActor(actorIndexSeed);
    _;
  }

  modifier countCall(bytes32 key) {
    calls[key]++;
    _;
  }

  function actors() public view returns (address[] memory) {
    return _actors.addrs;
  }

  function randomActor(uint256 actorSeed) public view returns (address) {
    return _actors.rand(actorSeed);
  }

  function forEachActor(function(address) external returns (address[] memory) func) public {
    return _actors.forEach(func);
  }

  function reduceActors(
    uint256 acc,
    function(uint256,address) external returns (uint256) func) public returns (uint256) 
  {
    return _actors.reduce(acc, func);
  }

}