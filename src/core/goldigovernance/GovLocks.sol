//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


// |============================================================================================|
// |    ______      _____    __      _____    __   __       _____     _____   __  __   ______   |
// |   /_/\___\    ) ___ (  /\_\    /\ __/\  /\_\ /\_\     ) ___ (   /\ __/\ /\_\\  /\/ ____/\  |
// |   ) ) ___/   / /\_/\ \( ( (    ) )  \ \ \/_/( ( (    / /\_/\ \  ) )__\/( ( (/ / /) ) __\/  |
// |  /_/ /  ___ / /_/ (_\ \\ \_\  / / /\ \ \ /\_\\ \_\  / /_/ (_\ \/ / /    \ \_ / /  \ \ \    |
// |  \ \ \_/\__\\ \ )_/ / // / /__\ \ \/ / // / // / /__\ \ )_/ / /\ \ \_   / /  \ \  _\ \ \   |
// |   )_)  \/ _/ \ \/_\/ /( (_____() )__/ /( (_(( (_____(\ \/_\/ /  ) )__/\( (_(\ \ \)____) )  |
// |   \_\____/    )_____(  \/_____/\/___\/  \/_/ \/_____/ )_____(   \/___\/ \/_//__\/\____\/   |
// |                                                                                            |
// |============================================================================================|
// ==============================================================================================
// ========================================= GovLocks ===========================================
// ==============================================================================================


import { SafeTransferLib } from "../../../lib/solady/src/utils/SafeTransferLib.sol";
import { ERC20 } from "../../../lib/solady/src/tokens/ERC20.sol";


