// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

import {Test} from "forge-std/Test.sol";
import {StakeTogether} from "../../src/stake_together/StakeTogether.sol";
import {CloudCoin} from "../../src/stake_together/StakeTogether.sol";

contract StakeTogetherTest is Test {
    StakeTogether staking;
    CloudCoin cloudCoin;
    address user1 = address(1);
    address user2 = address(2);
    address user3 = address(3);

    function setUp() public {
        cloudCoin = new CloudCoin();
        staking = new StakeTogether(
            address(cloudCoin),
            block.timestamp + 1 days,
            block.timestamp + 30 days
        );
        cloudCoin.mint(address(staking), 1_000_000 ether);
        cloudCoin.mint(user1, 1_000 ether);
        cloudCoin.mint(user2, 100_000 ether);
        cloudCoin.mint(user3, 500_000 ether);

        vm.prank(user1);
        cloudCoin.approve(address(staking), 1_000 ether);
        vm.prank(user2);
        cloudCoin.approve(address(staking), 100_000 ether);
        vm.prank(user3);
        cloudCoin.approve(address(staking), 500_000 ether);
    }

    function testInitialBalanceCheck() public view {
        assertEq(cloudCoin.balanceOf(address(staking)), 1_000_000 ether);
        assertEq(cloudCoin.balanceOf(user1), 1_000 ether);
        assertEq(cloudCoin.balanceOf(user2), 100_000 ether);
        assertEq(cloudCoin.balanceOf(user3), 500_000 ether);
    }

    function testStake_RevertIfNotStartedYet() public {
        vm.startPrank(user1);
        vm.expectRevert("Staking not allowed at this time");
        staking.stake(500 ether);
    }

    function testStake_RevertIfTransferFailed() public {
        vm.startPrank(user1);
        vm.warp(block.timestamp + 2 days);
        vm.expectRevert();
        staking.stake(2_000 ether);
    }

    function testStake_RevertIfLessThan7DaysLeft() public {
        vm.startPrank(user1);
        vm.warp(staking.expirationDate() - 6 days);
        vm.expectRevert("Staking not allowed at this time");
        staking.stake(500 ether);
    }

    function testStake_StakeForThreeUsers() public {
        vm.warp(staking.beginDate());
        vm.prank(user1);
        staking.stake(1_000 ether);

        vm.warp(staking.beginDate() + 1);
        vm.prank(user2);
        staking.stake(100_000 ether);

        vm.warp(staking.beginDate() + 3);
        vm.prank(user3);
        staking.stake(500_000 ether);

        assertEq(staking.totalStakesAmount(), 601_000 ether);
    }
}
