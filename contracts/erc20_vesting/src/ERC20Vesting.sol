// SPDX-License-Identifier: UNLICENSED

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

pragma solidity >=0.7.0 <0.9.0;

contract ERC20Vesting {
    ERC20 token;

    struct VestingSchedule {
        uint totalAmount;
        uint claimedAmount;
        uint startTime;
        uint duration;
    }

    mapping(address => VestingSchedule) public vestings;

    // TODO: lets have this error for now, later i will think what to do for multiple vesting claims
    error AlreadyVested();

    error ZeroDuration();
    error ZeroAddress();
    error NoTokens();
    error CantClaimYet();
    error NothingToClaim();

    modifier notZeroAddress(address addr) {
        if (addr == address(0)) revert ZeroAddress();
        _;
    }

    constructor(address _tokenAddress) {
        token = ERC20(_tokenAddress);
    }

    function depositFor(
        address user,
        uint amount,
        uint duration
    ) public notZeroAddress(user) {
        if (vestings[user].totalAmount > 0) revert AlreadyVested();
        if (duration == 0) revert ZeroDuration();
        vestings[user] = VestingSchedule({
            totalAmount: amount,
            claimedAmount: 0,
            startTime: block.timestamp,
            duration: duration
        });
        require(
            token.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );
    }

    function claim() public {
        VestingSchedule storage userVesting = vestings[msg.sender];

        if (userVesting.totalAmount < 1) revert NoTokens();
        if (block.timestamp < userVesting.startTime + userVesting.duration)
            revert CantClaimYet();

        uint elapsed = block.timestamp - userVesting.startTime;
        if (elapsed > userVesting.duration) {
            elapsed = userVesting.duration;
        }
        uint totalUnlocked = (userVesting.totalAmount * elapsed) /
            userVesting.duration;

        if (totalUnlocked <= userVesting.claimedAmount) {
            revert NothingToClaim();
        }

        uint claimableNow = totalUnlocked - userVesting.claimedAmount;

        userVesting.claimedAmount++;
        require(token.transfer(msg.sender, claimableNow), "Transfer failed");
    }
}
