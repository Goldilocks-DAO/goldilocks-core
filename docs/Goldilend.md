﻿# Goldilend Smart Contract

  

  

  

## Description

  

  

Goldilend is a smart contract for fixed term Bong Bear (and rebase) NFT Lending.

  

  

  

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

  

  

- IERC721
- IERC721Receiver
- Goldilocked

  

  

- iBGTVault

  

  

  

## Structs

  

  

  

### Loan

  

  

- **collateralNFTs**: Array of addresses representing collateral NFTs for the loan.

  

  

- **collateralNFTIds**: Array of uint256 representing collateral NFT IDs.

  

  

- **borrowedAmount**: uint256 representing the borrowed amount (including interest).

  

  

- **interest**: uint256 representing the interest.

  

  

- **duration**: uint256 representing the duration.

  

  

- **endDate**: uint256 representing the end date.

  

  

- **loanId**: uint256 representing the loan ID.

  

  

- **liquidated**: bool indicating if the loan has been liquidated.

  

  

  

### Boost

  

  

- **partnerNFTs**: Array of addresses representing locked partner NFT's generating user boost.

  

  

- **partnerNFTIds**: Array of uint256 representing ID's of the user's locked partner NFT's.

  

  

- **boostMagnitude**: uint256 representing the total magnitude of user boost (as a fraction of 1000).

  

  

- **expiry**: uint256 representing the expiry of the boost.

  

  

  

## State Variables

  

  

- **goldilocked**: Address of Goldilocked Contract.

  

  

- **hj**: Address of apdao multisig.

  

  

- **ibgt**: Address of iBGT token.

  

  

- **ibgtVault**: Address of iBGTVault contract.

  

  

- **multisig**: Address of Goldilocks DAO multisig.

  

  

- **timelock**: Address of GoldilocksDAO timelock contract.

  

  

- **boosts**: Mapping of Boosts associated with addresses.

  

  

- **loans**: Mapping of Loans associated with addresses.

  

  

- **partnerNFTBoosts**: Mapping of partner NFT's to associated boosts (as fractions of 1000).

  

  

- **nftFairValues**: Mapping of NFT's to fair values (as %'s of totalValuation).

  

  

- **stakedGiBGT**: Mapping of staked GiBGT associated with addresses.

  

  

- **claimablePrg**: Mapping of claimable PORRIDGE associated with addresses.

  

  

- **prgPerTokenDebt**: Mapping of PORRIDGE per token debt associated with addresses.

  

  

- **claimableRewardsPerGiBGTStored**: Mapping of claimable rewards per GiBGT stored for each reward token.

  

  

- **lastRewardUpdateTime**: Uint representing the last update of claimable rewards.

  

  

- **outstandingRewardsPerReward**: Mapping of outstanding rewards for each reward token.

  

  

- **claimableRewards**: Double mapping of claimable rewards associated with addresses.

  

  

- **rewardPerTokenDebt**: Double mapping of reward per token debt associated with addresses.

  

  

- **deployTime**: uint256 representing the deployment time.

  

  

- **totalValuation**: uint256 representing the total valuation of NFT's.

  

  

- **protocolInterestRate**: uint256 representing the protocol interest rate.

  

  

- **outstandingDebt**: uint256 representing the cumulative outstanding debt of unpaid loans.

  

  

- **poolSize**: uint256 representing the lending pool size.

  

  

- **boostLockDuration**: uint256 representing the required length of partner NFT locks in order to gain boost.

  

  

- **slope**: uint256 representing the rate at which the interest rate increases as a function of loan duration.

  

  

- **minDuration**: uint256 representing the minimum loan duration.

  

  

- **maxDuration**: uint256 representing the maximum loan duration.

  

  

- **multisigClaims**: uint256 representing the rewards available to be claimed by the Goldilocks DAO multisig.

  

  

- **apdaoClaims**: uint256 representing the rewards available to be claimed by the apdao multisig.

  

  

- **multisigShare**: uint256 representing the portion of interest payments paid to Goldilocks DAO.

  

  

- **apdaoShare**: uint256 representing the portion of interest payments paid to apdao.

  

  

- **annualPrgEmissions**: uint256 representing the annual porridge emissions.

  

  

- **claimablePrgPerGiBGTStored**: uint256 representing the claimable PORRIDGE per GiBGT stored.

  

  

- **lastPrgUpdateTime**: uint256 representing the last time claimable PORRIDGE was updated.

  

  

