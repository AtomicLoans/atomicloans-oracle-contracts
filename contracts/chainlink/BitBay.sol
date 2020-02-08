pragma solidity 0.4.26;

import "./ChainLink.sol";

contract BitBay is ChainLink {
    bytes32 constant UINT256_MUL_JOB = bytes32("f291f8597d174f4aa1983b0e27ae160f"); // CHAINLINK MAINNET https://docs.chain.link/docs/decentralized-oracles-ethereum-mainnet HttpGet JsonParse Multiply EthUint256
    // bytes32 constant UINT256_MUL_JOB = bytes32("29fa9aa13bf1468788b7cc4a500a45b8"); // CHAINLINK KOVAN https://docs.chain.link/docs/testnet-oracles HttpGet JsonParse Multiply EthUint256
    bytes32 constant UINT256_MUL_JOB__LINK = bytes32("513907f96955437a8ac02a5d70e5bdea"); // CRYPTOCOMPARE CHAINLINK MAINNET https://docs.chain.link/docs/cryptocompare-chainlink-ethereum-mainnet Chainlink JobID
    // bytes32 constant UINT256_MUL_JOB__LINK = bytes32("7f350c947b0d4d758aadd5acb41d2474"); // CRYPTOCOMPARE CHAINLINK KOVAN https://docs.chain.link/docs/cryptocompare Kovan JobID

    constructor(Medianizer med_, ERC20 link_, address oracle_)
        public
        ChainLink(med_, link_, oracle_)
    {}

    function getAssetPrice(uint128 payment) internal returns (bytes32 queryId) {
        Chainlink.Request memory req = buildChainlinkRequest(UINT256_MUL_JOB, this, this.returnAssetPrice.selector);
        req.add("get", "https://bitbay.net/API/Public/btcusd/ticker.json");
        req.add("path", "last");
        req.addInt("times", WAD); // Convert string from API to WAD
        queryId = sendChainlinkRequest(req, div(payment, 2)); // Divide by 2 so that payment covers both asset price and asset token price
    }

    function getPaymentTokenPrice(uint128 payment, bytes32 queryId) internal returns (bytes32) {
        Chainlink.Request memory req = buildChainlinkRequest(UINT256_MUL_JOB__LINK, this, this.returnPaymentTokenPrice.selector);
        req.add("endpoint", "price");
        req.add("fsym", "LINK");
        req.add("tsyms", "USD");
        req.add("copyPath", "USD");
        req.addInt("times", WAD); // Convert string from API to WAD
        bytes32 linkId = sendChainlinkRequest(req, div(payment, 2)); // Divide by 2 so that payment covers both asset price and asset token price
        linkIdToQueryId[linkId] = queryId;
        return linkId;
    }
}
