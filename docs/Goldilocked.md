﻿# Goldilocked Smart Contract

  

## Description

  

Goldilocked hosts the PORRIDGE token and controls staking and borrowing for LOCKS.

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


- `stakedLocks`: mapping  that tracks the amount of LOCKS staked by each user.

- `claimablePrg`: mapping that tracks the claimable PORRIDGE rewards for each user.

- `prgPerTokenDebt`: mapping that tracks the debt of PORRIDGE rewards per LOCKS token for the user.

- `borrowedHoney`: mapping that tracks the amount of HONEY borrowed by each user.

- `seedAllocations`: mapping that tracks seed investor allocations of LOCKS.

- `teamAllocations`: mapping that tracks team allocations of LOCKS.

- `deployTime`: uint256 - Timestamp of contract deployment.

- `vestingStart`: uint256 - Timestamp marking the start of vesting period for seed investors.

- `vestingEnd`: uint256 - Timestamp marking the end of vesting period for seed investors.

- `goldiswap`: Address of the Goldiswap contract.

- `goldilend`: Address of the Goldilend contract.

- `govlocks`: Address of the govLocks contract.

- `honey`: Address of the HONEY token contract.

- `annualPrgEmissions`: uint256 - Annual emission rate of PORRIDGE tokens.

- `lastUpdateTime`: uint256 - Timestamp of the last update for PORRIDGE rewards.

- `claimablePrgPerLocksStored`: uint256 - Claimable PORRIDGE per LOCKS token.

- `timelock`:  Address of the Timelock contract.


## Functions

  

#### name

 
Returns the name of the PORRIDGE token.

 

#### symbol

  

Returns the symbol of the PORRIDGE token.

  

  

### Constructor

  

#### constructor

  

Initializes the Goldilocked contract and sets initial values of variables. 

  

| Parameter  | Type | Description  |
|----------------------|---------------|-----------------------------------------------|
| `_goldiswap` | address  | Address of Goldiswap contract.  |
| `_goldilend` | address  | Address of Goldilend contract.  |
| `_govlocks`  | address  | Address of govLocks contract. |
| `_honey` | address  | Address of the HONEY contract.  |
| `_timelock`  | address  | Address of the Timelock contract. |
| `allocationsAddress` | address[]  | Addresses of seed investors.  |
| `allocationsAmt` | uint256[]  | Amounts of staked/locked LOCKS allocated to seed investors.
| `initialSupply`  | uint256  | Initial supply of the PORRIDGE token. |

  

### View Functions

  

#### userStakedLocks

Returns the staked LOCKS of a user.
  

| Parameter | Type | Description  |
|----------------------|---------------|-----------------------------------------------|
| `user`  | address  | Address of the user. |

  

#### userClaimablePrg

  

Returns the claimable yield of a user.

  

| Parameter | Type | Description  |
|----------------------|---------------|-----------------------------------------------|
| `user`  | address  | Address of the user. |

  

#### userLockedLocks

  

Returns the locked LOCKS of a user.

  

| Parameter | Type | Description  |
|----------------------|---------------|-----------------------------------------------|
| `user`  | address  | Address of the user. |

  

#### userBorrowedHoney

  

Returns the borrowed HONEY of a user.

  

| Parameter | Type | Description  |
|----------------------|---------------|-----------------------------------------------|
| `user`  | address  | Address of the user. |

  

#### userBorrowLimit

  

Returns the maximum borrow limit of a user.

  

| Parameter | Type | Description  |
|----------------------|---------------|-----------------------------------------------|
| `user`  | address  | Address of the user. |

  

#### userVestingCheck

  

Returns the a bool checking whether the user has enough unvested tokens to unstake the desired amount.

  

| Parameter | Type | Description  |
|----------------------|---------------|-----------------------------------------------|
| `user`  | address  | Address of the user. |


  

### External Functions

  

#### stake

  

Stakes LOCKS and begins earning PORRIDGE rewards.

  

| Parameter | Type | Description  |
|----------------------|---------------|-----------------------------------------------|
| `amount`  | uint256  | Amount of LOCKS to stake. |

  

#### unstake

  

Unstakes LOCKS and claims PORRIDGE rewards.

  

| Parameter | Type | Description  |
|----------------------|---------------|-----------------------------------------------|
| `amount`  | uint256  | Amount of LOCKS to unstake. |

  

