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
import { IPythUpgradable } from "../../interfaces/IPythUpgradable.sol";
import { IStreamingNFT } from "../../interfaces/IStreamingNFT.sol";


/// @title RebaseGoldilend 
/// @notice Bong Bear (and rebase) Fixed Term NFT Lending
contract RebaseGoldilend is Initializable, OwnableUpgradeable, UUPSUpgradeable, IRebaseGoldilend {
    

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      STATE VARIABLES                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


    /// @notice Buffer period where borrowers are protected from liquidation
    uint256 public constant LOAN_GRACE_PERIOD = 1 days;

    /// @notice Period where bidders may place bids on liquidatable loans
    uint256 public constant AUCTION_PERIOD = 2 days;

    /// @notice Address of multisig
    address public multisig;

    /// @notice Address of timelock
    address public timelock;

    /// @notice Address of the Debt Asset
    address public debtAsset;

    /// @notice Address of Goldilend Debt Asset
    address public glDebtAsset;

    /// @notice Address of Pyth price feed
    address public pythPriceFeed;

    /// @notice ID of the bera price feed
    bytes32 public beraPythPriceFeedId;

    /// @notice Value for calculating interest payment on loans
    uint256 public interestPaymentPercentage;

    /// @notice Value used to multiply utilization ratio in interest calculation
    uint256 public utilizationRatioMultiplier;

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

    /// @notice Minimum utilization of protocol liquidity
    uint256 public minUtilization;

    /// @notice Threshold of protocol liquidity to enfore minimum utilization
    uint256 public liquidityThreshold;

    /// @notice Boolean value if borrowing is active
    bool public borrowingActive;

    /// @notice Indicates if contract beras are initialized
    bool public berasInitialized;

    /// @notice Tracks surplus winning bids on liquidatable loan auctions
    uint256 public auctionSurplus;

    /// @notice Maps users to total amount of their loans
    mapping(address => uint256) public userLoanAmount;

    /// @notice Maps users to loans
    mapping(address => mapping(uint256 => Loan)) public loans;

    /// @notice Maps rebase bera to unvested weight
    mapping(address => uint256) public unvestedWeights;

    /// @notice Maps rebase bera to streaming contract address
    mapping(address => address) public streamingAddresses;

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
    /// @param _timelock Address of the timelock
    /// @param _debtAsset Address of the Debt Asset
    /// @param _glDebtAsset Address of Goldilend Debt Asset
    function initialize(
        address _multisig,
        address _timelock,
        address _debtAsset,
        address _glDebtAsset
    ) public initializer {
        __Ownable_init(_multisig);
        __UUPSUpgradeable_init();
        multisig = _multisig;
        timelock = _timelock;
        debtAsset = _debtAsset;
        glDebtAsset = _glDebtAsset;
    }


    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      EXTERNAL FUNCTIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


    /// @inheritdoc IRebaseGoldilend
    function deposit(uint256 amount) external {
        uint256 _ghoneySupply = GoldilendDebtAsset(glDebtAsset).totalSupply();
        uint256 newghoneySupply = _ghoneySupply + amount;
        if(_ghoneySupply > liquidityThreshold) {
            if(FixedPointMathLib.divWad(outstandingDebt, newghoneySupply) < minUtilization) revert MinUtilizationExceeded();
        }
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
        if(unvestedWeights[collateralNFT] == 0) revert InvalidCollateral();
        uint256 _ghoneySupply = GoldilendDebtAsset(glDebtAsset).totalSupply();
        uint256 userLoansLength = userLoanAmount[msg.sender];
        uint256 _outstandingDebt = outstandingDebt;
        if(borrowAmount > _ghoneySupply / 10) revert InvalidLoanAmount();
        uint256 interest = _calculateInterest(borrowAmount, _outstandingDebt, duration);
        uint256 fairValue = _calculateFairValue(collateralNFT);
        if(_outstandingDebt + borrowAmount > _ghoneySupply * maxUtilization / 100) revert MaxUtilizationExceeded();
        if(borrowAmount + interest > fairValue || borrowAmount > _ghoneySupply - _outstandingDebt) revert BorrowLimitExceeded();
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
        if(newDuration < renewMinDuration || newDuration > renewMaxDuration) revert InvalidDuration();
        Loan memory userLoan = loans[msg.sender][userLoanId];
        if(userLoan.repaid || userLoan.liquidated) revert InvalidRenew();
        if(block.timestamp > userLoan.endDate + LOAN_GRACE_PERIOD) revert LoanExpired();
        if(userLoan.endDate - block.timestamp > renewMinDuration) revert InvalidRenew();
        uint256 _outstandingDebt = outstandingDebt;
        uint256 _ghoneySupply = GoldilendDebtAsset(glDebtAsset).totalSupply();
        uint256 newEndDate = block.timestamp + newDuration;
        uint256 newInterest = _calculateInterest(userLoan.borrowedAmount, _outstandingDebt, newEndDate - userLoan.endDate) + newBorrowAmount > 0 ? _calculateInterest(newBorrowAmount, _outstandingDebt, newDuration) : 0;
        if(userLoan.borrowedAmount + newBorrowAmount > _ghoneySupply / 10) revert InvalidLoanAmount();
        if(_outstandingDebt + newBorrowAmount > _ghoneySupply * maxUtilization / 100) revert MaxUtilizationExceeded();
        if(userLoan.borrowedAmount + newBorrowAmount + newInterest > _calculateFairValue(userLoan.collateralNFT) || newBorrowAmount > _ghoneySupply - _outstandingDebt) revert BorrowLimitExceeded();
        outstandingDebt += newBorrowAmount;
        Loan storage newUserLoan = loans[msg.sender][userLoanId];
        newUserLoan.borrowedAmount += newBorrowAmount;
        newUserLoan.interest += newInterest;
        newUserLoan.duration = newDuration;
        newUserLoan.endDate = newEndDate;
        if(newInterest > maxInterest) revert MoreThanMaxInterest();
        if(newBorrowAmount > 0) SafeTransferLib.safeTransfer(debtAsset, msg.sender, newBorrowAmount - newInterest);
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

    /// @inheritdoc IRebaseGoldilend
    function placeBid(address loanOriginator, uint256 loanId, uint256 bidAmount) external {
        Loan memory userLoan = loans[loanOriginator][loanId];
        if(userLoan.repaid || userLoan.liquidated) revert Unliquidatable();
        if(block.timestamp <= userLoan.endDate + LOAN_GRACE_PERIOD) revert Unliquidatable();
        if(block.timestamp > userLoan.endDate + LOAN_GRACE_PERIOD + AUCTION_PERIOD) revert AuctionEnded();
        if(bidAmount <= userLoan.borrowedAmount) revert InsufficientBid();
        Bid memory currentHighestBid = highestBid[loanOriginator][loanId];
        if(bidAmount > currentHighestBid.bidAmount) {
            highestBid[loanOriginator][loanId] = Bid({
                loanOriginator: loanOriginator,
                loanId: loanId,
                bidder: msg.sender,
                bidAmount: bidAmount
            });
            SafeTransferLib.safeTransferFrom(debtAsset, msg.sender, address(this), bidAmount);
            if(currentHighestBid.bidAmount > 0) SafeTransferLib.safeTransfer(debtAsset, currentHighestBid.bidder, currentHighestBid.bidAmount);
            emit BidPlaced(loanOriginator, loanId, msg.sender, bidAmount);
        }
        else {
            revert NotHighestBid();
        }
    }

    /// @inheritdoc IRebaseGoldilend
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
        if(unvestedWeights[collateralNFT] == 0) revert InvalidCollateral();
        uint256 _ghoneySupply = GoldilendDebtAsset(glDebtAsset).totalSupply();
        if(borrowAmount > _ghoneySupply / 10) revert InvalidLoanAmount();
        uint256 fairValue = _calculateFairValue(collateralNFT);
        uint256 debt = outstandingDebt;
        uint256 _interest = _calculateInterest(borrowAmount, debt, duration);
        if(debt + borrowAmount > _ghoneySupply * maxUtilization / 100) revert MaxUtilizationExceeded();
        if(borrowAmount + _interest > fairValue || borrowAmount > _ghoneySupply - debt) revert BorrowLimitExceeded();
        return _interest;
    }

    /// @inheritdoc IRebaseGoldilend
    function calculateFairValue(address rebaseBera) external view returns (uint256) {
        return _calculateFairValue(rebaseBera);
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
        uint256 ratio = FixedPointMathLib.divWad(debt + borrowAmount, GoldilendDebtAsset(glDebtAsset).totalSupply() * utilizationRatioMultiplier) + interestPaymentPercentage;
        uint256 interestRate = FixedPointMathLib.mulWad(ratio, rate + FixedPointMathLib.mulWad(FixedPointMathLib.mulWad(slope, rate), durationPortion));
        return FixedPointMathLib.mulWad(FixedPointMathLib.mulWad(interestRate, borrowAmount), durationPortion);
    }

    /// @notice Calculates the fair value of a bera NFT based on its unvested bera
    /// @param rebaseBera Address of the bera NFT to be valued
    /// @return fairValue Fair value of NFT
    function _calculateFairValue(address rebaseBera) internal view returns (uint256) {
        IPythUpgradable.Price memory beraPriceResult = IPythUpgradable(pythPriceFeed).getPrice(beraPythPriceFeedId);
        uint256 beraPrice = uint256(uint64(beraPriceResult.price));

        uint256 vest;
        uint256 vestingDuration = 730 days;
        address streamingAddress = streamingAddresses[rebaseBera];
        uint256 cliffEnd = IStreamingNFT(streamingAddress).cliffEndTimestamp();
        uint256 cliffAmount = IStreamingNFT(streamingAddress).cliffUnlockAmount();
        uint256 vestedRewards = IStreamingNFT(streamingAddress).vestedRewards();
        if(block.timestamp < cliffEnd) {
            vest = cliffAmount + vestedRewards;
        }
        else {
            uint256 timeSinceCliff = block.timestamp - cliffEnd;
            if(timeSinceCliff >= vestingDuration) {
                vest = 0;
            }
            else {
                uint256 elapsedPortion = FixedPointMathLib.divWad(timeSinceCliff, vestingDuration);
                uint256 remainingPortion = 1e18 - elapsedPortion;
                vest = FixedPointMathLib.mulWad(remainingPortion, vestedRewards);
            }
        }

        uint256 formattedBeraPrice = beraPrice * (10 ** uint256(uint8(18 + int8(beraPriceResult.expo))));
        return FixedPointMathLib.mulWad(vest, formattedBeraPrice) * unvestedWeights[rebaseBera] / 100;
    }


    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    PERMISSIONED FUNCTIONS                  */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/


    /// @inheritdoc IRebaseGoldilend
    function changeLendingParams(
        uint256 _protocolInterestRate,
        uint256 _slope,
        address _pythPriceFeed,
        bytes32 _beraPythPriceFeedId,
        uint256 _interestPaymentPercentage,
        uint256 _utilizationRatioMultiplier,
        uint256 _minUtilization,
        uint256 _liquidityThreshold
    ) public {
        if(msg.sender != multisig) revert NotMultisig();
        protocolInterestRate = _protocolInterestRate;
        slope = _slope;
        pythPriceFeed = _pythPriceFeed;
        beraPythPriceFeedId = _beraPythPriceFeedId;
        interestPaymentPercentage = _interestPaymentPercentage;
        utilizationRatioMultiplier = _utilizationRatioMultiplier;
        minUtilization = _minUtilization;
        liquidityThreshold = _liquidityThreshold;
        emit NewProtocolInterestRate(_protocolInterestRate);
        emit NewSlope(_slope);
    }

    /// @inheritdoc IRebaseGoldilend
    function changeGovParams(
        uint256 _minDuration,
        uint256 _maxDuration,
        uint256 _renewMinDuration,
        uint256 _renewMaxDuration,
        uint256 _maxUtilization
    ) external {
        if(msg.sender != timelock) revert NotTimelock();
        _changeGovParams(
            _minDuration,
            _maxDuration,
            _renewMinDuration,
            _renewMaxDuration,
            _maxUtilization
        );
    }

    /// @notice Adjusts the protocol governance lending parameters
    /// @param _minDuration New minimum duration
    /// @param _maxDuration New maximum duration
    /// @param _renewMinDuration New minimum renew duration
    /// @param _renewMaxDuration New maximum renew duration
    /// @param _maxUtilization New Max Utilization
    function _changeGovParams(
        uint256 _minDuration,
        uint256 _maxDuration,
        uint256 _renewMinDuration,
        uint256 _renewMaxDuration,
        uint256 _maxUtilization
    ) internal {
        minDuration = _minDuration;
        maxDuration = _maxDuration;
        renewMinDuration = _renewMinDuration;
        renewMaxDuration = _renewMaxDuration;
        maxUtilization = _maxUtilization;
        emit NewDurations(_minDuration, _maxDuration);
        emit NewMaxUtilization(_maxUtilization);
        
    }

    /// @inheritdoc IRebaseGoldilend
    function initializeGovParams(
        uint256 _minDuration,
        uint256 _maxDuration,
        uint256 _renewMinDuration,
        uint256 _renewMaxDuration,
        uint256 _maxUtilization
    ) external {
        if(msg.sender != multisig) revert NotMultisig();
        _changeGovParams(
            _minDuration,
            _maxDuration,
            _renewMinDuration,
            _renewMaxDuration,
            _maxUtilization
        );
    }

    /// @inheritdoc IRebaseGoldilend
    function changeBorrowingActive(bool _borrowingActive) external {
        if(msg.sender != multisig) revert NotMultisig();
        borrowingActive = _borrowingActive;
        emit NewBorrowingActive(_borrowingActive);
    }

    /// @inheritdoc IRebaseGoldilend
    function recoverTokens(address token) external {
        if(msg.sender != multisig) revert NotMultisig();
        SafeTransferLib.safeTransfer(token, multisig, ERC20(token).balanceOf(address(this)));
    }

    /// @inheritdoc IRebaseGoldilend
    function changeUnvestedWeights(
        address[] calldata _beras,
        uint256[] calldata _weights,
        address[] calldata _streams
    ) public {
        if(msg.sender != multisig) revert NotMultisig();
        if(_beras.length != _weights.length) revert ArrayMismatch();
        if(_beras.length != _streams.length) revert ArrayMismatch();
        uint256 weightsLength = _weights.length;
        for(uint256 i; i < weightsLength; ++i) {
            unvestedWeights[_beras[i]] = _weights[i];
            streamingAddresses[_beras[i]] = _streams[i];
        }
    }

    /// @inheritdoc IRebaseGoldilend
    function initializeBeras(
        address[] calldata _beras,
        uint256[] calldata _weights,
        address[] calldata _streams
    ) external {
        if(msg.sender != multisig) revert NotMultisig();
        if(berasInitialized) revert AlreadyInitialized();
        
        changeUnvestedWeights(_beras, _weights, _streams);

        berasInitialized = true;
        borrowingActive = true;
    }

    /// @inheritdoc IRebaseGoldilend
    function withdrawSurplus() external {
        if(msg.sender != multisig) revert NotMultisig();
        uint256 _auctionSurplus = auctionSurplus;
        auctionSurplus = 0;
        SafeTransferLib.safeTransfer(debtAsset, multisig, _auctionSurplus);
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