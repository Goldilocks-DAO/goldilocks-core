//SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { IPythUpgradable } from "../interfaces/IPythUpgradable.sol";

/// @title MockPyth
/// @notice Mock Pyth oracle for testing purposes
/// @dev Always returns a fixed price regardless of timestamp, allowing time warping in tests
contract MockPyth is IPythUpgradable {

    // Fixed BERA price for testing (e.g., $5.00 with expo -8)
    int64 public mockPrice;
    int32 public mockExpo;

    constructor() {
        // Default BERA price: $2.00 with 8 decimals precision (200000000 = 2.00 * 10^8)
        mockPrice = 200000000;
        mockExpo = -8;
    }

    /// @notice Set the mock price
    /// @param _price The price to return
    /// @param _expo The exponent for the price
    function setPrice(int64 _price, int32 _expo) external {
        mockPrice = _price;
        mockExpo = _expo;
    }

    /// @notice Get the price for any feed ID
    /// @return price The mocked price data
    function getPrice(bytes32 /* id */) external view override returns (Price memory price) {
        // Ignore the id parameter and always return the mock price
        return Price({
            price: mockPrice,
            conf: 1000000, // Mock confidence interval
            expo: mockExpo,
            publishTime: block.timestamp // Always use current block timestamp
        });
    }
}
