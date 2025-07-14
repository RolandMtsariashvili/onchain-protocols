// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

import {ERC20} from "./ERC20.sol";
import {ERC721} from "./ERC721.sol";

contract LOMOCoin is ERC20 {
    constructor() ERC20("LOMO Coin", "LOMO", 18) {
        _mint(msg.sender, 100);
    }
}

contract LomoNFT is ERC721 {
    address public minter;

    constructor() ERC721("LomoNFT", "LNFT") {}

    function setMinter(address _minter) public {
        require(minter == address(0), "Minter already set");
        minter = _minter;
    }

    function mint(address to, uint tokenId) public {
        require(msg.sender == minter, "Not allowed");
        _mint(to, tokenId);
    }
}

contract NFTShop {
    LOMOCoin public lomoCoin;
    LomoNFT public lomoNft;
    uint public constant PRICE = 10;
    uint private _nextTokenId;

    constructor(address lomoAddress, address nftAddress) {
        lomoCoin = LOMOCoin(lomoAddress);
        lomoNft = LomoNFT(nftAddress);
    }

    function mintNFT() public {
        bool success = lomoCoin.transferFrom(msg.sender, address(this), PRICE);
        require(success, "Payment Failed");

        lomoNft.mint(msg.sender, _nextTokenId);
        _nextTokenId++;
    }
}
