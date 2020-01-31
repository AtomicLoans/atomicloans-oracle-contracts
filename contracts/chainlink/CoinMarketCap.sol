pragma solidity ^0.4.26;

import "./ChainLink.sol";

contract CoinMarketCap is ChainLink {
    bytes32 constant UINT256_MUL_JOB = bytes32("f1805afed6a0482bb43702692ff9e061"); // COINMARKETCAP CHAINLINK MAINNET https://docs.chain.link/docs/coinmarketcap-chainlink-ethereum-mainnet Chainlink JobID
    // bytes32 constant UINT256_MUL_JOB = bytes32("cbb45ecb040340389e49b77704184e5a"); // COINMARKETCAP CHAINLINK KOVAN https://docs.chain.link/docs/coinmarketcap Kovan JobID

    constructor(Medianizer med_, ERC20 link_, address oracle_)
        public
        ChainLink(med_, link_, oracle_)
    {}

    function getAssetPrice(uint128 payment) internal returns (bytes32 queryId) {
        Chainlink.Request memory req = buildChainlinkRequest(UINT256_MUL_JOB, this, this.returnAssetPrice.selector);
        req.add("sym", "BTC");
        req.add("convert", "USD");
        string[] memory path = new string[](5);
        path[0] = "data";
        path[1] = "BTC";
        path[2] = "quote";
        path[3] = "USD";
        path[4] = "price";
        req.addStringArray("copyPath", path);
        req.addInt("times", WAD); // Convert string from API to WAD
        queryId = sendChainlinkRequest(req, div(payment, 2)); // Divide by 2 so that payment covers both asset price and asset token price
    }

    function getPaymentTokenPrice(uint128 payment, bytes32 queryId) internal returns (bytes32) {
        Chainlink.Request memory req = buildChainlinkRequest(UINT256_MUL_JOB, this, this.returnPaymentTokenPrice.selector);
        req.add("sym", "LINK");
        req.add("convert", "USD");
        string[] memory path = new string[](5);
        path[0] = "data";
        path[1] = "LINK";
        path[2] = "quote";
        path[3] = "USD";
        path[4] = "price";
        req.addStringArray("copyPath", path);
        req.addInt("times", WAD); // Convert string from API to WAD
        bytes32 linkId = sendChainlinkRequest(req, div(payment, 2)); // Divide by 2 so that payment covers both asset price and asset token price
        linkIdToQueryId[linkId] = queryId;
        return linkId;
    }
}
