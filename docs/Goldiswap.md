# Goldiswap Smart Contract Documentation

## Overview

Goldiswap is a custom AMM for managing the liquidity, price and trading of the LOCKS token (the governance token for Goldilocks DAO). It inherits ERC20 because it doubles as the actual token contract for LOCKS. 


## Contract Details

- **Contract Name**: Goldiswap
- **Version**: 0.8.20
- **License**: MIT

## Authors

- geeb
- ampnoob

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

### `constructor(uint256 _fsl, uint256 _psl, address _goldilocked, address _honey, address _multisig, address _timelock, uint256 initialSupply)`

Initializes the Goldiswap contract and sets initial state variable values.

- `_fsl`: Initial value of FSL.
- `_psl`: Initial value of PSL.
- `_goldilocked`: Address of Goldilocked.
- `_honey`: Address of HONEY token.
- `_multisig`: Address of the Goldilocks DAO multisig.
- `_timelock`: Address of the timelock contract.
- `initialSupply`: Initial supply of the LOCKS token.

## External Functions

### `buy(uint256 amount, uint256 maxAmount)`

Allows users to buy LOCKS tokens with HONEY tokens.

- `amount`: Amount of LOCKS to buy.
- `maxAmount`: Maximum amount of HONEY to spend.

### `sell(uint256 amount, uint256 minAmount)`

Allows users to sell LOCKS tokens for HONEY tokens.

- `amount`: Amount of LOCKS to sell.
- `minAmount`: Minimum amount of HONEY to receive.

### `redeem(uint256 amount)`

Allows users to redeem LOCKS tokens for floor value.

- `amount`: Amount of LOCKS to redeem.

## View Functions

### `floorPrice()`

Returns the current floor price of LOCKS.

### `marketPrice()`

Returns the current market price of LOCKS.

## Internal Functions

### `_floorPrice(uint256 _fsl, uint256 _supply)`

Calculates the floor price of $LOCKS.

- `_fsl`: Current FSL.
- `_supply`: Current token supply.

### `_marketPrice(uint256 _fsl, uint256 _psl, uint256 _supply)`

Calculates the market price of LOCKS.

- `_fsl`: Current FSL.
- `_psl`: Current PSL.
- `_supply`: Current token supply.

### `_buyLoop(uint256 _fsl, uint256 _psl, uint256 _supply, uint256 leftover)`

Loops through the amount of LOCKS tokens to buy and calculates the total price.

- `_fsl`: Temporary variable for FSL.
- `_psl`: Temporary variable for PSL.
- `_supply`: Temporary variable for supply.
- `leftover`: Amount of LOCKS tokens being bough.

### `_sellLoop(uint256 _fsl, uint256 _psl, uint256 _supply, uint256 leftover)`

Loops through the amount of LOCKS tokens to sell and calculates the sale proceeds.

- `_fsl`: Temporary variable for FSL.
- `_psl`: Temporary variable for PSL.
- `_supply`: Temporary variable for supply.
- `leftover`: Amount of LOCKS tokens to sell.

### `_pow(uint256 x, uint256 y)`

Raises `x` to the power of `y`.

- `x`: Base number.
- `y`: Exponent.

### `_floorRaise()`

Increases the FSL and target ratio, and decreases the PSL if the target ratio is exceeded.

### `_floorDecrease()`

Decreases the target ratio if more than a day has elapsed since the last floorRaise or  floorDecrease.

## Permissioned Functions

### `borrowTransfer(address to, uint256 amount, uint256 fee)`

Transfers HONEY to the user who is borrowing against their locks.

- `to`: Address to transfer HONEY to.
- `amount`: Amount of HONEY to transfer.
- `fee`: Fee that is sent to the treasury.

### `porridgeMint(address to, uint256 amount)`

Mints LOCKS tokens from PORRIDGE token stirring.

- `to`: Recipient of minted LOCKS tokens.
- `amount`: Amount of minted LOCKS tokens.

### `injectLiquidity(uint256 amount)`

Allows the DAO to inject liquidity into the contract.

- `amount`: Amount of liquidity to add. 


