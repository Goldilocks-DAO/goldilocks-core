//SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;


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
// ======================================== Goldilend ===========================================
// ==============================================================================================


import { FixedPointMathLib } from "../../../lib/solady/src/utils/FixedPointMathLib.sol";
import { SafeTransferLib } from "../../../lib/solady/src/utils/SafeTransferLib.sol";
import { ERC20 } from "../../../lib/solady/src/tokens/ERC20.sol";
import { IERC721 } from "../../../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import { IERC721Receiver } from "../../../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import { Initializable } from "../../../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "../../../lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import { UUPSUpgradeable } from "../../../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import { IBeraBondNFT } from "../../interfaces/IBeraBondNFT.sol";
import { IGl00DelegationRegistry } from "../../interfaces/IGl00DelegationRegistry.sol";
import { IGoldilend } from "../../interfaces/IGoldilend.sol";
import { GLWBera } from "./GLWBera.sol";
import { GLDWBera } from "./GLDWBera.sol";


/// @title Goldilend
/// @notice Bong Bear (and rebase) Fixed Term NFT Lending
contract Goldilend is Initializable, OwnableUpgradeable, UUPSUpgradeable, IGoldilend, IERC721Receiver {


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                      STATE VARIABLES                       */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    

  /// @notice Value for calculating interest payment on loans
  uint256 public constant INTEREST_PAYMENT_PERCENTAGE = 5e17;

  /// @notice Buffer period where borrowers are protected from liquidation
  uint256 public constant LOAN_GRACE_PERIOD = 1 days;

  /// @notice Max number of loans an address can originate
  uint256 public constant MAX_LOANS = 25;

  /// @notice Address of multisig
  address public multisig;

  /// @notice Address of APDAO
  address public apdao;

  /// @notice Address of Timelock
  address public timelock;

  /// @notice Address of WBERA
  address public wbera;

  /// @notice Address of BGT
  address public bgt;

  /// @notice Address of Delegation Registry
  address public delegationRegistry;

  /// @notice Address of Goldilend Wrapped Bera
  address public glwbera;

  /// @notice Address of Goldilend Debt Wrapped Bera
  address public gldwbera;

  /// @notice Interest rate of protocol
  uint256 public protocolInterestRate;

  /// @notice Outstanding debt of all unpaid loans
  uint256 public outstandingDebt;

  /// @notice Size of lending pool
  uint256 public poolSize;

  /// @notice Rate at which interest rate increases
  uint256 public slope;

  /// @notice Minimum loan duration
  uint256 public minDuration;

  /// @notice Maximum loan duration
  uint256 public maxDuration;

  /// @notice Maximum utilization of protocol liquidity
  uint256 public maxUtilization;

  /// @notice Portion of interest payments to multisig
  uint256 public multisigClaims;

  /// @notice Portion of interest payments to apdao
  uint256 public apdaoClaims;

  /// @notice Share of interest payments to multisig
  uint256 public multisigShare;

  /// @notice Share of interest payments to apdao
  uint256 public apdaoShare;

  /// @notice Boolean value if borrowing is active
  bool public borrowingActive;

  /// @notice Indicates if contract parameters are initialized
  bool public parametersInitialized;

  /// @notice Indicates if contract beras are initialized
  bool public berasInitialized;

  /// @notice Maps users to total amount of their loans
  mapping(address => uint256) public userLoanAmount;

  /// @notice Maps users to loans
  mapping(address => mapping(uint256 => Loan)) public loans;

  /// @notice Maps NFT to fair value
  mapping(address => uint256) public nftFairValues;


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                         CONSTRUCTOR                        */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
  

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  /// @notice Initializer of the contract
  /// @param _timelock Address of the timelock
  /// @param _multisig Address of the multisig
  /// @param _apdao Address of APDAO
  /// @param _wbera Address of WBERA
  /// @param _bgt Address of BGT
  /// @param _glwbera Address of Goldilend Wrapped Bera
  /// @param _gldwbera Address of Goldilend Debt Wrapped Bera
  function initialize(
    address _timelock,
    address _multisig,
    address _apdao,
    address _wbera,
    address _bgt,
    address _glwbera,
    address _gldwbera
  ) public initializer {
    __Ownable_init(_multisig);
    __UUPSUpgradeable_init();
    timelock = _timelock;
    multisig = _multisig;
    apdao = _apdao;
    wbera = _wbera;
    bgt = _bgt;
    glwbera = _glwbera;
    gldwbera = _gldwbera;
  }


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                      EXTERNAL FUNCTIONS                    */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @inheritdoc IGoldilend
  function lock(uint256 amount) external {
    uint256 mintAmount = _glWBERAMintAmount(amount);
    poolSize += amount;
    SafeTransferLib.safeTransferFrom(wbera, msg.sender, address(this), amount);
    GLWBera(glwbera).mintglWBERA(msg.sender, mintAmount);
    emit WBERALock(msg.sender, amount);
  }

  /// @inheritdoc IGoldilend
  function unlock(uint256 amount) external {
    uint256 unlockAmount = _glWBERAUnlockAmount(amount);
    poolSize -= unlockAmount;
    GLWBera(glwbera).burnglWBERA(msg.sender, amount);
    SafeTransferLib.safeTransfer(wbera, msg.sender, unlockAmount);
    emit WBERAUnlock(msg.sender, unlockAmount);
  }

  /// @inheritdoc IGoldilend
  function borrow(
    uint256 borrowAmount,
    uint256 duration,
    address collateralNFT,
    uint256 collateralNFTId
  ) external {
    if(!borrowingActive) revert NotActive();
    if(duration < minDuration || duration > maxDuration) revert InvalidDuration();
    if(borrowAmount > poolSize / 10) revert InvalidLoanAmount();
    if(nftFairValues[collateralNFT] == 0) revert InvalidCollateral();
    uint256 userLoansLength = userLoanAmount[msg.sender];
    uint256 fairValue = nftFairValues[collateralNFT];
    uint256 debt = outstandingDebt;
    uint256 interest = _calculateInterest(borrowAmount, debt, duration);
    if(debt + borrowAmount > poolSize * maxUtilization / 100) revert MaxUtilizationExceeded();
    if(borrowAmount + interest > fairValue || borrowAmount > poolSize - debt) revert BorrowLimitExceeded();
    outstandingDebt += borrowAmount;
    address[] memory collateralNFTs = new address[](1);
    collateralNFTs[0] = collateralNFT;
    uint256[] memory collateralNFTIds = new uint256[](1);
    collateralNFTIds[0] = collateralNFTId;
    Loan memory loan = Loan({
      collateralNFTs: collateralNFTs,
      collateralNFTIds: collateralNFTIds,
      borrowedAmount: borrowAmount + interest,
      interest: interest,
      duration: duration,
      endDate: block.timestamp + duration,
      loanId: userLoansLength + 1,
      liquidated: false
    });
    loans[msg.sender][userLoansLength + 1] = loan;
    userLoanAmount[msg.sender]++;
    IERC721(collateralNFT).transferFrom(msg.sender, address(this), collateralNFTId);
    SafeTransferLib.safeTransfer(wbera, msg.sender, borrowAmount);
    GLDWBera(gldwbera).mintgldWBERA(msg.sender, borrowAmount);
    emit Borrow(msg.sender, userLoansLength + 1, borrowAmount, interest, block.timestamp + duration, collateralNFT, collateralNFTId);
  }

  /// @inheritdoc IGoldilend
  function berabondBorrow(
    uint256 borrowAmount,
    address collateralNFT,
    uint256 collateralNFTId
  ) external {
    if(!borrowingActive) revert NotActive();
    if(nftFairValues[collateralNFT] == 0) revert InvalidCollateral();
    uint256 bgtBalance = _getTBABGTBalance(collateralNFT, collateralNFTId);
    uint256 maxBorrow = bgtBalance * 80 / 100;
    if(borrowAmount > maxBorrow) revert InvalidLoanAmount();
    uint256 userLoansLength = userLoanAmount[msg.sender];
    uint256 debt = outstandingDebt;
    if(debt + borrowAmount > poolSize * maxUtilization / 100) revert MaxUtilizationExceeded();
    if(borrowAmount > poolSize - debt) revert BorrowLimitExceeded();
    outstandingDebt += borrowAmount;
    address[] memory collateralNFTs = new address[](1);
    collateralNFTs[0] = collateralNFT;
    uint256[] memory collateralNFTIds = new uint256[](1);
    collateralNFTIds[0] = collateralNFTId;
    Loan memory loan = Loan({
      collateralNFTs: collateralNFTs,
      collateralNFTIds: collateralNFTIds,
      borrowedAmount: borrowAmount,
      interest: 0,
      duration: 180 days,
      endDate: block.timestamp + 180 days,
      loanId: userLoansLength + 1,
      liquidated: false
    });
    loans[msg.sender][userLoansLength + 1] = loan;
    userLoanAmount[msg.sender]++;
    // use nft's existing approval mechanism to lock bgt during transfer
    IERC721(collateralNFT).transferFrom(msg.sender, address(this), collateralNFTId);
    SafeTransferLib.safeTransfer(wbera, msg.sender, borrowAmount);
    GLDWBera(gldwbera).mintgldWBERA(msg.sender, borrowAmount);
    emit Borrow(msg.sender, userLoansLength + 1, borrowAmount, 0, block.timestamp + 180 days, collateralNFT, collateralNFTId);
  }

  /// @inheritdoc IGoldilend
  function repay(uint256 repayAmount, uint256 userLoanId) external {
    Loan memory userLoan = loans[msg.sender][userLoanId];
    if(repayAmount > userLoan.borrowedAmount) repayAmount = userLoan.borrowedAmount;
    if(block.timestamp > userLoan.endDate + LOAN_GRACE_PERIOD) revert LoanExpired();
    uint256 interestLoanRatio = FixedPointMathLib.divWad(userLoan.interest, userLoan.borrowedAmount);
    uint256 interest = FixedPointMathLib.mulWadUp(repayAmount, interestLoanRatio);
    outstandingDebt -= repayAmount - interest > outstandingDebt ? outstandingDebt : repayAmount - interest;
    loans[msg.sender][userLoanId].borrowedAmount -= repayAmount;
    loans[msg.sender][userLoanId].interest -= interest;
    _updateInterestClaims(interest);
    SafeTransferLib.safeTransferFrom(wbera, msg.sender, address(this), repayAmount);
    GLDWBera(gldwbera).burngldWBERA(msg.sender, userLoan.borrowedAmount - userLoan.interest);
    if(userLoan.borrowedAmount - repayAmount == 0) {
      uint256 userLoanCollateralLength = userLoan.collateralNFTs.length;
      for(uint256 i; i < userLoanCollateralLength;){
        IERC721(userLoan.collateralNFTs[i]).transferFrom(address(this), msg.sender, userLoan.collateralNFTIds[i]);
        unchecked {
          ++i;
        }
      }
    }
    emit Repay(msg.sender, repayAmount);
  }

  /// @inheritdoc IGoldilend
  function liquidate(address user, uint256 userLoanId) external {
    Loan memory userLoan = loans[msg.sender][userLoanId];
    if(block.timestamp < userLoan.endDate + LOAN_GRACE_PERIOD || userLoan.liquidated || userLoan.borrowedAmount == 0) revert Unliquidatable();
    loans[user][userLoanId].liquidated = true;
    loans[user][userLoanId].borrowedAmount = 0;
    outstandingDebt -=  userLoan.borrowedAmount - userLoan.interest > outstandingDebt ? outstandingDebt : userLoan.borrowedAmount - userLoan.interest;
    uint256 userLoanCollateralLength = userLoan.collateralNFTs.length;
    for(uint256 i; i < userLoanCollateralLength;) {
      IERC721(userLoan.collateralNFTs[i]).safeTransferFrom(address(this), multisig, userLoan.collateralNFTIds[i]);
      unchecked {
        ++i;
      }
    }
    emit Liquidation(msg.sender, user, userLoan.borrowedAmount, userLoanId);
  }


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                  EXTERNAL VIEW FUNCTIONS                   */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @inheritdoc IGoldilend
  function getUserLoan(address user, uint256 userLoanId) external view returns (Loan memory) {
    return loans[user][userLoanId];
  }

  /// @inheritdoc IGoldilend
  function calculateInterest(
    uint256 borrowAmount,
    uint256 duration,
    address collateralNFT
  ) external view returns (uint256) {
    if(duration < minDuration || duration > maxDuration) revert InvalidDuration();
    if(borrowAmount > poolSize / 10) revert InvalidLoanAmount();
    if(nftFairValues[collateralNFT] == 0) revert InvalidCollateral();
    uint256 fairValue = nftFairValues[collateralNFT];
    uint256 debt = outstandingDebt;
    if(borrowAmount > fairValue || borrowAmount > poolSize - debt) revert BorrowLimitExceeded();
    return _calculateInterest(borrowAmount, debt, duration);
  }

  /// @inheritdoc IGoldilend
  function getTBABGTBalance(address nft, uint256 tokenId) external view returns (uint256) {
    return _getTBABGTBalance(nft, tokenId);
  }


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                      INTERNAL FUNCTIONS                    */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @notice Update internal variables tracking amount of interest for multisig and apdao
  /// @dev Multisig can claim 4.5% and apdao can claim 0.5% of interest paid
  /// @param interest Interest paid during repayment
  function _updateInterestClaims(uint256 interest) internal {
    multisigClaims += interest * multisigShare / 1000;
    apdaoClaims += interest * apdaoShare / 1000;
  }


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                   INTERNAL VIEW FUNCTIONS                  */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/  


  /// @notice Caluclates the total interest due at repayment
  /// @param borrowAmount Amount to be borrowed
  /// @param debt Current amount of outstanding debt
  /// @return interest Total interest due at repayment
  function _calculateInterest(
    uint256 borrowAmount, 
    uint256 debt,
    uint256 duration
  ) internal view returns (uint256) {
    uint256 rate = protocolInterestRate;
    uint256 durationPortion = FixedPointMathLib.divWad(duration, 365 days);
    uint256 ratio = FixedPointMathLib.divWad(debt + borrowAmount, poolSize) + INTEREST_PAYMENT_PERCENTAGE;
    uint256 interestRate = rate + FixedPointMathLib.mulWad(FixedPointMathLib.mulWad(slope, rate), FixedPointMathLib.mulWad(ratio, durationPortion));
    uint256 interestAdjusted = FixedPointMathLib.mulWad(FixedPointMathLib.mulWad(interestRate, borrowAmount), durationPortion);
    return interestAdjusted / 100;
  }

  /// @notice Calculates the amount of glWBERA to mint
  /// @param lockAmount Amount of WBERA to lock
  /// @return mintAmount Total supply of glWBERA divided by the lending pool size multiplied by lockAmount
  function _glWBERAMintAmount(uint256 lockAmount) internal view returns (uint256) {
    uint256 supply = GLWBera(glwbera).totalSupply();
    uint256 _poolSize = poolSize;
    return _poolSize > 0 && supply > 0 ? FixedPointMathLib.mulWad(lockAmount, _glWBERARatio(supply, _poolSize)) : lockAmount;
  }

  /// @notice Calculates the amount of WBERA to unlock
  /// @param burnAmount Amount of glWBERA to burn 
  /// @return unlockAmount The burnAmount divided by the total supply of glWBERA divided by the lending pool size
  function _glWBERAUnlockAmount(uint256 burnAmount) internal view returns (uint256) {
    uint256 supply = GLWBera(glwbera).totalSupply();
    uint256 _poolSize = poolSize;
    return FixedPointMathLib.divWad(burnAmount, _glWBERARatio(supply, _poolSize));
  }

  /// @notice Calculates the current glWBERA ratio
  /// @return gibgtRatio Total supply of glWBERA divided by the lending pool size
  function _glWBERARatio(uint256 supply, uint256 _poolSize) internal pure returns (uint256) {
    return FixedPointMathLib.divWad(supply, _poolSize);
  }

  /// @notice Returns the BGT balance of the token bound account
  /// @return bgtBalance BGT balance of TBA
  function _getTBABGTBalance(address nft, uint256 tokenId) internal view returns (uint256) {
    if(nftFairValues[nft] == 0) revert InvalidCollateral();
    address tba = IBeraBondNFT(nft).getTokenBoundAccount(tokenId);
    return ERC20(bgt).balanceOf(tba);
  }


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                    PERMISSIONED FUNCTIONS                  */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @inheritdoc IGoldilend
    function changeValue(
    address[] calldata _nfts,
    uint256[] calldata _nftFairValues
  ) external {
    if(msg.sender != multisig) revert NotMultisig();
    if(_nfts.length != _nftFairValues.length) revert ArrayMismatch();
    uint256 nftFairValuesLength = _nftFairValues.length;
    for(uint256 i; i < nftFairValuesLength;) {
      nftFairValues[_nfts[i]] = _nftFairValues[i];
      unchecked {
        ++i;
      }
    }
  } 

  /// @inheritdoc IGoldilend
  function changeLendingParams(
    uint256 _protocolInterestRate,
    uint256 _multisigShare,
    uint256 _apdaoShare,
    uint256 _slope,
    uint256 _minDuration,
    uint256 _maxDuration
  ) external {
    if(msg.sender != timelock) revert NotTimelock();
    protocolInterestRate = _protocolInterestRate;
    multisigShare = _multisigShare;
    apdaoShare = _apdaoShare;
    slope = _slope;
    minDuration = _minDuration;
    maxDuration = _maxDuration;
    emit NewProtocolInterestRate(_protocolInterestRate);
    emit NewShareRates(_multisigShare, _apdaoShare);
    emit NewSlope(_slope);
    emit NewDurations(_minDuration, _maxDuration);
  }

  /// @inheritdoc IGoldilend
  function changeBorrowingActive(bool _borrowingActive) external {
    if(msg.sender != multisig) revert NotMultisig();
    borrowingActive = _borrowingActive;
    emit NewBorrowingActive(_borrowingActive);
  }

  /// @inheritdoc IGoldilend
  function multisigInterestClaim() external {
    if(msg.sender != multisig) revert NotMultisig();
    uint256 interestClaim = multisigClaims;
    multisigClaims = 0;
    SafeTransferLib.safeTransfer(wbera, multisig, interestClaim);
    emit MultisigInterestClaim(interestClaim);
  }

  /// @inheritdoc IGoldilend
  function apdaoInterestClaim() external {
    if(msg.sender != apdao) revert NotAPDAO();
    uint256 interestClaim = apdaoClaims;
    apdaoClaims = 0;
    SafeTransferLib.safeTransfer(wbera, apdao, interestClaim);
    emit ApdaoInterestClaim(interestClaim);
  }

  /// @inheritdoc IGoldilend
  function initializeParameters(
    uint256 _multisigShare,
    uint256 _apdaoShare,
    uint256 _minDuration,
    uint256 _maxDuration,
    uint256 _protocolInterestRate,
    uint256 _slope,
    uint256 _maxUtilization
  ) external {
    if(msg.sender != multisig) revert NotMultisig();
    if(parametersInitialized) revert AlreadyInitialized();
    parametersInitialized = true;
    multisigShare = _multisigShare;
    apdaoShare = _apdaoShare;
    minDuration = _minDuration;
    maxDuration = _maxDuration;
    protocolInterestRate = _protocolInterestRate;
    slope = _slope;
    maxUtilization = _maxUtilization;
    emit NewShareRates(_multisigShare, _apdaoShare);
    emit NewDurations(_minDuration, _maxDuration);
    emit NewProtocolInterestRate(_protocolInterestRate);
    emit NewSlope(_slope);
  }

  /// @inheritdoc IGoldilend
  function initializeBeras(
    address[] calldata _nfts,
    uint256[] calldata _nftFairValues
  ) external {
    if(msg.sender != multisig) revert NotMultisig();
    if(_nfts.length != _nftFairValues.length) revert ArrayMismatch();
    if(berasInitialized) revert AlreadyInitialized();
    berasInitialized = true;
    uint256 nftFairValuesLength = _nftFairValues.length;
    for(uint256 i; i < nftFairValuesLength;) {
      nftFairValues[_nfts[i]] = _nftFairValues[i];
      unchecked {
        ++i;
      }
    }
    borrowingActive = true;
  }

  /// @inheritdoc IGoldilend
  function recoverTokens(address token) external {
    if(msg.sender != multisig) revert NotMultisig();
    SafeTransferLib.safeTransfer(token, multisig, ERC20(token).balanceOf(address(this)));
  }

  /// @inheritdoc IGoldilend
  function increaseglWBERABacking(uint256 amount) external {
    if(msg.sender != multisig) revert NotMultisig();
    SafeTransferLib.safeTransferFrom(wbera, msg.sender, address(this), amount);
    poolSize += amount;
  }

  /// @inheritdoc IGoldilend
  function manageDelegation(
    address nft,
    uint256 tokenId,
    address delegatee,
    uint256 permissions
  ) external {
    if(msg.sender != multisig) revert NotMultisig();
    address payable tba = IBeraBondNFT(nft).getTokenBoundAccount(tokenId);
    IGl00DelegationRegistry(delegationRegistry).setDelegation(
      tba,
      delegatee,
      permissions,
      30 days
    );
  }


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                   IMPLEMENTATION FUNCTION                  */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) external virtual returns (bytes4) {
    return IERC721Receiver.onERC721Received.selector;
  }

  function _authorizeUpgrade(address newImplementation)
    internal
    override
    onlyOwner
  {}

}