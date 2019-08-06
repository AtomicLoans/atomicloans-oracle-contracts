pragma solidity ^0.4.26;

import "./ChainLink.sol";

contract SoChain is ChainLink {
    bytes32 constant UINT256_MUL_JOB = bytes32("80fecd06d2e14c67a22cee5f9728e067"); // FIEWS ROPSTEN
    // bytes32 constant UINT256_MUL_JOB = bytes32("98839fc3b550436bbe752f82d7521843"); // FIEWS MAINNET
    bytes32 constant UINT256_MUL_JOB__LINK = bytes32("35e428271aad4506afc4f4089ce98f68"); // CRYPTOCOMPARE CHAINLINK ROPSTEN
    // bytes32 constant UINT256_MUL_JOB__LINK = bytes32("513907f96955437a8ac02a5d70e5bdea"); // CRYPTOCOMPARE CHAINLINK MAINNET

    constructor(Medianizer med_, ERC20 link_, address oracle_)
        public
        ChainLink(med_, link_, oracle_)
    {}

    function getAssetPrice(uint128 payment) internal returns (bytes32 queryId) {
        Chainlink.Request memory req = buildChainlinkRequest(UINT256_MUL_JOB, this, this.returnAssetPrice.selector);
        req.add("get", "https://chain.so/api/v2/get_info/BTC");
        req.add("path", "data.price");
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
        bytes32 linkrId = sendChainlinkRequest(req, div(payment, 2));
        linkrs[linkrId] = queryId;
        return linkrId;
    }
}
