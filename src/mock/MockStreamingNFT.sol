//SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { IStreamingNFT } from "../interfaces/IStreamingNFT.sol";

contract MockStreamingNFT is IStreamingNFT {
    uint256 public cliffUnlockAmount;
    uint256 public vestedRewards;
    uint256 public cliffEndTimestamp;

    constructor(uint256 _cliffUnlockAmount, uint256 _vestedRewards, uint256 _cliffEndTimestamp) {
        cliffUnlockAmount = _cliffUnlockAmount;
        vestedRewards = _vestedRewards;
        cliffEndTimestamp = _cliffEndTimestamp;
    }

    function setCliffUnlockAmount(uint256 _amount) external {
        cliffUnlockAmount = _amount;
    }

    function setVestedRewards(uint256 _amount) external {
        vestedRewards = _amount;
    }

    function setCliffEndTimestamp(uint256 _timestamp) external {
        cliffEndTimestamp = _timestamp;
    }
}
