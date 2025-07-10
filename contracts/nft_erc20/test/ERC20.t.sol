// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

import {Test, console} from "forge-std/Test.sol";
import {ERC20} from "../src/ERC20.sol";

contract ERC20Test is Test {
    ERC20 token;

    function setUp() public {
        token = new ERC20("Test", "TEST", 18);
    }

    function testInitialSupply() public view {
        assertEq(token.totalSupply(), 0);
    }

    function testMintIncreaseBalanceAndSupply() public {
        token.mint(address(this), 100);
        assertEq(token.totalSupply(), 100);
        assertEq(token.balanceOf(address(this)), 100);
    }

    function testMintFromNotOwnerShouldFail() public {
        address notOwner = makeAddr("notOwner");

        vm.prank(notOwner);
        vm.expectRevert(ERC20.OnlyOwner.selector);
        token.mint(address(notOwner), 100);
    }

    function testTransfer() public {
        token.mint(address(this), 100);
        address recipient = makeAddr("recipient");
        token.transfer(recipient, 50);
        assertEq(token.balanceOf(recipient), 50);
        assertEq(token.balanceOf(address(this)), 50);
    }

    function testTransferInsufficientBalance() public {
        token.mint(address(this), 100);
        address recipient = makeAddr("recipient");
        vm.expectRevert(ERC20.InsufficientBalance.selector);
        token.transfer(recipient, 150);
    }
}