#### stir

  

Burns PORRIDGE to buy LOCKS at floor price.

  

| Parameter | Type | Description  |
|----------------------|---------------|-----------------------------------------------|
| `amount`  | uint256  | Amount of PORRIDGE to stir.  |

  

#### claim

Claims PORRIDGE rewards.

  

#### borrow

Lends out HONEY using staked LOCKS as collateral.

  

| Parameter | Type | Description  |
|----------------------|---------------|-----------------------------------------------|
| `amount`  | uint256  | Amount of HONEY to borrow. |

  

#### repay

  

Repays HONEY loans.

  

| Parameter | Type | Description  |
|----------------------|---------------|-----------------------------------------------|
| `amount`  | uint256  | Amount of HONEY to repay.  |

  

### Internal Functions

  

#### _updateClaimablePrg

  

Updates claimable PORRIDGE rewards for a user.

  

| Parameter | Type | Description  |
|----------------------|---------------|-----------------------------------------------|
| `user`  | address  | Address to update claimable PORRIDGE for.|

  

#### _claim

  

Calculates and distributes PORRIDGE rewards to a user.

  

| Parameter | Type | Description  |
|----------------------|---------------|-----------------------------------------------|
| `claimer` | address  | User to claim PORRIDGE rewards for.  |
| `claimable`| uint256 | Amount of PORRIDGE to be claimed.  |

  

#### _calculateClaimablePrg

  

Calculates claimable PORRIDGE rewards for a user.

  

| Parameter | Type | Description  |
|----------------------|---------------|-----------------------------------------------|
| `user`  | address  | Address to calculate claimable PORRIDGE for.|

  

#### _claimablePrgPerLocks

  

Calculates claimable PORRIDGE per LOCKS token.

  

#### _borrowLimitCheck

  

Checks if the user has enough borrowing power for desired loan amount.

  

| Parameter | Type | Description  |
|----------------------|---------------|-----------------------------------------------|
| `amount`  | uint256  | Amount of HONEY the user is requesting to borrow.|
| `floorPrice`| uint256  | Current floor price of LOCKS.  |


#### _borrowLimit

  

Determine the user's borrowing power, which should be equal to the floor price of their staked LOCKS minus the balance of their outstanding loans.

  

| Parameter | Type | Description  |
|----------------------|---------------|-----------------------------------------------|
| `user`  | address  | Address of the user. |
| `floorPrice`| uint256  | Current floor price of LOCKS.  |

  

#### _lockedLocks

  

Calculates the amount of locked LOCKS for a user -- i.e. amount of staked LOCKS that is currently being used to collateralize their loans.

  

| Parameter | Type | Description  |
|----------------------|---------------|-----------------------------------------------|
| `user`  | address  | Address to calculate locked LOCKS for. |

  

#### _calcFee

  

Calculates the fee for borrowing.

  

| Parameter | Type | Description  |
|----------------------|---------------|-----------------------------------------------|
| `amount`  | uint256  | Amount of HONEY the user is requesting to borrow.|

  

#### _vestingCheck

  

Calculates whether a seed investor has enough vested tokens to unstake the desired amount.

  

| Parameter | Type | Description  |
|----------------------|---------------|-----------------------------------------------|
| `user`  | address  | Address of the unstaker.  |
| `amount`  | uint256  | Amount of LOCKS to unstake. |

  

  

### Permissioned Functions

  

#### goldilendMint

  

Allows the Goldilend contract to mint PORRIDGE to GiBGT stakers.

  

| Parameter | Type | Description  |
|----------------------|---------------|-----------------------------------------------|
| `to`  | address  | Recipient of minted PORRIDGE tokens. |
| `amount`  | uint256  | Amount of minted PORRIDGE tokens. |

  

#### changePrgEmissions

  

Allows the DAO to change PORRIDGE emissions for LOCKS stakers.

  

| Parameter  | Type | Description  |
|----------------------|---------------|-----------------------------------------------|
| `newPrgEmissions`  | uint256  | New annual PORRIDGE emission rate for LOCKS staking.|

  

#### mintPorridge

  

Allows the DAO to mint PORRIDGE.

  

| Parameter  | Type | Description  |
|----------------------|---------------|-----------------------------------------------|
| `multisig` | address  | Address to mint PORRIDGE to. |
| `newPorridge`  | uint256  | Amount of PORRIDGE to mint.  |