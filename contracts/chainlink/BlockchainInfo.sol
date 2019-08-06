pragma solidity ^0.4.26;

import "./ChainLink.sol";

contract BlockchainInfo is ChainLink {
    bytes32 constant UINT256_MUL_JOB = bytes32("9f0406209cf64acda32636018b33de11"); // CHAINLINK ROPSTEN
    // bytes32 constant UINT256_MUL_JOB = bytes32("f291f8597d174f4aa1983b0e27ae160f"); // CHAINLINK MAINNET
    bytes32 constant UINT256_MUL_JOB__LINK = bytes32("35e428271aad4506afc4f4089ce98f68"); // CRYPTOCOMPARE CHAINLINK ROPSTEN
    // bytes32 constant UINT256_MUL_JOB__LINK = bytes32("513907f96955437a8ac02a5d70e5bdea"); // CRYPTOCOMPARE CHAINLINK MAINNET

    constructor(Medianizer med_, ERC20 link_, address oracle_)
        public
        ChainLink(med_, link_, oracle_)
    {}

    function getAssetPrice(uint128 payment) internal returns (bytes32 queryId) {
        Chainlink.Request memory req = buildChainlinkRequest(UINT256_MUL_JOB, this, this.cur.selector);
        req.add("get", "https://blockchain.info/ticker?currency=USD");
        req.add("path", "USD.last");
        req.addInt("times", 1000000000000000000);
        queryId = sendChainlinkRequest(req, div(payment, 2));
    }

    function chec(uint128 payment, bytes32 queryId) internal returns (bytes32) {
        Chainlink.Request memory req = buildChainlinkRequest(UINT256_MUL_JOB__LINK, this, this.sup.selector);
        req.add("endpoint", "price");
        req.add("fsym", "LINK");
        req.add("tsyms", "USD");
        req.add("copyPath", "USD");
        req.addInt("times", 1000000000000000000);
        bytes32 linkrId = sendChainlinkRequest(req, div(payment, 2));
        linkrs[linkrId] = queryId;
        return linkrId;
    }
}
