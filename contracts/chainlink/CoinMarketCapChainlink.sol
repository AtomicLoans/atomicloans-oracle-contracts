pragma solidity >0.4.18;

import "./ChainlinkOracle.sol";

contract CoinMarketCapChainlinkOracle is ChainlinkOracle {
    bytes32 constant UINT256_MUL_JOB = bytes32("ce36a79ea04c4d3ca015d267784417bd");

    function call() internal {
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
        sendChainlinkRequest(req, div(pmt, 2));
    }

    function chec() internal {
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
        sendChainlinkRequest(req, div(pmt, 2));
    }
}