# Goldilocked Smart Contract

## Description

Mints Porridge for staked Locks and facilitates borrowing against Locks

## Variables

| Name                       | Type     | Description                                         |
|----------------------------|----------|-----------------------------------------------------|
| stakedLocks                | mapping  | Tracks the amount of LOCKS staked by each user.    |
| claimablePrg               | mapping  | Tracks the claimable PORRIDGE rewards for each user.|
| prgPerTokenDebt            | mapping  | Tracks the debt of PORRIDGE rewards per LOCKS token for the user.|
| borrowedHoney              | mapping  | Tracks the amount of HONEY borrowed by each user.   |
| seedAllocations            | mapping  | Tracks seed investor allocations of LOCKS.                  |
| teamAllocations            | mapping  | Tracks team allocations of LOCKS.                  |
| deployTime                 | uint256  | Timestamp of contract deployment.                  |
| vestingStart               | uint256  | Timestamp marking the start of vesting period for seed investors.     |
| vestingEnd                 | uint256  | Timestamp marking the end of vesting period for seed investors.      |
| goldiswap                  | address  | Address of the Goldiswap contract.                 |
| goldilend                  | address  | Address of the Goldilend contract.                 |
| govlocks                   | address  | Address of the govLocks contract.                  |
| honey                      | address  | Address of the HONEY token contract.               |
| ANNUAL_PORRIDGE_EMISSIONS  | uint256  | Annual emission rate of PORRIDGE tokens.          |
| lastUpdateTime             | uint256  | Timestamp of the last update for PORRIDGE rewards.                      |
| claimablePrgPerLocksStored | uint256  | Claimable PORRIDGE per LOCKS token.               |
| timelock                   | address  | Address of the Timelock contract.                  |

## Functions

#### `name()`

Returns the name of the PORRIDGE token.

#### `symbol()`

Returns the symbol of the PORRIDGE token.


### Constructor

#### `constructor()`

Initializes the Goldilocked contract.

| Parameter            | Type       | Description                                    |
|----------------------|------------|------------------------------------------------|
| `_goldiswap`         | address    | Address of Goldiswap contract.                |
| `_goldilend`         | address    | Address of Goldilend contract.                |
| `_govlocks`          | address    | Address of govLocks contract.                 |
| `_honey`             | address    | Address of the HONEY contract.                |
| `_timelock`          | address    | Address of the Timelock contract.             |
| `allocationsAddress` | address[]  | Addresses of seed investors.              |
| `allocationsAmt`     | uint256[]  | Amounts of staked/locked LOCKS allocated to seed investors.
| `initialSupply`      | uint256    | Initial supply of the PORRIDGE token.       

### View Functions

#### `userStakedLocks(address user)`

Returns the staked LOCKS of a user.

| Parameter | Type     | Description                            |
|-----------|----------|----------------------------------------|
| `user`    | address  | Address of the user.                   |

#### `userClaimablePrg(address user)`

Returns the claimable yield of a user.

| Parameter | Type     | Description                            |
|-----------|----------|----------------------------------------|
| `user`    | address  | Address of the user.                   |

#### `userLockedLocks(address user)`

Returns the locked LOCKS of a user.

| Parameter | Type     | Description                            |
|-----------|----------|----------------------------------------|
| `user`    | address  | Address of the user.                   |

#### `userBorrowedHoney(address user)`

Returns the borrowed HONEY of a user.

| Parameter | Type     | Description                            |
|-----------|----------|----------------------------------------|
| `user`    | address  | Address of the user.                   |

#### `userBorrowLimit(address user)`

Returns the maximum borrow limit of a user.

| Parameter | Type     | Description                            |
|-----------|----------|----------------------------------------|
| `user`    | address  | Address of the user.                   |

#### `userVestingCheck(address user)`

Returns the a bool checking whether the user has enough unvested tokens to unstake the desired amount.

| Parameter | Type     | Description                            |
|-----------|----------|----------------------------------------|
| `user`    | address  | Address of the user.                   |
  |

### External Functions

#### `stake(uint256 amount)`

Stakes LOCKS and begins earning PORRIDGE rewards.

| Parameter | Type     | Description                            |
|-----------|----------|----------------------------------------|
| `amount`  | uint256  | Amount of LOCKS to stake.             |

#### `unstake(uint256 amount)`

Unstakes LOCKS and claims PORRIDGE rewards.

| Parameter | Type     | Description                            |
|-----------|----------|----------------------------------------|
| `amount`  | uint256  | Amount of LOCKS to unstake.           |

#### `stir(uint256 amount)`

