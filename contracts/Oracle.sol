pragma solidity 0.4.26;

import "./DSMath.sol";
import "./ERC20.sol";
import "./MedianizerInterface.sol";

/**
 * @title Atomic Loans Oracle Contract
 * @author Atomic Loans
 */
contract Oracle is DSMath {
    uint32  constant public DELAY = 900; // 15 Minutes
    uint128 constant public prem = 1100000000000000000; // premium 1.1 (10%)
    uint128 constant public turn = 1010000000000000000; // minimum price change 1.01 (1%)

    MedianizerInterface med; // This constant should be initialized upon construction in child contract

    uint32 public expiry;
    uint32 public timeout;
    uint128 assetPrice;
    uint128 public paymentTokenPrice;
    uint256 rewardAmount;

    mapping(bytes32 => AsyncRequest) asyncRequests;

    /**
     * @notice Container for Chainlink / Oraclize Requests
     * @member rewardee The address of the oracle updater
     * @member payment Amount of tokens paid by updater to Chainlink / Oraclize
     * @member disbursement Amount of stablecoin tokens to be rewarded to updater
     * @member token Address of stablecoin token to be used for disbursement
     * @member assetPriceSet Indicates that the Asset Price has been set
     * @member paymentTokenPriceSet Indicates that the Payment Token Price has been set
     */
    struct AsyncRequest {
        address rewardee;
        uint128 payment;
        uint128 disbursement;
        ERC20 token;
        bool assetPriceSet;
        bool paymentTokenPriceSet;
    }

    event SetAssetPrice(bytes32 queryId, uint128 assetPrice_, uint32 expiry_);

    event SetPaymentTokenPrice(bytes32 queryId, uint128 paymentTokenPrice_);

    event Reward(bytes32 queryId);

    /**
     * @notice Return Oracle price without asserting
     */
    function peek() public view returns (bytes32,bool) {
        return (bytes32(uint(assetPrice)), now < expiry);
    }

    /**
     * @notice Return Oracle price and assert that value has been set recently
     */
    function read() public view returns (bytes32) {
        assert(now < expiry);
        return bytes32(uint(assetPrice));
    }

    /**
     * @notice Set Asset Price for Oracle on update (Oraclize) or returnAssetPrice (Chainlink)
     * @param queryId ID of the query from Chainlink or Oraclize
     * @param assetPrice_ Price of asset in WAD
     * @param expiry_ Amount of time this asset price is valid for (12 hours)
     */
    function setAssetPrice(bytes32 queryId, uint128 assetPrice_, uint32 expiry_) internal {
        asyncRequests[queryId].disbursement = 0;
        if (assetPrice_ >= wmul(assetPrice, turn) || assetPrice_ <= wdiv(assetPrice, turn)) {
            asyncRequests[queryId].disbursement = asyncRequests[queryId].payment;
        }
        assetPrice = assetPrice_;
        expiry = expiry_;
        med.poke();
        asyncRequests[queryId].assetPriceSet = true;
        if (asyncRequests[queryId].paymentTokenPriceSet) {reward(queryId);}

        emit SetAssetPrice(queryId, assetPrice_, expiry_);
    }

    /**
     * @notice Set Payment Token (ETH / LINK) Price for Oracle on __callback (Oraclize) or returnPaymentTokenPrice (Chainlink)
     * @param queryId ID of the query from Chainlink or Oraclize
     * @param paymentTokenPrice_ Price of payment token in WAD
     */
    function setPaymentTokenPrice(bytes32 queryId, uint128 paymentTokenPrice_) internal {
        paymentTokenPrice = paymentTokenPrice_;
        asyncRequests[queryId].paymentTokenPriceSet = true;
        if (asyncRequests[queryId].assetPriceSet) {reward(queryId);}

        emit SetPaymentTokenPrice(queryId, paymentTokenPrice_);
    }

    /**
     * @notice Reward user that called update on the Oracle with tokens equal to ther payment * premium (1.1)
     * @param queryId ID of the query from Chainlink or Oraclize
     */
    function reward(bytes32 queryId) internal {
        rewardAmount = wmul(wmul(paymentTokenPrice, asyncRequests[queryId].disbursement), prem);
        if (asyncRequests[queryId].token.balanceOf(address(this)) >= rewardAmount && asyncRequests[queryId].disbursement > 0) {
            require(asyncRequests[queryId].token.transfer(asyncRequests[queryId].rewardee, rewardAmount), "Oracle.reward: token transfer failed");
        }
        delete(asyncRequests[queryId]);

        emit Reward(queryId);
    }

    /**
     * @notice Sets Max Reward for Chainlink Contracts
     * @param maxReward_ Max Reward amount that can be awarded for updating Chainlink Oracle
     */
    function setMaxReward(uint256 maxReward_) public;

    /**
     * @notice Sets Gas Limit for Oraclize Contracts
     * @param gasLimit_ Gas Limit that Oraclize will use when updating the contracts
     */
    function setGasLimit(uint256 gasLimit_) public;
}
