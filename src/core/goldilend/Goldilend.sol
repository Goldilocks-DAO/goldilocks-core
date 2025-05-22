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

  /// @notice Maps user to loans
  mapping(address => Loan[]) public loans;

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
  /// @param _glwbera Address of Goldilend Wrapped Bera
  /// @param _gldwbera Address of Goldilend Debt Wrapped Bera
  function initialize(
    address _timelock,
    address _multisig,
    address _apdao,
    address _wbera,
    address _glwbera,
    address _gldwbera
  ) public initializer {
    __Ownable_init(_multisig);
    __UUPSUpgradeable_init();
    timelock = _timelock;
    multisig = _multisig;
    apdao = _apdao;
    wbera = _wbera;
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
    if(amount > poolSize - outstandingDebt) revert InsufficientPRG();
    uint256 redeemAmount = _glWBERAMintAmount(amount);
    poolSize -= amount;
    GLWBera(glwbera).burnglWBERA(msg.sender, redeemAmount);
    SafeTransferLib.safeTransfer(wbera, msg.sender, amount);
    emit WBERAUnlock(msg.sender, amount);
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
    uint256 userLoansLength = loans[msg.sender].length;
    if(userLoansLength == MAX_LOANS) revert TooManyLoans();
    uint256 fairValue = nftFairValues[collateralNFT];
    uint256 debt = outstandingDebt;
    uint256 interest = _calculateInterest(borrowAmount, debt, duration);
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
    loans[msg.sender].push(loan);
    IERC721(collateralNFT).transferFrom(msg.sender, address(this), collateralNFTId);
    SafeTransferLib.safeTransfer(wbera, msg.sender, borrowAmount);
    GLDWBera(gldwbera).mintgldWBERA(msg.sender, borrowAmount);
    emit Borrow(msg.sender, userLoansLength + 1, borrowAmount, interest, block.timestamp + duration, collateralNFT, collateralNFTId);
  }

  /// @inheritdoc IGoldilend
  function repay(uint256 repayAmount, uint256 userLoanId) external {
    (Loan memory userLoan, uint256 index) = _lookupLoan(msg.sender, userLoanId);
    if(repayAmount > userLoan.borrowedAmount) repayAmount = userLoan.borrowedAmount;
    if(block.timestamp > userLoan.endDate + LOAN_GRACE_PERIOD) revert LoanExpired();
    uint256 interestLoanRatio = FixedPointMathLib.divWad(userLoan.interest, userLoan.borrowedAmount);
    uint256 interest = FixedPointMathLib.mulWadUp(repayAmount, interestLoanRatio);
    outstandingDebt -= repayAmount - interest > outstandingDebt ? outstandingDebt : repayAmount - interest;
    loans[msg.sender][index].borrowedAmount -= repayAmount;
    loans[msg.sender][index].interest -= interest;
    poolSize += interest * (1000 - (multisigShare + apdaoShare)) / 1000;
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
    (Loan memory userLoan, uint256 index) = _lookupLoan(user, userLoanId);
    if(block.timestamp < userLoan.endDate + LOAN_GRACE_PERIOD || userLoan.liquidated || userLoan.borrowedAmount == 0) revert Unliquidatable();
    loans[user][index].liquidated = true;
    loans[user][index].borrowedAmount = 0;
    outstandingDebt -=  userLoan.borrowedAmount - userLoan.interest > outstandingDebt ? outstandingDebt : userLoan.borrowedAmount - userLoan.interest;
    // IGoldilocked(goldilocked).goldilendMint(address(this), userLoan.borrowedAmount - userLoan.interest);
    uint256 userLoanCollateralLength = userLoan.collateralNFTs.length;
    for(uint256 i; i < userLoanCollateralLength;) {
      IERC721(userLoan.collateralNFTs[i]).safeTransferFrom(address(this), multisig, userLoan.collateralNFTIds[i]);
      unchecked {
        ++i;
      }
    }
    emit Liquidation(msg.sender, user, userLoan.borrowedAmount);
  }

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                  EXTERNAL VIEW FUNCTIONS                   */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @inheritdoc IGoldilend
  function lookupLoans(address user) external view returns (Loan[] memory userLoans) {
    userLoans = loans[user];
  }

  /// @inheritdoc IGoldilend
  function lookupLoan(address user, uint256 userLoanId) external view returns (Loan memory loan) {
    (loan, ) = _lookupLoan(user, userLoanId);
  }

  /// @inheritdoc IGoldilend
  function getglWBERARatio() external view returns (uint256) {
    uint256 supply = GLWBera(glwbera).totalSupply();
    uint256 _poolSize = poolSize;
    return _glWBERARatio(supply, _poolSize);
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

  /// @notice Finds the loan by userId
  /// @param userLoanId Id of loan to be found
  function _lookupLoan(
    address user, 
    uint256 userLoanId
  ) internal view returns (Loan memory userLoan, uint256 index) {
    uint256 loanLength = loans[user].length;
    for(uint256 i = loanLength; i > 0;) {
      unchecked {
        --i;
      }
      if(loans[user][i].loanId == userLoanId) return (loans[user][i], i);
    }
    revert LoanNotFound();
  }

  /// @notice Calculates the amount of glwBERA to mint
  /// @param lockAmount Amount of iBGT to lock
  /// @return mintAmount Total supply of glwBERA divided by the lending pool size multiplied by lockAmount
  function _glWBERAMintAmount(uint256 lockAmount) internal view returns (uint256) {
    uint256 supply = GLWBera(glwbera).totalSupply();
    uint256 _poolSize = poolSize;
    return _poolSize > 0 && supply > 0 ? FixedPointMathLib.mulWad(lockAmount, _glWBERARatio(supply, _poolSize)) : lockAmount;
  }

  /// @notice Calculates the current glWBERA ratio
  /// @return glWBERARatio Total supply of glWBERA divided by the lending pool size
  function _glWBERARatio(uint256 supply, uint256 _poolSize) internal pure returns (uint256) {
    return FixedPointMathLib.divWad(supply, _poolSize);
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
  function changeProtocolInterestRate(uint256 _protocolInterestRate) external {
    if(msg.sender != timelock) revert NotTimelock();
    protocolInterestRate = _protocolInterestRate;
    emit NewProtocolInterestRate(_protocolInterestRate);
  }

  /// @inheritdoc IGoldilend
  function changeShareRates(uint256 _multisigShare, uint256 _apdaoShare) external {
    if(msg.sender != timelock) revert NotTimelock();
    multisigShare = _multisigShare;
    apdaoShare = _apdaoShare;
    emit NewShareRates(_multisigShare, _apdaoShare);
  }

  /// @inheritdoc IGoldilend
  function changeSlope(uint256 _slope) external {
    if(msg.sender != timelock) revert NotTimelock();
    slope = _slope;
    emit NewSlope(_slope);
  }

  /// @inheritdoc IGoldilend
  function changeDurations(uint256 _minDuration, uint256 _maxDuration) external {
    if(msg.sender != timelock) revert NotTimelock();
    minDuration = _minDuration;
    maxDuration = _maxDuration;
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
    uint256 _slope 
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