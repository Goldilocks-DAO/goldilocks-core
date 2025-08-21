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
import { SafeTransferLib } from "../../../lib/solady/src/utils/SafeTransferLib.sol";
import { ERC20 } from "../../../lib/solady/src/tokens/ERC20.sol";
import { IERC721 } from "../../../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import { IBeraBondNFT } from "../../interfaces/IBeraBondNFT.sol";
import { IGl00DelegationRegistry } from "../../interfaces/IGl00DelegationRegistry.sol";


/// @title BerabondGoldilend 
/// @notice Berabond Fixed Term NFT Lending
contract BerabondGoldilend is GoldilendBase {

    address public bgt;
    address public delegationRegistry;
    address public berabond;
    uint256 public LTV;
    mapping(address => uint256[]) public userTokenIds;
    event Renew(address indexed user, uint256 loanId, uint256 newBorrowAmount, uint256 newInterest, uint256 newDuration);

    /// @notice Borrows WBERA against value of the BeraBond NFT
    /// @param borrowAmount Amount of WBERA to borrow
    /// @param duration Duration of loan
    /// @param collateralNFT Berabond NFT to use as collateral
    /// @param collateralNFTId Token Id of NFT to use as collateral
    function berabondBorrow(
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
        uint256 bgtBalance = _getTBABGTBalance(collateralNFT, collateralNFTId);
        uint256 maxBorrow = bgtBalance * LTV / 100;
        if(nftFairValues[collateralNFT] == 0) revert InvalidCollateral();
        if(borrowAmount > maxBorrow) revert InvalidLoanAmount();
        if(borrowAmount > _poolSize / 10) revert InvalidLoanAmount();
        uint256 interest = _calculateInterest(borrowAmount, _outstandingDebt, duration);
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
        userTokenIds[msg.sender].push(collateralNFTId);
        IERC721(collateralNFT).transferFrom(msg.sender, address(this), collateralNFTId);
        SafeTransferLib.safeTransfer(debtAsset, msg.sender, borrowAmount - interest);
        SafeTransferLib.safeTransfer(debtAsset, multisig, interest);
        emit Borrow(msg.sender, userLoansLength + 1, borrowAmount, 0, block.timestamp + duration, collateralNFT, collateralNFTId);
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

    /// @notice Claims BGT rewards from BeraBond NFT
    /// @param rewardContracts Addresses of BGT reward vaults to claim from
    function claimYield(address[] memory rewardContracts) external {
        uint256 userTokenIdsLength = userTokenIds[msg.sender].length;
        for(uint256 i; i < userTokenIdsLength;) {
            address payable tba = IBeraBondNFT(berabond).getTokenBoundAccount(userTokenIds[msg.sender][i]);
            IBeraBondNFT(tba).claimFromEach(rewardContracts, msg.sender);
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Returns the BGT balance of the token bound account
    /// @param nft Address of the token bound account
    /// @param tokenId ID of the token bound account
    /// @return BGT balance of TBA
    function getTBABGTBalance(address nft, uint256 tokenId) external view returns (uint256) {
        return _getTBABGTBalance(nft, tokenId);
    }

    /// @notice Returns the BGT balance of the token bound account
    /// @param nft Address of the token bound account
    /// @param tokenId ID of the token bound account
    /// @return BGT balance of TBA
    function _getTBABGTBalance(address nft, uint256 tokenId) internal view returns (uint256) {
        address tba = IBeraBondNFT(nft).getTokenBoundAccount(tokenId);
        return ERC20(bgt).balanceOf(tba);
    }

    /// @notice Manages the delegation of the token bound account to a delegatee
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