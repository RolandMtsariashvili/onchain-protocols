// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

import {Test} from "forge-std/Test.sol";
import {LOMOCoin} from "../src/NFTShop.sol";
import {ERC20} from "../src/ERC20.sol";
import {LomoNFT} from "../src/NFTShop.sol";
import {NFTShop} from "../src/NFTShop.sol";

contract NFTShopTest is Test {
    LOMOCoin token;
    LomoNFT nft;
    NFTShop shop;
    address user = address(1);

    function setUp() public {
        token = new LOMOCoin();
        nft = new LomoNFT();
        shop = new NFTShop(address(token), address(nft));
        nft.setMinter(address(shop));

        token.transfer(user, 100);
    }

    function testPurchase() public {
        vm.startPrank(user);
        token.approve(address(shop), 20);
        shop.mintNFT();
        vm.stopPrank();

        assertEq(token.balanceOf(user), 90);
        assertEq(token.balanceOf(address(shop)), 10);
        assertEq(nft.ownerOf(0), user);
        assertEq(nft.balanceOf(user), 1);
    }
}
