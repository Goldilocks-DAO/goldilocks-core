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


/// @title RebaseGoldilend 
/// @notice Bong Bear (and rebase) Fixed Term NFT Lending
contract RebaseGoldilend is GoldilendBase {

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
        Loan memory loan = Loan({
        collateralNFT: collateralNFT,
        collateralNFTId: collateralNFTId,
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
        emit Borrow(msg.sender, userLoansLength + 1, borrowAmount, interest, block.timestamp + duration, collateralNFT, collateralNFTId);
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

}