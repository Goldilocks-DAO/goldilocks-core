# Timelock Contract Documentation

## Summary

The Timelock contract is a governance mechanism that introduces a delay between the proposal and execution of certain actions. It allows for queued transactions to be executed after a specified delay period, providing additional security and oversight in the governance process.

## License
 SPDX-License-Identifier: MIT
## Version 
Solidity ^0.8.20
## Authors
 ampnoob - geeb 


## State Variables

- **Grace Period**
  - Description: Grace period of a transaction going stale.
  - Value: 14 days

- **Minimum Delay**
  - Description: Minimum delay for queuing a transaction.
  - Value: 2 days

- **Maximum Delay**
  - Description: Maximum delay for queuing a transaction.
  - Value: 30 days

- **Goldigovernor Address**
  - Description: Address of Goldigovernor contract.

- **Multisig Address**
  - Description: Address of multisig contract.

- **Queued Transactions**
  - Description: Mapping of transaction hash to boolean indicating if the transaction is queued.

- **Delay**
  - Description: Delay for queuing a transaction.


## Constructor

### Timelock Constructor

Initializes the Timelock contract with the specified parameters.

| Parameter    | Description                              |
|--------------|------------------------------------------|
| `_goldigov`  | Goldigovernor address.                   |
| `_multisig`  | Multisig address.                        |
| `_delay`     | Delay in blocks for queuing transactions.|

## Errors

- **Invalid Delay**
  - Description: Error thrown when the provided delay is invalid.

- **Invalid ETA**
  - Description: Error thrown when the provided ETA is invalid.

- **Not Goldigov**
  - Description: Error thrown when the sender is not Goldigovernor.

- **Not Multisig**
  - Description: Error thrown when the sender is not the multisig.

- **Transaction Not Queued**
  - Description: Error thrown when attempting to execute or cancel a transaction that is not queued.

- **Transaction Locked**
  - Description: Error thrown when attempting to execute a transaction before its execution time.

- **Transaction Stale**
  - Description: Error thrown when attempting to execute a transaction after its grace period has passed.

- **Transaction Reverted**
  - Description: Error thrown when a transaction execution reverts.

## Events

- **New Admin**
  - Description: Event emitted when a new admin is set.

- **New Delay**
  - Description: Event emitted when the delay is updated.

- **Cancel Transaction**
  - Description: Event emitted when a transaction is canceled.

- **Execute Transaction**
  - Description: Event emitted when a transaction is executed.

- **Queue Transaction**
  - Description: Event emitted when a transaction is queued.



## External Functions

### Queue Transaction

Queues a transaction for execution.

| Parameter  | Description                                         |
|------------|-----------------------------------------------------|
| `target`   | Address to send the transaction to.                 |
| `eta`      | Duration of time until transaction can be executed, in blocks. |
| `value`    | Amount of ETH to be sent with transaction.         |
| `data`     | Calldata to be sent with transaction.               |
| `signature`| Signature of transaction.                           |

### Execute Transaction

Executes a queued transaction if the delay has passed.

| Parameter  | Description                                         |
|------------|-----------------------------------------------------|
| `target`   | Address to send the transaction to.                 |
| `eta`      | Duration of time until transaction can be executed, in blocks. |
| `value`    | Amount of ETH to be sent with transaction.         |
| `data`     | Calldata to be sent with transaction.               |
| `signature`| Signature of transaction.                           |

### Cancel Transaction

Cancels a queued transaction before execution.

| Parameter  | Description                                         |
|------------|-----------------------------------------------------|
| `target`   | Address to send the transaction to.                 |
| `eta`      | Duration of time until transaction can be executed, in blocks. |
| `value`    | Amount of ETH to be sent with transaction.         |
| `data`     | Calldata to be sent with transaction.               |
| `signature`| Signature of transaction.                           |

### Set Delay

Sets the delay for queuing transactions.

| Parameter | Description         |
|-----------|---------------------|
| `_delay`  | New Timelock delay. |
