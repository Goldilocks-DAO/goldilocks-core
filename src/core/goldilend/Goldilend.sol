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
// ======================================== Goldilend ===========================================
// ==============================================================================================


import { FixedPointMathLib } from "../../../lib/solady/src/utils/FixedPointMathLib.sol";
import { SafeTransferLib } from "../../../lib/solady/src/utils/SafeTransferLib.sol";
import { ERC20 } from "../../../lib/solady/src/tokens/ERC20.sol";
import { IERC721 } from "../../../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import { IERC721Receiver } from "../../../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import { IGoldilend } from "../../interfaces/IGoldilend.sol";
import { IGoldilocked } from "../../interfaces/IGoldilocked.sol";
import { GPRG } from "./GPRG.sol";
import { DPRG } from "./DPRG.sol";


/// @title Goldilend
/// @notice Bong Bear (and rebase) Fixed Term NFT Lending
contract Goldilend is IGoldilend, IERC721Receiver {


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
  address public immutable multisig;

  /// @notice Address of Timelock
  address public immutable timelock;

  /// @notice Address of porridge
  address public immutable porridge;

  /// @notice Address of Goldilend Porridge
  address public immutable gprg;

  /// @notice Address of Debt Porridge
  address public immutable dprg;

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
  

  /// @notice Constructor of this contract
  /// @param _multisig Address of the multisig
  /// @param _timelock Address of the timelock
  /// @param _porridge Address of Porridge
  /// @param _gprg Address of Goldilend Porridge
  /// @param _dprg Address of Debt Porridge
  constructor(
    address _timelock,
    address _multisig,
    address _porridge,
    address _gprg,
    address _dprg
  ) {
    multisig = _multisig;
    timelock = _timelock;
    porridge = _porridge;
    gprg = _gprg;
    dprg = _dprg;
  }


  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                      EXTERNAL FUNCTIONS                    */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


  /// @inheritdoc IGoldilend
  function lock(uint256 amount) external {
    uint256 mintAmount = _GPRGMintAmount(amount);
    poolSize += amount;
    SafeTransferLib.safeTransferFrom(porridge, msg.sender, address(this), amount);
    GPRG(gprg).mintGPRG(msg.sender, mintAmount);
    emit PorridgeLock(msg.sender, amount);
  }

  /// @inheritdoc IGoldilend
  function unlock(uint256 amount) external {
    require(poolSize - outstandingDebt >= amount);
    uint256 redeemAmount = _GPRGMintAmount(amount);
    poolSize -= amount;
    GPRG(gprg).burnGPRG(msg.sender, redeemAmount);
    SafeTransferLib.safeTransferFrom(porridge, address(this), msg.sender, amount);
    emit PorridgeUnlock(msg.sender, amount);
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
    SafeTransferLib.safeTransfer(porridge, msg.sender, borrowAmount);
    DPRG(dprg).mintDPRG(msg.sender, borrowAmount);
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
    poolSize += interest;
    SafeTransferLib.safeTransferFrom(porridge, msg.sender, address(this), repayAmount);
    DPRG(dprg).burnDPRG(msg.sender, repayAmount);
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
    IGoldilocked(porridge).goldilendMint(address(this), userLoan.borrowedAmount - userLoan.interest);
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
  function getGPRGRatio() external view returns (uint256) {
    uint256 supply = GPRG(gprg).totalSupply();
    uint256 _poolSize = poolSize;
    return _GPRGRatio(supply, _poolSize);
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

  /// @notice Calculates the amount of GiBGT to mint
  /// @param lockAmount Amount of iBGT to lock
  /// @return mintAmount Total supply of GiBGT divided by the lending pool size multiplied by lockAmount
  function _GPRGMintAmount(uint256 lockAmount) internal view returns (uint256) {
    uint256 supply = GPRG(gprg).totalSupply();
    uint256 _poolSize = poolSize;
    return _poolSize > 0 && supply > 0 ? FixedPointMathLib.mulWad(lockAmount, _GPRGRatio(supply, _poolSize)) : lockAmount;
  }

  /// @notice Calculates the current $GiBGT ratio
  /// @return gibgtRatio Total supply of $GiBGT divided by the lending pool size
  function _GPRGRatio(uint256 supply, uint256 _poolSize) internal pure returns (uint256) {
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
    uint256 totalNftFairValue;
    for(uint256 i; i < nftFairValuesLength;) {
      nftFairValues[_nfts[i]] = _nftFairValues[i];
      totalNftFairValue += _nftFairValues[i];
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
  function initializeParameters(
    uint256 _minDuration,
    uint256 _maxDuration,
    uint256 _protocolInterestRate,
    uint256 _slope 
  ) external {
    if(msg.sender != multisig) revert NotMultisig();
    if(parametersInitialized) revert AlreadyInitialized();
    parametersInitialized = true;
    minDuration = _minDuration;
    maxDuration = _maxDuration;
    protocolInterestRate = _protocolInterestRate;
    slope = _slope;
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
    uint256 totalNftFairValue;
    for(uint256 i; i < nftFairValuesLength;) {
      nftFairValues[_nfts[i]] = _nftFairValues[i];
      totalNftFairValue += _nftFairValues[i];
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

}