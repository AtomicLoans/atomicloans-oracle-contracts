pragma solidity 0.4.26;

// import "./Chainlinked.sol"; // MAINNET
import "../test/ChainlinkedTesting.sol"; // TESTING
import "../Oracle.sol";
import "../ERC20.sol";

contract ChainLink is ChainlinkClient, Oracle {
    ERC20 link;
    uint256 maxReward; // Max reward

    bytes32 public lastQueryId;

    uint256 public constant DEFAULT_LINK_PAYMENT = 2 * LINK; // Default link payment
    uint256 public constant ORACLE_EXPIRY = 12 hours; // Oracle expiry (price needs to be updated every 12 hours to be considered up to date)

    mapping(bytes32 => bytes32) linkIdToQueryId;

    constructor(MedianizerInterface med_, ERC20 link_, address oracle_)
        public
    {
        med = med_;
        link = link_;
        setChainlinkToken(address(link_));
        setChainlinkOracle(oracle_);
        asyncRequests[lastQueryId].payment = uint128(DEFAULT_LINK_PAYMENT);
    }

    function bill() public view returns (uint256) {
        return asyncRequests[lastQueryId].payment;
    }

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

    function returnAssetPrice(bytes32 requestId_, uint256 price_) // Currency
        public
        recordChainlinkFulfillment(requestId_)
    {
        setAssetPrice(requestId_, uint128(price_), uint32(now + ORACLE_EXPIRY));
    }

    function returnPaymentTokenPrice(bytes32 requestId_, uint256 price_) // Supply Currency
        public
        recordChainlinkFulfillment(requestId_)
    {
        setPaymentTokenPrice(linkIdToQueryId[requestId_], uint128(price_));
    }

    function reward(bytes32 queryId) internal { // Reward
        rewardAmount = wmul(wmul(paymentTokenPrice, asyncRequests[queryId].disbursement), prem);
        if (asyncRequests[queryId].token.balanceOf(address(this)) >= min(maxReward, rewardAmount) && asyncRequests[queryId].disbursement > 0) {
            require(asyncRequests[queryId].token.transfer(asyncRequests[queryId].rewardee, min(maxReward, rewardAmount)), "ChainLink.reward: token transfer failed");
        }
    }

    function setMaxReward(uint256 maxReward_) public {
        require(msg.sender == address(med), "ChainLink.setMaxReward: msg.sender isn't medianizer address");
        maxReward = maxReward_;
    }

    function setGasLimit(uint256 gasLimit_) public {
        require(msg.sender == address(med), "Oraclize.setGasLimit: msg.sender isn't medianizer address");
    }
}