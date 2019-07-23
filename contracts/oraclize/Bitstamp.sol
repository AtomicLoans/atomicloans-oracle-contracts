pragma solidity ^0.4.26;

import "./Oraclize.sol";

contract Bitstamp is Oraclize {
    constructor(DSValue med_, DSValue medm_, WETH weth_)
        public
        Oraclize(med_, medm_, weth_)
    {}

    function call()
        internal
    {
        weth.withdraw(pmt);
        require(oraclize_getPrice("URL") <= address(this).balance);
        oraclize_query("URL", "json(https://www.bitstamp.net/api/v2/ticker/btcusd).last");
    }
}