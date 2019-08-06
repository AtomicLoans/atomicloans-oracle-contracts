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
        areqs[lastQueryId].pmt = uint128(2 * LINK);
    }

    function bill() public view returns (uint256) {
        return areqs[lastQueryId].pmt;
    }

    function pack(uint128 pmt_, ERC20 tok_) { // payment
        require(uint32(now) > timeout);
        require(link.transferFrom(msg.sender, address(this), uint(pmt_)));
        bytes32 queryId = call(pmt_);
        lastQueryId = queryId;
        bytes32 linkrId = chec(pmt_, queryId);
        linkrs[linkrId] = queryId;
        areqs[queryId].owed = msg.sender;
        areqs[queryId].pmt  = pmt_;
        areqs[queryId].tok  = tok_;
        timeout = uint32(now) + DELAY;
    }

    function call(uint128 pmt) internal returns (bytes32);

    function chec(uint128 pmt, bytes32 queryId) internal returns (bytes32);

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
        rewardAmount = wmul(wmul(paymentTokenPrice, areqs[queryId].dis), prem);
        if (areqs[queryId].tok.balanceOf(address(this)) >= min(maxReward, rewardAmount) && areqs[queryId].dis > 0) {
            require(areqs[queryId].tok.transfer(areqs[queryId].owed, min(maxReward, rewardAmount)));
        }
    }

    function setMaxReward(uint256 maxReward_) public {
        require(msg.sender == address(med));
        maxReward = maxReward_;
    }
}