Burns PORRIDGE to buy LOCKS at floor price.

| Parameter | Type     | Description                            |
|-----------|----------|----------------------------------------|
| `amount`  | uint256  | Amount of PORRIDGE to stir.            |

#### `claim()`

Claims PORRIDGE rewards.

#### `borrow(uint256 amount)`

Lends out HONEY using staked LOCKS as collateral.

| Parameter | Type     | Description                            |
|-----------|----------|----------------------------------------|
| `amount`  | uint256  | Amount of HONEY to borrow.             |

#### `repay(uint256 amount)`

Repays HONEY loans.

| Parameter | Type     | Description                            |
|-----------|----------|----------------------------------------|
| `amount`  | uint256  | Amount of HONEY to repay.              |

### Internal Functions

#### `_updateClaimablePrg(address user)`

Updates claimable PORRIDGE rewards for a user.

| Parameter | Type     | Description                            |
|-----------|----------|----------------------------------------|
| `user`    | address  | Address to update claimable PORRIDGE for.|

#### `_claim(address claimer, uint256 claimable)`

Calculates and distributes PORRIDGE rewards to a user.

| Parameter | Type     | Description                            |
|-----------|----------|----------------------------------------|
| `claimer` | address  | User to claim PORRIDGE rewards for.    |
| `claimable`| uint256 | Amount of PORRIDGE to be claimed.      |

#### `_calculateClaimablePrg(address user)`

Calculates claimable PORRIDGE rewards for a user.

| Parameter | Type     | Description                            |
|-----------|----------|----------------------------------------|
| `user`    | address  | Address to calculate claimable PORRIDGE for.|

#### `_claimablePrgPerLocks()`

Calculates claimable PORRIDGE per LOCKS token.

#### `_borrowLimitCheck(uint256 amount, uint256 floorPrice)`

Checks if the user has enough borrowing power for desired loan amount.

| Parameter   | Type     | Description                                      |
|-------------|----------|--------------------------------------------------|
| `amount`    | uint256  | Amount of HONEY the user is requesting to borrow.|
| `floorPrice`| uint256  | Current floor price of LOCKS.                    |

#### `_borrowLimit(address user, uint256 floorPrice)`

Determine the user's borrowing power, which should be equal to the floor price of their staked LOCKS minus the balance of their outstanding loans.

| Parameter   | Type     | Description                                      |
|-------------|----------|--------------------------------------------------|
| `user`      | address  | Address of the user.                             |
| `floorPrice`| uint256  | Current floor price of LOCKS.                    |

#### `_lockedLocks(address user)`

Calculates the amount of locked LOCKS for a user -- i.e. amount of staked LOCKS that is currently being used to collateralize their loans.

| Parameter   | Type     | Description                                      |
|-------------|----------|--------------------------------------------------|
| `user`      | address  | Address to calculate locked LOCKS for.           |

#### `_calcFee(uint256 amount)`

Calculates the fee for borrowing.

| Parameter   | Type     | Description                                      |
|-------------|----------|--------------------------------------------------|
| `amount`    | uint256  | Amount of HONEY the user is requesting to borrow.|

#### `_vestingCheck(address user, uint256 amount)`

Calculates whether a seed investor has enough vested tokens to unstake the desired amount.

| Parameter   | Type     | Description                                      |
|-------------|----------|--------------------------------------------------|
| `user`      | address  | Address of the unstaker.                        |
| `amount`    | uint256  | Amount of LOCKS to unstake.                     |


### Permissioned Functions

#### `goldilendMint(address to, uint256 amount)`

Allows the Goldilend contract to mint PORRIDGE to GiBGT stakers.

| Parameter | Type     | Description                            |
|-----------|----------|----------------------------------------|
| `to`      | address  | Recipient of minted PORRIDGE tokens.   |
| `amount`  | uint256  | Amount of minted PORRIDGE tokens.     |

#### `changePrgEmissions(uint256 newPrgEmissions)`

Allows the DAO to change PORRIDGE emissions for LOCKS stakers.

| Parameter          | Type     | Description                                    |
|--------------------|----------|------------------------------------------------|
| `newPrgEmissions`  | uint256  | New annual PORRIDGE emission rate for LOCKS staking.|

#### `mintPorridge(address multisig, uint256 newPorridge)`

Allows the DAO to mint PORRIDGE.

| Parameter      | Type     | Description                            |
|----------------|----------|----------------------------------------|
| `multisig`     | address  | Address to mint PORRIDGE to.           |
| `newPorridge`  | uint256  | Amount of PORRIDGE to mint.            |

