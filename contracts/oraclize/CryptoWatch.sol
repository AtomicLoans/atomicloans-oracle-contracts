pragma solidity 0.4.26;

import "./Oraclize.sol";

contract CryptoWatch is Oraclize {
    constructor(MedianizerInterface med_, MedianizerInterface medm_, WETH weth_)
        public
        Oraclize(med_, medm_, weth_)
    {}

    function getAssetPrice(uint128 payment_)
        internal returns (bytes32 queryId)
    {
        weth.withdraw(payment_);
        require(oraclize_getPrice("URL") <= address(this).balance, "CryptoWatch.getAssetPrice: Ether balance is less than oraclize price");
        queryId = oraclize_query("URL", "json(https://api.cryptowat.ch/markets/coinbase-pro/btcusd/price).result.price");
    }
}
