pragma solidity ^0.4.26;

import "./ChainLink.sol";

contract Gemini is ChainLink {
    bytes32 constant UINT256_MUL_JOB = bytes32("c179a8180e034cf5a341488406c32827"); // LINKPOOL ROPSTEN
    // bytes32 constant UINT256_MUL_JOB = bytes32("1bc4f827ff5942eaaa7540b7dd1e20b9"); // LINKPOOL MAINNET
    bytes32 constant UINT256_MUL_JOB__LINK = bytes32("35e428271aad4506afc4f4089ce98f68"); // CRYPTOCOMPARE CHAINLINK ROPSTEN
    // bytes32 constant UINT256_MUL_JOB__LINK = bytes32("513907f96955437a8ac02a5d70e5bdea"); // CRYPTOCOMPARE CHAINLINK MAINNET

    constructor(Medianizer med_, ERC20 link_, address oracle_)
        public
        ChainLink(med_, link_, oracle_)
    {}

    function getAssetPrice(uint128 payment) internal returns (bytes32 queryId) {
        Chainlink.Request memory req = buildChainlinkRequest(UINT256_MUL_JOB, this, this.returnAssetPrice.selector);
        req.add("get", "https://api.gemini.com/v1/pubticker/btcusd");
        req.add("path", "last");
        req.addInt("times", 1000000000000000000);
        queryId = sendChainlinkRequest(req, div(payment, 2));
    }

    function getPaymentTokenPrice(uint128 payment, bytes32 queryId) internal returns (bytes32) {
        Chainlink.Request memory req = buildChainlinkRequest(UINT256_MUL_JOB__LINK, this, this.returnPaymentTokenPrice.selector);
        req.add("endpoint", "price");
        req.add("fsym", "LINK");
        req.add("tsyms", "USD");
        req.add("copyPath", "USD");
        req.addInt("times", 1000000000000000000);
        bytes32 linkId = sendChainlinkRequest(req, div(payment, 2));
        linkIdToQueryId[linkId] = queryId;
        return linkId;
    }
}
