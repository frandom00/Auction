🚀 Overview
This contract enables participants to bid for an item in a secure and transparent auction. The highest bid must always be at least 5% higher than the previous highest bid. The auction is time-limited and includes features such as automatic bid refunds, time extension during the last 10 minutes, a 2% commission for the seller, and on-chain event notifications.

📦 Constructor
constructor(uint256 _durationSeconds)

Initializes the auction with a custom duration in seconds.

owner is set as the deployer of the contract.

startTime is set to the block timestamp at deployment.

endTime is calculated as startTime + _durationSeconds.

🏷️ Function: bid()
function bid() external payable

Allows participants to place bids. Requirements:

The new bid must be at least 5% greater than the current highest bid.

The auction must still be active (block.timestamp < endTime).

If the bid is placed during the last 10 minutes of the auction, the auction end time is extended by 10 more minutes.

The previous highest bidder's amount is stored in pendingReturns so they can withdraw later.

Emits the NewBid event.

🥇 Function: getWinner()
function getWinner() external view returns (address, uint256)

Returns the current winner and the amount of the highest bid.

📜 Function: getAllBids()
function getAllBids() external view returns (Bid[] memory)

Returns a list of all bids placed, including the bidder address and bid amount.

💸 Function: withdraw()
function withdraw() external

Allows users to withdraw any refundable amount from previous bids that were overbid.

🏁 Function: finalizeAuction()
function finalizeAuction() external onlyOwner auctionEnded

Finalizes the auction. Can only be called by the owner after the auction ends.

Transfers 98% of the winning bid to the seller (contract owner).

Retains 2% as commission.

Marks the auction as finalized.

Emits the AuctionFinalized event.

💰 Deposit Management
All bids are deposited directly into the contract via msg.value.

Users' previous overbid amounts are recorded in the pendingReturns mapping and can be withdrawn.

🔁 Partial Refunds
If a participant places multiple bids and gets outbid, the older bid amounts become available for withdrawal through withdraw(). This prevents users from locking excessive funds.

Example:

Time	User	Bid
T0	Alice	1 ETH
T1	Bob	2 ETH
T2	Alice	3 ETH

→ Alice can withdraw the 1 ETH from T0 once she places her 3 ETH bid at T2.

⚙️ Modifiers Used
onlyOwner: Restricts access to the auction owner (contract deployer).

auctionActive: Ensures certain functions are only callable while the auction is still ongoing.

auctionEnded: Ensures finalization can only happen once the auction has ended and hasn’t been finalized yet.

📢 Events
event NewBid(address indexed bidder, uint256 amount);

event AuctionFinalized(address winner, uint256 amount);

Used to notify the frontend or watchers of key state changes in real time.

🔐 Security Considerations
Validates bid amounts strictly.

Prevents reentrancy by using the Checks-Effects-Interactions pattern in withdraw().

Ensures funds can’t be permanently locked.

Uses modifiers to enforce auction state rules.

🧪 Network & Deployment
Network: Sepolia Testnet

Contract Verified: ✅ Yes

🔗 Contract URL:  https://sepolia.etherscan.io/address/0xdf7ff98dafb505e99ece01c97c780c99fdee9723#code
