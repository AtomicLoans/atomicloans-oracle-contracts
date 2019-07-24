pragma solidity >0.4.18;

import "./Oraclize.sol";

contract CryptoWatch is Oraclize {
    constructor(Medianizer med_, Medianizer medm_, WETH weth_)
        public
        Oraclize(med_, medm_, weth_)
    {}

    function call()
        internal
    {
        weth.withdraw(pmt);
        require(oraclize_getPrice("URL") <= address(this).balance);
        oraclize_query("URL", "json(https://api.cryptowat.ch/markets/coinbase-pro/btcusd/price).result.price");
    }
}