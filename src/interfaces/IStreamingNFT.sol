//SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface IStreamingNFT {
    function cliffUnlockAmount() external view returns (uint256);
    function vestedRewards() external view returns (uint256);
}