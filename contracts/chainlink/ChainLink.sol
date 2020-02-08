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

    constructor(Medianizer med_, ERC20 link_, address oracle_)
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

    function update(uint128 payment_, ERC20 token_) { // payment
        require(uint32(now) > timeout);
        require(link.transferFrom(msg.sender, address(this), uint(payment_)));
        bytes32 queryId = getAssetPrice(payment_);
        lastQueryId = queryId;
        bytes32 linkId = getPaymentTokenPrice(payment_, queryId);
        linkIdToQueryId[linkId] = queryId;
        asyncRequests[queryId].rewardee = msg.sender;
        asyncRequests[queryId].payment  = payment_;
        asyncRequests[queryId].token    = token_;
        timeout = uint32(now) + DELAY;
    }

    function getAssetPrice(uint128 payment) internal returns (bytes32);

    function getPaymentTokenPrice(uint128 payment, bytes32 queryId) internal returns (bytes32);

    function returnAssetPrice(bytes32 _requestId, uint256 _price) // Currency
        public
        recordChainlinkFulfillment(_requestId)
    {
        setAssetPrice(_requestId, uint128(_price), uint32(now + ORACLE_EXPIRY));
    }
    
    function returnPaymentTokenPrice(bytes32 _requestId, uint256 _price) // Supply Currency
        public
        recordChainlinkFulfillment(_requestId)
    {
        setPaymentTokenPrice(linkIdToQueryId[_requestId], uint128(_price));
    }

    function reward(bytes32 queryId) internal { // Reward
        rewardAmount = wmul(wmul(paymentTokenPrice, asyncRequests[queryId].disbursement), prem);
        if (asyncRequests[queryId].token.balanceOf(address(this)) >= min(maxReward, rewardAmount) && asyncRequests[queryId].disbursement > 0) {
            require(asyncRequests[queryId].token.transfer(asyncRequests[queryId].rewardee, min(maxReward, rewardAmount)));
        }
    }

    function setMaxReward(uint256 maxReward_) public {
        require(msg.sender == address(med));
        maxReward = maxReward_;
    }
}