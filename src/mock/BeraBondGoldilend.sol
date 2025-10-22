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
// ================================== BeraBondGoldilend =========================================
// ==============================================================================================


import { FixedPointMathLib } from "../../lib/solady/src/utils/FixedPointMathLib.sol";
import { SafeTransferLib } from "../../lib/solady/src/utils/SafeTransferLib.sol";
import { ERC20 } from "../../lib/solady/src/tokens/ERC20.sol";
import { IERC721 } from "../../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import { IERC721Receiver } from "../../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import { Initializable } from "../../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "../../lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import { UUPSUpgradeable } from "../../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import { IBeraBondNFT } from "../interfaces/IBeraBondNFT.sol";
import { IGl00DelegationRegistry } from "../interfaces/IGl00DelegationRegistry.sol";
import { GoldilendDebtAsset } from "../core/goldilend/GoldilendDebtAsset.sol";
import { IBeraBondGoldilend } from "../interfaces/IBeraBondGoldilend.sol";


/// @title BeraBondGoldilend 
/// @notice BeraBond Fixed Term NFT Lending
contract BeraBondGoldilend is Initializable, OwnableUpgradeable, UUPSUpgradeable, IBeraBondGoldilend {


    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      STATE VARIABLES                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


    /// @notice Value for calculating interest payment on loans
    uint256 public constant INTEREST_PAYMENT_PERCENTAGE = 5e17;

    /// @notice Buffer period where borrowers are protected from liquidation
    uint256 public constant LOAN_GRACE_PERIOD = 1 days;

    /// @notice Period where bidders may place bids on liquidatable loans
    uint256 public constant AUCTION_PERIOD = 2 days;

    /// @notice Address of multisig
    address public multisig;

    /// @notice Address of Goldilend Debt Asset
    address public glDebtAsset;

    /// @notice Address of Berachain Governance Token
    address public bgt;

    /// @notice Address of BeraBond NFT
    address public berabond;

    /// @notice Address of BeraBond Delegation Registry
    address public delegationRegistry;

    /// @notice Maximum Loan to Value ratio
    uint256 public LTV;

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

    /// @notice Minimum renew duration
    uint256 public renewMinDuration;

    /// @notice Maximum renew duration
    uint256 public renewMaxDuration;

    /// @notice Maximum utilization of protocol liquidity
    uint256 public maxUtilization;

    /// @notice Boolean value if borrowing is active
    bool public borrowingActive;

    /// @notice Indicates if contract parameters are initialized
    bool public parametersInitialized;

    /// @notice Tracks surplus winning bids on liquidatable loan auctions
    uint256 public auctionSurplus;

    /// @notice Maps users to total amount of their loans
    mapping(address => uint256) public userLoanAmount;

    /// @notice Maps users to loans
    mapping(address => mapping(uint256 => Loan)) public loans;

    /// @notice Maps user address to IDs of BeraBonds in Goldilend
    mapping(address => uint256[]) public depositedBeraBondIDs;

    /// @notice Maps loan originator to loan id to the highest bid
    mapping(address => mapping(uint256 => Bid)) public highestBid;


    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTRUCTOR                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializer of the contract
    /// @param _multisig Address of the multisig
    /// @param _glDebtAsset Address of Goldilend Debt Asset
    /// @param _bgt Address of BGT
    /// @param _berabond Address of BeraBond
    /// @param _delegationRegistry Address of the BeraBond Delegation Registry
    function initialize(
        address _multisig,
        address _glDebtAsset,
        address _bgt,
        address _berabond,
        address _delegationRegistry
    ) public initializer {
        __Ownable_init(_multisig);
        __UUPSUpgradeable_init();
        multisig = _multisig;
        glDebtAsset = _glDebtAsset;
        bgt = _bgt;
        berabond = _berabond;
        delegationRegistry = _delegationRegistry;
    }


    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      EXTERNAL FUNCTIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


    /// @inheritdoc IBeraBondGoldilend
    function deposit() external payable {
        if(msg.value == 0) revert InvalidAmount();
        GoldilendDebtAsset(glDebtAsset).mintglDebtAsset(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    /// @inheritdoc IBeraBondGoldilend
    function withdraw(uint256 amount) external {
        GoldilendDebtAsset(glDebtAsset).burnglDebtAsset(msg.sender, amount);
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if(!success) revert TransferFailed();
        emit Withdraw(msg.sender, amount);
    }

    /// @inheritdoc IBeraBondGoldilend
    function borrow(
        uint256 borrowAmount,
        uint256 maxInterest,
        uint256 duration,
        address collateralNFT,
        uint256 collateralNFTId
    ) external payable {
        if(!borrowingActive) revert NotActive();
        if(duration < minDuration || duration > maxDuration) revert InvalidDuration();
        if(collateralNFT != berabond) revert InvalidCollateral();
        uint256 bgtBalance = _getTBABGTBalance(collateralNFT, collateralNFTId);
        uint256 maxBorrow = bgtBalance * LTV / 100;
        uint256 interest = _calculateInterest(borrowAmount, outstandingDebt, duration);
        uint256 _gberaSupply = GoldilendDebtAsset(glDebtAsset).totalSupply();
        if(borrowAmount + interest > maxBorrow) revert InvalidLoanAmount();
        if(borrowAmount > _gberaSupply / 10) revert InvalidLoanAmount();
        if(outstandingDebt + borrowAmount > _gberaSupply * maxUtilization / 100) revert MaxUtilizationExceeded();
        if(borrowAmount > _gberaSupply - outstandingDebt) revert BorrowLimitExceeded();
        uint256 userLoansLength = userLoanAmount[msg.sender];
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
        depositedBeraBondIDs[msg.sender].push(collateralNFTId);
        IERC721(collateralNFT).transferFrom(msg.sender, address(this), collateralNFTId);
        if(interest > maxInterest) revert MoreThanMaxInterest();
        (bool success1, ) = payable(msg.sender).call{value: borrowAmount - interest}("");
        if(!success1) revert TransferFailed();
        (bool success2, ) = payable(multisig).call{value: interest}("");
        if(!success2) revert TransferFailed();
        emit Borrow(msg.sender, userLoansLength + 1, borrowAmount, interest, block.timestamp + duration, collateralNFT, collateralNFTId);
    }

    /// @inheritdoc IBeraBondGoldilend
    function renew(
        uint256 userLoanId,
        uint256 newDuration,
        uint256 newBorrowAmount,
        uint256 maxInterest
    ) external payable {
        if(!borrowingActive) revert NotActive();
        if(newDuration < renewMinDuration || newDuration > renewMaxDuration) revert InvalidDuration();
        Loan memory userLoan = loans[msg.sender][userLoanId];
        if(userLoan.repaid || userLoan.liquidated) revert InvalidRenew();
        if(userLoan.endDate - block.timestamp > renewMinDuration) revert InvalidRenew();
        if(block.timestamp > userLoan.endDate + LOAN_GRACE_PERIOD) revert LoanExpired();
        uint256 _outstandingDebt = outstandingDebt;
        uint256 _gberaSupply = GoldilendDebtAsset(glDebtAsset).totalSupply();
        uint256 newEndDate = block.timestamp + newDuration;
        uint256 newInterest = _calculateInterest(userLoan.borrowedAmount, _outstandingDebt, newEndDate - userLoan.endDate) + newBorrowAmount > 0 ? _calculateInterest(newBorrowAmount, _outstandingDebt, newDuration) : 0;
        uint256 bgtBalance = _getTBABGTBalance(userLoan.collateralNFT, userLoan.collateralNFTId);
        if(userLoan.borrowedAmount + newBorrowAmount + newInterest > bgtBalance * LTV / 100) revert InvalidLoanAmount();
        if(userLoan.borrowedAmount + newBorrowAmount > _gberaSupply / 10) revert InvalidLoanAmount();
        if(_outstandingDebt + newBorrowAmount > _gberaSupply * maxUtilization / 100) revert MaxUtilizationExceeded();
        if(newBorrowAmount > _gberaSupply - _outstandingDebt) revert BorrowLimitExceeded();
        outstandingDebt += newBorrowAmount;
        Loan storage newUserLoan = loans[msg.sender][userLoanId];
        newUserLoan.borrowedAmount += newBorrowAmount;
        newUserLoan.interest += newInterest;
        newUserLoan.duration = newDuration;
        newUserLoan.endDate = newEndDate;
        if(newInterest > maxInterest) revert MoreThanMaxInterest();
        if(newBorrowAmount > 0) {
            (bool success1, ) = payable(msg.sender).call{value: newBorrowAmount - newInterest}("");
            if(!success1) revert TransferFailed();
        }
        (bool success2, ) = payable(multisig).call{value: newInterest}("");
        if(!success2) revert TransferFailed();
        emit Renew(msg.sender, userLoanId, newBorrowAmount, newInterest, newDuration);
    }

    /// @inheritdoc IBeraBondGoldilend
    function repay(uint256 userLoanId) external payable {
        if(msg.value == 0) revert InvalidAmount();
        Loan memory userLoan = loans[msg.sender][userLoanId];
        if(userLoan.repaid || userLoan.liquidated) revert InvalidRepay();
        uint256 repayAmount = msg.value;
        if(repayAmount > userLoan.borrowedAmount) revert OverPayment();
        if(block.timestamp > userLoan.endDate + LOAN_GRACE_PERIOD) revert LoanExpired();
        if(repayAmount > outstandingDebt) repayAmount = outstandingDebt;
        outstandingDebt -= repayAmount;
        if(userLoan.borrowedAmount - repayAmount == 0) {
            loans[msg.sender][userLoanId].borrowedAmount = 0;
            loans[msg.sender][userLoanId].repaid = true;
            _removeFromDepositedBeraBondIDs(userLoan.collateralNFTId, msg.sender);
            IERC721(userLoan.collateralNFT).transferFrom(address(this), msg.sender, userLoan.collateralNFTId);
        }
        else {
            loans[msg.sender][userLoanId].borrowedAmount -= repayAmount;
        }
        emit Repay(msg.sender, userLoanId, repayAmount);
    }

    /// @inheritdoc IBeraBondGoldilend
    function placeBid(address loanOriginator, uint256 loanId) external payable {
        Loan memory userLoan = loans[loanOriginator][loanId];
        if(userLoan.repaid || userLoan.liquidated) revert Unliquidatable();
        if(block.timestamp <= userLoan.endDate + LOAN_GRACE_PERIOD) revert Unliquidatable();
        if(block.timestamp > userLoan.endDate + LOAN_GRACE_PERIOD + AUCTION_PERIOD) revert AuctionEnded();
        if(msg.value <= userLoan.borrowedAmount) revert InsufficientBid();
        Bid memory currentHighestBid = highestBid[loanOriginator][loanId];
        if(msg.value > currentHighestBid.bidAmount) {
            highestBid[loanOriginator][loanId] = Bid({
                loanOriginator: loanOriginator,
                loanId: loanId,
                bidder: msg.sender,
                bidAmount: msg.value
            });
            if(currentHighestBid.bidAmount > 0) payable(currentHighestBid.bidder).call{value: currentHighestBid.bidAmount}("");
            emit BidPlaced(loanOriginator, loanId, msg.sender, msg.value);
        }
        else {
            revert NotHighestBid();
        }
    }

    /// @inheritdoc IBeraBondGoldilend
    function closeAuction(address loanOriginator, uint256 loanId) external {
        Loan memory userLoan = loans[loanOriginator][loanId];
        if(userLoan.repaid || userLoan.liquidated) revert Unliquidatable();
        if(block.timestamp <= userLoan.endDate + LOAN_GRACE_PERIOD + AUCTION_PERIOD) revert AuctionNotEnded();
        Bid memory winningBid = highestBid[loanOriginator][loanId];
        loans[loanOriginator][loanId].liquidated = true;
        loans[loanOriginator][loanId].borrowedAmount = 0;
        outstandingDebt -= userLoan.borrowedAmount > outstandingDebt ? outstandingDebt : userLoan.borrowedAmount;
        if(winningBid.bidder == address(0)) {
            IERC721(userLoan.collateralNFT).transferFrom(address(this), multisig, userLoan.collateralNFTId);
            emit AuctionClosed(loanOriginator, loanId, multisig, 0, true);
        }
        else {
            address winner = winningBid.bidder;
            IERC721(userLoan.collateralNFT).transferFrom(address(this), winner, userLoan.collateralNFTId);
            if(winningBid.bidAmount > userLoan.borrowedAmount) {
                auctionSurplus += winningBid.bidAmount - userLoan.borrowedAmount;
            }
            emit AuctionClosed(loanOriginator, loanId, winner, winningBid.bidAmount, false);
        }
        emit Liquidation(msg.sender, loanOriginator, userLoan.borrowedAmount, loanId);
    }

    /// @inheritdoc IBeraBondGoldilend
    function claimYield(uint256 beraBondID, address[] memory rewardContracts) external {
        uint256 depositedBeraBondIDsLength = depositedBeraBondIDs[msg.sender].length;
        bool found = false;
        for(uint256 i; i < depositedBeraBondIDsLength; ++i) {
            if(depositedBeraBondIDs[msg.sender][i] == beraBondID) {
                found = true;
                break;
            }
        }
        if(!found) revert InvalidCollateral();
        address payable tba = IBeraBondNFT(berabond).getTokenBoundAccount(beraBondID);
        IBeraBondNFT(tba).claimFromEach(rewardContracts, msg.sender);
    }


    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  EXTERNAL VIEW FUNCTIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


    /// @inheritdoc IBeraBondGoldilend
    function getUserLoan(address user, uint256 userLoanId) external view returns (Loan memory) {
        return loans[user][userLoanId];
    }

    /// @inheritdoc IBeraBondGoldilend
    function calculateInterest(
        uint256 borrowAmount,
        uint256 duration,
        address collateralNFT,
        uint256 collateralNFTId
    ) external view returns (uint256) {
        if(duration < minDuration || duration > maxDuration) revert InvalidDuration();
        uint256 _gberaSupply = GoldilendDebtAsset(glDebtAsset).totalSupply();
        if(borrowAmount > _gberaSupply / 10) revert InvalidLoanAmount();
        if(collateralNFT != berabond) revert InvalidCollateral();
        uint256 bgtBalance = _getTBABGTBalance(collateralNFT, collateralNFTId);
        uint256 maxBorrow = bgtBalance * LTV / 100;
        uint256 debt = outstandingDebt;
        uint256 _interest = _calculateInterest(borrowAmount, debt, duration);
        if(debt + borrowAmount > _gberaSupply * maxUtilization / 100) revert MaxUtilizationExceeded();
        if(borrowAmount + _interest > maxBorrow || borrowAmount > _gberaSupply - debt) revert BorrowLimitExceeded();
        return _interest;
    }

    /// @inheritdoc IBeraBondGoldilend
    function getTBABGTBalance(address nft, uint256 tokenId) external view returns (uint256) {
        return _getTBABGTBalance(nft, tokenId);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     INTERNAL FUNCTIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/  

    /// @notice Removes an NFT ID from the depositedBeraBondIDs array
    /// @param beraBondID NFT ID to remove
    /// @param user User whose array to modify
    function _removeFromDepositedBeraBondIDs(uint256 beraBondID, address user) internal {
        uint256[] storage userDepositedIDs = depositedBeraBondIDs[user];
        uint256 depositedBeraBondIDsLength = depositedBeraBondIDs[user].length;
        for(uint256 i; i < depositedBeraBondIDsLength; ++i) {   
            if(userDepositedIDs[i] == beraBondID) {
                userDepositedIDs[i] = userDepositedIDs[userDepositedIDs.length - 1];
                userDepositedIDs.pop();
                break;
            }
        }
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
        uint256 ratio = FixedPointMathLib.divWad(debt + borrowAmount, GoldilendDebtAsset(glDebtAsset).totalSupply()) + INTEREST_PAYMENT_PERCENTAGE;
        uint256 interestRate = rate + FixedPointMathLib.mulWad(FixedPointMathLib.mulWad(slope, rate), FixedPointMathLib.mulWad(ratio, durationPortion));
        return FixedPointMathLib.mulWad(FixedPointMathLib.mulWad(interestRate, borrowAmount), durationPortion);
    }

    /// @notice Returns the BGT balance of the token bound account
    /// @param nft Address of the token bound account
    /// @param tokenId ID of the token bound account
    /// @return BGT balance of TBA
    function _getTBABGTBalance(address nft, uint256 tokenId) internal view returns (uint256) {
        address tba = IBeraBondNFT(nft).getTokenBoundAccount(tokenId);
        return ERC20(bgt).balanceOf(tba);
    }


    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    PERMISSIONED FUNCTIONS                  */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


    /// @inheritdoc IBeraBondGoldilend
    function changeLendingParams(
        uint256 _protocolInterestRate,
        uint256 _minDuration,
        uint256 _maxDuration,
        uint256 _renewMinDuration,
        uint256 _renewMaxDuration,
        uint256 _slope,
        uint256 _maxUtilization,
        uint256 _LTV
    ) public {
        if(msg.sender != multisig) revert NotMultisig();
        protocolInterestRate = _protocolInterestRate;
        minDuration = _minDuration;
        maxDuration = _maxDuration;
        renewMinDuration = _renewMinDuration;
        renewMaxDuration = _renewMaxDuration;
        slope = _slope;
        maxUtilization = _maxUtilization;
        LTV = _LTV;
        emit NewProtocolInterestRate(_protocolInterestRate);
        emit NewDurations(_minDuration, _maxDuration);
        emit NewSlope(_slope);
        emit NewMaxUtilization(_maxUtilization);
        emit NewLTV(_LTV);
    }

    /// @inheritdoc IBeraBondGoldilend
    function changeBorrowingActive(bool _borrowingActive) external {
        if(msg.sender != multisig) revert NotMultisig();
        borrowingActive = _borrowingActive;
        emit NewBorrowingActive(_borrowingActive);
    }

    /// @inheritdoc IBeraBondGoldilend
    function initializeParameters(
        uint256 _protocolInterestRate,
        uint256 _minDuration,
        uint256 _maxDuration,
        uint256 _renewMinDuration,
        uint256 _renewMaxDuration,
        uint256 _slope,
        uint256 _maxUtilization,
        uint256 _LTV
    ) external {
        if(msg.sender != multisig) revert NotMultisig();
        if(parametersInitialized) revert AlreadyInitialized();

        changeLendingParams(_protocolInterestRate, _minDuration, _maxDuration,  _renewMinDuration, _renewMaxDuration, _slope, _maxUtilization, _LTV);

        borrowingActive = true;
        parametersInitialized = true;
    }

    /// @inheritdoc IBeraBondGoldilend
    function recoverTokens(address token) external {
        if(msg.sender != multisig) revert NotMultisig();
        uint256 balance = ERC20(token).balanceOf(address(this));
        SafeTransferLib.safeTransfer(token, multisig, balance);
    }

    /// @inheritdoc IBeraBondGoldilend
    function withdrawSurplus() external {
        if(msg.sender != multisig) revert NotMultisig();
        uint256 _auctionSurplus = auctionSurplus;
        auctionSurplus = 0;
        (bool success, ) = payable(multisig).call{value: _auctionSurplus}("");
        if(!success) revert TransferFailed();
    }

    /// @inheritdoc IBeraBondGoldilend
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
    /*                  IMPLEMENTATION FUNCTIONS                  */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    receive() external payable {}

}