pragma solidity ^0.4.26;

import "./Oraclize.sol";

contract Bitstamp is Oraclize {
    constructor(Medianizer med_, Medianizer medm_, WETH weth_)
        public
        Oraclize(med_, medm_, weth_)
    {}

    function call(uint128 pmt)
        internal returns (bytes32 queryId)
    {
        weth.withdraw(pmt);
        require(oraclize_getPrice("URL") <= address(this).balance);
        queryId = oraclize_query("URL", "json(https://www.bitstamp.net/api/v2/ticker/btcusd).last");
    }
}
