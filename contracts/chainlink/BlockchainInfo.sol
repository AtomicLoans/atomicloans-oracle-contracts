pragma solidity 0.4.26;

import "./ChainLink.sol";

contract BlockchainInfo is ChainLink {
    /**
     * CHAINLINK MAINNET
     * https://docs.chain.link/docs/decentralized-oracles-ethereum-mainnet
     * HttpGet JsonParse Multiply EthUint256
     */
    bytes32 constant UINT256_MUL_JOB = bytes32("f291f8597d174f4aa1983b0e27ae160f");

    /**
     * CHAINLINK KOVAN
     * https://docs.chain.link/docs/testnet-oracles
     * HttpGet JsonParse Multiply EthUint256
     */
    // bytes32 constant UINT256_MUL_JOB = bytes32("29fa9aa13bf1468788b7cc4a500a45b8");

    /**
     * CRYPTOCOMPARE CHAINLINK MAINNET
     * https://docs.chain.link/docs/cryptocompare-chainlink-ethereum-mainnet
     * Chainlink JobID
     */
    bytes32 constant UINT256_MUL_JOB__LINK = bytes32("513907f96955437a8ac02a5d70e5bdea");

    /**
     * CRYPTOCOMPARE CHAINLINK KOVAN
     * https://docs.chain.link/docs/cryptocompare
     * Kovan JobID
     */
    // bytes32 constant UINT256_MUL_JOB__LINK = bytes32("7f350c947b0d4d758aadd5acb41d2474");

    constructor(MedianizerInterface med_, ERC20 link_, address oracle_)
        public
        ChainLink(med_, link_, oracle_)
    {}

    function getAssetPrice(uint128 payment_) internal returns (bytes32 queryId) {
        Chainlink.Request memory req = buildChainlinkRequest(UINT256_MUL_JOB, this, this.returnAssetPrice.selector);
        req.add("get", "https://blockchain.info/ticker?currency=USD");
        req.add("path", "USD.last");
        req.addInt("times", WAD); // Convert string from API to WAD
        queryId = sendChainlinkRequest(req, div(payment_, 2)); // Divide by 2 so that payment covers both asset price and token price
    }

    function getPaymentTokenPrice(uint128 payment_, bytes32 queryId) internal returns (bytes32) {
        Chainlink.Request memory req = buildChainlinkRequest(UINT256_MUL_JOB__LINK, this, this.returnPaymentTokenPrice.selector);
        req.add("endpoint", "price");
        req.add("fsym", "LINK");
        req.add("tsyms", "USD");
        req.add("copyPath", "USD");
        req.addInt("times", WAD); // Convert string from API to WAD
        bytes32 linkId = sendChainlinkRequest(req, div(payment_, 2)); // Divide by 2 so that payment covers both asset price and token price
        linkIdToQueryId[linkId] = queryId;
        return linkId;
    }
}
