// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract ERC20Vesting {
    ERC20 token;
    address owner;

    event Deposited(address indexed user, uint amount, uint duration);
    event Claimed(address user, uint amount);

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
    error NotOwner();

    constructor(address _tokenAddress) {
        token = ERC20(_tokenAddress);
        owner = msg.sender;
    }

    modifier notZeroAddress(address addr) {
        if (addr == address(0)) revert ZeroAddress();
        _;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    function _claimableNow(
        VestingSchedule storage vesting
    ) internal view returns (uint) {
        if (vesting.totalAmount == 0) return 0;

        uint elapsed = block.timestamp - vesting.startTime;
        if (elapsed > vesting.duration) elapsed = vesting.duration;

        uint totalUnlocked = (vesting.totalAmount * elapsed) / vesting.duration;
        if (totalUnlocked <= vesting.claimedAmount) return 0;

        return totalUnlocked - vesting.claimedAmount;
    }

    function claimableNow(address user) public view returns (uint) {
        return _claimableNow(vestings[user]);
    }

    function depositFor(
        address user,
        uint amount,
        uint duration
    ) public notZeroAddress(user) onlyOwner {
        if (vestings[user].totalAmount > 0) revert AlreadyVested();
        if (duration == 0) revert ZeroDuration();
        vestings[user] = VestingSchedule({
            totalAmount: amount,
            claimedAmount: 0,
            startTime: block.timestamp,
            duration: duration
        });
        emit Deposited(user, amount, duration);
        require(
            token.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );
    }

    function claim() public {
        VestingSchedule storage userVesting = vestings[msg.sender];

        uint claimableNow_ = _claimableNow(userVesting);
        if (claimableNow_ == 0) revert NothingToClaim();

        userVesting.claimedAmount += claimableNow_;

        emit Claimed(msg.sender, claimableNow_);
        require(token.transfer(msg.sender, claimableNow_), "Transfer failed");
    }
}
