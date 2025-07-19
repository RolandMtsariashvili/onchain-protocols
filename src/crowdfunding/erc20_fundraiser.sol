// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract ERC20Fundraiser is ReentrancyGuard {
    struct Campaign {
        address creator;
        uint goal;
        uint deadline;
        uint totalDonated;
        address tokenAddress;
        bool goalReached;
        bool fundsWithdrawn;
    }

    mapping(uint => Campaign) public campaigns;
    mapping(uint => mapping(address => uint)) public donations;

    uint private _nextCampaignId;

    event FundraiserCreated(uint indexed id, address indexed creator);
    event DonationAdded(uint indexed id, address indexed donor, uint amount);
    event CreatorWithdrawn(
        uint indexed id,
        address indexed creator,
        uint amount
    );
    event DonorWithdrawn(uint indexed id, address indexed donor, uint amount);

    function createFundraiser(
        uint goal,
        uint deadline,
        address tokenAddress
    ) public nonReentrant {
        require(goal > 0, "Goal can not be zero");
        require(deadline > block.timestamp, "Deadline cant be in the past");
        require(tokenAddress != address(0), "Token address can be 0");

        unchecked {
            _nextCampaignId++;
        }

        campaigns[_nextCampaignId] = Campaign({
            creator: msg.sender,
            goal: goal,
            deadline: deadline,
            totalDonated: 0,
            tokenAddress: tokenAddress,
            goalReached: false,
            fundsWithdrawn: false
        });

        emit FundraiserCreated(_nextCampaignId, msg.sender);
    }

    function donate(uint campaignId, uint tokenAmount) public nonReentrant {
        Campaign storage campaign = campaigns[campaignId];
        require(tokenAmount > 0, "donated amount cant be 0");
        require(campaign.creator != address(0), "Campaign not found");
        require(!campaign.goalReached, "Campaign already reached the goal");

        campaign.totalDonated += tokenAmount;
        if (campaign.totalDonated >= campaign.goal) {
            // TODO: Maybe refund if over funded?
            campaign.goalReached = true;
        }

        donations[campaignId][msg.sender] += tokenAmount;

        IERC20(campaign.tokenAddress).transferFrom(
            msg.sender,
            address(this),
            tokenAmount
        );

        emit DonationAdded(campaignId, msg.sender, tokenAmount);
    }

    function withdraw(uint campaignId) public nonReentrant {
        Campaign storage campaign = campaigns[campaignId];
        require(
            campaign.creator == msg.sender,
            "You are not the creator of the campaign"
        );
        require(campaign.goalReached, "Campaign haven't reached its goal yet");

        campaign.fundsWithdrawn = true;
        IERC20(campaign.tokenAddress).transfer(
            msg.sender,
            campaign.totalDonated
        );

        emit CreatorWithdrawn(campaignId, msg.sender, campaign.totalDonated);
    }

    function refund(uint campaignId) public nonReentrant {
        Campaign storage campaign = campaigns[campaignId];
        uint amountDonated = donations[campaignId][msg.sender];
        require(amountDonated > 0, "you haven't made any donations");
        require(!campaign.goalReached, "Campaign has reached its goal");
        require(
            block.timestamp >= campaign.deadline,
            "Campaign is still active, cant withdraw"
        );

        unchecked {
            campaign.totalDonated -= amountDonated;
        }

        donations[campaignId][msg.sender] = 0;

        IERC20(campaign.tokenAddress).transfer(msg.sender, amountDonated);

        emit DonorWithdrawn(campaignId, msg.sender, amountDonated);
    }
}
