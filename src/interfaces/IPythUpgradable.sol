//SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface IPythUpgradable {
    struct Price {
        int64 price;
        uint64 conf;
        int32 expo;
        uint publishTime;
    }
    function getPrice(bytes32 id) external view returns (Price memory price);
}