// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract NFTSwap is ReentrancyGuard, IERC721Receiver {
    uint private nextSwapId = 1;

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

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
        uint indexed swapId,
        address indexed initiator,
        address offeredTokenAddress,
        uint offeredTokenId,
        address requestedTokenAddress,
        uint requestedTokenId
    );

    event SwapFulfilled(uint swapId, address indexed counterparty);

    event SwapExecuted(
        uint indexed swapId,
        address indexed initiator,
        address indexed counterparty,
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

    function getSwap(uint swapId) public view returns (Swap memory) {
        return swaps[swapId];
    }

    function fulfillSwap(uint swapId) public nonReentrant {
        Swap storage swap = swaps[swapId];

        require(
            swap.counterparty == msg.sender || swap.counterparty == address(0),
            "caller is not a counterparty"
        );
        require(!swap.counterpartyDeposited, "Swap already fulfilled");
        require(
            swap.expiresAt == 0 || block.timestamp <= swap.expiresAt,
            "Swap request expired"
        );
        require(
            IERC721(swap.requestedNFT.tokenAddress).ownerOf(
                swap.requestedNFT.tokenId
            ) == msg.sender,
            "you don't have needed token"
        );

        swap.counterpartyDeposited = true;
        swap.counterparty = msg.sender;

        IERC721(swap.requestedNFT.tokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            swap.requestedNFT.tokenId
        );

        emit SwapFulfilled(swapId, msg.sender);
    }

    function executeSwap(uint swapId) public nonReentrant {
        Swap storage swap = swaps[swapId];

        require(
            msg.sender == swap.counterparty || msg.sender == swap.initiator,
            "You are not eligible for executing swap"
        );
        require(
            swap.counterpartyDeposited && swap.initiatorDeposited,
            "Not both parties have deposited token"
        );
        require(
            swap.expiresAt == 0 || block.timestamp <= swap.expiresAt,
            "Swap request expired"
        );

        IERC721(swap.requestedNFT.tokenAddress).safeTransferFrom(
            address(this),
            swap.initiator,
            swap.requestedNFT.tokenId
        );
        IERC721(swap.offeredNft.tokenAddress).safeTransferFrom(
            address(this),
            swap.counterparty,
            swap.offeredNft.tokenId
        );

        emit SwapExecuted(
            swapId,
            swap.initiator,
            swap.counterparty,
            swap.offeredNft.tokenAddress,
            swap.offeredNft.tokenId,
            swap.requestedNFT.tokenAddress,
            swap.requestedNFT.tokenId
        );

        delete swaps[swapId];
    }

    function cancelSwap(uint swapId) public nonReentrant {
        Swap storage swap = swaps[swapId];

        require(msg.sender == swap.initiator, "only initiator can cancel");
        require(!swap.counterpartyDeposited, "Swap already approved");

        IERC721(swap.offeredNft.tokenAddress).safeTransferFrom(
            address(this),
            swap.initiator,
            swap.offeredNft.tokenId
        );

        delete swaps[swapId];
    }

    function reclaimAfterExpiry(uint swapId) public nonReentrant {
        Swap storage swap = swaps[swapId];
        require(block.timestamp > swap.expiresAt, "Not yet expired");

        if (swap.initiatorDeposited) {
            IERC721(swap.offeredNft.tokenAddress).safeTransferFrom(
                address(this),
                swap.initiator,
                swap.offeredNft.tokenId
            );
        }

        if (swap.counterpartyDeposited) {
            IERC721(swap.requestedNFT.tokenAddress).safeTransferFrom(
                address(this),
                swap.counterparty,
                swap.requestedNFT.tokenId
            );
        }

        delete swaps[swapId];
    }
}
