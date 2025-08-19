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
    mapping(address => uint256[]) public userTokenIds;

    function berabondBorrow(
        uint256 borrowAmount,
        uint256 duration,
        address collateralNFT,
        uint256 collateralNFTId
    ) external {
        if(!borrowingActive) revert NotActive();
        if(duration < minDuration || duration > maxDuration) revert InvalidDuration();
        if(nftFairValues[collateralNFT] == 0) revert InvalidCollateral();
        uint256 _poolSize = poolSize;
        uint256 _outstandingDebt = outstandingDebt;
        uint256 bgtBalance = _getTBABGTBalance(collateralNFT, collateralNFTId);
        uint256 maxBorrow = bgtBalance * 80 / 100;
        uint256 userLoansLength = userLoanAmount[msg.sender];
        if(borrowAmount > maxBorrow) revert InvalidLoanAmount();
        uint256 interest = _calculateInterest(borrowAmount, _outstandingDebt, duration);
        if(_outstandingDebt + borrowAmount > _poolSize * maxUtilization / 100) revert MaxUtilizationExceeded();
        if(borrowAmount > _poolSize - _outstandingDebt) revert BorrowLimitExceeded();
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

    function renew(
        uint256 userLoanId,
        uint256 newDuration,
        uint256 newBorrowAmount
    ) external {

    }

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

    function getTBABGTBalance(address nft, uint256 tokenId) external view returns (uint256) {
        return _getTBABGTBalance(nft, tokenId);
    }

    /// @notice Returns the BGT balance of the token bound account
    /// @return bgtBalance BGT balance of TBA
    function _getTBABGTBalance(address nft, uint256 tokenId) internal view returns (uint256) {
        address tba = IBeraBondNFT(nft).getTokenBoundAccount(tokenId);
        return ERC20(bgt).balanceOf(tba);
    }

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