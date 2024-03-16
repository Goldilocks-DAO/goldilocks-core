# Goldilend Smart Contract

  

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

- **hj**: Address of Honeyjar multisig.

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

- **porridgeMultiple**: uint256 representing the amount of porridge emitted per staked GiGBT annually. 

- **slope**: uint256 representing the rate at which the interest rate increases as a function of loan duration.

- **minDuration**: uint256 representing the minimum loan duration.

- **maxDuration**: uint256 representing the maximum loan duration.

- **multisigClaims**: uint256 representing the rewards available to be claimed by the Goldilocks DAO multisig.

- **honeyjarClaims**: uint256 representing the rewards available to be claimed by the honeyjar multisig.

- **multisigShare**: uint256 representing the portion of interest payments paid to Goldilocks DAO.

- **honeyjarShare**: uint256 representing the portion of interest payments paid to honeyjar.

- **ANNUAL_PORRIDGE_EMISSIONS**: uint256 representing the annual porridge emissions.

- **claimablePrgPerGiBGTStored**: uint256 representing the claimable PORRIDGE per GiBGT stored.

- **lastPrgUpdateTime**: uint256 representing the last time claimable PORRIDGE was updated.

- **totalStakedGiBGT**: uint256 representing the total staked GiBGT.

- **rewardTokens**: Array of addresses representing reward tokens.

- **borrowingActive**: bool indicating if borrowing is active.

## Constructor

constructs contract and sets initial values for state variables. 

### Parameters

- **_goldilocked**: Address of Goldilocked.

- **_timelock**: Address of the Goldilocks DAO timelock.

- **_multisig**: Address of the Goldilocks DAO multisig.

- **_hj**: Address of Honeyjar.

- **_ibgt**: Address of iBGT.

- **_ibgtVault**: Address of iBGTVault.

- **_partnerNFTs**: Array of partnership NFTs.

- **_partnerNFTBoosts**: Array of partnership NFT boosts.

- **_rewardTokens**: Array of reward tokens from iBGT staking.

  

## Functions

  

### name

Returns the name of the GiBGT token.

  

### symbol

Returns the symbol of the GiBGT token.

## View Functions

### lookupLoans
- **Description**: Returns the details of all loans originated from a user.
- **Parameters**:
  - `user`: Originator of the loan.
- **Returns**: Array of Loan structs representing user's loans.

### lookupLoan
- **Description**: Returns the details of a specific loan.
- **Parameters**:
  - `user`: Originator of the loan.
  - `userLoanId`: ID of the loan.
- **Returns**: Loan struct representing the specified loan.

### lookupBoost
- **Description**: Returns the details of a boost.
- **Parameters**:
  - `user`: Owner of the boost.
- **Returns**: Boost struct representing the user's boost.

### userClaimablePrg
- **Description**: Returns the claimable PORRIDGE of GiBGT staker.
- **Parameters**:
  - `user`: GiBGT staker address.
- **Returns**: uint256 representing the claimable PORRIDGE.

### getGiBGTRatio
- **Description**: Returns the current ratio of GiBGT supply to the amount of iBGT in the lendingpool.
- **Returns**: uint256 representing the GiBGT ratio.

