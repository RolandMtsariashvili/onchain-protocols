// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

import "forge-std/Test.sol";
import "../../src/erc20_vesting/ERC20Vesting.sol";

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor() ERC20("MockERC20", "MCK20") {}
    function mint(address to, uint amount) public {
        _mint(to, amount);
    }
}

contract ERC20VestingTest is Test {
    ERC20Vesting vesting;
    MockERC20 token;
    address user = address(1);
    address admin;

    function setUp() public {
        token = new MockERC20();
        vesting = new ERC20Vesting(address(token));
        admin = address(this);

        token.mint(admin, 100);
        token.approve(address(vesting), type(uint).max);
    }

    function testDepositWorks() public {
        vesting.depositFor(user, 50, 7 days);

        (
            uint totalAmount,
            uint claimedAmount,
            uint startTime,
            uint duration
        ) = vesting.vestings(user);

        assertEq(totalAmount, 50);
        assertEq(claimedAmount, 0);
        assertApproxEqAbs(startTime, block.timestamp, 2);
        assertEq(duration, 7 days);
    }

    function testDepositShouldFailForNotOwner() public {
        vm.prank(user);
        vm.expectRevert(ERC20Vesting.NotOwner.selector);
        vesting.depositFor(address(2), 50, 2 days);
    }

    function testClaimAfterHalfTime() public {
        vesting.depositFor(user, 100, 10 days);
        assertEq(token.balanceOf(user), 0);

        vm.warp(block.timestamp + 5 days);
        vm.prank(user);
        vesting.claim();
        assertEq(token.balanceOf(user), 50);

        vm.warp(block.timestamp + 3 days);
        vm.prank(user);
        vesting.claim();
        assertEq(token.balanceOf(user), 80);
    }

    function testNothingToClaim() public {
        vesting.depositFor(user, 100, 10 days);

        vm.prank(user);
        vm.expectRevert(ERC20Vesting.NothingToClaim.selector);
        vesting.claim();
    }
}
