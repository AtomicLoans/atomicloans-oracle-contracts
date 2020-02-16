pragma solidity 0.4.26;

import "./ChainLink.sol";

/**
 * @title Atomic Loans CryptoCompare Chainlink Contract
 * @author Atomic Loans
 */
contract CryptoCompare is ChainLink {
    /**
     * CRYPTOCOMPARE CHAINLINK MAINNET
     * https://docs.chain.link/docs/cryptocompare-chainlink-ethereum-mainnet
     * Chainlink JobID
     */
    bytes32 constant UINT256_MUL_JOB = bytes32("513907f96955437a8ac02a5d70e5bdea");

    /**
     * CRYPTOCOMPARE CHAINLINK KOVAN
     * https://docs.chain.link/docs/cryptocompare
     * Kovan JobID
     */
    // bytes32 constant UINT256_MUL_JOB = bytes32("7f350c947b0d4d758aadd5acb41d2474");

    /**
     * @notice Construct a new CryptoCompare Chainlink Oracle
     * @param med_ The address of the Medianizer
     * @param link_ The LINK token address
     * @param oracle_ The Chainlink Oracle address
     */
    constructor(MedianizerInterface med_, ERC20 link_, address oracle_) public ChainLink(med_, link_, oracle_) {}

    /**
     * @notice Creates request for Chainlink to get the BTC price
     * @param payment_ The amount of LINK used as payment for Oraclize
     */
    function getAssetPrice(uint128 payment_) internal returns (bytes32 queryId) {
        Chainlink.Request memory req = buildChainlinkRequest(UINT256_MUL_JOB, this, this.returnAssetPrice.selector);
        req.add("endpoint", "price");
        req.add("fsym", "BTC");
        req.add("tsyms", "USD");
        req.add("copyPath", "USD");
        req.addInt("times", WAD); // Convert string from API to WAD
        queryId = sendChainlinkRequest(req, div(payment_, 2)); // Divide by 2 so that payment covers both asset price and token price
    }

    /**
     * @notice Creates request for Chainlink to get the LINK price
     * @param payment_ The amount of LINK used as payment for Chainlink
     * @param queryId ID of the query from Chainlink
     */
    function getPaymentTokenPrice(uint128 payment_, bytes32 queryId) internal returns (bytes32) {
        Chainlink.Request memory req = buildChainlinkRequest(UINT256_MUL_JOB, this, this.returnPaymentTokenPrice.selector);
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