### getFairValues
- **Description**: Returns the fair value of NFTs (as %'s of the total valuation). 
- **Parameters**:
  - `collateralNFTs`: Array of collateral NFTs.
- **Returns**: uint256 representing the fair value of NFTs.
## External Functions

### boost (for adding single NFT's to boosts)
- **Description**: Locks partner NFT to receive a boost on staking yield and discounted borrowing rates.
- **Parameters**:
  - `partnerNFT`: NFT address to transfer to this contract.
  - `partnerNFTId`: Token ID of NFT to be transferred.
  
### boost  (for adding multiple NFT's to boosts)
- **Description**: Locks partner NFTs to receive a boost on staking yield and discounted borrowing rates.
- **Parameters**:
  - `partnerNFTs`: Array of NFT addresses to transfer to this contract.
  - `partnerNFTIds`: Array of token IDs for NFTs to be transferred.

### withdrawBoost
- **Description**: Claims NFT's from expired boosts.

### lock
- **Description**: Locks iBGT into lending pool and mints GiBGT.
- **Parameters**:
  - `amount`: Amount of iBGT to lock.

### stake
- **Description**: Stakes GiBGT.
- **Parameters**:
  - `amount`: Amount of GiBGT to stake.

### unstake
- **Description**: Unstakes GiBGT.
- **Parameters**:
  - `amount`: Amount of GiBGT to unstake.

### claim
- **Description**: Claims GiBGT staking rewards (PORRIDGE and other reward tokens).

### updateClaimableRewards
- **Description**: Updates claimable rewards from iBGT staking.

### borrow (for loans with 1 NFT as collateral)
- **Description**: Borrows iBGT against the value of NFT.
- **Parameters**:
  - `borrowAmount`: Amount of iBGT to borrow.
  - `duration`: Duration of the loan.
  - `collateralNFT`: NFT collection to use as collateral.
  - `collateralNFTId`: Token ID of the NFT to use as collateral.

### borrow  (for loans with > 1 NFT as collateral)
- **Description**: Borrows iBGT against the value of NFTs.
- **Parameters**:
  - `borrowAmount`: Amount of iBGT to borrow.
  - `duration`: Duration of the loan.
  - `collateralNFTs`: Array of NFT collections to use as collateral.
  - `collateralNFTIds`: Array of token IDs of NFTs to use as collateral.

### repay
- **Description**: Repays borrowed iBGT.
- **Parameters**:
  - `repayAmount`: Amount of iBGT to repay.
  - `userLoanId`: ID of the loan to repay.

### liquidate
- **Description**: Liquidates overdue loans by paying iBGT to purchase collateral.
- **Parameters**:
  - `user`: Owner of the loan to be liquidated.
  - `userLoanId`: Loan to be liquidated.
## Internal Functions

### _updateClaimablePrg
- **Description**: Updates claimable PORRIDGE for GiBGT stakers
- **Parameters**:
  - `user`: Address to update claimable PORRIDGE for.

### _updateClaimableRewards
- **Description**: Updates claimable rewards for GiBGT stakers.
- **Parameters**:
  - `user`: Address to update claimable rewards for.

### _claimPrg
- **Description**: Calculates and distributes PORRIDGE to the claimer.
- **Parameters**:
  - `claimer`: User that is claiming PORRIDGE.
  - `claimable`: Amount of PORRIDGE to be claimed.

### _claimRewards
- **Description**: Calculates and distributes rewards to the claimer.
- **Parameters**:
  - `claimer`: User that is claiming rewards.

### _calculateClaimablePrg
- **Description**: Calculates claimable PORRIDGE for the user.
- **Parameters**:
  - `user`: Address to calculate claimable PORRIDGE for.
- **Returns**: The amount of claimable PORRIDGE.

### _calculateClaimableRewards
- **Description**: Calculates claimable rewards for the user.
- **Parameters**:
  - `user`: Address to calculate claimable rewards for.
  - `rewardToken`: Reward token to calculate claimable rewards for.
  - `outstandingRewards`: Outstanding rewards available.
- **Returns**: The amount of claimable rewards.

### _claimablePrgPerGiBGT
- **Description**: Calculates claimable $PRG per $GiBGT.
- **Returns**: The claimable $PRG per $GiBGT.

### _claimableRewardPerGiBGT
- **Description**: Calculates total claimable rewards per GiBGT since deployment.
- **Parameters**:
  - `rewardToken`: Token to calculate claimable rewards for.
  - `outstandingRewards`: Outstanding rewards available.
- **Returns**: The total claimable rewards per GiBGT since deployment. 

### _calculateFairValue
- **Description**: Calculates the fair value of NFT's being borrowed against.
- **Parameters**:
  - `collateralNFTs`: NFT to find total value of.
- **Returns**: The total fair value of NFT's.

### _calculateInterest
- **Description**: Calculates the total interest due at repayment of a loan.
- **Parameters**:
  - `borrowAmount`: Amount to be borrowed.
  - `debt`: Current amount of outstanding debt in protocol.
  - `duration`: Duration of the loan.
- **Returns**: The total interest due at repayment.

### _lookupLoan
- **Description**: Finds the loan by userId.
- **Parameters**:
  - `user`: User address.
  - `userLoanId`: ID of the loan to be found.
- **Returns**: The loan details and index.

### _refreshiBGT
- **Description**: Stakes iBGT in Infrared vault.
- **Parameters**:
  - `ibgtAmount`: Amount of iBGT to stake.

### _GiBGTMintAmount
- **Description**: Calculates the amount of GiBGT to mint for locked iBGT.
- **Parameters**:
  - `lockAmount`: Amount of iBGT to lock.
- **Returns**: The total supply of GiBGT divided by the lending pool size multiplied by amount locked.

### _GiBGTRatio
- **Description**: Calculates the current ratio of GiBGT supply to lending pool size.
- **Returns**: The total supply of GiBGT divided by the lending pool size.

### _buildBoost (1 NFT boost)
- **Description**: Creates the struct containing the details of the boost.
- **Parameters**:
  - `partnerNFT`: NFT address to transfer to this contract.
  - `partnerNFTId`: Token ID of NFT to be transferred.
- **Returns**: The boost struct.

### _buildBoost (> 1 NFT boost)
- **Description**: Creates the struct containing the details of the boost.
- **Parameters**:
  - `partnerNFTs`: Array of NFT addresses to transfer to this contract.
  - `partnerNFTIds`: Array of token IDs for NFTs to be transferred.
- **Returns**: The boost struct.

### _updateInterestClaims
- **Description**: Update internal variables tracking the amount of interest revenue for Goldilocks DAO multisig and AP DAO multisig.
- **Parameters**:
  - `interest`: Interest paid during repayment.
## Permissioned Functions

### changeValue
- **Description**: Allows the DAO to adjust the valuation of the NFTs to borrow against.
- **Parameters**:
  - `_totalValuation`: Total valuation of all NFTs able to be borrowed against.
  - `_nfts`: NFTs that are able to be borrowed against.
  - `_nftFairValues`: Percentage each NFT is valued as a proportion of the total valuation.

### changeProtocolInterestRate
- **Description**: Allows the DAO to adjust the basic interest rate for the protocol.
- **Parameters**:
  - `_protocolInterestRate`: New basic interest rate.

### changeShareRates
- **Description**: Allows the DAO to adjust shares of interest payment.
- **Parameters**:
  - `_multisigShare`: New share for Goldilocks DAO multisig.
  - `_honeyjarShare`: New share for AP DAO.

### changeSlope
- **Description**: Allows the DAO to adjust the rate at which the basic interest rate scales with time.
- **Parameters**:
  - `_slope`: New slope.

### changeDurations
- **Description**: Allows the DAO to adjust the min and max duration of loans.
- **Parameters**:
  - `_minDuration`: New minimum duration.
  - `_maxDuration`: New maximum duration.

### changePrgEmissions
- **Description**: Allows the DAO to change PORRIDGE emissions.
- **Parameters**:
  - `newPrgEmissions`: Sets the annual PORRIDGE emission rate for GiBGT staking.

### addRewardTokens
- **Description**: Allows multisig to add yield tokens to Goldilend.
- **Parameters**:
  - `_rewardTokens`: Tokens to add to yieldTokens array.

### changeBorrowingActive
- **Description**: Allows multisig to activate or inactivate lending.
- **Parameters**:
  - `_borrowingActive`: Value that activates or inactivates.

### multisigInterestClaim
- **Description**: Allows the Goldilocks DAO multisig to claim revenue from interest.

### honeyjarInterestClaim
- **Description**: Allows the AP DAO multisig to claim revenue from interest..

### initializeProtocol
- **Description**: Allows the multisig to initialize the protocol and set key parameters. 
- **Parameters**:
  - `_nfts`: NFTs that are able to be borrowed against.
  - `_nftFairValues`: Percentage each NFT is valued as a proportion of the total valuation.
  - `_totalValuation`: Total valuation of all NFTs able to be borrowed against.
  - `_multisigShare`: New share for multisig.
  - `_honeyjarShare`: New share for honeyjar.
  - `_minDuration`: New minimum duration.
  - `_maxDuration`: New maximum duration.
  - `_startingPoolSize`: Initial pool size.

### sunsetProtocol
- **Description**: Allows the DAO to sunset protocol and withdraw all funds from the lending pool. 

## Implementation Function

### onERC721Received
- **Description**: Receives ERC721 tokens.
- **Returns**: The ERC721Receiver selector.





