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
// ===================================== GoldilendBase ==========================================
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
import { IGoldilendBase } from "../../interfaces/IGoldilendBase.sol";
import { GLWBera } from "./GLWBera.sol";


/// @title GoldilendBase
/// @notice Bong Bear (and rebase) Fixed Term NFT Lending
abstract contract GoldilendBase is Initializable, OwnableUpgradeable, UUPSUpgradeable, IGoldilendBase, IERC721Receiver {


    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      STATE VARIABLES                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


    /// @notice Value for calculating interest payment on loans
    uint256 public constant INTEREST_PAYMENT_PERCENTAGE = 5e17;

    /// @notice Buffer period where borrowers are protected from liquidation
    uint256 public constant LOAN_GRACE_PERIOD = 1 days;

    /// @notice Address of multisig
    address public multisig;

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
    /// @param _wbera Address of WBERA
    /// @param _bgt Address of BGT
    /// @param _glwbera Address of Goldilend Wrapped Bera
    function initialize(
        address _timelock,
        address _multisig,
        address _wbera,
        address _bgt,
        address _glwbera
    ) public initializer {
        __Ownable_init(_multisig);
        __UUPSUpgradeable_init();
        timelock = _timelock;
        multisig = _multisig;
        wbera = _wbera;
        bgt = _bgt;
        glwbera = _glwbera;
    }


    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      EXTERNAL FUNCTIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


    /// @inheritdoc IGoldilendBase
    function lock(uint256 amount) external {
        uint256 mintAmount = _glWBERAMintAmount(amount);
        poolSize += amount;
        SafeTransferLib.safeTransferFrom(wbera, msg.sender, address(this), amount);
        GLWBera(glwbera).mintglWBERA(msg.sender, mintAmount);
        emit WBERALock(msg.sender, amount);
    }

    /// @inheritdoc IGoldilendBase
    function unlock(uint256 amount) external {
        uint256 unlockAmount = _glWBERAUnlockAmount(amount);
        poolSize -= unlockAmount;
        GLWBera(glwbera).burnglWBERA(msg.sender, amount);
        SafeTransferLib.safeTransfer(wbera, msg.sender, unlockAmount);
        emit WBERAUnlock(msg.sender, unlockAmount);
    }

    /// @inheritdoc IGoldilendBase
    function repay(uint256 repayAmount, uint256 userLoanId) external {
        Loan memory userLoan = loans[msg.sender][userLoanId];
        if(repayAmount > userLoan.borrowedAmount) repayAmount = userLoan.borrowedAmount;
        if(block.timestamp > userLoan.endDate + LOAN_GRACE_PERIOD) revert LoanExpired();
        uint256 interestLoanRatio = FixedPointMathLib.divWad(userLoan.interest, userLoan.borrowedAmount);
        uint256 interest = FixedPointMathLib.mulWadUp(repayAmount, interestLoanRatio);
        outstandingDebt -= repayAmount - interest > outstandingDebt ? outstandingDebt : repayAmount - interest;
        loans[msg.sender][userLoanId].borrowedAmount -= repayAmount;
        loans[msg.sender][userLoanId].interest -= interest;
        multisigClaims += interest;
        SafeTransferLib.safeTransferFrom(wbera, msg.sender, address(this), repayAmount);
        if(userLoan.borrowedAmount - repayAmount == 0) {
        IERC721(userLoan.collateralNFT).transferFrom(address(this), msg.sender, userLoan.collateralNFTId);
        }
        emit Repay(msg.sender, repayAmount);
    }

    /// @inheritdoc IGoldilendBase
    function liquidate(address user, uint256 userLoanId) external {
        Loan memory userLoan = loans[msg.sender][userLoanId];
        if(block.timestamp < userLoan.endDate + LOAN_GRACE_PERIOD || userLoan.liquidated || userLoan.borrowedAmount == 0) revert Unliquidatable();
        loans[user][userLoanId].liquidated = true;
        loans[user][userLoanId].borrowedAmount = 0;
        outstandingDebt -=  userLoan.borrowedAmount - userLoan.interest > outstandingDebt ? outstandingDebt : userLoan.borrowedAmount - userLoan.interest;
        IERC721(userLoan.collateralNFT).safeTransferFrom(address(this), multisig, userLoan.collateralNFTId);
        emit Liquidation(msg.sender, user, userLoan.borrowedAmount, userLoanId);
    }


    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  EXTERNAL VIEW FUNCTIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


    /// @inheritdoc IGoldilendBase
    function getUserLoan(address user, uint256 userLoanId) external view returns (Loan memory) {
        return loans[user][userLoanId];
    }

    /// @inheritdoc IGoldilendBase
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


    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    PERMISSIONED FUNCTIONS                  */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


    /// @inheritdoc IGoldilendBase
    function changeLendingParams(
        uint256 _protocolInterestRate,
        uint256 _slope,
        uint256 _minDuration,
        uint256 _maxDuration
    ) external {
        if(msg.sender != timelock) revert NotTimelock();
        protocolInterestRate = _protocolInterestRate;
        slope = _slope;
        minDuration = _minDuration;
        maxDuration = _maxDuration;
        emit NewProtocolInterestRate(_protocolInterestRate);
        emit NewSlope(_slope);
        emit NewDurations(_minDuration, _maxDuration);
    }

    /// @inheritdoc IGoldilendBase
    function changeBorrowingActive(bool _borrowingActive) external {
        if(msg.sender != multisig) revert NotMultisig();
        borrowingActive = _borrowingActive;
        emit NewBorrowingActive(_borrowingActive);
    }

    /// @inheritdoc IGoldilendBase
    function multisigInterestClaim() external {
        if(msg.sender != multisig) revert NotMultisig();
        uint256 interestClaim = multisigClaims;
        multisigClaims = 0;
        SafeTransferLib.safeTransfer(wbera, multisig, interestClaim);
        emit MultisigInterestClaim(interestClaim);
    }

    /// @inheritdoc IGoldilendBase
    function initializeParameters(
        uint256 _minDuration,
        uint256 _maxDuration,
        uint256 _protocolInterestRate,
        uint256 _slope,
        uint256 _maxUtilization
    ) external {
        if(msg.sender != multisig) revert NotMultisig();
        if(parametersInitialized) revert AlreadyInitialized();
        parametersInitialized = true;
        minDuration = _minDuration;
        maxDuration = _maxDuration;
        protocolInterestRate = _protocolInterestRate;
        slope = _slope;
        maxUtilization = _maxUtilization;
        emit NewDurations(_minDuration, _maxDuration);
        emit NewProtocolInterestRate(_protocolInterestRate);
        emit NewSlope(_slope);
    }

    /// @inheritdoc IGoldilendBase
    function recoverTokens(address token) external {
        if(msg.sender != multisig) revert NotMultisig();
        SafeTransferLib.safeTransfer(token, multisig, ERC20(token).balanceOf(address(this)));
    }

    /// @inheritdoc IGoldilendBase
    function increaseglWBERABacking(uint256 amount) external {
        if(msg.sender != multisig) revert NotMultisig();
        SafeTransferLib.safeTransferFrom(wbera, msg.sender, address(this), amount);
        poolSize += amount;
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