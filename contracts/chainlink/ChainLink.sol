pragma solidity >0.4.18;

import "./Chainlinked.sol";
import "../Oracle.sol";
import "../ERC20.sol";
import "../DSValue.sol";

contract ChainLink is ChainlinkClient, Oracle {
    ERC20 link;

    constructor(DSValue med_, ERC20 link_, address oracle_)
        public
    {
        med = med_;
        link = link_;
        setChainlinkToken(address(link_));
        setChainlinkOracle(oracle_);
        pmt = uint128(2 * LINK);
        dis = pmt; 
    }

    function pack(uint128 pmt_, ERC20 tok_) { // payment
        require(uint32(now) > lag);
        link.transferFrom(msg.sender, address(this), uint(pmt_));
        pmt = pmt_;
        lag = uint32(now) + DELAY;
        owed = msg.sender;
        tok = tok_;
        told = false;
        posted = false;
        call();
        chec();
    }

    function call() internal {
        zzz = uint32(now + 43200);
    }

    function chec() internal {
        dis = pmt;
    }

    function cur(bytes32 _requestId, uint256 _price) // Currency
        public
        recordChainlinkFulfillment(_requestId)
    {
        post(uint128(_price), uint32(now + 43200));
    }
    
    function sup(bytes32 _requestId, uint256 _price) // Supply Currency
        public
        recordChainlinkFulfillment(_requestId)
    {
        tell(uint128(_price));
    }

    function setMax(uint256 maxr_) public {
        require(msg.sender == address(med));
        maxr = maxr_;
    }
}