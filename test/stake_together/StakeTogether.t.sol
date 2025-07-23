// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

import {Test} from "forge-std/Test.sol";
import {StakeTogether} from "../../src/stake_together/StakeTogether.sol";
import {CloudCoin} from "../../src/stake_together/StakeTogether.sol";

contract StakeTogetherTest is Test {
    StakeTogether staking;
    CloudCoin cloudCoin;

    function setUp() public {
        cloudCoin = new CloudCoin();
        staking = new StakeTogether(
            address(cloudCoin),
            block.timestamp + 1 days,
            block.timestamp + 30 days
        );
        cloudCoin.mint(address(staking), 1_000_000 ether);
    }

    function testInitialBalanceCheck() public view {
        assertEq(cloudCoin.balanceOf(address(staking)), 1_000_000 ether);
    }
}
