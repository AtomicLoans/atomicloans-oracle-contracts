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

    mapping(bytes32 => Areq) areqs;

    struct Areq {
        address owed;
        uint128 pmt;
        uint128 dis;
        ERC20 tok;
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
        areqs[queryId].dis = 0;
        if (assetPrice_ >= wmul(assetPrice, turn) || assetPrice_ <= wdiv(assetPrice, turn)) { areqs[queryId].dis = areqs[queryId].pmt; }
        assetPrice = assetPrice_;
        expiry = expiry_;
        med.poke();
        areqs[queryId].posted = true;
        if (areqs[queryId].told) { ward(queryId); }
    }

    function tell(bytes32 queryId, uint128 paymentTokenPrice_) internal {
        paymentTokenPrice = paymentTokenPrice_;
        areqs[queryId].told = true;
        if (areqs[queryId].posted) { ward(queryId); }
    }

    function ward(bytes32 queryId) internal { // Reward
        rewardAmount = wmul(wmul(paymentTokenPrice, areqs[queryId].dis), prem);
        if (areqs[queryId].tok.balanceOf(address(this)) >= rewardAmount && areqs[queryId].dis > 0) {
            require(areqs[queryId].tok.transfer(areqs[queryId].owed, rewardAmount));
        }
        delete(areqs[queryId]);
    }

    function setMaxReward(uint256 maxReward_) public;
}
