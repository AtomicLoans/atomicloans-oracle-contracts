pragma solidity ^0.4.26;

import "./Oraclize.sol";

contract Coinpaprika is Oraclize {
    constructor(MedianizerInterface med_, MedianizerInterface medm_, WETH weth_)
        public
        Oraclize(med_, medm_, weth_)
    {}

    function getAssetPrice(uint128 payment)
        internal returns (bytes32 queryId)
    {
        weth.withdraw(payment);
        require(oraclize_getPrice("URL") <= address(this).balance);
        queryId = oraclize_query("URL", "json(https://api.coinpaprika.com/v1/tickers/btc-bitcoin).quotes.USD.price");
    }
}
