// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

import "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

import {EnglishAuction} from "../../src/english_auction/EnglishAuction.sol";

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract SellERC721 is ERC721 {
    constructor() ERC721("SellToken", "STK") {}

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }
}

contract EnglishAuctionTest is Test {
    EnglishAuction englishAuction;
    SellERC721 token;
    EnglishAuction.NFT nft;
    address seller = address(1);
    address bidder1 = address(2);
    address bidder2 = address(3);

    function setUp() public {
        englishAuction = new EnglishAuction();
        token = new SellERC721();
        token.mint(seller, 1);
        nft = EnglishAuction.NFT({tokenAddress: address(token), tokenId: 1});
        vm.deal(bidder1, 1 ether);

        vm.prank(seller);
        token.approve(address(englishAuction), 1);
    }

    function testDeposit_depositNft() public {
        vm.startPrank(seller);
        vm.expectEmit(true, true, false, true);
        emit EnglishAuction.AuctionCreated(
            1,
            seller,
            nft.tokenAddress,
            nft.tokenId,
            block.timestamp + 2 days,
            50_000 gwei
        );
        console.log("sadasd");
        englishAuction.deposit(nft, block.timestamp + 2 days, 50_000 gwei);
        (address _seller, , , , , , ) = englishAuction.auctions(1);
        assertEq(_seller, seller);
        vm.stopPrank();
    }

    function testBid_RevertIfDeadlinePassed() public {
        uint deadline = block.timestamp + 2 days;

        vm.prank(seller);
        englishAuction.deposit(nft, deadline, 50_000 gwei);

        console.log(englishAuction.getAuction(1).deadline, deadline);
        vm.prank(bidder1);
        vm.warp(deadline + 3 days);
        vm.expectRevert("Auction has ended");
        englishAuction.bid{value: 100000 gwei}(1); // 👈 this line must immediately follow
        // vm.expectRevert("Auction has ended"); // 👈 must go BEFORE the call
    }
}
