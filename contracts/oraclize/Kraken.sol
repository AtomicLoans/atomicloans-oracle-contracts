pragma solidity >0.4.18;

import "./Oraclize.sol";

contract Kraken is Oraclize {
    constructor(DSValue med_, DSValue medm_, WETH weth_)
        public
        Oraclize(med_, medm_, weth_)
    {}

    function call()
        internal
    {
        weth.withdraw(pmt);
        require(oraclize_getPrice("URL") <= address(this).balance);
        oraclize_query("URL", "json(https://api.kraken.com/0/public/Ticker?pair=XBTUSD).result.XXBTZUSD.b[0]");
    }
}