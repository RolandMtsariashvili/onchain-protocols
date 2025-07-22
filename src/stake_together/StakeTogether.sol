// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract CloudCoin is ERC20 {
    constructor(
        address stakingContract,
        uint mintAmount
    ) ERC20("CloudCoin", "CCN") {
        _mint(stakingContract, mintAmount);
    }
}

contract StakeTogether is ReentrancyGuard {
    CloudCoin public cloudCoin;

    uint public beginDate;
    uint public expirationDate;

    uint constant mintAmount = 1_000_000 ether;

    uint public totalStakesAmount;

    struct Stake {
        uint amount;
        uint timestamp;
    }

    mapping(address => Stake) public stakes;

    event StakeMade(address indexed stakerAddress, uint amount);

    constructor(address _cloudCoin, uint _beginDate, uint _expirationDate) {
        cloudCoin = new CloudCoin(_cloudCoin, mintAmount);
        beginDate = _beginDate;
        expirationDate = _expirationDate;
    }

    function stakeCoins(uint amount) public nonReentrant {
        require(amount > 0, "Amount cant be 0");
        require(stakes[msg.sender].amount == 0, "You have already Staked");
        require(
            block.timestamp >= beginDate,
            "Stacking not started  yet started"
        );
        require(
            block.timestamp < expirationDate - 7 days,
            "Stacking window has passed"
        );

        stakes[msg.sender] = Stake({
            amount: amount,
            timestamp: block.timestamp
        });
        totalStakesAmount += amount;

        cloudCoin.transferFrom(msg.sender, address(this), amount);

        emit StakeMade(msg.sender, amount);
    }

    function withdraw() public {
        Stake memory stake = stakes[msg.sender];

        require(stake.amount > 0, "No stake found");
        require(block.timestamp > expirationDate, "Staking not finished yet");

        require(
            stake.timestamp <= expirationDate - 7 days,
            "You did not stake for 7 full days"
        );

        uint userShare = (stake.amount * 1_000_000 ether) / totalStakesAmount;

        delete stakes[msg.sender];
        cloudCoin.transfer(msg.sender, userShare);
    }
}
