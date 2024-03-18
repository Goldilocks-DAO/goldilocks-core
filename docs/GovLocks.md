
## GovLocks Contract Documentation

  

### Description

  

GovLocks is a governance wrapper for the Locks token.

## License
 SPDX-License-Identifier: MIT
## Version 
Solidity ^0.8.20
## Authors
 ampnoob - geeb 
## Imports 
safeTransferLib-ERC20

### Structs

  

#### Checkpoint

- **Description**: Represents a checkpoint for vote tracking.


- `fromBlock`: Block number from which the checkpoint starts.

- `votes`: Number of votes at the checkpoint.

  

### State Variables

  

- `locks`: Address of the Locks token.

- `goldilocked`: Address of the Goldilocked contract.

- `deposits`: Mapping of user addresses to their deposited Locks amount.

- `delegates`: Mapping of user addresses to their delegated address.

- `numCheckpoints`: Mapping of user addresses to the number of checkpoints.

- `checkpoints`: Mapping of user addresses to a block number to a checkpoint.

  

### Constructor

  

#### Constructor

- **Description**: Initializes the GovLocks contract.

- **Parameters**:

| Name             | Type     | Description                                |
|------------------|----------|--------------------------------------------|
| `_locks`         | address  | Address of the Locks token.                |
| `_goldilocked`   | address  | Address of the Goldilocked contract.       |
| `apdao`          | address  | Address of APDAO.                          |
| `apdaoVotingPower` | uint256 | Governance power to grant to APDAO.        |


### Errors

  

- `NoSuchBlock`: The requested block does not exist.

- `NotGoldilocked`: The contract is not interacting with Goldilocked.

  

### Events

  

- `DelegateVotesChanged`: Triggered when the delegate votes change.

- `DelegateChanged`: Triggered when the delegate is changed.

  

### View Functions

  

#### Get Votes

- **Description**: Returns the current votes balance of a user.

- **Parameters**:

| Name     | Type     | Description                        |
|----------|----------|------------------------------------|
| `user`   | address  | Address of the user for the query. |

- **Returns**: Current votes balance.

  

#### Get Prior Votes

- **Description**: Returns the votes balance from a prior block of a user.

- **Parameters**:

| Name             | Type     | Description                                     |
|------------------|----------|-------------------------------------------------|
| `user`           | address  | Address of the user for the query.              |
| `blockNumber`    | uint256  | Block number for which the votes balance is queried. |

- **Returns**: Votes balance from the prior block.

  

## External Functions

  

### Deposit

- **Description**: Deposits Locks to mint GovLocks.

- **Parameters**:

| Name      | Type     | Description                            |
|-----------|----------|----------------------------------------|
| `amount`  | uint256  | Amount of Locks to deposit.           |

- **Errors**: None.

  

### Withdraw

- **Description**: Withdraws Locks to burn Govlocks.

- **Parameters**:

| Name      | Type     | Description                            |
|-----------|----------|----------------------------------------|
| `amount`  | uint256  | Amount of Locks to withdraw.          |

- **Errors**: None.

  

### Delegate

- **Description**: Delegates votes from `msg.sender` to `delegatee`.

- **Parameters**:

| Name          | Type     | Description                        |
|---------------|----------|------------------------------------|
| `delegatee`   | address  | Address to delegate votes to.     |

- **Errors**: None.

  

## Internal Functions

  

### Delegate

- **Description**: Delegates votes from `delegator` to `delegatee`.

- **Parameters**:

| Name          | Type     | Description                            |
|---------------|----------|----------------------------------------|
| `delegator`   | address  | Address of the delegator.             |
| `delegatee`   | address  | Address to delegate votes to.         |

- **Errors**: None.

  

### Move Delegates

- **Description**: Moves delegated votes between representatives.

- **Parameters**:

| Name        | Type     | Description                                    |
|-------------|----------|------------------------------------------------|
| `srcRep`    | address  | Source representative address.                 |
| `dstRep`    | address  | Destination representative address.            |
| `amt`       | uint256  | Amount of votes to move.                       |

- **Errors**: None.

  

### Write Checkpoint

- **Description**: Writes vote balance checkpoint.

- **Parameters**:

| Name          | Type     | Description                                    |
|---------------|----------|------------------------------------------------|
| `delegatee`   | address  | Address of the delegatee.                     |
| `nCheckpoints`| uint256  | Number of checkpoints.                        |
| `oldVotes`    | uint256  | Old vote count.                               |
| `newVotes`    | uint256  | New vote count.                               |

- **Errors**: None.

  

## Permissioned Function

  

### Update Staked Balance

- **Description**: Moves delegated votes during Locks stake or unstake.

- **Parameters**:

| Name     | Type     | Description                            |
|----------|----------|----------------------------------------|
| `from`   | address  | Address from which votes are being moved. |
| `to`     | address  | Address to which votes are being moved.   |
| `amt`    | uint256  | Amount of votes being moved.          |

- **Errors**:

- `NotGoldilocked`: If the sender is not `goldilocked`.

  

## Implementation Function

  

### After Token Transfer

- **Description**: Moves delegated votes after a token transfer.

- **Parameters**:

| Name      | Type     | Description                            |
|-----------|----------|----------------------------------------|
| `from`    | address  | Address from which tokens are transferred. |
| `to`      | address  | Address to which tokens are transferred.   |
| `amt`     | uint256  | Amount of tokens being transferred.      |

- **Errors**: None.
