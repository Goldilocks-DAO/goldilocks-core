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
// ================================== BerabondGoldilend =========================================
// ==============================================================================================


import { GoldilendBase } from "./GoldilendBase.sol";


/// @title BerabondGoldilend 
/// @notice Berabond Fixed Term NFT Lending
contract BerabondGoldilend is GoldilendBase {

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
        Loan memory loan = Loan({
        collateralNFT: collateralNFT,
        collateralNFTId: collateralNFTId,
        borrowedAmount: borrowAmount,
        interest: 0,
        duration: 180 days,
        endDate: block.timestamp + 180 days,
        loanId: userLoansLength + 1,
        liquidated: false
        });
        loans[msg.sender][userLoansLength + 1] = loan;
        userLoanAmount[msg.sender]++;
        IERC721(collateralNFT).transferFrom(msg.sender, address(this), collateralNFTId);
        SafeTransferLib.safeTransfer(wbera, msg.sender, borrowAmount);
        emit Borrow(msg.sender, userLoansLength + 1, borrowAmount, 0, block.timestamp + 180 days, collateralNFT, collateralNFTId);
    }

    function getTBABGTBalance(address nft, uint256 tokenId) external view returns (uint256) {
        return _getTBABGTBalance(nft, tokenId);
    }

    /// @notice Returns the BGT balance of the token bound account
    /// @return bgtBalance BGT balance of TBA
    function _getTBABGTBalance(address nft, uint256 tokenId) internal view returns (uint256) {
        if(nftFairValues[nft] == 0) revert InvalidCollateral();
        address tba = IBeraBondNFT(nft).getTokenBoundAccount(tokenId);
        return ERC20(bgt).balanceOf(tba);
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

}