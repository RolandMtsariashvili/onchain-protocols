// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract ETHFundraiser is ReentrancyGuard {
    struct Campaign {
        address creator;
        uint goal;
        uint deadline;
        uint totalDonated;
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

    function createFundraiser(uint goal, uint deadline) public nonReentrant {
        require(goal > 0, "Goal can not be zero");
        require(deadline > block.timestamp, "Deadline cant be in the past");

        unchecked {
            _nextCampaignId++;
        }

        campaigns[_nextCampaignId] = Campaign({
            creator: msg.sender,
            goal: goal,
            deadline: deadline,
            totalDonated: 0,
            goalReached: false,
            fundsWithdrawn: false
        });

        emit FundraiserCreated(_nextCampaignId, msg.sender);
    }

    function donate(uint campaignId) public payable nonReentrant {
        Campaign storage campaign = campaigns[campaignId];
        require(msg.value > 0, "donated amount cant be 0");
        require(campaign.creator != address(0), "Campaign not found");
        require(!campaign.goalReached, "Campaign already reached the goal");

        campaign.totalDonated += msg.value;
        if (campaign.totalDonated >= campaign.goal) {
            // TODO: Maybe refund if over funded?
            campaign.goalReached = true;
        }

        donations[campaignId][msg.sender] += msg.value;

        emit DonationAdded(campaignId, msg.sender, msg.value);
    }

    function withdraw(uint campaignId) public nonReentrant {
        Campaign storage campaign = campaigns[campaignId];
        require(
            campaign.creator == msg.sender,
            "You are not the creator of the campaign"
        );
        require(campaign.goalReached, "Campaign haven't reached its goal yet");

        campaign.fundsWithdrawn = true;

        (bool success, ) = campaign.creator.call{value: campaign.totalDonated}(
            ""
        );
        require(success, "ETH Transaction fails");

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

        (bool success, ) = msg.sender.call{value: amountDonated}("");
        require(success, "ETH transaction failed");
        emit DonorWithdrawn(campaignId, msg.sender, amountDonated);
    }

    function getContractBalance() external view returns (uint) {
        return address(this).balance;
    }
}
