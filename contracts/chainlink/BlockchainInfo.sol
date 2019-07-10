pragma solidity >0.4.18;

import "./ChainLink.sol";
import "../DSValue.sol";

contract BlockchainInfo is ChainLink {
    bytes32 constant UINT256_MUL_JOB = bytes32("9f0406209cf64acda32636018b33de11");
    bytes32 constant UINT256_MUL_JOB__LINK = bytes32("35e428271aad4506afc4f4089ce98f68");

    constructor(DSValue med_, ERC20 link_, address oracle_)
        public
        ChainLink(med_, link_, oracle_)
    {}

    function call() internal {
        Chainlink.Request memory req = buildChainlinkRequest(UINT256_MUL_JOB, this, this.cur.selector);
        req.add("get", "https://blockchain.info/ticker?currency=USD");
        req.add("path", "USD.last");
        req.addInt("times", 1000000000000000000);
        sendChainlinkRequest(req, div(pmt, 2));
    }

    function chec() internal {
        Chainlink.Request memory req = buildChainlinkRequest(UINT256_MUL_JOB__LINK, this, this.sup.selector);
        req.add("endpoint", "price");
        req.add("fsym", "LINK");
        req.add("tsyms", "USD");
        req.add("copyPath", "USD");
        req.addInt("times", 1000000000000000000);
        sendChainlinkRequest(req, div(pmt, 2));
    }
}