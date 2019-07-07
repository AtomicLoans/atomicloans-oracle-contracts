pragma solidity >0.4.18;

import "./OraclizeOracle.sol";

contract CoinbaseOraclizeOracle is OraclizeOracle {
    function call()
        internal
    {
        weth.withdraw(pmt);
        require(oraclize_getPrice("URL") <= address(this).balance);
        oraclize_query("URL", "json(https://api.pro.coinbase.com/products/BTC-USD/ticker).price");
    }
}