pragma solidity ^0.4.26;

import "./DSMath.sol";
import "./ERC20.sol";
import "./Medianizer.sol";

contract Oracle is DSMath {
    uint32  constant public DELAY = 900; // 15 Minutes
    uint128 constant public prem = 1100000000000000000; // premium 1.1 (10%)
    uint128 constant public turn = 1010000000000000000; // minimum price change 1.01 (1%)

    Medianizer med;

    uint32 public expiry;
    uint32 public timeout;
    uint128 assetPrice;                     
    uint128 public paymentTokenPrice;
    uint256 rewardAmount;

    mapping(bytes32 => AsyncRequest) asyncRequests;

    struct AsyncRequest {
        address rewardee;
        uint128 payment;
        uint128 disbursement;
        ERC20 token;
        bool posted;
        bool told;
    }

    function peek() public view
        returns (bytes32,bool)
    {
        return (bytes32(uint(assetPrice)), now < expiry);
    }

    function read() public view
        returns (bytes32)
    {
        assert(now < expiry);
        return bytes32(uint(assetPrice));
    }
    
    function post(bytes32 queryId, uint128 assetPrice_, uint32 expiry_) internal
    {
        asyncRequests[queryId].disbursement = 0;
        if (assetPrice_ >= wmul(assetPrice, turn) || assetPrice_ <= wdiv(assetPrice, turn)) { asyncRequests[queryId].disbursement = asyncRequests[queryId].payment; }
        assetPrice = assetPrice_;
        expiry = expiry_;
        med.poke();
        asyncRequests[queryId].posted = true;
        if (asyncRequests[queryId].told) { ward(queryId); }
    }

    function tell(bytes32 queryId, uint128 paymentTokenPrice_) internal {
        paymentTokenPrice = paymentTokenPrice_;
        asyncRequests[queryId].told = true;
        if (asyncRequests[queryId].posted) { ward(queryId); }
    }

    function ward(bytes32 queryId) internal { // Reward
        rewardAmount = wmul(wmul(paymentTokenPrice, asyncRequests[queryId].disbursement), prem);
        if (asyncRequests[queryId].token.balanceOf(address(this)) >= rewardAmount && asyncRequests[queryId].disbursement > 0) {
            require(asyncRequests[queryId].token.transfer(asyncRequests[queryId].rewardee, rewardAmount));
        }
        delete(asyncRequests[queryId]);
    }

    function setMaxReward(uint256 maxReward_) public;
}
