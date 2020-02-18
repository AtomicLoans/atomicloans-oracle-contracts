pragma solidity 0.4.26;

import "./Oraclize.sol";

/**
 * @title Atomic Loans Kraken Oraclize Contract
 * @author Atomic Loans
 */
contract Kraken is Oraclize {
    /**
     * @notice Construct a new Kraken Oraclize Oracle
     * @param med_ The address of the Medianizer
     * @param medm_ The address of the MakerDAO Medianizer
     * @param weth_ The WETH token address
     */
    constructor(MedianizerInterface med_, MedianizerInterface medm_, WETH weth_) public Oraclize(med_, medm_, weth_) {}

    /**
     * @notice Creates request for Oraclize to get the BTC price
     * @param payment_ The amount of WETH used as payment for Oraclize
     */
    function getAssetPrice(uint128 payment_) internal returns (bytes32 queryId) {
        weth.withdraw(payment_);
        require(oraclize_getPrice("URL", gasLimit) <= address(this).balance, "Kraken.getAssetPrice: Ether balance is less than oraclize price");
        queryId = oraclize_query("URL", "json(https://api.kraken.com/0/public/Ticker?pair=XBTUSD).result.XXBTZUSD.c.0", gasLimit);
    }
}