- **totalStakedGiBGT**: uint256 representing the total staked GiBGT.

  

  

- **rewardTokens**: Array of addresses representing reward tokens.

  

  

- **borrowingActive**: bool indicating if borrowing is active.

  

  

## Constructor

  

  

Constructs contract and sets initial values for state variables.

  

  

### Parameters

  

  

- **_goldilocked**: Address of Goldilocked.

  

  

- **_timelock**: Address of the Goldilocks DAO timelock.

  

  

- **_multisig**: Address of the Goldilocks DAO multisig.

  

  

- **_apdao**: Address of apdao.

  

  

- **_ibgt**: Address of iBGT.

- **_ibgtVault**: Address of iBGTVault.

  

- **_rewardTokens**: Array of reward tokens from iBGT staking.

  

  

  

## Functions

  

  

  

### name

  

  

Returns the name of the GiBGT token.

  

  

  

### symbol

  

  

Returns the symbol of the GiBGT token.

  

  

## View Functions

  

  


### lookupLoans

- **Description**: Returns the details of all loans originated from a user.

| Parameter | Data Type | Description          |
|-----------|-----------|----------------------|
| `user`    | Address   | Originator of the loan |

- **Returns**: Array of Loan structs representing user's loans.

### lookupLoan

- **Description**: Returns the details of a specific loan.

| Parameter     | Data Type | Description                      |
|---------------|-----------|----------------------------------|
| `user`        | Address   | Originator of the loan           |
| `userLoanId`  | uint256   | ID of the loan                   |

- **Returns**: Loan struct representing the specified loan.

### lookupBoost

- **Description**: Returns the details of a boost.

| Parameter | Data Type | Description         |
|-----------|-----------|---------------------|
| `user`    | Address   | Owner of the boost  |

- **Returns**: Boost struct representing the user's boost.

### userClaimablePrg

- **Description**: Returns the claimable PORRIDGE of GiBGT staker.

| Parameter | Data Type | Description              |
|-----------|-----------|--------------------------|
| `user`    | Address   | GiBGT staker address    |

- **Returns**: uint256 representing the claimable PORRIDGE.

### getGiBGTRatio

- **Description**: Returns the current ratio of GiBGT supply to the amount of iBGT in the lending pool.

- **Returns**: uint256 representing the GiBGT ratio.

### getFairValues

