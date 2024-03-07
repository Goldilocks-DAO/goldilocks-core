//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;


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


import { ERC20 } from "../../lib/solady/src/tokens/ERC20.sol";
import { SafeTransferLib } from "../../lib/solady/src/utils/SafeTransferLib.sol";
import { FixedPointMathLib } from "../../lib/solady/src/utils/FixedPointMathLib.sol";
import { Goldiswap } from "./Goldiswap.sol";
import { govLOCKS } from "../governance/govLOCKS.sol";


/// @title Goldilocked
/// @author geeb
/// @author ampnoob
contract Goldilocked is ERC20 {


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                      STATE VARIABLES                       */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  mapping(address => uint256) public stakedLocks;
  mapping(address => uint256) public claimablePrg;
  mapping(address => uint256) public prgPerTokenDebt;
  mapping(address => uint256) public lockedLocks;
  mapping(address => uint256) public borrowedHoney;
  mapping(address => uint256) public initialAllocations;

  uint256 public ANNUAL_PORRIDGE_EMISSIONS = 5e17;
  uint256 public deployTime;
  uint256 public vestingStart;
  uint256 public vestingEnd;
  address public goldiswap;
  address public goldilend;
  address public govlocks;
  address public honey;
  address public multisig;


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                          CONSTRUCTOR                       */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @notice Constructor of this contract
  /// @param _goldiswap Address of Goldiswap  
  /// @param _goldilend Address of Goldilend contract
  /// @param _govlocks Address of govLOCKS contract
  /// @param _honey Address of the HONEY contract
  /// @param allocationsAddress Addresses receiving $LOCKS
  /// @param allocationsAmt Amounts of $LOCKS to stake and lock
  constructor(
    address _goldiswap,
    address _goldilend,
    address _govlocks,
    address _honey,
    address[] memory allocationsAddress,
    uint256[] memory allocationsAmt
  ) {
    goldiswap = _goldiswap;
    goldilend = _goldilend;
    govlocks = _govlocks;
    honey = _honey;
    multisig = msg.sender;
    deployTime = block.timestamp;
    vestingStart = block.timestamp + 90 days;
    vestingEnd = block.timestamp + 90 days + 365 days;
    uint256 floor = Goldiswap(goldiswap).floorPrice();
    for(uint8 i; i < allocationsAddress.length; i++) {
      stakedLocks[allocationsAddress[i]] = allocationsAmt[i];
      lockedLocks[allocationsAddress[i]] = allocationsAmt[i];
      borrowedHoney[allocationsAddress[i]] = FixedPointMathLib.mulWad(floor, allocationsAmt[i]);
      initialAllocations[allocationsAddress[i]] = allocationsAmt[i];
      govLOCKS(govlocks).updateStakedBalance(address(0), allocationsAddress[i], allocationsAmt[i]);

    }
    _mint(multisig, 200000000e18);
  }

  /// @notice Returns the name of the $PRG token
  function name() public pure override returns (string memory) {
    return "Porridge";
  }

  /// @notice Returns the symbol of the $PRG token
  function symbol() public pure override returns (string memory) {
    return "PRG";
  }


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                           ERRORS                           */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  error NotGoldilend();
  error NotMultisig();
  error NotVested();
  error InvalidUnstake();
  error LocksBorrowedAgainst();
  error InsufficientBorrowLimit();
  error ExcessiveRepay();


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                           EVENTS                           */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  event Staked(address indexed user, uint256 amount);
  event Unstaked(address indexed user, uint256 amount);
  event Stirred(address indexed user, uint256 amount);
  event Claimed(address indexed user, uint256 amount);
  event Borrowed(address indexed user, uint256 amount);
  event Repaid(address indexed user, uint256 amount);


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                       VIEW FUNCTIONS                       */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @notice Returns the staked $LOCKS of a user
  /// @param user Address of user
  function userStakedLocks(address user) external view returns (uint256) {
    return stakedLocks[user];
  }

  /// @notice Returns the claimable yield of a user
  /// @param user Address of user
  function userClaimablePrg(address user) external view returns (uint256) {
    return _calculateClaimablePrg(user);
  }

  /// @notice Returns the locked $LOCKS of a user
  /// @param user Address of user
  function userLockedLocks(address user) external view returns (uint256) {
    return lockedLocks[user];
  }

  /// @notice Returns the borrowed $HONEY of a user
  /// @param user Address of user
  function userBorrowedHoney(address user) external view returns (uint256) {
    return borrowedHoney[user];
  }

  /// @notice Returns the borrow limit of a user
  /// @param user Address of user
  function userBorrowLimit(address user) external view returns (uint256) {
    uint256 floorPrice = Goldiswap(goldiswap).floorPrice();
    return _borrowLimit(user, floorPrice);
  }

  /// @notice Returns the amount of unvested $LOCKS of a user
  /// @param user Address of user
  function userVestingCheck(address user) external view returns (uint256) {
    return _vestingCheck(user, type(uint256).max);
  }


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                    EXTERNAL FUNCTIONS                      */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @notice Stakes $LOCKS and begins earning $PRG
  /// @param amount Amount of $LOCKS to stake
  function stake(uint256 amount) external {
    _updateClaimablePrg(msg.sender);
    stakedLocks[msg.sender] += amount;
    govLOCKS(govlocks).updateStakedBalance(address(0), msg.sender, amount);
    SafeTransferLib.safeTransferFrom(goldiswap, msg.sender, address(this), amount);
    emit Staked(msg.sender, amount);
  }

  /// @notice Unstakes $LOCKS and claims $PRG 
  /// @param amount Amount of $LOCKS to unstake
  function unstake(uint256 amount) external {
    uint256 vest = _vestingCheck(msg.sender, amount);
    if(amount > vest) revert NotVested();
    uint256 _stakedLocks = stakedLocks[msg.sender];
    if(amount > _stakedLocks) revert InvalidUnstake();
    if(amount > _stakedLocks - lockedLocks[msg.sender]) revert LocksBorrowedAgainst();
    _updateClaimablePrg(msg.sender);
    stakedLocks[msg.sender] -= amount;
    govLOCKS(govlocks).updateStakedBalance(msg.sender, address(0), amount);
    SafeTransferLib.safeTransfer(goldiswap, msg.sender, amount);
    emit Unstaked(msg.sender, amount);
  }

  /// @notice Burns $PRG to buy $LOCKS at floor price
  /// @param amount Amount of $PRG to burn
  function stir(uint256 amount) external {
    _burn(msg.sender, amount);
    SafeTransferLib.safeTransferFrom(honey, msg.sender, goldiswap, FixedPointMathLib.mulWad(amount, Goldiswap(goldiswap).floorPrice()));
    Goldiswap(goldiswap).porridgeMint(msg.sender, amount);
    emit Stirred(msg.sender, amount);
  }

  /// @notice Claim $PRG rewards
  function claim() external {
    _updateClaimablePrg(msg.sender);
    _claim(msg.sender, claimablePrg[msg.sender]);    
  }

  /// @notice Lends out $HONEY using staked $LOCKS as collateral
  /// @dev borrowLimit is floor price of $LOCKS * amount of available staked $LOCKS
  /// @param amount Amount of $HONEY to borrow
  function borrow(uint256 amount) external {
    uint256 floorPrice = Goldiswap(goldiswap).floorPrice();
    if(!_borrowLimitCheck(amount, floorPrice)) revert InsufficientBorrowLimit();
    lockedLocks[msg.sender] += FixedPointMathLib.divWad(amount, floorPrice);
    borrowedHoney[msg.sender] += amount;
    uint256 fee = _calcFee(amount);
    Goldiswap(goldiswap).borrowTransfer(msg.sender, amount, fee);
    emit Borrowed(msg.sender, amount);
  }

  /// @notice Settles $HONEY loans
  /// @param amount Amount of $HONEY to repay
  function repay(uint256 amount) external {
    if(borrowedHoney[msg.sender] < amount) revert ExcessiveRepay();
    uint256 repaidLocks = _calcRepayingLocks(amount);
    lockedLocks[msg.sender] -= repaidLocks;
    borrowedHoney[msg.sender] -= amount;
    SafeTransferLib.safeTransferFrom(honey, msg.sender, goldiswap, amount);
    emit Repaid(msg.sender, amount);
  }


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                      INTERNAL FUNCTIONS                    */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @notice Updates claimable $PRG for user that is staking, unstaking, or claiming
  /// @param user Address to update claimable $PRG for
  function _updateClaimablePrg(address user) internal {
    claimablePrg[user] = _calculateClaimablePrg(user);
    prgPerTokenDebt[user] = _claimablePrgPerLocks();
  }

  /// @notice Calculates and distributes $PRG
  /// @param claimer User that is claiming $PRG
  /// @param claimable Amount of $PRG to be claimed
  function _claim(address claimer, uint256 claimable) internal {
    if(claimable > 0) {
      claimablePrg[msg.sender] = 0;
      _mint(claimer, claimable);
      emit Claimed(msg.sender, claimable);
    }
  }

  /// @notice Calculates claimable $PRG
  /// @param user Address to calculate claimable $PRG for
  function _calculateClaimablePrg(address user) internal view returns (uint256) {
    return FixedPointMathLib.mulWad(stakedLocks[user], _claimablePrgPerLocks() - prgPerTokenDebt[user]) + claimablePrg[user];
  }

  /// @notice Calculates claimable $PRG per $LOCKS token
  function _claimablePrgPerLocks() internal view returns (uint256) {
    uint256 timeSinceDeploy = block.timestamp - deployTime;
    return FixedPointMathLib.mulWad(ANNUAL_PORRIDGE_EMISSIONS, FixedPointMathLib.divWad(timeSinceDeploy, 365 days));
  }

  /// @notice Calculates the amount of $LOCKS to return to users
  /// @dev repaidLocks = (repaid $HONEY / borrowed $HONEY) * locked $LOCKS
  /// @param amount Amount of $HONEY user is repaying with
  /// @return repaidLocks Amount of $LOCKS that is returned to user
  function _calcRepayingLocks(uint256 amount) internal view returns (uint256 repaidLocks) {
    repaidLocks = FixedPointMathLib.mulWad(FixedPointMathLib.divWad(amount, borrowedHoney[msg.sender]), lockedLocks[msg.sender]);
  }

  /// @notice Checks if the user has enough borrowing power
  /// @param amount Amount of $HONEY the user is requesting to borrow
  /// @param floorPrice Current floor price of $LOCKS
  /// @return check Returns true if the user has enough borrowing power
  function _borrowLimitCheck(uint256 amount, uint256 floorPrice) internal view returns (bool check) {
    uint256 limit = _borrowLimit(msg.sender, floorPrice);
    check = limit >= amount;
  }

  /// @notice Checks if the user has enough borrowing power
  /// @dev limit = $LOCKS floor price * available staked $LOCKS
  /// @param user Address of user
  /// @param floorPrice Current floor price of $LOCKS
  /// @return limit Returns the borrowing power of the user
  function _borrowLimit(address user, uint256 floorPrice) internal view returns (uint256 limit) {
    uint256 staked = stakedLocks[msg.sender];
    uint256 locked = lockedLocks[user];
    limit = FixedPointMathLib.mulWad(floorPrice, staked - locked);
  }

  /// @notice Calculates the fee for borrowing
  /// @dev 3% fee
  /// @param amount Amount of $HONEY the user is requesting to borrow
  /// @return fee Fee that user pays for borrowing
  function _calcFee(uint256 amount) internal pure returns (uint256 fee) {
    return (amount / 100) * 3;
  }

  /// @notice Calculates the amount of vested tokens for the user
  /// @param user Address of unstaker
  /// @param amount Amount of $LOCKS to unstake
  function _vestingCheck(address user, uint256 amount) internal view returns (uint256) {
    uint256 teamAllocation = 10000000e18;
    uint256 initialAllocation = initialAllocations[user];
    if(initialAllocation > 0) {
      if(initialAllocation >= teamAllocation) {
        return 0;
      }
      else {
        if(block.timestamp < vestingStart) return 0;
        uint256 vestPortion = FixedPointMathLib.divWad(block.timestamp - vestingStart, vestingEnd - vestingStart);
        return FixedPointMathLib.mulWad(vestPortion, initialAllocation);
      }
    }
    else {
      return amount;
    }
  }


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                    PERMISSIONED FUNCTIONS                  */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @notice Mints $PRG to user who is staking $gBERA
  /// @dev Only Goldilend contract can call this function
  /// @param to Recipient of minted $PRG tokens
  /// @param amount Amount of minted $PRG tokens
  function goldilendMint(address to, uint256 amount) external {
    if(msg.sender != goldilend) revert NotGoldilend();
    _mint(to, amount);
  }

  function changePorridgeEmissions(uint256 newEmissions) external {
    if(msg.sender != multisig) revert NotMultisig();
    ANNUAL_PORRIDGE_EMISSIONS = newEmissions;
  }

  function mintPorridge(uint256 newPorridge) external {
    if(msg.sender != multisig) revert NotMultisig();
    _mint(msg.sender, newPorridge);
  }

}