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
// =================================== RebaseGoldilend ==========================================
// ==============================================================================================


import { FixedPointMathLib } from "../../../lib/solady/src/utils/FixedPointMathLib.sol";
import { SafeTransferLib } from "../../../lib/solady/src/utils/SafeTransferLib.sol";
import { ERC20 } from "../../../lib/solady/src/tokens/ERC20.sol";
import { IERC721 } from "../../../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import { IERC721Receiver } from "../../../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import { Initializable } from "../../../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "../../../lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import { UUPSUpgradeable } from "../../../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import { IRebaseGoldilend } from "../../interfaces/IRebaseGoldilend.sol";
import { GoldilendDebtAsset } from "./GoldilendDebtAsset.sol";


/// @title RebaseGoldilend 
/// @notice Bong Bear (and rebase) Fixed Term NFT Lending
contract RebaseGoldilend is Initializable, OwnableUpgradeable, UUPSUpgradeable, IRebaseGoldilend, IERC721Receiver {
    

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

    /// @notice Address of the Debt Asset
    address public debtAsset;

    /// @notice Address of Goldilend Debt Asset
    address public glDebtAsset;

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
    /// @param _debtAsset Address of the Debt Asset
    /// @param _glDebtAsset Address of Goldilend Debt Asset
    function initialize(
        address _timelock,
        address _multisig,
        address _debtAsset,
        address _glDebtAsset
    ) public initializer {
        __Ownable_init(_multisig);
        __UUPSUpgradeable_init();
        timelock = _timelock;
        multisig = _multisig;
        debtAsset = _debtAsset;
        glDebtAsset = _glDebtAsset;
    }


    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      EXTERNAL FUNCTIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


    /// @inheritdoc IRebaseGoldilend
    function deposit(uint256 amount) external {
        uint256 mintAmount = _glDebtAssetMintAmount(amount);
        poolSize += amount;
        SafeTransferLib.safeTransferFrom(debtAsset, msg.sender, address(this), amount);
        GoldilendDebtAsset(glDebtAsset).mintglDebtAsset(msg.sender, mintAmount);
        emit Deposit(msg.sender, amount, mintAmount);
    }

    /// @inheritdoc IRebaseGoldilend
    function withdraw(uint256 amount) external {
        uint256 withdrawAmount = _glDebtAssetWithdrawAmount(amount);
        poolSize -= withdrawAmount;
        GoldilendDebtAsset(glDebtAsset).burnglDebtAsset(msg.sender, amount);
        SafeTransferLib.safeTransfer(debtAsset, msg.sender, withdrawAmount);
        emit Withdraw(msg.sender, withdrawAmount, amount);
    }

    /// @inheritdoc IRebaseGoldilend
    function borrow(
        uint256 borrowAmount,
        uint256 duration,
        address collateralNFT,
        uint256 collateralNFTId
    ) external {
        if(!borrowingActive) revert NotActive();
        if(duration < minDuration || duration > maxDuration) revert InvalidDuration();
        uint256 _poolSize = poolSize;
        uint256 fairValue = nftFairValues[collateralNFT];
        uint256 userLoansLength = userLoanAmount[msg.sender];
        uint256 _outstandingDebt = outstandingDebt;
        if(borrowAmount > _poolSize / 10) revert InvalidLoanAmount();
        uint256 interest = _calculateInterest(borrowAmount, _outstandingDebt, duration);
        if(fairValue == 0) revert InvalidCollateral();
        if(_outstandingDebt + borrowAmount > _poolSize * maxUtilization / 100) revert MaxUtilizationExceeded();
        if(borrowAmount + interest > fairValue || borrowAmount > _poolSize - _outstandingDebt) revert BorrowLimitExceeded();
        outstandingDebt += borrowAmount;
        Loan memory loan = Loan({
            collateralNFT: collateralNFT,
            collateralNFTId: collateralNFTId,
            borrowedAmount: borrowAmount,
            interest: interest,
            duration: duration,
            endDate: block.timestamp + duration,
            loanId: userLoansLength + 1,
            repaid: false,
            liquidated: false
        });
        loans[msg.sender][userLoansLength + 1] = loan;
        userLoanAmount[msg.sender]++;
        IERC721(collateralNFT).transferFrom(msg.sender, address(this), collateralNFTId);
        SafeTransferLib.safeTransfer(debtAsset, msg.sender, borrowAmount - interest);
        SafeTransferLib.safeTransfer(debtAsset, multisig, interest);
        emit Borrow(msg.sender, userLoansLength + 1, borrowAmount, interest, block.timestamp + duration, collateralNFT, collateralNFTId);
    }

    /// @inheritdoc IRebaseGoldilend
    function renew(
        uint256 userLoanId,
        uint256 newDuration,
        uint256 newBorrowAmount
    ) external {
        if(!borrowingActive) revert NotActive();
        if(newDuration < minDuration || newDuration > maxDuration) revert InvalidDuration();
        Loan memory userLoan = loans[msg.sender][userLoanId];
        uint256 _outstandingDebt = outstandingDebt;
        uint256 _poolSize = poolSize;
        uint256 newInterest = _calculateInterest(userLoan.borrowedAmount + newBorrowAmount, _outstandingDebt, newDuration);
        if(newBorrowAmount > _poolSize / 10) revert InvalidLoanAmount();
        if(_outstandingDebt + newBorrowAmount > _poolSize * maxUtilization / 100) revert MaxUtilizationExceeded();
        if(userLoan.borrowedAmount + newBorrowAmount + newInterest > nftFairValues[userLoan.collateralNFT] || newBorrowAmount > _poolSize - _outstandingDebt) revert BorrowLimitExceeded();
        outstandingDebt += newBorrowAmount;
        Loan storage newUserLoan = loans[msg.sender][userLoanId];
        newUserLoan.borrowedAmount += newBorrowAmount;
        newUserLoan.interest += newInterest;
        newUserLoan.duration += newDuration;
        newUserLoan.endDate += newDuration;
        SafeTransferLib.safeTransfer(debtAsset, msg.sender, newBorrowAmount - newInterest);
        SafeTransferLib.safeTransfer(debtAsset, multisig, newInterest);
        emit Renew(msg.sender, userLoanId, newBorrowAmount, newInterest, newDuration);
    }

    /// @inheritdoc IRebaseGoldilend
    function repay(uint256 repayAmount, uint256 userLoanId) external {
        Loan memory userLoan = loans[msg.sender][userLoanId];
        if(repayAmount > userLoan.borrowedAmount) repayAmount = userLoan.borrowedAmount;
        if(block.timestamp > userLoan.endDate + LOAN_GRACE_PERIOD) revert LoanExpired();
        if(repayAmount > _outstandingDebt) repayAmount = _outstandingDebt;
        outstandingDebt -= repayAmount;
        SafeTransferLib.safeTransferFrom(debtAsset, msg.sender, address(this), repayAmount);
        if(userLoan.borrowedAmount - repayAmount == 0) {
            loans[msg.sender][userLoanId].borrowedAmount = 0;
            loans[msg.sender][userLoanId].repaid = true;
            IERC721(userLoan.collateralNFT).transferFrom(address(this), msg.sender, userLoan.collateralNFTId);
        }
        else {
            loans[msg.sender][userLoanId].borrowedAmount -= repayAmount;
        }
        emit Repay(msg.sender, userLoanId, repayAmount);
    }

    /// @inheritdoc IRebaseGoldilend
    function liquidate(address user, uint256 userLoanId) external {
        Loan memory userLoan = loans[user][userLoanId];
        if(block.timestamp < userLoan.endDate + LOAN_GRACE_PERIOD || userLoan.liquidated || userLoan.borrowedAmount == 0) revert Unliquidatable();
        loans[user][userLoanId].liquidated = true;
        loans[user][userLoanId].borrowedAmount = 0;
        outstandingDebt -=  userLoan.borrowedAmount > outstandingDebt ? outstandingDebt : userLoan.borrowedAmount;
        poolSize -= userLoan.borrowedAmount > poolSize ? poolSize : userLoan.borrowedAmount;
        IERC721(userLoan.collateralNFT).safeTransferFrom(address(this), multisig, userLoan.collateralNFTId);
        emit Liquidation(msg.sender, user, userLoan.borrowedAmount, userLoanId);
    }


    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  EXTERNAL VIEW FUNCTIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


    /// @inheritdoc IRebaseGoldilend
    function getUserLoan(address user, uint256 userLoanId) external view returns (Loan memory) {
        return loans[user][userLoanId];
    }

    /// @inheritdoc IRebaseGoldilend
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

    /// @notice Calculates the amount of Goldilend Debt Asset to mint
    /// @param depositAmount Amount of the debt asset to deposit
    /// @return mintAmount Total supply of the goldilend debt asset divided by the lending pool size multiplied by depsoitAmount
    function _glDebtAssetMintAmount(uint256 depositAmount) internal view returns (uint256) {
        uint256 supply = GoldilendDebtAsset(glDebtAsset).totalSupply();
        uint256 _poolSize = poolSize;
        return _poolSize > 0 && supply > 0 ? FixedPointMathLib.mulWad(depositAmount, _glDebtAssetRatio(supply, _poolSize)) : depositAmount;
    }

    /// @notice Calculates the amount of debt asset to withdraw
    /// @param burnAmount Amount of the Goldilend Debt Asset to burn 
    /// @return withdrawAmount The burnAmount divided by the total supply of goldilend debt asset divided by the lending pool size
    function _glDebtAssetWithdrawAmount(uint256 burnAmount) internal view returns (uint256) {
        uint256 supply = GoldilendDebtAsset(glDebtAsset).totalSupply();
        uint256 _poolSize = poolSize;
        return FixedPointMathLib.divWad(burnAmount, _glDebtAssetRatio(supply, _poolSize));
    }

    /// @notice Calculates the current glDebtAsset ratio
    /// @return gibgtRatio Total supply of glDebtAsset divided by the lending pool size
    function _glDebtAssetRatio(uint256 supply, uint256 _poolSize) internal pure returns (uint256) {
        return FixedPointMathLib.divWad(supply, _poolSize);
    }


    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    PERMISSIONED FUNCTIONS                  */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


    /// @inheritdoc IRebaseGoldilend
    function changeLendingParams(
        uint256 _protocolInterestRate,
        uint256 _minDuration,
        uint256 _maxDuration,
        uint256 _slope,
        uint256 _maxUtilization
    ) external {
        if(msg.sender != multisig) revert NotMultisig();
        protocolInterestRate = _protocolInterestRate;
        minDuration = _minDuration;
        maxDuration = _maxDuration;
        slope = _slope;
        maxUtilization = _maxUtilization;
        emit NewProtocolInterestRate(_protocolInterestRate);
        emit NewDurations(_minDuration, _maxDuration);
        emit NewSlope(_slope);
        emit NewMaxUtilization(_maxUtilization);
    }

    /// @inheritdoc IRebaseGoldilend
    function changeBorrowingActive(bool _borrowingActive) external {
        if(msg.sender != multisig) revert NotMultisig();
        borrowingActive = _borrowingActive;
        emit NewBorrowingActive(_borrowingActive);
    }

    /// @inheritdoc IRebaseGoldilend
    function initializeParameters(
        uint256 _protocolInterestRate,
        uint256 _minDuration,
        uint256 _maxDuration,
        uint256 _slope,
        uint256 _maxUtilization
    ) external {
        if(msg.sender != multisig) revert NotMultisig();
        if(parametersInitialized) revert AlreadyInitialized();
        parametersInitialized = true;
        protocolInterestRate = _protocolInterestRate;
        minDuration = _minDuration;
        maxDuration = _maxDuration;
        slope = _slope;
        maxUtilization = _maxUtilization;
        emit NewProtocolInterestRate(_protocolInterestRate);
        emit NewDurations(_minDuration, _maxDuration);
        emit NewSlope(_slope);
        emit NewMaxUtilization(_maxUtilization);
    }

    /// @inheritdoc IRebaseGoldilend
    function recoverTokens(address token) external {
        if(msg.sender != multisig) revert NotMultisig();
        SafeTransferLib.safeTransfer(token, multisig, ERC20(token).balanceOf(address(this)));
    }

    /// @inheritdoc IRebaseGoldilend
    function increaseglDebtAssetBacking(uint256 amount) external {
        if(msg.sender != multisig) revert NotMultisig();
        SafeTransferLib.safeTransferFrom(debtAsset, msg.sender, address(this), amount);
        poolSize += amount;
    }

    /// @inheritdoc IRebaseGoldilend
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

    /// @inheritdoc IRebaseGoldilend
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


    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  IMPLEMENTATION FUNCTIONS                  */
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