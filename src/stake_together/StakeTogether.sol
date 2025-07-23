// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract CloudCoin is ERC20 {
    constructor() ERC20("CloudCoin", "CCN") {}

    function mint(address stakingContract, uint mintAmount) external {
        _mint(stakingContract, mintAmount);
    }
}

contract StakeTogether is ReentrancyGuard {
    CloudCoin public cloudCoin;

    uint public beginDate;
    uint public expirationDate;

    uint constant mintAmount = 1_000_000 ether;

    uint public totalStakesAmount;

    struct UserStake {
        uint amount;
        uint timestamp;
        bool claimed;
    }

    mapping(address => UserStake) public stakes;

    event StakeMade(address indexed stakerAddress, uint amount);
    event Withdrawn(
        address indexed user,
        uint amountStaked,
        uint rewardClaimed
    );

    modifier onlyDuringStakingWindow() {
        require(
            block.timestamp >= beginDate &&
                block.timestamp < expirationDate - 7 days,
            "Staking not allowed at this time"
        );
        _;
    }

    constructor(address _cloudCoin, uint _beginDate, uint _expirationDate) {
        cloudCoin = CloudCoin(_cloudCoin);
        beginDate = _beginDate;
        expirationDate = _expirationDate;
    }

    function stake(uint amount) public onlyDuringStakingWindow nonReentrant {
        require(amount > 0, "Amount cant be 0");
        require(stakes[msg.sender].amount == 0, "You have already Staked");

        stakes[msg.sender] = UserStake({
            amount: amount,
            claimed: false,
            timestamp: block.timestamp
        });
        totalStakesAmount += amount;

        cloudCoin.transferFrom(msg.sender, address(this), amount);

        emit StakeMade(msg.sender, amount);
    }

    function withdraw() public {
        UserStake storage userStake = stakes[msg.sender];

        require(userStake.amount > 0, "Never staked");
        require(!userStake.claimed, "Already withdrawn");
        require(block.timestamp > expirationDate, "Staking not finished yet");

        require(
            userStake.timestamp <= expirationDate - 7 days,
            "You did not stake for 7 full days"
        );

        uint userShare = (userStake.amount * 1_000_000 ether) /
            totalStakesAmount;

        userStake.claimed = true;
        cloudCoin.transfer(msg.sender, userShare);

        emit Withdrawn(msg.sender, userStake.amount, userShare);
    }
}
