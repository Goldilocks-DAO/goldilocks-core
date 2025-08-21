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


import { GoldilendBase } from "./GoldilendBase.sol";
import { IERC721 } from "../../../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import { SafeTransferLib } from "../../../lib/solady/src/utils/SafeTransferLib.sol";


/// @title RebaseGoldilend 
/// @notice Bong Bear (and rebase) Fixed Term NFT Lending
contract RebaseGoldilend is GoldilendBase {

    event Renew(address indexed user, uint256 loanId, uint256 newBorrowAmount, uint256 newInterest, uint256 newDuration);

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

    /// @notice Renews loan with new expiry
    /// @param userLoanId Loan to be renewed
    /// @param newDuration New duration of the loan
    /// @param newBorrowAmount Amount of additional debt asset to be borrowed
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

}