pragma solidity 0.4.26;

import "./Oraclize.sol";

contract Kraken is Oraclize {
    constructor(MedianizerInterface med_, MedianizerInterface medm_, WETH weth_)
        public
        Oraclize(med_, medm_, weth_)
    {}

    function getAssetPrice(uint128 payment_)
        internal returns (bytes32 queryId)
    {
        weth.withdraw(payment_);
        require(oraclize_getPrice("URL", gasLimit) <= address(this).balance, "Kraken.getAssetPrice: Ether balance is less than oraclize price");
        queryId = oraclize_query("URL", "json(https://api.kraken.com/0/public/Ticker?pair=XBTUSD).result.XXBTZUSD.c.0", gasLimit);
    }
}
