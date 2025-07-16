// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract NFTSwap is ReentrancyGuard {
    uint private nextSwapId = 1;

    struct NFT {
        address tokenAddress;
        uint tokenId;
    }

    struct Swap {
        address initiator;
        NFT offeredNft;
        NFT requestedNFT;
        address counterparty;
        bool initiatorDeposited;
        bool counterpartyDeposited;
        uint createdAt;
        uint expiresAt;
    }

    mapping(uint => Swap) public swaps;

    event SwapCreated(
        uint swapId,
        address indexed initiator,
        address offeredTokenAddress,
        uint offeredTokenId,
        address requestedTokenAddress,
        uint requestedTokenId
    );

    // TODO: Maybe have specific counterparty and expiration time as optional params?
    function createSwap(
        NFT memory offeredNft,
        NFT memory requestedNFT
    ) public nonReentrant {
        require(
            offeredNft.tokenAddress != requestedNFT.tokenAddress ||
                offeredNft.tokenId != requestedNFT.tokenId,
            "Tokens must be different"
        );
        require(
            offeredNft.tokenId > 0 && requestedNFT.tokenId > 0,
            "Token IDs must be greater than 0"
        );

        Swap memory swap = Swap({
            initiator: msg.sender,
            offeredNft: offeredNft,
            requestedNFT: requestedNFT,
            counterparty: address(0),
            initiatorDeposited: true, // True, since will be reverted if safeTransferFrom fails
            counterpartyDeposited: false,
            createdAt: block.timestamp,
            expiresAt: block.timestamp + 1 days
        });

        uint swapId = nextSwapId;
        unchecked {
            nextSwapId++;
        }
        swaps[swapId] = swap;

        IERC721(offeredNft.tokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            offeredNft.tokenId
        );

        emit SwapCreated(
            swapId,
            msg.sender,
            offeredNft.tokenAddress,
            offeredNft.tokenId,
            requestedNFT.tokenAddress,
            requestedNFT.tokenId
        );
    }
}
