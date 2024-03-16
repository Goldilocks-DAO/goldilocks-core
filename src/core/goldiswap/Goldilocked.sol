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
// ======================================= Goldilocked ==========================================
// ==============================================================================================


import { ERC20 } from "../../../lib/solady/src/tokens/ERC20.sol";
import { SafeTransferLib } from "../../../lib/solady/src/utils/SafeTransferLib.sol";
import { FixedPointMathLib } from "../../../lib/solady/src/utils/FixedPointMathLib.sol";
import { IGoldilocked } from "../../interfaces/IGoldilocked.sol";
import { IGoldiswap } from "../../interfaces/IGoldiswap.sol";
import { GovLocks } from "../../core/goldigovernance/GovLocks.sol";


/// @title Goldilocked
/// @notice Mints Porridge for staked Locks and facilitates borrowing against Locks
contract Goldilocked is IGoldilocked, ERC20 {


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                      STATE VARIABLES                       */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @notice Timestamp of contract deployment
  uint256 public immutable deployTime;

  /// @notice Timestamp of seed investor vesting start
  uint256 public immutable vestingStart;

  /// @notice Timestamp of seed investor vesting end
  uint256 public immutable vestingEnd;

  /// @notice Address of Goldiswap
  address public immutable goldiswap;

  /// @notice Address of Goldilend
  address public immutable goldilend;

  /// @notice Address of GovLocks
  address public immutable govlocks;

  /// @notice Address of Honey
  address public immutable honey;

  /// @notice Address of Timelock
  address public immutable timelock;

  /// @notice Annual emission rate of Porridge
  uint256 public annualPrgEmissions;

  /// @notice Timestamp of last update of claimable Porridge reward
  uint256 public lastUpdateTime;

  /// @notice Claimable Porridge per staked Locks
  uint256 public claimablePrgPerLocksStored;
  
  /// @notice Maps user to amount of staked Locks
  mapping(address => uint256) public stakedLocks;

  /// @notice Maps user to amount of claimable Porridge
  mapping(address => uint256) public claimablePrg;

  /// @notice Maps user to amount of Porridge reward debt
  mapping(address => uint256) public prgPerTokenDebt;

  /// @notice Maps user to amount of borrowed Honey
  mapping(address => uint256) public borrowedHoney;

  /// @notice Maps seed investor to initial Locks allocation
  mapping(address => uint256) public seedAllocations;

  /// @notice Maps team member to initial Locks allocation
  mapping(address => uint256) public teamAllocations;


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                          CONSTRUCTOR                       */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @notice Constructor of this contract
  /// @param _goldiswap Address of Goldiswap  
  /// @param _goldilend Address of Goldilend
  /// @param _govlocks Address of GovLocks
  /// @param _honey Address of Honey
  /// @param _timelock Address of Timelock
  /// @param _annualPrgEmissions Initial annual Porridge emissions
  /// @param allocationsAddress Addresses receiving Locks
  /// @param allocationsAmt Amounts of Locks to stake and lock
  /// @param initialSupply Initial supply of Porridge
  constructor(
    address _goldiswap,
    address _goldilend,
    address _govlocks,
    address _honey,
    address _timelock,
    uint256 initialSupply,
    uint256 _annualPrgEmissions,
    address[] memory allocationsAddress,
    uint256[] memory allocationsAmt
  ) {
    goldiswap = _goldiswap;
    goldilend = _goldilend;
    govlocks = _govlocks;
    honey = _honey;
    timelock = _timelock;
    deployTime = block.timestamp;
    vestingStart = block.timestamp + 90 days;
    vestingEnd = block.timestamp + 90 days + 365 days;
    annualPrgEmissions = _annualPrgEmissions;
    uint256 floor = IGoldiswap(goldiswap).floorPrice();
    for(uint8 i; i < allocationsAddress.length; i++) {
      stakedLocks[allocationsAddress[i]] = allocationsAmt[i];
      borrowedHoney[allocationsAddress[i]] = FixedPointMathLib.mulWad(floor, allocationsAmt[i]);
      i < 3 ? teamAllocations[allocationsAddress[i]] = allocationsAmt[i] : seedAllocations[allocationsAddress[i]] = allocationsAmt[i];
      GovLocks(govlocks).updateStakedBalance(address(0), allocationsAddress[i], allocationsAmt[i]);
    }
    _mint(msg.sender, initialSupply);
  }

  /// @notice Returns the name of Porridge token
  function name() public pure override returns (string memory) {
    return "Porridge";
  }

  /// @notice Returns the symbol of Porridge token
  function symbol() public pure override returns (string memory) {
    return "PRG";
  }


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                       VIEW FUNCTIONS                       */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @inheritdoc IGoldilocked
  function userStakedLocks(address user) external view returns (uint256) {
    return stakedLocks[user];
  }

  /// @inheritdoc IGoldilocked
  function userClaimablePrg(address user) external view returns (uint256) {
    return _calculateClaimablePrg(user);
  }

  /// @inheritdoc IGoldilocked
  function userLockedLocks(address user) external view returns (uint256) {
    return _lockedLocks(user);
  }

  /// @inheritdoc IGoldilocked
  function userBorrowedHoney(address user) external view returns (uint256) {
    return borrowedHoney[user];
  }

  /// @inheritdoc IGoldilocked
  function userBorrowLimit(address user) external view returns (uint256) {
    uint256 floorPrice = IGoldiswap(goldiswap).floorPrice();
    return _borrowLimit(user, floorPrice);
  }

  /// @inheritdoc IGoldilocked
  function userVestingCheck(address user) external view returns (uint256) {
    return _vestingCheck(user, type(uint256).max);
  }


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                    EXTERNAL FUNCTIONS                      */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @inheritdoc IGoldilocked
  function stake(uint256 amount) external {
    if(seedAllocations[msg.sender] > 0) revert Vesting();
    _updateClaimablePrg(msg.sender);
    stakedLocks[msg.sender] += amount;
    GovLocks(govlocks).updateStakedBalance(address(0), msg.sender, amount);
    SafeTransferLib.safeTransferFrom(goldiswap, msg.sender, address(this), amount);
    emit Stake(msg.sender, amount);
  }

  /// @inheritdoc IGoldilocked
  function unstake(uint256 amount) external {
    uint256 vest = _vestingCheck(msg.sender, amount);
    if(amount > vest) revert NotVested();
    uint256 _stakedLocks = stakedLocks[msg.sender];
    if(amount > _stakedLocks) revert InvalidUnstake();
    if(amount > _stakedLocks - _lockedLocks(msg.sender)) revert LocksBorrowedAgainst();
    _updateClaimablePrg(msg.sender);
    stakedLocks[msg.sender] -= amount;
    GovLocks(govlocks).updateStakedBalance(msg.sender, address(0), amount);
    SafeTransferLib.safeTransfer(goldiswap, msg.sender, amount);
    emit Unstake(msg.sender, amount);
  }

  /// @inheritdoc IGoldilocked
  function stir(uint256 amount) external {
    uint256 cost = FixedPointMathLib.mulWad(amount, IGoldiswap(goldiswap).floorPrice());
    _burn(msg.sender, amount);
    SafeTransferLib.safeTransferFrom(honey, msg.sender, goldiswap, cost);
    IGoldiswap(goldiswap).porridgeMint(msg.sender, amount, cost);
    emit Stir(msg.sender, amount);
  }

  /// @inheritdoc IGoldilocked
  function claim() external {
    _updateClaimablePrg(msg.sender);
    _claim(msg.sender, claimablePrg[msg.sender]);    
  }

  /// @inheritdoc IGoldilocked
  function borrow(uint256 amount) external {
    uint256 floorPrice = IGoldiswap(goldiswap).floorPrice();
    if(!_borrowLimitCheck(amount, floorPrice)) revert InsufficientBorrowLimit();
    borrowedHoney[msg.sender] += amount;
    uint256 fee = amount * 3 / 100;
    IGoldiswap(goldiswap).borrowTransfer(msg.sender, amount, fee);
    emit Borrow(msg.sender, amount);
  }

  /// @inheritdoc IGoldilocked
  function repay(uint256 amount) external {
    if(borrowedHoney[msg.sender] < amount) revert ExcessiveRepay();
    borrowedHoney[msg.sender] -= amount;
    SafeTransferLib.safeTransferFrom(honey, msg.sender, goldiswap, amount);
    emit Repay(msg.sender, amount);
  }


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                   INTERNAL VIEW FUNCTIONS                  */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    
  /// @notice Calculates claimable Porridge
  /// @param user Address of user
  function _calculateClaimablePrg(address user) internal view returns (uint256) {
    return FixedPointMathLib.mulWad(stakedLocks[user], _claimablePrgPerLocks() - prgPerTokenDebt[user]) + claimablePrg[user];
  }

  /// @notice Calculates claimable Porridge per Locks token
  function _claimablePrgPerLocks() internal view returns (uint256) {
    if(block.timestamp - lastUpdateTime == 0) {
      return claimablePrgPerLocksStored;
    }
    return claimablePrgPerLocksStored + FixedPointMathLib.mulWad(FixedPointMathLib.divWad(block.timestamp - lastUpdateTime, 365 days), annualPrgEmissions);
  }

  /// @notice Checks if user has enough borrowing power
  /// @param amount Amount of Honey user is requesting to borrow
  /// @param floorPrice Locks floor price
  function _borrowLimitCheck(uint256 amount, uint256 floorPrice) internal view returns (bool) {
    uint256 limit = _borrowLimit(msg.sender, floorPrice);
    return limit >= amount;
  }

  /// @notice Returns Honey borrow limit
  /// @dev limit = Locks floor price * staked Locks - locked locks
  /// @param user Address of user
  /// @param floorPrice Locks floor price
  function _borrowLimit(address user, uint256 floorPrice) internal view returns (uint256) {
    uint256 staked = stakedLocks[user];
    uint256 locked = _lockedLocks(user);
    return FixedPointMathLib.mulWad(floorPrice, staked - locked);
  }

  /// @notice Calculates amount of locked Locks
  /// @dev locked locks = borrowed honey / floor price
  /// @param user Address of user
  function _lockedLocks(address user) internal view returns (uint256) {
    return FixedPointMathLib.divWad(borrowedHoney[user], IGoldiswap(goldiswap).floorPrice());
  }

  /// @notice Calculates amount of unvested Locks
  /// @param user Address of unstaker
  /// @param amount Amount of Locks to unstake
  function _vestingCheck(address user, uint256 amount) internal view returns (uint256) {
    if(teamAllocations[user] > 0) return 0;
    uint256 initialAllocation = seedAllocations[user];
    if(initialAllocation > 0) {
      if(block.timestamp < vestingStart) return 0;
      uint256 vestPortion = FixedPointMathLib.divWad(block.timestamp - vestingStart, vestingEnd - vestingStart);
      return FixedPointMathLib.mulWad(vestPortion, initialAllocation) - (initialAllocation - stakedLocks[user]);
    }
    else {
      return amount;
    }
  }


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                      INTERNAL FUNCTIONS                    */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @notice Updates claimable Porridge
  /// @param user Address of user
  function _updateClaimablePrg(address user) internal {
    claimablePrgPerLocksStored = _claimablePrgPerLocks();
    lastUpdateTime = block.timestamp;
    if(user != address(0)) {
      claimablePrg[user] = _calculateClaimablePrg(user);
      prgPerTokenDebt[user] = claimablePrgPerLocksStored;
    }
  }

  /// @notice Mints claimable Porridge
  /// @param claimer User that is claiming Porridge
  /// @param claimable Amount of Porridge to be claimed
  function _claim(address claimer, uint256 claimable) internal {
    if(claimable > 0) {
      claimablePrg[claimer] = 0;
      _mint(claimer, claimable);
      emit Claim(claimer, claimable);
    }
  }


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                    PERMISSIONED FUNCTIONS                  */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @inheritdoc IGoldilocked
  function goldilendMint(address to, uint256 amount) external {
    if(msg.sender != goldilend) revert NotGoldilend();
    _mint(to, amount);
  }

  /// @inheritdoc IGoldilocked
  function changePrgEmissions(uint256 newPrgEmissions) external {
    if(msg.sender != timelock) revert NotTimelock();
    _updateClaimablePrg(address(0));
    annualPrgEmissions = newPrgEmissions;
  }

  /// @inheritdoc IGoldilocked
  function mintPorridge(address multisig, uint256 newPorridge) external {
    if(msg.sender != timelock) revert NotTimelock();
    _mint(multisig, newPorridge);
  }

}