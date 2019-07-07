pragma solidity >0.4.18;

import "./ChainlinkOracle.sol";

contract CryptoCompareChainlinkOracle is ChainlinkOracle {
    bytes32 constant UINT256_MUL_JOB = bytes32("35e428271aad4506afc4f4089ce98f68");

    function call() internal {
        Chainlink.Request memory req = buildChainlinkRequest(UINT256_MUL_JOB, this, this.cur.selector);
        req.add("endpoint", "price");
        req.add("fsym", "BTC");
        req.add("tsyms", "USD");
        req.add("copyPath", "USD");
        req.addInt("times", 1000000000000000000);
        sendChainlinkRequest(req, div(pmt, 2));
    }

    function chec() internal {
        Chainlink.Request memory req = buildChainlinkRequest(UINT256_MUL_JOB, this, this.sup.selector);
        req.add("endpoint", "price");
        req.add("fsym", "LINK");
        req.add("tsyms", "USD");
        req.add("copyPath", "USD");
        req.addInt("times", 1000000000000000000);
        sendChainlinkRequest(req, div(pmt, 2));
    }
}