/// @title Governance Locks
/// @notice Governance wrapper for Locks token
/// @dev Forked from Uniswap token contract, https://etherscan.io/address/0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984
contract GovLocks is ERC20 {


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                           STRUCT                           */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  struct Checkpoint {
    uint256 fromBlock;
    uint256 votes;
  }


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                      STATE VARIABLES                       */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @notice Address of Locks token
  address public immutable locks;

  /// @notice Address of Goldilocked
  address public immutable goldilocked;

  /// @notice Maps user to amount of Locks deposited
  mapping(address => uint256) public deposits;

  /// @notice Maps user to delegated address
  mapping(address => address) public delegates;

  /// @notice Maps user to amount of checkpoints
  mapping(address => uint256) public numCheckpoints;

  /// @notice Maps user to a block number to a checkpoint
  mapping(address => mapping(uint256 => Checkpoint)) public checkpoints;


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                          CONSTRUCTOR                       */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @notice Constructor of this contract
  /// @param _locks Address of Locks
  /// @param _goldilocked Address of Goldilocked
  /// @param honeyjar Address of Honeyjar
  /// @param honeyjarVotingPower Governance power to grant to Honeyjar
  constructor(
    address _locks,
    address _goldilocked,
    address honeyjar,
    uint256 honeyjarVotingPower
  ) {
    locks = _locks;
    goldilocked = _goldilocked;
    _moveDelegates(address(0), honeyjar, honeyjarVotingPower);
  }

  /// @notice Returns the name of GovLocks token
  function name() public pure override returns (string memory) {
    return "Governance Locks";
  }

  /// @notice Returns the symbol of GovLocks token
  function symbol() public pure override returns (string memory) {
    return "govLOCKS";
  }


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                           ERRORS                           */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  error NoSuchBlock();
  error NotGoldilocked();


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                           EVENTS                           */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  event DelegateVotesChanged(
    address indexed delegate,
    uint256 previousBalance,
    uint256 newBalance
  );
  event DelegateChanged(
    address indexed delegator,
    address indexed fromDelegate,
    address indexed toDelegate
  );


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                       VIEW FUNCTIONS                       */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @notice Returns current votes balance
  /// @param user Address of user for query
  function getVotes(address user) external view returns (uint256) {
    uint256 nCheckpoints = numCheckpoints[user];
    return nCheckpoints > 0 ? checkpoints[user][nCheckpoints - 1].votes : 0;
  }

  /// @notice Returns votes balance from prior block
  /// @param user Address of user for query
  function getPriorVotes(address user, uint256 blockNumber) external view returns (uint256) {
    if(blockNumber >= block.number) revert NoSuchBlock();
    uint256 nCheckpoints = numCheckpoints[user];
    if (nCheckpoints == 0) {
      return 0;
    }
    // First check most recent balance
    if (checkpoints[user][nCheckpoints - 1].fromBlock <= blockNumber) {
      return checkpoints[user][nCheckpoints - 1].votes;
    }
    // Next check implicit zero balance
    if (checkpoints[user][0].fromBlock > blockNumber) {
      return 0;
    }
    uint256 lower = 0;
    uint256 upper = nCheckpoints - 1;
    while (upper > lower) {
      uint256 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
      Checkpoint memory cp = checkpoints[user][center];
      if (cp.fromBlock == blockNumber) {
        return cp.votes;
      } else if (cp.fromBlock < blockNumber) {
        lower = center;
      } else {
        upper = center - 1;
      }
    }
    return checkpoints[user][lower].votes;
  }


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                    EXTERNAL FUNCTIONS                      */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @notice Deposits Locks to mint GovLocks
  /// @param amount Amount of Locks to deposit
  function deposit(uint256 amount) external {
    deposits[msg.sender] += amount;
    _moveDelegates(address(0), delegates[msg.sender], amount);
    SafeTransferLib.safeTransferFrom(locks, msg.sender, address(this), amount);
    _mint(msg.sender, amount);
  }

  /// @notice Withdraws Locks to burn Govlocks
  /// @param amount Amount of Locks to withdraw
  function withdraw(uint256 amount) external {
    deposits[msg.sender] -= amount;
    _moveDelegates(delegates[msg.sender], address(0), amount);
    _burn(msg.sender, amount);
    SafeTransferLib.safeTransfer(locks, msg.sender, amount);
  }

  /// @notice Delegates votes from msg.sender to delegatee
  /// @param delegatee Address to delegate votes to
  function delegate(address delegatee) external {
    _delegate(msg.sender, delegatee);
  }


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                      INTERNAL FUNCTIONS                    */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @notice Delegates votes from delegator to delegateee
  function _delegate(address delegator, address delegatee) internal {
    address currentDelegate = delegates[delegator];
    uint256 delegatorBalance = balanceOf(delegator);
    delegates[delegator] = delegatee;
    _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    emit DelegateChanged(delegator, currentDelegate, delegatee);
  }

  /// @notice Delegates votes from delegator to delegateee
  function _moveDelegates(address srcRep, address dstRep, uint256 amt) internal {
    if (srcRep != dstRep && amt > 0) {
      if (srcRep != address(0)) {
        uint256 srcRepNum = numCheckpoints[srcRep];
        uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
        uint256 srcRepNew = srcRepOld - amt;
        _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
      }
      if (dstRep != address(0)) {
        uint256 dstRepNum = numCheckpoints[dstRep];
        uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
        uint256 dstRepNew = dstRepOld + amt;
        _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
      }
    }
  }

  /// @notice Writes vote balance checkpoint
  function _writeCheckpoint(
    address delegatee, 
    uint256 nCheckpoints, 
    uint256 oldVotes, 
    uint256 newVotes
  ) internal {
    if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == block.number) {
      checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
    } else {
      checkpoints[delegatee][nCheckpoints] = Checkpoint(block.number, newVotes);
      numCheckpoints[delegatee] = nCheckpoints + 1;
    }
    emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
  }


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                    PERMISSIONED FUNCTION                   */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @notice Moves delegated votes during Locks stake or unstake
  function updateStakedBalance(address from, address to, uint256 amt) external {
    if(msg.sender != goldilocked) revert NotGoldilocked();
    _moveDelegates(from, to, amt);
  }


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                   IMPLEMENTATION FUNCTION                  */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @notice Moves delegated votes after a token transfer
  function _afterTokenTransfer(address from, address to, uint256 amt) internal override {
    if(from != address(0) && to != address(0)) {
      _moveDelegates(delegates[from], delegates[to], amt);
    }
  }

}