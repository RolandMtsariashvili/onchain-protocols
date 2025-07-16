// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

import "forge-std/Test.sol";
import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {NFTSwap} from "../../src/nft_swap/NFTSwap.sol";

contract InitiatorsMockNFT is ERC721 {
    constructor() ERC721("MockInitiatorNFT", "MINFT") {
        _mint(msg.sender, 1);
    }
}

contract CounterpartMockNft is ERC721 {
    constructor() ERC721("MockCounterpartyNFT", "MCNFT") {
        _mint(msg.sender, 1);
    }
}

contract NFTSwapTest is Test {
    address user = address(1);
    ERC721 initiatorNft;
    ERC721 counterpartNft;
    NFTSwap nftSwap;

    function setUp() public {
        initiatorNft = new InitiatorsMockNFT();
        counterpartNft = new CounterpartMockNft();
        nftSwap = new NFTSwap();

        initiatorNft.approve(address(nftSwap), 1);
    }

    function testCreateSwap() public {
        NFTSwap.NFT memory offered = NFTSwap.NFT(address(initiatorNft), 1);
        NFTSwap.NFT memory requested = NFTSwap.NFT(address(counterpartNft), 1);

        nftSwap.createSwap(offered, requested);

        NFTSwap.Swap memory swap = nftSwap.getSwap(1);
        assertEq(swap.initiator, address(this));
        assertEq(swap.counterparty, address(0));
        assertEq(swap.initiatorDeposited, true);
        assertEq(swap.counterpartyDeposited, false);
    }
}
