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

    event NewBid(address indexed bidder, uint256 amount);
    event AuctionFinalized(address winner, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this");
        _;
    }

    modifier auctionActive() {
        require(block.timestamp < endTime, "Auction is not active");
        _;
    }

    modifier auctionEnded() {
        require(block.timestamp >= endTime, "Auction is still active");
        require(!finalized, "Auction already finalized");
        _;
    }

    constructor(uint256 _durationSeconds) {
        owner = msg.sender;
        startTime = block.timestamp;
        endTime = startTime + _durationSeconds;
    }

    function bid() external payable auctionActive {
        require(msg.value > highestBid.amount * 105 / 100, "Bid must be at least 5% higher");

        if (endTime - block.timestamp <= 10 minutes) {
            endTime = 10 minutes;
        }

        if (highestBid.amount > 0) {
            pendingReturns[highestBid.bidder] += highestBid.amount;
        }

        highestBid = Bid(msg.value, msg.sender);
        allBids.push(Bid(msg.value, msg.sender));

        emit NewBid(msg.sender, msg.value);
    }

    function getWinner() external view returns (address, uint256) {
        return (highestBid.bidder, highestBid.amount);
    }

    function getAllBids() external view returns (Bid[] memory) {
        return allBids;
    }

    function withdraw() external {
        uint256 amount = pendingReturns[msg.sender];
        require(amount > 0, "Nothing to withdraw");

        pendingReturns[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function finalizeAuction() external onlyOwner auctionEnded {
        finalized = true;

        uint256 commission = highestBid.amount * 2 / 100;
        uint256 sellerAmount = highestBid.amount - commission;

        payable(owner).transfer(sellerAmount);
        emit AuctionFinalized(highestBid.bidder, highestBid.amount);
    }
}
