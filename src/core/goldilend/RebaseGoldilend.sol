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
contract RebaseGoldilend is Initializable, OwnableUpgradeable, UUPSUpgradeable, IRebaseGoldilend {
    

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      STATE VARIABLES                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


    /// @notice Value for calculating interest payment on loans
    uint256 public constant INTEREST_PAYMENT_PERCENTAGE = 5e17;

    /// @notice Buffer period where borrowers are protected from liquidation
    uint256 public constant LOAN_GRACE_PERIOD = 1 days;

    uint256 public constant AUCTION_PERIOD = 2 days;

    /// @notice Address of multisig
    address public multisig;

    /// @notice Address of the Debt Asset
    address public debtAsset;

    /// @notice Address of Goldilend Debt Asset
    address public glDebtAsset;

    /// @notice Interest rate of protocol
    uint256 public protocolInterestRate;

    /// @notice Outstanding debt of all unpaid loans
    uint256 public outstandingDebt;

    /// @notice Rate at which interest rate increases
    uint256 public slope;

    /// @notice Minimum loan duration
    uint256 public minDuration;

    /// @notice Maximum loan duration
    uint256 public maxDuration;

    /// @notice Maximum utilization of protocol liquidity
    uint256 public maxUtilization;

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

    mapping(address => mapping(uint256 => Bid[])) public bids;


    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTRUCTOR                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializer of the contract
    /// @param _multisig Address of the multisig
    /// @param _debtAsset Address of the Debt Asset
    /// @param _glDebtAsset Address of Goldilend Debt Asset
    function initialize(
        address _multisig,
        address _debtAsset,
        address _glDebtAsset
    ) public initializer {
        __Ownable_init(_multisig);
        __UUPSUpgradeable_init();
        multisig = _multisig;
        debtAsset = _debtAsset;
        glDebtAsset = _glDebtAsset;
    }


    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      EXTERNAL FUNCTIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


    /// @inheritdoc IRebaseGoldilend
    function deposit(uint256 amount) external {
        SafeTransferLib.safeTransferFrom(debtAsset, msg.sender, address(this), amount);
        GoldilendDebtAsset(glDebtAsset).mintglDebtAsset(msg.sender, amount);
        emit Deposit(msg.sender, amount);
    }

    /// @inheritdoc IRebaseGoldilend
    function withdraw(uint256 amount) external {
        GoldilendDebtAsset(glDebtAsset).burnglDebtAsset(msg.sender, amount);
        SafeTransferLib.safeTransfer(debtAsset, msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }

    /// @inheritdoc IRebaseGoldilend
    function borrow(
        uint256 borrowAmount,
        uint256 maxInterest,
        uint256 duration,
        address collateralNFT,
        uint256 collateralNFTId
    ) external {
        if(!borrowingActive) revert NotActive();
        if(duration < minDuration || duration > maxDuration) revert InvalidDuration();
        uint256 _glhoneySupply = GoldilendDebtAsset(glDebtAsset).totalSupply();
        uint256 fairValue = nftFairValues[collateralNFT];
        uint256 userLoansLength = userLoanAmount[msg.sender];
        uint256 _outstandingDebt = outstandingDebt;
        if(borrowAmount > _glhoneySupply / 10) revert InvalidLoanAmount();
        uint256 interest = _calculateInterest(borrowAmount, _outstandingDebt, duration);
        if(fairValue == 0) revert InvalidCollateral();
        if(_outstandingDebt + borrowAmount > _glhoneySupply * maxUtilization / 100) revert MaxUtilizationExceeded();
        if(borrowAmount + interest > fairValue || borrowAmount > _glhoneySupply - _outstandingDebt) revert BorrowLimitExceeded();
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
        if(interest > maxInterest) revert MoreThanMaxInterest();
        SafeTransferLib.safeTransfer(debtAsset, msg.sender, borrowAmount - interest);
        SafeTransferLib.safeTransfer(debtAsset, multisig, interest);
        emit Borrow(msg.sender, userLoansLength + 1, borrowAmount, interest, block.timestamp + duration, collateralNFT, collateralNFTId);
    }

    /// @inheritdoc IRebaseGoldilend
    function renew(
        uint256 userLoanId,
        uint256 newDuration,
        uint256 newBorrowAmount,
        uint256 maxInterest
    ) external {
        if(!borrowingActive) revert NotActive();
        if(newDuration < minDuration || newDuration > maxDuration) revert InvalidDuration();
        Loan memory userLoan = loans[msg.sender][userLoanId];
        if(userLoan.repaid || userLoan.liquidated) revert InvalidRenew();
        if(block.timestamp > userLoan.endDate + LOAN_GRACE_PERIOD) revert LoanExpired();
        uint256 _outstandingDebt = outstandingDebt;
        uint256 _glhoneySupply = GoldilendDebtAsset(glDebtAsset).totalSupply();
        uint256 newInterest = _calculateInterest(userLoan.borrowedAmount + newBorrowAmount, _outstandingDebt, newDuration);
        if(userLoan.borrowedAmount + newBorrowAmount > _glhoneySupply / 10) revert InvalidLoanAmount();
        if(_outstandingDebt + newBorrowAmount > _glhoneySupply * maxUtilization / 100) revert MaxUtilizationExceeded();
        if(userLoan.borrowedAmount + newBorrowAmount + newInterest > nftFairValues[userLoan.collateralNFT] || newBorrowAmount > _glhoneySupply - _outstandingDebt) revert BorrowLimitExceeded();
        outstandingDebt += newBorrowAmount;
        Loan storage newUserLoan = loans[msg.sender][userLoanId];
        newUserLoan.borrowedAmount += newBorrowAmount;
        newUserLoan.interest += newInterest;
        newUserLoan.duration += newDuration;
        newUserLoan.endDate = block.timestamp + newDuration;
        if(newInterest > maxInterest) revert MoreThanMaxInterest();
        SafeTransferLib.safeTransfer(debtAsset, msg.sender, newBorrowAmount - newInterest);
        SafeTransferLib.safeTransfer(debtAsset, multisig, newInterest);
        emit Renew(msg.sender, userLoanId, newBorrowAmount, newInterest, newDuration);
    }

    /// @inheritdoc IRebaseGoldilend
    function repay(uint256 repayAmount, uint256 userLoanId) external {
        Loan memory userLoan = loans[msg.sender][userLoanId];
        if(userLoan.repaid || userLoan.liquidated) revert InvalidRepay();
        if(repayAmount > userLoan.borrowedAmount) revert OverPayment();
        if(block.timestamp > userLoan.endDate + LOAN_GRACE_PERIOD) revert LoanExpired();
        if(repayAmount > outstandingDebt) repayAmount = outstandingDebt;
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

    // /// @inheritdoc IRebaseGoldilend
    // function liquidate(address user, uint256 userLoanId) external {
    //     Loan memory userLoan = loans[user][userLoanId];
    //     if(block.timestamp < userLoan.endDate + LOAN_GRACE_PERIOD || userLoan.borrowedAmount == 0) revert Unliquidatable();
    //     loans[user][userLoanId].liquidated = true;
    //     loans[user][userLoanId].borrowedAmount = 0;
    //     outstandingDebt -=  userLoan.borrowedAmount > outstandingDebt ? outstandingDebt : userLoan.borrowedAmount;
    //     IERC721(userLoan.collateralNFT).transferFrom(address(this), multisig, userLoan.collateralNFTId);
    //     emit Liquidation(msg.sender, user, userLoan.borrowedAmount, userLoanId);
    // }

    /// @inheritdoc IRebaseGoldilend
    function placeBid(address loanOriginator, uint256 loanId, uint256 bidAmount) external {
        Loan memory userLoan = loans[loanOriginator][loanId];
        if(userLoan.repaid || userLoan.liquidated) revert Unliquidatable();
        if(block.timestamp <= userLoan.endDate + LOAN_GRACE_PERIOD) revert Unliquidatable();
        if(block.timestamp > userLoan.endDate + LOAN_GRACE_PERIOD + AUCTION_PERIOD) revert AuctionEnded();
        SafeTransferLib.safeTransferFrom(debtAsset, msg.sender, address(this), bidAmount);
        Bid memory newBid = Bid({
            loanOriginator: loanOriginator,
            loanId: loanId,
            bidder: msg.sender,
            bidAmount: bidAmount
        });        
        bids[loanOriginator][loanId].push(newBid);        
        emit BidPlaced(loanOriginator, loanId, msg.sender, bidAmount);
    }

    /// @inheritdoc IRebaseGoldilend
    function closeAuction(address loanOriginator, uint256 loanId) external {
        Loan memory userLoan = loans[loanOriginator][loanId];
        if(userLoan.repaid || userLoan.liquidated) revert Unliquidatable();
        if(block.timestamp <= userLoan.endDate + LOAN_GRACE_PERIOD + AUCTION_PERIOD) revert AuctionNotEnded();
        Bid[] memory loanBids = bids[loanOriginator][loanId];
        loans[loanOriginator][loanId].liquidated = true;
        loans[loanOriginator][loanId].borrowedAmount = 0;
        outstandingDebt -= userLoan.borrowedAmount > outstandingDebt ? outstandingDebt : userLoan.borrowedAmount;
        if(loanBids.length == 0) {
            IERC721(userLoan.collateralNFT).transferFrom(address(this), multisig, userLoan.collateralNFTId);
            emit AuctionClosed(loanOriginator, loanId, multisig, 0, true);
        }
        else {
            uint256 highestBidIndex = 0;
            uint256 highestBidAmount = loanBids[0].bidAmount;
            uint256 loanBidsLength = loanBids.length;
            for(uint256 i = 1; i < loanBidsLength; ++i) {
                if(loanBids[i].bidAmount > highestBidAmount) {
                    highestBidAmount = loanBids[i].bidAmount;
                    highestBidIndex = i;
                }
            }
            address winner = loanBids[highestBidIndex].bidder;
            IERC721(userLoan.collateralNFT).transferFrom(address(this), winner, userLoan.collateralNFTId);
            if(highestBidAmount > userLoan.borrowedAmount) {
                SafeTransferLib.safeTransfer(debtAsset, multisig, highestBidAmount - userLoan.borrowedAmount);
            }
            for(uint256 i; i < loanBids.length; ++i) {
                if(i != highestBidIndex) {
                    SafeTransferLib.safeTransfer(debtAsset, loanBids[i].bidder, loanBids[i].bidAmount);
                }
            }
            emit AuctionClosed(loanOriginator, loanId, winner, highestBidAmount, false);
        }
        emit Liquidation(msg.sender, loanOriginator, userLoan.borrowedAmount, loanId);
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
        if(nftFairValues[collateralNFT] == 0) revert InvalidCollateral();
        uint256 _glhoneySupply = GoldilendDebtAsset(glDebtAsset).totalSupply();
        if(borrowAmount > _glhoneySupply / 10) revert InvalidLoanAmount();
        uint256 fairValue = nftFairValues[collateralNFT];
        uint256 debt = outstandingDebt;
        uint256 _interest = _calculateInterest(borrowAmount, debt, duration);
        if(debt + borrowAmount > _glhoneySupply * maxUtilization / 100) revert MaxUtilizationExceeded();
        if(borrowAmount + _interest > fairValue || borrowAmount > _glhoneySupply - debt) revert BorrowLimitExceeded();
        return _interest;
    }


    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    INTERNAL VIEW FUNCTION                  */
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
        uint256 ratio = FixedPointMathLib.divWad(debt + borrowAmount, GoldilendDebtAsset(glDebtAsset).totalSupply()) + INTEREST_PAYMENT_PERCENTAGE;
        uint256 interestRate = rate + FixedPointMathLib.mulWad(FixedPointMathLib.mulWad(slope, rate), FixedPointMathLib.mulWad(ratio, durationPortion));
        return FixedPointMathLib.mulWad(FixedPointMathLib.mulWad(interestRate, borrowAmount), durationPortion);
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
    ) public {
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

        changeLendingParams(_protocolInterestRate, _minDuration, _maxDuration, _slope, _maxUtilization);
        
        parametersInitialized = true;
    }

    /// @inheritdoc IRebaseGoldilend
    function recoverTokens(address token) external {
        if(msg.sender != multisig) revert NotMultisig();
        SafeTransferLib.safeTransfer(token, multisig, ERC20(token).balanceOf(address(this)));
    }

    /// @inheritdoc IRebaseGoldilend
    function changeValue(
        address[] calldata _nfts,
        uint256[] calldata _nftFairValues
    ) public {
        if(msg.sender != multisig) revert NotMultisig();
        if(_nfts.length != _nftFairValues.length) revert ArrayMismatch();
        uint256 nftFairValuesLength = _nftFairValues.length;
        for(uint256 i; i < nftFairValuesLength; ++i) {
            nftFairValues[_nfts[i]] = _nftFairValues[i];
        }
    }

    /// @inheritdoc IRebaseGoldilend
    function initializeBeras(
        address[] calldata _nfts,
        uint256[] calldata _nftFairValues
    ) external {
        if(msg.sender != multisig) revert NotMultisig();
        if(berasInitialized) revert AlreadyInitialized();
        
        changeValue(_nfts, _nftFairValues);

        berasInitialized = true;
        borrowingActive = true;
    }


    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  IMPLEMENTATION FUNCTIONS                  */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

}