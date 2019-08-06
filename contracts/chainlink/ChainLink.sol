pragma solidity ^0.4.26;

// import "./Chainlinked.sol"; // MAINNET
import "./ChainlinkedTesting.sol"; // TESTING
import "../Oracle.sol";
import "../ERC20.sol";

contract ChainLink is ChainlinkClient, Oracle {
    ERC20 link;
    uint256 maxReward; // Max reward

    bytes32 public lastQueryId;

    mapping(bytes32 => bytes32) linkrs;

    constructor(Medianizer med_, ERC20 link_, address oracle_)
        public
    {
        med = med_;
        link = link_;
        setChainlinkToken(address(link_));
        setChainlinkOracle(oracle_);
        asyncRequests[lastQueryId].payment = uint128(2 * LINK);
    }

    function bill() public view returns (uint256) {
        return asyncRequests[lastQueryId].payment;
    }

    function pack(uint128 payment_, ERC20 tok_) { // payment
        require(uint32(now) > timeout);
        require(link.transferFrom(msg.sender, address(this), uint(payment_)));
        bytes32 queryId = call(payment_);
        lastQueryId = queryId;
        bytes32 linkrId = chec(payment_, queryId);
        linkrs[linkrId] = queryId;
        asyncRequests[queryId].rewardee = msg.sender;
        asyncRequests[queryId].payment  = payment_;
        asyncRequests[queryId].tok      = tok_;
        timeout = uint32(now) + DELAY;
    }

    function call(uint128 payment) internal returns (bytes32);

    function chec(uint128 payment, bytes32 queryId) internal returns (bytes32);

    function cur(bytes32 _requestId, uint256 _price) // Currency
        public
        recordChainlinkFulfillment(_requestId)
    {
        post(_requestId, uint128(_price), uint32(now + 43200));
    }
    
    function sup(bytes32 _requestId, uint256 _price) // Supply Currency
        public
        recordChainlinkFulfillment(_requestId)
    {
        tell(linkrs[_requestId], uint128(_price));
    }

    function ward(bytes32 queryId) internal { // Reward
        rewardAmount = wmul(wmul(paymentTokenPrice, asyncRequests[queryId].disbursement), prem);
        if (asyncRequests[queryId].tok.balanceOf(address(this)) >= min(maxReward, rewardAmount) && asyncRequests[queryId].disbursement > 0) {
            require(asyncRequests[queryId].tok.transfer(asyncRequests[queryId].rewardee, min(maxReward, rewardAmount)));
        }
    }

    function setMaxReward(uint256 maxReward_) public {
        require(msg.sender == address(med));
        maxReward = maxReward_;
    }
}