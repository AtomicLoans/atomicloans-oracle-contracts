pragma solidity ^0.4.26;

import "./ChainLink.sol";

contract SoChain is ChainLink {
    bytes32 constant UINT256_MUL_JOB = bytes32("9f0406209cf64acda32636018b33de11");
    bytes32 constant UINT256_MUL_JOB__LINK = bytes32("35e428271aad4506afc4f4089ce98f68");

    constructor(Medianizer med_, ERC20 link_, address oracle_)
        public
        ChainLink(med_, link_, oracle_)
    {}

    function call(uint128 pmt) internal returns (bytes32 queryId) {
        Chainlink.Request memory req = buildChainlinkRequest(UINT256_MUL_JOB, this, this.cur.selector);
        req.add("get", "https://chain.so/api/v2/get_info/BTC");
        req.add("path", "data.price");
        req.addInt("times", 1000000000000000000);
        queryId = sendChainlinkRequest(req, div(pmt, 2));
    }

    function chec(uint128 pmt, bytes32 queryId) internal returns (bytes32) {
        Chainlink.Request memory req = buildChainlinkRequest(UINT256_MUL_JOB__LINK, this, this.sup.selector);
        req.add("endpoint", "price");
        req.add("fsym", "LINK");
        req.add("tsyms", "USD");
        req.add("copyPath", "USD");
        req.addInt("times", 1000000000000000000);
        bytes32 linkrId = sendChainlinkRequest(req, div(pmt, 2));
        linkrs[linkrId] = queryId;
        return linkrId;
    }
}
