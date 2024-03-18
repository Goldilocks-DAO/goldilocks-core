
# Goldigovernor Smart Contract Documentation

  

## Description


Goldigovernor is a governance contract for Goldilocks DAO, forked from Uniswap governance contracts.

  ## License

SPDX-License-Identifier: MIT

## Version

Solidity ^0.8.20

## Authors

ampnoob - geeb

## Imports
Timelock-Govlocks-Goldiswap

## Structs & Enums

  

### Proposal

- **Description**: Represents a governance proposal.

- `targets`: Array of contract addresses targeted by the proposal.

- `signatures`: Array of function signatures corresponding to the calls to be made.

- `calldatas`: Array of encoded data for function calls.

- `values`: Array of ETH values to be sent with each call.

- `proposer`: Address of the proposer.

- `id`: Proposal ID.

- `eta`: Timestamp when the proposal will be executable.

- `startBlock`: Block number when voting starts.

- `endBlock`: Block number when voting ends.

- `forVotes`: Total number of votes in favor of the proposal.

- `againstVotes`: Total number of votes against the proposal.

- `abstainVotes`: Total number of abstaining votes.

- `cancelled`: Bool indicating if the proposal is cancelled.

- `executed`: Bool indicating if the proposal is executed.

- `receipts`: Mapping of voter addresses to their voting receipts.

  

### Receipt

- **Variables**:

- `support`: Indicates whether the voter supports the proposal.

- `votes`: Number of votes the voter cast.

- `hasVoted`: Bool indicating if the voter has voted.

  

### ProposalState

- **Description**: Enum representing the state of a proposal.

  

## State Variables

  

- `name`: Name of the contract.

- `MIN_PROPOSAL_THRESHOLD`: Minimum proposal threshold.

- `MAX_PROPOSAL_THRESHOLD`: Maximum proposal threshold.

- `MIN_VOTING_PERIOD`: Minimum voting period (in blocks).

- `MAX_VOTING_PERIOD`: Maximum voting period (in blocks).

- `MIN_VOTING_DELAY`: Minimum voting delay (in blocks).

- `MAX_VOTING_DELAY`: Maximum voting delay (in blocks).

- `proposalMaxOperations`: Maximum transactions in one proposal.

- `quorumVotes`: Amount of votes required to reach quorum -- 5% of LOCKS supply.

- `DOMAIN_TYPEHASH`: Typehash of ERC721Domain.

- `BALLOT_TYPEHASH`: Typehash of ballot.

- `timelock`: Address of Timelock contract.

- `govlocks`: Address of GovLocks contract.

- `multisig`: Address of multisig contract.

- `proposals`: Mapping of proposal IDs to proposals.

- `latestProposalIds`: Mapping of user addresses to their latest proposal IDs.

- `votingDelay`: Delay before voting on a proposal may take place (in blocks).

- `votingPeriod`: Period to vote on a proposal (in blocks).

- `proposalThreshold`: Number of votes required for a voter to become a proposer.

- `proposalCount`: Total number of proposals.

  

## Constructor

  


### Constructor

| Parameter           | Data Type | Description                                                  |
|---------------------|-----------|--------------------------------------------------------------|
| `_timelock`         | address   | Address of Timelock contract.                                |
| `_govlocks`         | address   | Address of GovLocks contract.                                |
| `_multisig`         | address   | Address of multisig contract.                                |
| `_votingPeriod`     | uint256   | Duration of voting on a proposal (in blocks).                |
| `_votingDelay`      | uint256   | Delay before voting on a proposal may take place (in blocks).|
| `_proposalThreshold`| uint256   | Number of votes required for a voter to become a proposer.   |

## Errors

- `ArrayMismatch`: Array length mismatch.
- `AlreadyProposing`: The user is already proposing.
- `AlreadyQueued`: Proposal is already queued.
- `AlreadyVoted`: Voter has already voted on the proposal.
- `AboveThreshold`: Voter has above-threshold voting power.
- `BelowThreshold`: Voter has below-threshold voting power.
- `InvalidVotingParameter`: Invalid voting parameter provided.
- `InvalidProposalAction`: Invalid proposal action attempted.
- `InvalidProposalState`: Invalid proposal state encountered.
- `InvalidVoteType`: Invalid vote type provided.
- `InvalidSignature`: Invalid function signature.
- `NotMultisig`: Address is not a multisig.
- `NotProposer`: Address is not the proposer.

## Events

- `ProposalCreated`: Triggered when a new proposal is created.
- `VoteCast`: Triggered when a vote is cast.
- `ProposalCanceled`: Triggered when a proposal is canceled.
- `ProposalQueued`: Triggered when a proposal is queued.
- `ProposalExecuted`: Triggered when a proposal is executed.
- `VotingDelaySet`: Triggered when the voting delay is set.
- `VotingPeriodSet`: Triggered when the voting period is set.
- `ProposalThresholdSet`: Triggered when the proposal threshold is set.
- `NewAdmin`: Triggered when a new admin is set.

## External Functions

### Propose

- **Description**: Proposes a new proposal, proposer must have delegates above the proposal threshold.

| Parameter   | Data Type | Description                                      |
|-------------|-----------|--------------------------------------------------|
| `targets`   | address[] | Target addresses for proposal calls.             |
| `values`    | uint256[] | Eth values for proposal calls.                   |
| `signatures`| bytes[]   | Function signatures for proposal calls.          |
| `calldatas` | bytes[]   | Calldatas for proposal calls.                    |
| `description`| string    | String description of the proposal.              |