- **Description**: Returns the fair value of NFTs (as %'s of the total valuation).

| Parameter         | Data Type | Description                      |
|-------------------|-----------|----------------------------------|
| `collateralNFTs`  | Array     | Array of collateral NFTs        |

- **Returns**: uint256 representing the fair value of NFTs.

  

## External Functions

### boost (for adding single NFT's to boosts)

- **Description**: Locks partner NFT to receive a boost on staking yield and discounted borrowing rates.

| Parameter     | Data Type | Description                               |
|---------------|-----------|-------------------------------------------|
| `partnerNFT`  | Address   | NFT address to transfer to this contract |
| `partnerNFTId`| uint256   | Token ID of NFT to be transferred         |

### boost  (for adding multiple NFT's to boosts)

- **Description**: Locks partner NFTs to receive a boost on staking yield and discounted borrowing rates.

| Parameter        | Data Type | Description                               |
|------------------|-----------|-------------------------------------------|
| `partnerNFTs`    | Array     | Array of NFT addresses to transfer to this contract |
| `partnerNFTIds`  | Array     | Array of token IDs for NFTs to be transferred       |

### withdrawBoost

- **Description**: Claims NFT's from expired boosts.

### lock

- **Description**: Locks iBGT into lending pool and mints GiBGT.

| Parameter | Data Type | Description                 |
|-----------|-----------|-----------------------------|
| `amount`  | uint256   | Amount of iBGT to lock     |

### stake

- **Description**: Stakes GiBGT.

| Parameter | Data Type | Description                 |
|-----------|-----------|-----------------------------|
| `amount`  | uint256   | Amount of GiBGT to stake   |

### unstake

- **Description**: Unstakes GiBGT.

| Parameter | Data Type | Description                 |
|-----------|-----------|-----------------------------|
| `amount`  | uint256   | Amount of GiBGT to unstake |

### claim

- **Description**: Claims GiBGT staking rewards (PORRIDGE and other reward tokens).

### updateClaimableRewards

- **Description**: Updates claimable rewards from iBGT staking.

### borrow (for loans with 1 NFT as collateral)

- **Description**: Borrows iBGT against the value of NFT.

| Parameter         | Data Type | Description                               |
|-------------------|-----------|-------------------------------------------|
| `borrowAmount`    | uint256   | Amount of iBGT to borrow                  |
| `duration`        | uint256   | Duration of the loan                      |
| `collateralNFT`   | Address   | NFT collection to use as collateral       |
| `collateralNFTId` | uint256   | Token ID of the NFT to use as collateral  |

### borrow  (for loans with > 1 NFT as collateral)

- **Description**: Borrows iBGT against the value of NFTs.

| Parameter           | Data Type | Description                                  |
|---------------------|-----------|----------------------------------------------|
| `borrowAmount`      | uint256   | Amount of iBGT to borrow                     |
| `duration`          | uint256   | Duration of the loan                         |
| `collateralNFTs`    | Array     | Array of NFT collections to use as collateral |
| `collateralNFTIds`  | Array     | Array of token IDs of NFTs to use as collateral |

### repay

- **Description**: Repays borrowed iBGT.

| Parameter     | Data Type | Description                 |
|---------------|-----------|-----------------------------|
| `repayAmount` | uint256   | Amount of iBGT to repay     |
| `userLoanId`  | uint256   | ID of the loan to repay     |

### liquidate

- **Description**: Liquidates overdue loans by paying iBGT to purchase collateral.

| Parameter     | Data Type | Description                           |
|---------------|-----------|---------------------------------------|
| `user`        | Address   | Owner of the loan to be liquidated    |
| `userLoanId`  | uint256   | Loan to be liquidated                 |


  

## Internal Functions

  

  


### _updateClaimablePrg

- **Description**: Updates claimable PORRIDGE for GiBGT stakers

| Parameter | Data Type | Description                            |
|-----------|-----------|----------------------------------------|
| `user`    | Address   | Address to update claimable PORRIDGE for |

### _updateClaimableRewards

- **Description**: Updates claimable rewards for GiBGT stakers.

| Parameter | Data Type | Description                            |
|-----------|-----------|----------------------------------------|
| `user`    | Address   | Address to update claimable rewards for |

### _claimPrg

- **Description**: Calculates and distributes PORRIDGE to the claimer.

| Parameter | Data Type | Description                            |
|-----------|-----------|----------------------------------------|
| `claimer` | Address   | User that is claiming PORRIDGE         |
| `claimable` | uint256  | Amount of PORRIDGE to be claimed       |

### _claimRewards

- **Description**: Calculates and distributes rewards to the claimer.

| Parameter | Data Type | Description                            |
|-----------|-----------|----------------------------------------|
| `claimer` | Address   | User that is claiming rewards          |

### _calculateClaimablePrg

- **Description**: Calculates claimable PORRIDGE for the user.

| Parameter | Data Type | Description                            |
|-----------|-----------|----------------------------------------|
| `user`    | Address   | Address to calculate claimable PORRIDGE for |

| Returns   | Data Type | Description                            |
|-----------|-----------|----------------------------------------|
|           | uint256   | The amount of claimable PORRIDGE       |

### _calculateClaimableRewards

- **Description**: Calculates claimable rewards for the user.

| Parameter         | Data Type | Description                                    |
|-------------------|-----------|------------------------------------------------|
| `user`            | Address   | Address to calculate claimable rewards for     |
| `rewardToken`     | Address   | Reward token to calculate claimable rewards for |
| `outstandingRewards` | uint256 | Outstanding rewards available                   |

| Returns   | Data Type | Description                                   |
|-----------|-----------|-----------------------------------------------|
|           | uint256   | The amount of claimable rewards               |

### _claimablePrgPerGiBGT

- **Description**: Calculates claimable $PRG per $GiBGT.

| Returns   | Data Type | Description                                   |
|-----------|-----------|-----------------------------------------------|
|           | uint256   | The claimable $PRG per $GiBGT                |

### _claimableRewardPerGiBGT

- **Description**: Calculates total claimable rewards per GiBGT since deployment.

| Parameter         | Data Type | Description                                    |
|-------------------|-----------|------------------------------------------------|
| `rewardToken`     | Address   | Token to calculate claimable rewards for        |
| `outstandingRewards` | uint256 | Outstanding rewards available                   |

| Returns   | Data Type | Description                                    |
|-----------|-----------|------------------------------------------------|
|           | uint256   | The total claimable rewards per GiBGT since deployment |

### _calculateFairValue

- **Description**: Calculates the fair value of NFT's being borrowed against.

| Parameter         | Data Type | Description                                    |
|-------------------|-----------|------------------------------------------------|
| `collateralNFTs` | Array     | NFT to find total value of                     |

| Returns   | Data Type | Description                                    |
|-----------|-----------|------------------------------------------------|
|           | uint256   | The total fair value of NFT's                  |

### _calculateInterest

- **Description**: Calculates the total interest due at repayment of a loan.

| Parameter         | Data Type | Description                                    |
|-------------------|-----------|------------------------------------------------|
| `borrowAmount`    | uint256   | Amount to be borrowed                          |
| `debt`            | uint256   | Current amount of outstanding debt in protocol |
| `duration`        | uint256   | Duration of the loan                           |

| Returns   | Data Type | Description                                    |
|-----------|-----------|------------------------------------------------|
|           | uint256   | The total interest due at repayment            |

### _lookupLoan

- **Description**: Finds the loan by userId.

| Parameter         | Data Type | Description                                    |
|-------------------|-----------|------------------------------------------------|
| `user`            | Address   | User address                                   |
| `userLoanId`      | uint256   | ID of the loan to be found                     |

| Returns   | Data Type | Description                                    |
|-----------|-----------|------------------------------------------------|
|           |           | The loan details and index                     |

### _refreshiBGT

- **Description**: Stakes iBGT in Infrared vault.

| Parameter         | Data Type | Description                                    |
|-------------------|-----------|------------------------------------------------|
| `ibgtAmount`      | uint256   | Amount of iBGT to stake                        |

### _GiBGTMintAmount

- **Description**: Calculates the amount of GiBGT to mint for locked iBGT.

| Parameter         | Data Type | Description                                    |
|-------------------|-----------|------------------------------------------------|
| `lockAmount`      | uint256   | Amount of iBGT to lock                         |

| Returns   | Data Type | Description                                    |
|-----------|-----------|------------------------------------------------|
|           | uint256   | The total supply of GiBGT divided by the lending pool size multiplied by amount locked |

### _GiBGTRatio

- **Description**: Calculates the current ratio of GiBGT supply to lending pool size.

| Returns   | Data Type | Description                                    |
|-----------|-----------|------------------------------------------------|
|           | uint256   | The total supply of GiBGT divided by the lending pool size |

### _buildBoost (1 NFT boost)

- **Description**: Creates the struct containing the details of the boost.

| Parameter         | Data Type | Description                                    |
|-------------------|-----------|------------------------------------------------|
| `partnerNFT`      | Address   | NFT address to transfer to this contract       |
| `partnerNFTId`    | uint256   | Token ID of NFT to be transferred              |

| Returns   | Data Type | Description                                    |
|-----------|-----------|------------------------------------------------|
|           |           | The boost struct                               |

### _buildBoost (> 1 NFT boost)

- **Description**: Creates the struct containing the details of the boost.

| Parameter         | Data Type | Description                                    |
|-------------------|-----------|------------------------------------------------|
| `partnerNFTs`     | Array     | Array of NFT addresses to transfer to this contract |
| `partnerNFTIds`   | Array


  

## Permissioned Functions

  


### changeValue

- **Description**: Revise the valuation of the NFT's. 

| Parameter         | Data Type | Description                                        |
|-------------------|-----------|----------------------------------------------------|
| `_nfts`           | Array     | Array of NFT addresses that are adjustable for valuation. |
| `_nftFairValues`  | Array     | Array of percentage values representing the fair value of each NFT. |
| `_totalValuation` | uint256   | Total valuation of all NFTs.                      |

**Access Control:** Only callable by the timelock.

### changeProtocolInterestRate

- **Description**: Change the basic interest rate for NFT loans.

| Parameter              | Data Type | Description                                   |
|------------------------|-----------|-----------------------------------------------|
| `_protocolInterestRate`| uint256   | New basic interest rate.                      |

**Access Control:** Only callable by the timelock.

### changeShareRates

- **Description**: Change the % of interest payments taken as a fee by Goldilocks and/or AP DAO. 

| Parameter     | Data Type | Description                               |
|---------------|-----------|-------------------------------------------|
| `_multisigShare` | uint256   | New share for the Goldilocks DAO multisig.|
| `_apdaoShare`   | uint256   | New share for AP DAO.                      |

**Access Control:** Only callable by the timelock.

### changeSlope

- **Description**: Change the rate by which interest rates scale with duration. 

| Parameter | Data Type | Description                                        |
|-----------|-----------|----------------------------------------------------|
| `_slope`  | uint256   | New slope.                                         |

**Access Control:** Only callable by the timelock.

### changeDurations

- **Description**: Change minimum and maximum durations of loans. 

| Parameter       | Data Type | Description                             |
|-----------------|-----------|-----------------------------------------|
| `_minDuration`  | uint256   | New minimum duration.                   |
| `_maxDuration`  | uint256   | New maximum duration.                   |

**Access Control:** Only callable by the timelock.

### changePrgEmissions

- **Description**: Change rate of PORRIDGE emissions for GiBGT stakers. 

| Parameter          | Data Type | Description                                             |
|--------------------|-----------|---------------------------------------------------------|
| `newPrgEmissions`  | uint256   | New annual PORRIDGE emission rate for GiBGT staking.    |

**Access Control:** Only callable by the timelock.

### addRewardTokens
- **Description**: Add tokens that can be claimed as rewards by GiBGT stakers. 

| Parameter       | Data Type | Description                                     |
|-----------------|-----------|-------------------------------------------------|
| `_rewardTokens` | Array     | Tokens to add to the yieldTokens array.        |

**Access Control:** Only callable by the multisig.

### changeBorrowingActive

- **Description**: Set whether borrowing is active 

| Parameter          | Data Type | Description                                    |
|--------------------|-----------|------------------------------------------------|
| `_borrowingActive` | bool      | Value that activates or deactivates lending.   |

**Access Control:** Only callable by the multisig.

### multisigInterestClaim

- **Description**: Claim outstanding interest fees for Goldilocks DAO

**Access Control:** Only callable by the multisig.

### apdaoInterestClaim

- **Description**: Claim outstanding interest fees for AP DAO

**Access Control:** Only callable by the AP DAO multisig.

### initializeParameters

- **Description**: Sets initial values of relevant parameters

| Parameter                 | Data Type | Description                           |
|----------------------|-----------|---------------------------------------|
| `_multisigShare`     | `uint256` | Share for the Goldilocks DAO multisig.|
| `_apdaoShare`        | `uint256` | Share for AP DAO.                     |
| `_minDuration`       | `uint256` | Minimum duration of loans.            |
| `_maxDuration`       | `uint256` | Maximum duration of loans.            |
| `_startingPoolSize`  | `uint256` | Initial size of the lending pool.     |
| `_protocolInterestRate` | `uint256` | Basic interest rate for the protocol. |
| `_slope`             | `uint256` | Rate at which the basic interest rate scales with time. |
| `_annualPrgEmissions` | `uint256` | Annual PORRIDGE emission rate for GiBGT staking. |
| `_boostLockDuration` | `uint256` | Duration of boost lock.               |

**Access Control:** Only callable by the multisig.

### initializeBeras

- **Description**: Sets initial valuations of NFT's. 

| Parameter                 | Data Type           | Description                                    |
|----------------------|---------------------|------------------------------------------------|
| `_totalValuation`    | `uint256`           | Total valuation of all NFTs.                   |
| `_nfts`              | `address[] calldata` | Array of NFT addresses adjustable for valuation. |
| `_nftFairValues`     | `uint256[] calldata` | Array of percentage values representing the fair value of each NFT. |

**Access Control:** Only callable by the multisig.

### initializePartners

- **Description**: Sets initial boosts of partner NFT's. 

| Parameter                 | Data Type     | Description                                   |
|----------------------|---------------|-----------------------------------------------|
| `_partnerNFTs`      | `address[] memory` | Array of partnership NFT addresses.             |
| `_partnerNFTBoosts` | `uint8[] memory`   | Array of boost values associated with each NFT.|


**Access Control:** Only callable by the multisig.

### adjustBoosts

- **Description**: Adjusts partner NFT boosts


| Parameter                 | Data Type     | Description                                   |
|----------------------|---------------|-----------------------------------------------|
| `_partnerNFTs`      | `address[] memory` | Array of partnership NFT addresses.             |
| `_partnerNFTBoosts` | `uint8[] memory`   | Array of new boost values associated with each NFT.|
| `_boostLockDuration`| `uint256`     | Duration of boost lock.   

**Access Control:** Only callable by the timelock.


            

### sunsetProtocol

- **Description**: Withdraws funds from lending pool to sunset protocol.

**Access Control:** Only callable by the timelock.

  

  

  

  

## Implementation Function

  

  

### onERC721Received

  

- **Description**: Receives ERC721 tokens.

  

- **Returns**: The ERC721Receiver selector.