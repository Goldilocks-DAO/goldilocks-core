﻿﻿# Goldiswap Smart Contract Documentation

## Description

Goldiswap is a custom AMM for managing the liquidity, price and trading of the LOCKS token (the governance token for Goldilocks DAO). It inherits ERC20 because it doubles as the actual token contract for LOCKS. 



## License

  

  

SPDX-License-Identifier: MIT

  

  

  

## Version

  

  

Solidity ^0.8.20

  

  

  

## Authors

  

  

- ampnoob

  

  

- geeb

 

## Imports

- FixedPointMathLib


- SafeTransferLib


- ERC20

- IGoldiswap

## State Variables

- `MAX_FLOOR_REDUCE`: Maximum percentage decrease in the target ratio.
- `MAX_RATIO`: Maximum ratio between PSL and FSL.
- `fsl`: Floor supporting liquidity.
- `psl`: Price supporting liquidity.
- `targetRatio`: Target ratio between PSL and FSL.
- `lastFloorRaise`: Timestamp of the last floor increase.
- `lastFloorDecrease`: Timestamp of the last decrease in the targetRatio.
- `goldilocked`: Address of Goldilocked contract.
- `honey`: Address of HONEY token.
- `multisig`: Address of the Goldilocks DAO multisig.
- `timelock`: Address of the timelock contract.


## Constructor

### constructor()

Initializes the Goldiswap contract and sets initial state variable values.

| Parameter       | Data Type | Description                        |
|-----------------|-----------|------------------------------------|
| `_fsl`          | uint256   | Initial value of FSL.              |
| `_psl`          | uint256   | Initial value of PSL.              |
| `_goldilocked`  | address   | Address of Goldilocked.            |
| `_honey`        | address   | Address of HONEY token.            |
| `_multisig`     | address   | Address of the Goldilocks DAO multisig. |
| `_timelock`     | address   | Address of the timelock contract.  |
| `initialSupply` | uint256   | Initial supply of the LOCKS token. |

## External Functions

### buy

 Allows users to buy LOCKS tokens with HONEY tokens.


| Parameter     | Data Type | Description                       |
|---------------|-----------|-----------------------------------|
| `amount`      | uint256   | Amount of LOCKS to buy.          |
| `maxAmount`   | uint256   | Maximum amount of HONEY to spend.|

### sell

Allows users to sell LOCKS tokens for HONEY tokens.

| Parameter     | Data Type | Description                         |
|---------------|-----------|-------------------------------------|
| `amount`      | uint256   | Amount of LOCKS to sell.           |
| `minAmount`   | uint256   | Minimum amount of HONEY to receive.|

### redeem()

Allows users to redeem LOCKS tokens for floor value.

| Parameter     | Data Type | Description                   |
|---------------|-----------|-------------------------------|
| `amount`      | uint256   | Amount of LOCKS to redeem.   |

### injectLiquidity

Inject liquidity into the contract.

| Parameter | Type   | Description               |
|-----------|--------|---------------------------|
| `liquidity`  | uint256| Amount of liquidity to add.|

## View Functions

### floorPrice

Returns the current floor price of LOCKS.

### marketPrice

Returns the current market price of LOCKS.

## Internal Functions

### _floorPrice

Calculates the floor price of LOCKS.

| Parameter | Type   | Description                              |
|-----------|--------|------------------------------------------|
| `_fsl`    | uint256| Current FSL.                             |
| `_supply` | uint256| Current token supply.                    |

### _marketPrice

Calculates the market price of LOCKS.

| Parameter | Type   | Description                              |
|-----------|--------|------------------------------------------|
| `_fsl`    | uint256| Current FSL.                             |
| `_psl`    | uint256| Current PSL.                             |
| `_supply` | uint256| Current token supply.                    |

### _buyLoop

Loops through the amount of LOCKS tokens to buy and calculates the total price.

| Parameter  | Type   | Description                             |
|------------|--------|-----------------------------------------|
| `_fsl`     | uint256| Temporary variable for FSL.             |
| `_psl`     | uint256| Temporary variable for PSL.             |
| `_supply`  | uint256| Temporary variable for supply.          |
| `leftover` | uint256| Amount of LOCKS tokens being bought.   |

### _sellLoop

Loops through the amount of LOCKS tokens to sell and calculates the sale proceeds.

| Parameter  | Type   | Description                            |
|------------|--------|----------------------------------------|
| `_fsl`     | uint256| Temporary variable for FSL.            |
| `_psl`     | uint256| Temporary variable for PSL.            |
| `_supply`  | uint256| Temporary variable for supply.         |
| `leftover` | uint256| Amount of LOCKS tokens to sell.       |

### _pow

Raises `x` to the power of `y`.

| Parameter | Type   | Description                   |
|-----------|--------|-------------------------------|
| `x`       | uint256| Base number.                  |
| `y`       | uint256| Exponent.                     |

### _floorRaise

Increases the FSL and target ratio, and decreases the PSL if the target ratio is exceeded.

### _floorDecrease

Decreases the target ratio if more than a day has elapsed since the last floorRaise or floorDecrease.

## Permissioned Functions

### borrowTransfer

Transfers HONEY to the user who is borrowing against their locks.

| Parameter | Type   | Description                |
|-----------|--------|----------------------------|
| `to`      | address| Address to transfer HONEY to.|
| `amount`  | uint256| Amount of HONEY to transfer. |
| `fee`     | uint256| Fee that is sent to the treasury. |

### porridgeMint

Mints LOCKS tokens from PORRIDGE token stirring.

| Parameter | Type   | Description                    |
|-----------|--------|--------------------------------|
| `to`      | address| Recipient of minted LOCKS tokens.|
| `amount`  | uint256| Amount of minted LOCKS tokens.   |
| `cost`    | uint256| Cost of the floor price of the minted LOCKS tokens. |

### initializeProtocol

Allows multisig to initialize protocol

| Parameter | Type | Description |
|-----------|--------|--------------------------------|
| `amount` | uint256 | Amount to Honey to initialize with |
