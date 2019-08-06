pragma solidity ^0.4.26;

import "./ChainLink.sol";

contract CryptoCompare is ChainLink {
    bytes32 constant UINT256_MUL_JOB = bytes32("35e428271aad4506afc4f4089ce98f68"); // CRYPTOCOMPARE CHAINLINK ROPSTEN
    // bytes32 constant UINT256_MUL_JOB = bytes32("513907f96955437a8ac02a5d70e5bdea"); // CRYPTOCOMPARE CHAINLINK MAINNET

    constructor(Medianizer med_, ERC20 link_, address oracle_)
        public
        ChainLink(med_, link_, oracle_)
    {}

    function getAssetPrice(uint128 payment) internal returns (bytes32 queryId) {
        Chainlink.Request memory req = buildChainlinkRequest(UINT256_MUL_JOB, this, this.cur.selector);
        req.add("endpoint", "price");
        req.add("fsym", "BTC");
        req.add("tsyms", "USD");
        req.add("copyPath", "USD");
        req.addInt("times", 1000000000000000000);
        queryId = sendChainlinkRequest(req, div(payment, 2));
    }

    function chec(uint128 payment, bytes32 queryId) internal returns (bytes32) {
        Chainlink.Request memory req = buildChainlinkRequest(UINT256_MUL_JOB, this, this.sup.selector);
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
