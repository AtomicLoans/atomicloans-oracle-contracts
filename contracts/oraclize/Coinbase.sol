pragma solidity ^0.4.26;

import "./Oraclize.sol";

contract Coinbase is Oraclize {
    constructor(Medianizer med_, Medianizer medm_, WETH weth_)
        public
        Oraclize(med_, medm_, weth_)
    {}

    function call()
        internal
    {
        weth.withdraw(pmt);
        require(oraclize_getPrice("URL") <= address(this).balance);
        oraclize_query("URL", "json(https://api.pro.coinbase.com/products/BTC-USD/ticker).price");
    }
}