﻿  

# Goldivault Technical Documentation


  

## Introduction

  

The Goldivault contract is the base template contract for Goldilocks' yield splitting vaults, which allow users to seperate ownership of the future yield of an asset (earned through Infrared's vaults) from ownership of the asset itself.

## License 
SPDX-License-Identifier: MIT 

## Version 
Solidity ^0.8.20

## Authors  
 ampnoob & geeb
## Imports
  FixedPointMathLib - SafeTransferLib - ERC20 - IGoldivault - OnwershipToken - YieldToken
  

## State Variables

  

- `startTime`: Timestamp indicating the start time of the vault.

- `endTime`: Timestamp indicating the end time of the vault.

- `concludeTime`: Timestamp indicating the time when the vault was concluded.

- `earlyWithdrawalFee`: Fee charged for early withdrawal, expressed as a percentage.

- `yieldFee`: Fee charged for yield, expressed as a percentage.

- `delay`: Delay period after the vault concludes before redemption is allowed, in seconds.

- `duration`: Duration of the vault, in seconds.

- `ot`: Address of the ownership token contract.

- `yt`: Address of the yield token contract.

- `depositToken`: Address of the token used for deposits.

-  `depositTokenAmount`: Amount of deposit token in vault

- `depositVault`: Address of Infrared's vault for the deposit asset.

- `ibgt`: Address of IBGT token.

- `ibgtVault`: Address of Infrared's IBGT vault.

- `multisig`: Address of Goldilocks DAO's multisig wallet.

- `yieldTokens`: Array of addresses representing tokens that can be claimed as rewards by yield token holders.

- `concluded`: Bool indicating whether the vault is concluded.

  

## Constructor

  

The constructor initializes the Goldivaults contract, sets the initial values for the state variables, and approves token allowances to enable to contract to deposit assets into the relevant Infrared vaults.

  

## Errors

  

The contract defines several custom errors to handle exceptional conditions.

  

- `InsufficientTime`: Indicates insufficient time remaining for token deposits.

- `InvalidRedemption`: Indicates an invalid redemption request.

- `NotExpired`: Indicates an attempt to inappropriately perform an operation before expiry.

- `NotConcluded`: Indicates an attempt to inappropriately perform an operation conclusion or renewal.

- `NotMultisig`: Indicates an unauthorized attempt to exectue a permissioned function intended only for the DAO multisig.

- `AlreadyConcluded`: Indicates an attempt to inappropriately perform an operation on an already concluded vault.

- `ExcessiveRedeem`: Indicates an attempt to redeem an excessive amount.

  

## External Functions

  

### deposit

  

Allows users to deposit assets into the vault to receive ownership and yield tokens. The function calculates the ratio of time remaining until expiry to the total vault duration and mints yield tokens in that proportion to the number of deposit tokens deposited. Ownership tokens are minted at a 1:1 ratio to deposited deposit tokens.

  

| Name  | Data Type | Description  |
|---------|-----------|------------------------------------------------|
| amount  | uint256 | Amount of tokens to deposit  |

  

### redeemYield

  

Allows users to redeem yield tokens for a share of the yield accrued to the vault. A user is able to claim a proportion of the yield held in the vault equal to the ratio of their burned yield tokens to the total yield token supply.

  

| Name  | Data Type | Description  |
|---------|-----------|------------------------------------------------|
| amount  | uint256 | Amount of yield tokens to redeem |

  

### redeemOwnership

  

Allows users to withdraw ownership tokens from the vault. The function allows users to withdraw their deposited tokens and calculates the early withdrawal fee if applicable. To withdraw n deposit tokens, the user needs to burn n ownership tokens and x*n yield tokens, where x is the ratio of time remaining until vault expiry to the total vault duration.

  

| Name  | Data Type | Description  |
|---------|-----------|------------------------------------------------|
| amount  | uint256 | Amount of tokens to redeem |

  

### conclude

  

Concludes the vault at expiry. Once the vault reaches its end time, this function can be called to mark the vault as concluded and initiate the distribution of rewards.

  

### renew

  

Allows the multisig wallet to renew a concluded vault. If the vault has been concluded, this function can be called by the multisig wallet to renew the vault for another duration (beginning at the moment of renewal).

  

### compound

  

Compounds ibgt yield from the vault and restakes it. This function reinvests the accrued ibgt yield back into the vault to compound returns.

  

### addYieldTokens

  

Allows the multisig wallet to add yield tokens to the vault. This function enables the DAO to expand the variety of rewards that can be claimed by yield token holders.

  

| Name | Data Type  | Description  |
|--------------|----------------|--------------------------------------------|
| _yieldTokens | address[] calldata | Tokens to add to yieldTokens array |


  

### changeProtocolParameters

Allows DAO to set protocol parameters

| Name | Data Type  | Description  |
|--------------|----------------|--------------------------------------------|
| _earlyWithdrawalFee | uint256 | New early withdrawal fee |
| _yieldFee           | uint256 | New vault fee            |
| _delay | uint256 | New vault delay |
| _duration | uint256 | New vault duration |



  



  

## Inheritable Functions

  

The contract defines several functions that can be overridden by inheriting contracts for custom implementations

- `_vaultDeposit`: Internal function for depositing assets into the vault.

- `_concludeVaultRewards`: Internal function for concluding vault rewards.

- `_compoundVaultRewards`: Internal function for compounding vault rewards.

- `_unstakeDepositToken`: Internal function for withdrawing tokens from the vault.

