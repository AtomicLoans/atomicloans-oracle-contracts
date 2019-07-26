pragma solidity ^0.4.26;

import "./ChainlinkedTesting.sol";
import "../Oracle.sol";
import "../ERC20.sol";

contract ChainLink is ChainlinkClient, Oracle {
    ERC20 link;
    uint256 maxr; // Max reward

    constructor(Medianizer med_, ERC20 link_, address oracle_)
        public
    {
        med = med_;
        link = link_;
        setChainlinkToken(address(link_));
        setChainlinkOracle(oracle_);
        pmt = uint128(2 * LINK);
    }

    function pack(uint128 pmt_, ERC20 tok_) { // payment
        require(uint32(now) > lag);
        require(link.transferFrom(msg.sender, address(this), uint(pmt_)));
        pmt = pmt_;
        dis = 0;
        lag = uint32(now) + DELAY;
        owed = msg.sender;
        tok = tok_;
        told = false;
        posted = false;
        call();
        chec();
    }

    function call() internal;

    function chec() internal;

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

    function ward() internal { // Reward
        gain = wmul(wmul(lval, dis), prem);
        if (tok.balanceOf(address(this)) >= min(maxr, gain) && dis > 0) {
            require(tok.transfer(owed, min(maxr, gain)));
        }
    }

    function setMax(uint256 maxr_) public {
        require(msg.sender == address(med));
        maxr = maxr_;
    }
}