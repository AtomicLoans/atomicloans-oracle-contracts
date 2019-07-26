pragma solidity ^0.4.26;

import "./ChainLink.sol";

contract CoinMarketCap is ChainLink {
    bytes32 constant UINT256_MUL_JOB = bytes32("ce36a79ea04c4d3ca015d267784417bd");

    constructor(Medianizer med_, ERC20 link_, address oracle_)
        public
        ChainLink(med_, link_, oracle_)
    {}

    function call(uint128 pmt) internal returns (bytes32 queryId) {
        Chainlink.Request memory req = buildChainlinkRequest(UINT256_MUL_JOB, this, this.cur.selector);
        req.add("sym", "BTC");
        req.add("convert", "USD");
        string[] memory path = new string[](5);
        path[0] = "data";
        path[1] = "BTC";
        path[2] = "quote";
        path[3] = "USD";
        path[4] = "price";
        req.addStringArray("copyPath", path);
        req.addInt("times", 1000000000000000000);
        queryId = sendChainlinkRequest(req, div(pmt, 2));
    }

    function chec(uint128 pmt, bytes32 queryId) internal returns (bytes32) {
        Chainlink.Request memory req = buildChainlinkRequest(UINT256_MUL_JOB, this, this.sup.selector);
        req.add("sym", "LINK");
        req.add("convert", "USD");
        string[] memory path = new string[](5);
        path[0] = "data";
        path[1] = "LINK";
        path[2] = "quote";
        path[3] = "USD";
        path[4] = "price";
        req.addStringArray("copyPath", path);
        req.addInt("times", 1000000000000000000);
        bytes32 linkrId = sendChainlinkRequest(req, div(pmt, 2));
        linkrs[linkrId] = queryId;
        return linkrId;
    }
}
