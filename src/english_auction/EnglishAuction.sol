// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {console} from "forge-std/console.sol";

contract EnglishAuction is ReentrancyGuard, IERC721Receiver {
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

    struct Auction {
        address seller;
        NFT nft;
        uint deadline;
        uint reservePrice;
        bool sold;
        uint highestBid;
        address highestBidder;
    }

    uint nextAuctionId;
    // mapping(uint => )
    mapping(uint => Auction) public auctions;
    mapping(uint => mapping(address => uint)) public bids;

    event AuctionCreated(
        uint indexed id,
        address indexed seller,
        address nftTokenAddress,
        uint tokenId,
        uint deadline,
        uint reservePrice
    );
    event BidCreated(uint indexed id, address indexed bidder, uint bidAmount);
    event AuctionCompleted(
        uint indexed id,
        address indexed bidder,
        address indexed seller,
        uint bidAmount
    );
    event AuctionReclaimed(uint indexed id, address indexed seller);

    function deposit(
        NFT memory nft,
        uint deadline,
        uint reservePrice
    ) public nonReentrant {
        require(nft.tokenAddress != address(0), "Address can not be 0");
        require(deadline > block.timestamp, "Deadline can not be in the past");
        require(reservePrice > 0, "Reserve price can not be 0");

        unchecked {
            nextAuctionId++;
        }
        auctions[nextAuctionId] = Auction({
            seller: msg.sender,
            nft: nft,
            deadline: deadline,
            reservePrice: reservePrice,
            sold: false,
            highestBid: 0,
            highestBidder: address(0)
        });

        IERC721(nft.tokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            nft.tokenId
        );

        emit AuctionCreated(
            nextAuctionId,
            msg.sender,
            nft.tokenAddress,
            nft.tokenId,
            deadline,
            reservePrice
        );
    }

    function bid(uint auctionId) public payable nonReentrant {
        console.log("hereereasad");
        Auction storage auction = auctions[auctionId];
        require(block.timestamp < auction.deadline, "Auction has ended");
        require(
            msg.value > auction.highestBid,
            "You Cant bid lower than highest bid"
        );
        require(msg.sender != auction.highestBidder, "Already highest bidder");

        auction.highestBid = msg.value;
        auction.highestBidder = msg.sender;

        bids[auctionId][msg.sender] += msg.value;

        emit BidCreated(auctionId, msg.sender, msg.value);
    }

    function withdrawBid(uint auctionId) public nonReentrant {
        Auction storage auction = auctions[auctionId];
        require(block.timestamp > auction.deadline, "Auction is ongoing");
        require(
            auction.highestBidder != msg.sender,
            "Winner can not withdraw the bid"
        );

        uint bidToWithdraw = bids[auctionId][msg.sender];
        bids[auctionId][msg.sender] = 0;

        (bool success, ) = msg.sender.call{value: bidToWithdraw}("");
        require(success, "ETH transaction failed");
    }

    function sellerEndAuction(uint auctionId) public nonReentrant {
        Auction storage auction = auctions[auctionId];
        require(auction.seller == msg.sender, "You are not the seller");
        require(block.timestamp > auction.deadline, "Auction is ongoing");
        require(!auction.sold, "Auction is already sold");
        require(auction.highestBid >= auction.reservePrice, "Reserve not met");

        auction.sold = true;
        (bool success, ) = auction.seller.call{value: auction.highestBid}("");
        require(success, "Transaction to the seller failed");

        IERC721(auction.nft.tokenAddress).safeTransferFrom(
            address(this),
            auction.highestBidder,
            auction.nft.tokenId
        );

        emit AuctionCompleted(
            auctionId,
            auction.highestBidder,
            msg.sender,
            auction.highestBid
        );
    }

    function reclaimUnsoldNft(uint auctionId) public nonReentrant {
        Auction storage auction = auctions[auctionId];
        require(msg.sender == auction.seller, "You are not the seller");
        require(block.timestamp > auction.deadline, "Auction is still ongoing");
        require(
            auction.reservePrice >= auction.highestBid,
            "Auction has a winner"
        );

        auction.sold = true;

        IERC721(auction.nft.tokenAddress).safeTransferFrom(
            address(this),
            auction.seller,
            auction.nft.tokenId
        );

        emit AuctionReclaimed(auctionId, auction.seller);
    }

    function getAuction(uint auctionId) public view returns (Auction memory) {
        return auctions[auctionId];
    }
}
