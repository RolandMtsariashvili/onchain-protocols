// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {NFTSwap} from "../../src/nft_swap/NFTSwap.sol";

contract InitiatorsMockNFT is ERC721 {
    constructor() ERC721("MockInitiatorNFT", "MINFT") {}

    function mint() public {
        _mint(msg.sender, 1);
    }
}

contract CounterpartMockNft is ERC721 {
    constructor() ERC721("MockCounterpartyNFT", "MCNFT") {}

    function mint() public {
        _mint(msg.sender, 1);
    }
}

contract NFTSwapTest is Test {
    address initiatorUser = address(1);
    address counterpartyUser = address(2);

    InitiatorsMockNFT initiatorNft;
    CounterpartMockNft counterpartNft;
    NFTSwap nftSwap;

    NFTSwap.NFT offered;
    NFTSwap.NFT requested;

    function setUp() public {
        initiatorNft = new InitiatorsMockNFT();
        nftSwap = new NFTSwap();
        counterpartNft = new CounterpartMockNft();

        vm.startPrank(initiatorUser);
        initiatorNft.mint();
        initiatorNft.approve(address(nftSwap), 1);

        vm.startPrank(counterpartyUser);
        counterpartNft.mint();
        counterpartNft.approve(address(nftSwap), 1);
        vm.stopPrank();

        offered = NFTSwap.NFT(address(initiatorNft), 1);
        requested = NFTSwap.NFT(address(counterpartNft), 1);
    }

    function testCreateSwap() public {
        vm.prank(initiatorUser);
        nftSwap.createSwap(offered, requested);
        NFTSwap.Swap memory swap = nftSwap.getSwap(1);

        assertEq(swap.initiator, initiatorUser);
        assertEq(swap.counterparty, address(0));
        assertEq(swap.initiatorDeposited, true);
        assertEq(swap.counterpartyDeposited, false);
    }

    function testFulfilSwap() public {
        vm.prank(initiatorUser);
        nftSwap.createSwap(offered, requested);

        vm.prank(counterpartyUser);
        nftSwap.fulfillSwap(1);

        NFTSwap.Swap memory swap = nftSwap.getSwap(1);
        assertEq(swap.initiator, initiatorUser);
        assertEq(swap.counterparty, counterpartyUser);
        assertEq(swap.initiatorDeposited, true);
        assertEq(swap.counterpartyDeposited, true);
    }

    function testFulfilByInitiator() public {
        vm.prank(initiatorUser);
        nftSwap.createSwap(offered, requested);

        vm.prank(counterpartyUser);
        nftSwap.fulfillSwap(1);

        vm.prank(initiatorUser);
        nftSwap.executeSwap(1);

        assertEq(counterpartNft.ownerOf(requested.tokenId), initiatorUser);
        assertEq(initiatorNft.ownerOf(offered.tokenId), counterpartyUser);
    }

    function testCancelSwap() public {
        vm.startPrank(initiatorUser);
        nftSwap.createSwap(offered, requested);

        nftSwap.cancelSwap(1);
        vm.stopPrank();
        assertEq(nftSwap.getSwap(1).initiator, address(0));
    }

    function testCancelShouldFailIfApproved() public {
        vm.prank(initiatorUser);
        nftSwap.createSwap(offered, requested);

        vm.prank(counterpartyUser);
        nftSwap.fulfillSwap(1);

        vm.prank(initiatorUser);
        vm.expectRevert("Swap already approved");
        nftSwap.cancelSwap(1);
    }

    function testReclaimAfterExpiryShouldFailIfNotExpired() public {
        vm.prank(initiatorUser);
        nftSwap.createSwap(offered, requested);

        vm.prank(counterpartyUser);
        nftSwap.fulfillSwap(1);

        vm.prank(initiatorUser);
        vm.expectRevert("Not yet expired");
        nftSwap.reclaimAfterExpiry(1);
    }

    function testReclaimAfterExpiry() public {
        vm.prank(initiatorUser);
        nftSwap.createSwap(offered, requested);

        vm.prank(counterpartyUser);
        nftSwap.fulfillSwap(1);

        vm.warp(block.timestamp + 2 days);
        vm.prank(initiatorUser);
        nftSwap.reclaimAfterExpiry(1);

        assertEq(counterpartNft.ownerOf(requested.tokenId), counterpartyUser);
        assertEq(initiatorNft.ownerOf(offered.tokenId), initiatorUser);
    }
}
