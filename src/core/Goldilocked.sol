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


//todo: fix unweighted stake bug
//    could have a variable in struct that is claimable, add current claimable balance to it when staking on a staked position. will solve reentrancy and unweighted stake bug 
//todo: add checkpoints
//todo: fix balanceOf check to use checkpoints instead
import { ERC20 } from "../../lib/solady/src/tokens/ERC20.sol";
import { SafeTransferLib } from "../../lib/solady/src/utils/SafeTransferLib.sol";
import { FixedPointMathLib } from "../../lib/solady/src/utils/FixedPointMathLib.sol";
import { govLOCKS } from "../governance/govLOCKS.sol";
import { IGoldiswap } from "../interfaces/IGoldiswap.sol";


/// @title Goldilocked
/// @author geeb
/// @author ampnoob
contract Goldilocked is ERC20 {

  struct Stake {
    uint256 lastClaim;
    uint256 stakedBalance;
  }


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                      STATE VARIABLES                       */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  // uint32 public immutable DAYS_SECONDS = 86400;
  // uint16 public immutable DAILY_EMISSISION_RATE = 600;

  mapping(address => Stake) public stakes;
  mapping(address => uint256) public lockedLocks;
  mapping(address => uint256) public borrowedHoney;

  uint256 public ANNUAL_PORRIDGE_EMISSIONS = 5e17;
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
  constructor(
    address _goldiswap,
    address _goldilend,
    address _govlocks,
    address _honey
  ) {
    goldiswap = _goldiswap;
    goldilend = _goldilend;
    govlocks = _govlocks;
    honey = _honey;
    multisig = msg.sender;
  }

  /// @notice Returns the name of the $PRG token
  function name() public pure override returns (string memory) {
    return "Porridge Token";
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


  /// @notice Returns the staked $LOCKS of an address
  /// @param user Address to view staked $LOCKS
  function getStaked(address user) external view returns (uint256) {
    Stake memory userStake = stakes[user];
    return userStake.stakedBalance;
  }

  /// @notice Returns the stake start time of an address
  /// @param user Address to view stake start time
  function getStakeStartTime(address user) external view returns (uint256) {
    Stake memory userStake = stakes[user];
    return userStake.lastClaim;
  }

  /// @notice Returns the claimable yield of an address
  /// @param user Address to view claimable yield
  function getClaimable(address user) external view returns (uint256) {
    Stake memory userStake = stakes[user];
    uint256 stakedAmount = userStake.stakedBalance;
    return _calculateClaimable(user, stakedAmount);
  }

  /// @notice Returns the locked $LOCKS of a user
  /// @param user Address of user
  /// @return locked $LOCKS of user
  function getLocked(address user) external view returns (uint256) {
    return lockedLocks[user];
  }

  /// @notice Returns the borrowed $HONEY of a user
  /// @param user Address of user
  /// @return borrowed $HONEY of user
  function getBorrowed(address user) external view returns (uint256) {
    return borrowedHoney[user];
  }

  /// @notice Returns the borrow limit of a user
  /// @param user Address of user
  /// @return limit Limit of user
  function borrowLimit(address user) external view returns (uint256) {
    uint256 floorPrice = IGoldiswap(goldiswap).floorPrice();
    return _borrowLimit(user, floorPrice);
  }


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                    EXTERNAL FUNCTIONS                      */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @notice Stakes $LOCKS and begins earning $PRG
  /// @param amount Amount of $LOCKS to stake
  function stake(uint256 amount) external {
    Stake memory userStake = Stake({
      lastClaim: block.timestamp,
      stakedBalance: stakes[msg.sender].stakedBalance + amount
    });
    stakes[msg.sender] = userStake;
    govLOCKS(govlocks).updateStakedBalance(address(0), msg.sender, amount);
    SafeTransferLib.safeTransferFrom(goldiswap, msg.sender, address(this), amount);
    emit Staked(msg.sender, amount);
  }

  /// @notice Unstakes $LOCKS and claims $PRG 
  /// @param amount Amount of $LOCKS to unstake
  function unstake(uint256 amount) external {
    Stake memory userStake = stakes[msg.sender];
    if(amount > userStake.stakedBalance) revert InvalidUnstake();
    if(amount > userStake.stakedBalance - lockedLocks[msg.sender]) revert LocksBorrowedAgainst();
    uint256 stakedAmount = userStake.stakedBalance;
    stakes[msg.sender].stakedBalance -= amount;
    govLOCKS(govlocks).updateStakedBalance(msg.sender, address(0), amount);
    _claim(stakedAmount);
    SafeTransferLib.safeTransfer(goldiswap, msg.sender, amount);
    emit Unstaked(msg.sender, amount);
  }

  /// @notice Burns $PRG to buy $LOCKS at floor price
  /// @param amount Amount of $PRG to burn
  function stir(uint256 amount) external {
    _burn(msg.sender, amount);
    SafeTransferLib.safeTransferFrom(honey, msg.sender, goldiswap, FixedPointMathLib.mulWad(amount, IGoldiswap(goldiswap).floorPrice()));
    IGoldiswap(goldiswap).porridgeMint(msg.sender, amount);
    emit Stirred(msg.sender, amount);
  }

  /// @notice Claim $PRG rewards
  function claim() external {
    Stake memory userStake = stakes[msg.sender];
    _claim(userStake.stakedBalance);
  }

  /// @notice Lends out $HONEY using staked $LOCKS as collateral
  /// @dev borrowLimit is floor price of $LOCKS * amount of available staked $LOCKS
  /// @param amount Amount of $HONEY to borrow
  function borrow(uint256 amount) external {
    uint256 floorPrice = IGoldiswap(goldiswap).floorPrice();
    if(!_borrowLimitCheck(amount, floorPrice)) revert InsufficientBorrowLimit();
    lockedLocks[msg.sender] += FixedPointMathLib.divWad(amount, floorPrice);
    borrowedHoney[msg.sender] += amount;
    uint256 fee = _calcFee(amount);
    IGoldiswap(goldiswap).borrowTransfer(msg.sender, amount, fee);
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


  /// @notice Calculates and distributes yield
  /// @param stakedAmount Amount of $LOCKS the user has staked in the contract
  function _claim(uint256 stakedAmount) internal {
    uint256 claimable = _calculateClaimable(msg.sender, stakedAmount);
    if(claimable > 0) {
      stakes[msg.sender].lastClaim = block.timestamp;
      _mint(msg.sender, claimable);
      emit Claimed(msg.sender, claimable);
    }
  }
    
  /// @notice Calculates claimable yield
  /// @dev claimablePRG = (staked $LOCKS * 0.5 $PRG) * (days staked / 365 days)
  /// @param user Address of staker to calculate yield
  /// @param stakedAmount Amount of $LOCKS the user has staked in the contract
  /// @return yield Amount of $PRG earned by staker
  function _calculateClaimable(
    address user, 
    uint256 stakedAmount
  ) public view returns (uint256 yield) {
    uint256 timeStaked = _timeStaked(user);
    uint256 claimablePRG = FixedPointMathLib.mulWad(ANNUAL_PORRIDGE_EMISSIONS, stakedAmount);
    yield = FixedPointMathLib.mulWad(claimablePRG, FixedPointMathLib.divWad(timeStaked, 365 days));
    // uint256 yieldPortion = stakedAmount / DAILY_EMISSISION_RATE;
    // yield = FixedPointMathLib.mulWad(yieldPortion, FixedPointMathLib.divWad(timeStaked, DAYS_SECONDS));
  }

  /// @notice Calculates time staked of a staker
  /// @param user Address of staker to find time staked
  /// @return timeStaked staked of an address
  function _timeStaked(address user) internal view returns (uint256 timeStaked) {
    Stake memory userStake = stakes[user];
    timeStaked = block.timestamp - userStake.lastClaim;
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
    uint256 staked = stakes[user].stakedBalance;
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

  function changeEmissions(uint256 newEmissions) external {
    if(msg.sender != multisig) revert NotMultisig();
    ANNUAL_PORRIDGE_EMISSIONS = newEmissions;
  }

  function mintPorridge(uint256 newPorridge) external {
    if(msg.sender != multisig) revert NotMultisig();
    _mint(msg.sender, newPorridge);
  }

}