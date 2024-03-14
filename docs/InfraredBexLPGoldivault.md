# InfraredBexLPGoldivault Technical Documentation

## Table of Contents

- [Introduction](#introduction)
- [Overview](#overview)
- [Constructor](#constructor)
- [Inherited Functions](#inherited-functions)

## Introduction

InfraredBexLPGoldivault is a child of the Goldivault contract intended for BEX LP vaults on Infrared. Users deposit the relevant LP tokens from BEX in exchange for ownership and yield tokens, and the contract deposits those LP's in the corresponding Infrared Vault and stores (and compounds) the yield until its expiry. 

## Overview

InfraredBexLPGoldivault inherits from the Goldivault contract and implements additional functionality specific to BEX LP tokens.

## Constructor

The constructor initializes the InfraredBexLPGoldivault contract with specified parameters and calls the constructor of the parent Goldivault contract to set up the initial state.

## Inherited Functions

The InfraredBexLPGoldivault contract inherits several functions from the Goldivault contract and provides custom implementations for the following functions:

### _vaultDeposit

Internal function for depositing BEX LP tokens into the relevant Infrared vault. It calls the `stake` function of the BexLPVault contract to stake the specified amount of tokens.

| Name    | Data Type | Description                                    |
|---------|-----------|------------------------------------------------|
| amount  | uint256   | Amount of BexLP tokens to deposit             |

### _unstakeDepositToken

Internal function for withdrawing BEX LP tokens from the vault. It calls the `withdraw` function of the BexLPVault contract to withdraw the specified amount of tokens.

| Name    | Data Type | Description                                    |
|---------|-----------|------------------------------------------------|
| amount  | uint256   | Amount of BexLP tokens to withdraw            |

### _concludeVaultRewards

Internal function for recalling all staked assets and claiming all rewards at the conclusion of the vault. It calls the `exit` function of the BexLPVault and iBGTVault contracts to withdraw assets and claim outstanding rewards.

### _compoundVaultRewards

Internal function for compounding vault rewards. It calls the `getReward` function of the BexLPVault and iBGTVault contracts to claim rewards, distributes the yield fee to the multisig wallet, and restakes the remaining IBGT rewards.

This concludes the technical documentation of the InfraredBexLPGoldivault smart contract.

