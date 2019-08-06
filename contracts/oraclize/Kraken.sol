pragma solidity ^0.4.26;

import "./Oraclize.sol";

contract Kraken is Oraclize {
    constructor(Medianizer med_, Medianizer medm_, WETH weth_)
        public
        Oraclize(med_, medm_, weth_)
    {}

    function call(uint128 payment)
        internal returns (bytes32 queryId)
    {
        weth.withdraw(payment);
        require(oraclize_getPrice("URL") <= address(this).balance);
        queryId = oraclize_query("URL", "json(https://api.kraken.com/0/public/Ticker?pair=XBTUSD).result.XXBTZUSD.c.0");
    }
}
