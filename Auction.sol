// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Auction {
    struct Bid {
        uint256 amount;
        address bidder;
    }

    address public owner;
    Bid public highestBid;
    Bid[] private allBids;

    uint256 public startTime;
    uint256 public endTime;
    bool public finalized;

    mapping(address => uint256) public pendingReturns;
    mapping(address => bool) private hasBid;
    address[] private bidders;

    event NewBid(address indexed bidder, uint256 amount);
    event AuctionFinalized(address winner, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier auctionActive() {
        require(block.timestamp < endTime, "Auction ended");
        _;
    }

    modifier auctionEnded() {
        require(block.timestamp >= endTime, "Auction active");
        require(!finalized, "Already finalized");
        _;
    }

    /// Initializes the auction with a given duration in seconds
    /// @param _durationSeconds Duration in seconds
    constructor(uint256 _durationSeconds) {
        owner = msg.sender;
        startTime = block.timestamp;
        endTime = startTime + _durationSeconds;
    }

    /// Places a bid at least 5% higher than the current highest bid
    /// Extends auction 10 minutes if bid is placed in last 10 minutes
    function bid() external payable auctionActive {
        uint256 currentAmount = highestBid.amount;
        require(msg.value > currentAmount * 105 / 100, "Min 5% higher");

        if (endTime - block.timestamp <= 10 minutes) {
            endTime += 10 minutes;
        }

        if (currentAmount > 0) {
            pendingReturns[highestBid.bidder] += currentAmount;
        }

        highestBid = Bid(msg.value, msg.sender);
        allBids.push(highestBid);

        if (!hasBid[msg.sender]) {
            hasBid[msg.sender] = true;
            bidders.push(msg.sender);
        }

        emit NewBid(msg.sender, msg.value);
    }

    /// Returns the current highest bidder and amount
    /// @return Address of bidder and bid amount
    function getWinner() external view returns (address, uint256) {
        return (highestBid.bidder, highestBid.amount);
    }

    /// Returns all bids made during the auction
    /// @return Array of Bid structs
    function getAllBids() external view returns (Bid[] memory) {
        return allBids;
    }

    /// Allows user to withdraw full refundable balance
    function withdraw() external {
        uint256 amount = pendingReturns[msg.sender];
        require(amount > 0, "No funds");

        pendingReturns[msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
    }

    /// Allows user to withdraw part of refundable balance
    /// @param amount Amount to withdraw
    function withdrawPartial(uint256 amount) external {
        uint256 available = pendingReturns[msg.sender];
        require(amount > 0, "Zero amount");
        require(available >= amount, "Insufficient funds");

        pendingReturns[msg.sender] -= amount;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
    }

    /// Finalizes the auction and transfers funds to owner minus 2% commission
    function finalizeAuction() external onlyOwner auctionEnded {
        finalized = true;

        uint256 amount = highestBid.amount;
        uint256 commission = amount * 2 / 100;
        uint256 sellerAmount = amount - commission;

        (bool success, ) = payable(owner).call{value: sellerAmount}("");
        require(success, "Transfer failed");

        emit AuctionFinalized(highestBid.bidder, amount);
    }

    /// Refunds all pending returns to previous bidders using a loop
    function refundAll() external onlyOwner {
        uint256 len = bidders.length;

        for (uint256 i = 0; i < len; i++) {
            address bidder = bidders[i];
            uint256 amount = pendingReturns[bidder];

            if (amount > 0) {
                pendingReturns[bidder] = 0;
                (bool success, ) = payable(bidder).call{value: amount}("");
                require(success, "Refund failed");
            }
        }
    }

    /// Allows owner to recover stuck ETH in contract
    function emergencyWithdraw() external onlyOwner {
        (bool success, ) = payable(owner).call{value: address(this).balance}("");
        require(success, "Emergency failed");
    }
}
