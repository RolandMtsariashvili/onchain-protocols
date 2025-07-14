// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

import {Test, console} from "forge-std/Test.sol";
import {LOMOCoin} from "../../src/nft_erc20/NFTShop.sol";
import {ERC20} from "../../src/nft_erc20/ERC20.sol";

contract ERC20Test is Test {
    LOMOCoin token;

    function setUp() public {
        token = new LOMOCoin();
    }

    function testMintIncreaseBalanceAndSupply() public view {
        assertEq(token.totalSupply(), 100);
        assertEq(token.balanceOf(address(this)), 100);
    }

    function testTransfer() public {
        address recipient = makeAddr("recipient");
        token.transfer(recipient, 50);
        assertEq(token.balanceOf(recipient), 50);
        assertEq(token.balanceOf(address(this)), 50);
    }

    function testTransferInsufficientBalance() public {
        address recipient = makeAddr("recipient");
        vm.expectRevert(ERC20.InsufficientBalance.selector);
        token.transfer(recipient, 150);
    }

    function testSetAllowance() public {
        address ownerAddress = address(this);

        address spender = makeAddr("spender");
        address transferToAddress = makeAddr("transferToAddress");

        token.approve(spender, 50);
        assertEq(token.allowance(ownerAddress, spender), 50);

        vm.prank(spender);
        token.transferFrom(ownerAddress, transferToAddress, 50);
        assertEq(token.balanceOf(transferToAddress), 50);
        assertEq(token.balanceOf(ownerAddress), 50);

        assertEq(token.allowance(ownerAddress, spender), 0);
    }

    function testTransferMoreThanAllowanceShouldFail() public {
        address ownerAddress = address(this);

        address spender = makeAddr("spender");
        address transferToAddress = makeAddr("transferToAddress");

        token.approve(spender, 50);
        assertEq(token.allowance(ownerAddress, spender), 50);

        vm.prank(spender);
        vm.expectRevert(ERC20.InsufficientAllowance.selector);
        token.transferFrom(ownerAddress, transferToAddress, 70);
        assertEq(token.balanceOf(transferToAddress), 0);
        assertEq(token.balanceOf(ownerAddress), 100);

        assertEq(token.allowance(ownerAddress, spender), 50);
    }

    function testBurn() public {
        token.burn(40);
        assertEq(token.totalSupply(), 60);
        assertEq(token.balanceOf(address(this)), 60);
    }

    function testBurnFromFailsIfNotApproved() public {
        address spender = makeAddr("spender");
        token.approve(spender, 20);

        vm.prank(spender);
        vm.expectRevert(ERC20.InsufficientAllowance.selector);
        token.burnFrom(address(this), 30);
    }
}
