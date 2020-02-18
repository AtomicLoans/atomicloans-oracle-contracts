pragma solidity 0.4.26;

// import "./Chainlinked.sol"; // MAINNET
import "../test/ChainlinkedTesting.sol"; // TESTING
import "../Oracle.sol";
import "../ERC20.sol";

/**
 * @title Atomic Loans Chainlink Contract
 * @author Atomic Loans
 */
contract ChainLink is ChainlinkClient, Oracle {
    ERC20 link;
    uint256 maxReward; // Max reward

    bytes32 public lastQueryId;

    uint256 public constant DEFAULT_LINK_PAYMENT = 2 * LINK; // Default link payment
    uint256 public constant ORACLE_EXPIRY = 12 hours; // Oracle expiry (price needs to be updated every 12 hours to be considered up to date)

    mapping(bytes32 => bytes32) linkIdToQueryId;

    /**
     * @notice Construct a new Chainlink Oracle
     * @param med_ The address of the Medianizer
     * @param link_ The LINK token address
     * @param oracle_ The Chainlink Oracle address
     */
    constructor(MedianizerInterface med_, ERC20 link_, address oracle_) public {
        med = med_;
        link = link_;
        setChainlinkToken(address(link_));
        setChainlinkOracle(oracle_);
        asyncRequests[lastQueryId].payment = uint128(DEFAULT_LINK_PAYMENT);
    }

    /**
     * @notice Gets the payment needed to update the Oracle
     * @return Chaillink last price for query in wei
     */
    function bill() public view returns (uint256) {
        return asyncRequests[lastQueryId].payment;
    }

    /**
     * @notice Sender redeems LINK in exchange for Updating the Oracle and receiving stablecoin tokens
     * @param payment_ The amount of LINK used as payment for Chainlink
     * @param token_ The address of the ERC20 stablecoin to receive as a reward
     */
    function update(uint128 payment_, ERC20 token_) public { // payment
        require(uint32(now) > timeout, "ChainLink.update: now is less than timeout");
        require(link.transferFrom(msg.sender, address(this), uint(payment_)), "ChainLink.update: failed to transfer link from msg.sender");
        bytes32 queryId = getAssetPrice(payment_);
        lastQueryId = queryId;
        bytes32 linkId = getPaymentTokenPrice(payment_, queryId);
        linkIdToQueryId[linkId] = queryId;
        asyncRequests[queryId].rewardee = msg.sender;
        asyncRequests[queryId].payment = payment_;
        asyncRequests[queryId].token = token_;
        timeout = uint32(now) + DELAY;
    }

    function getAssetPrice(uint128) internal returns (bytes32);

    function getPaymentTokenPrice(uint128, bytes32) internal returns (bytes32);

    /**
     * @notice Chainlink returns result from API price query
     * @param requestId_ ID of the query from Chainlink
     * @param price_ API price returned from Chainlink query
     */
    function returnAssetPrice(bytes32 requestId_, uint256 price_) public recordChainlinkFulfillment(requestId_) {
        setAssetPrice(requestId_, uint128(price_), uint32(now + ORACLE_EXPIRY));
    }

    /**
     * @notice Chainlink returns result from API LINK price query
     * @param requestId_ ID of the query from Chainlink
     * @param price_ API LINK price returned from Chainlink query
     */
    function returnPaymentTokenPrice(bytes32 requestId_, uint256 price_) public recordChainlinkFulfillment(requestId_) {
        setPaymentTokenPrice(linkIdToQueryId[requestId_], uint128(price_));
    }

    /**
     * @notice Reward user that called update on the Oracle with tokens equal to ther payment * premium (1.1)
     * @param queryId ID of the query from Chainlink or Oraclize
     */
    function reward(bytes32 queryId) internal {
        rewardAmount = wmul(wmul(paymentTokenPrice, asyncRequests[queryId].disbursement), prem);
        if (asyncRequests[queryId].token.balanceOf(address(this)) >= min(maxReward, rewardAmount) && asyncRequests[queryId].disbursement > 0) {
            require(asyncRequests[queryId].token.transfer(asyncRequests[queryId].rewardee, min(maxReward, rewardAmount)), "ChainLink.reward: token transfer failed");
        }
    }

    /**
     * @notice Sets Max Reward for Chainlink Contracts
     * @param maxReward_ Max Reward amount that can be awarded for updating Chainlink Oracle
     */
    function setMaxReward(uint256 maxReward_) public {
        require(msg.sender == address(med), "ChainLink.setMaxReward: msg.sender isn't medianizer address");
        maxReward = maxReward_;
    }

    /**
     * @notice Sets Gas Limit for Oraclize Contracts
     */
    function setGasLimit(uint256) public {
        require(msg.sender == address(med), "Oraclize.setGasLimit: msg.sender isn't medianizer address");
    }
}