- **Returns**: Id of the new proposal.
- **Errors**:
  - `BelowThreshold`: If the proposer has delegates below the proposal threshold.
  - `ArrayMismatch`: If arrays lengths do not match.
  - `InvalidProposalAction`: If the proposal action is invalid.
  - `AlreadyProposing`: If the proposer is already proposing.

### Queue

- **Description**: Queues a proposal if successful.

| Parameter   | Data Type | Description                                      |
|-------------|-----------|--------------------------------------------------|
| `proposalId`| uint256   | Id of the proposal to queue.                     |

- **Errors**:
  - `InvalidProposalState`: If the proposal state is invalid.

### Execute

- **Description**: Executes a queued proposal if eta has passed.

| Parameter   | Data Type | Description                                      |
|-------------|-----------|--------------------------------------------------|
| `proposalId`| uint256   | Id of the proposal to execute.                   |

- **Errors**:
  - `InvalidProposalState`: If the proposal state is invalid.

### Cancel

- **Description**: Cancels a proposal only if sender is the proposer, or proposer delegates dropped below proposal threshold.

| Parameter   | Data Type | Description                                      |
|-------------|-----------|--------------------------------------------------|
| `proposalId`| uint256   | Id of the proposal to cancel.                    |

- **Errors**:
  - `InvalidProposalState`: If the proposal state is invalid.
  - `NotProposer`: If the sender is not the proposer.
  - `AboveThreshold`: If the proposer delegates are above the proposal threshold.

### CastVote

- **Description**: Casts a vote for a proposal.

| Parameter   | Data Type | Description                                      |
|-------------|-----------|--------------------------------------------------|
| `proposalId`| uint256   | Id of the proposal to vote on.                   |
| `support`   | uint8     | Support value for the vote. 0=against, 1=for, 2=abstain. |

### CastVoteWithReason

- **Description**: Casts a vote for a proposal with a reason.

| Parameter   | Data Type | Description                                      |
|-------------|-----------|--------------------------------------------------|
| `proposalId`| uint256   | Id of the proposal to vote on.                   |
| `support`   | uint8     | Support value for the vote. 0=against, 1=for, 2=abstain. |
| `reason`    | string    | Reason given for the vote by the voter.          |

### CastVoteBySig

- **Description**: Casts a vote for a proposal by signature.

| Parameter   | Data Type | Description                                      |
|-------------|-----------|--------------------------------------------------|
| `proposalId`| uint256   | Id of the proposal to vote on.                   |
| `support`   | uint8     | Support value for the vote. 0=against, 1=for, 2=abstain. |
| `v`         | uint8     | v value of the signature.                        |
| `r`         | bytes32   | r value of the signature.                        |
| `s`         | bytes32   | s value of the signature.                        |

- **Errors**:
  - `InvalidSignature`: If the signature is invalid.

## Internal Functions

### Get Proposal State

- **Description**: Returns the state of a proposal.

| Parameter   | Data Type | Description                                      |
|-------------|-----------|--------------------------------------------------|
| `proposalId`| uint256   | Id of the proposal.                               |

- **Returns**: State of the proposal.
- **Errors**: None.

### Queue Or Revert Internal

- **Description**: Queues transaction if not already queued.

| Parameter   | Data Type | Description                                      |
|-------------|-----------|--------------------------------------------------|
| `target`    | address   | Target address of the transaction.               |
| `value`     | uint256   | Eth value of the transaction.                    |
| `signature` | bytes4    | Function signature of the transaction.           |
| `data`      | bytes     | Data of the transaction.                          |
| `eta`       | uint256   | Estimated time of arrival for the transaction.    |

- **Errors**:
  - `AlreadyQueued`: If the transaction is already queued.

### Cast Vote Internal

- **Description**: Casts a vote.

| Parameter   | Data Type | Description                                      |
|-------------|-----------|--------------------------------------------------|
| `voter`     | address   | Address that is casting the vote.                |
| `proposalId`| uint256   | Id of the proposal to vote on.                   |
| `support`   | uint8     | Support value for the vote. 0=against, 1=for, 2=abstain. |

- **Returns**: Number of votes cast by the voter.
- **Errors**:
  - `InvalidProposalState`: If the proposal state is invalid.
  - `InvalidVoteType`: If the vote type is invalid.
  - `AlreadyVoted`: If the voter has already voted.

### Get Chain ID

- **Description**: Returns the chain ID.


## Permissioned Functions

### Set Voting Delay

- **Description**: Sets the voting delay.

| Parameter       | Data Type | Description                                      |
|-----------------|-----------|--------------------------------------------------|
| `newVotingDelay`| uint256   | New voting delay, in blocks.                     |

- **Errors**:
  - `NotMultisig`: If the sender is not the multisig.
  - `InvalidVotingParameter`: If the new voting delay is invalid.

### Set Voting Period

- **Description**: Sets the voting period.

| Parameter           | Data Type | Description                                      |
|---------------------|-----------|--------------------------------------------------|
| `newVotingPeriod`   | uint256   | New voting period, in blocks.                    |

- **Errors**:
  - `NotMultisig`: If the sender is not the multisig.
  - `InvalidVotingParameter`: If the new voting period is invalid.

### Set Proposal Threshold

- **Description**: Sets the proposal threshold.

| Parameter               | Data Type | Description                                      |
|-------------------------|-----------|--------------------------------------------------|
| `newProposalThreshold`  | uint256   | New proposal threshold.                          |

- **Errors**:
  - `NotMultisig`: If the sender is not the multisig.
  - `InvalidVotingParameter`: If the new proposal threshold is invalid.
