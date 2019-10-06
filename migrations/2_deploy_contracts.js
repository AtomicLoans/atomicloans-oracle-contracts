var ExampleCoin = artifacts.require("./ExampleDaiCoin.sol");
var ExampleLink = artifacts.require("./ExampleLinkCoin.sol");
var BlockchainInfo = artifacts.require("./chainlink/BlockchainInfo.sol");
var CoinMarketCap = artifacts.require("./chainlink/CoinMarketCap.sol");
var CryptoCompare = artifacts.require("./chainlink/CryptoCompare.sol");
var Gemini = artifacts.require("./chainlink/Gemini.sol");
var BitBay = artifacts.require("./chainlink/BitBay.sol");
var Bitstamp = artifacts.require("./oraclize/Bitstamp.sol");
var Coinbase = artifacts.require("./oraclize/Coinbase.sol");
var CryptoWatch = artifacts.require("./oraclize/CryptoWatch.sol");
var Coinpaprika = artifacts.require("./oraclize/Coinpaprika.sol");
var Kraken = artifacts.require("./oraclize/Kraken.sol");
var WETH9 = artifacts.require("./WETH9.sol");
var Medianizer = artifacts.require("./Medianizer.sol");
var MakerMedianizer = artifacts.require("./DSValue.sol");

module.exports = function(deployer) {
  deployer.then(async () => {
    // await deployer.deploy(ExampleCoin); // LOCAL
    // await deployer.deploy(ExampleLink); // LOCAL
    // var link = await ExampleLink.deployed(); // LOCAL
    // const link = { address: '0xa36085f69e2889c224210f603d836748e7dc0088' } // KOVAN
    const link = { address: '0x514910771af9ca656af840dff83e8264ecf986ca' } // MAINNET
    // const oracle = '0xc99B3D447826532722E41bc36e644ba3479E4365' // ROPSTEN
    // const oracle = '0x2f90A6D021db21e1B2A077c5a37B3C7E75D15b7e' // KOVAN
    const oracle = '0x89f70fA9F439dbd0A1BC22a09BEFc56adA04d9b4' // MAINNET
    // await deployer.deploy(WETH9); // LOCAL & KOVAN
    // var weth9 = await WETH9.deployed(); // LOCAL & KOVAN
    const weth9 = { address: '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2' } // MAINNET
    await deployer.deploy(Medianizer);
    var medianizer = await Medianizer.deployed();
    // await deployer.deploy(MakerMedianizer); // LOCAL
    // var makerMedianizer = await MakerMedianizer.deployed(); // LOCAL
    // await makerMedianizer.poke('0x0000000000000000000000000000000000000000000000108ee6a12edb308000') // LOCAL
    // const makerMedianizer = { address: '0xA944bd4b25C9F186A846fd5668941AA3d3B8425F' } // KOVAN
    const makerMedianizer = { address: '0x729D19f657BD0614b4985Cf1D82531c67569197B' } // MAINNET
    await deployer.deploy(BlockchainInfo, medianizer.address, link.address, oracle);
    var blockchainInfo = await BlockchainInfo.deployed();
    await deployer.deploy(CoinMarketCap, medianizer.address, link.address, oracle);
    var coinMarketCap = await CoinMarketCap.deployed();
    await deployer.deploy(CryptoCompare, medianizer.address, link.address, oracle);
    var cryptoCompare = await CryptoCompare.deployed();
    await deployer.deploy(Gemini, medianizer.address, link.address, oracle);
    var gemini = await Gemini.deployed();
    await deployer.deploy(BitBay, medianizer.address, link.address, oracle);
    var bitBay = await BitBay.deployed();
    await deployer.deploy(Bitstamp, medianizer.address, makerMedianizer.address, weth9.address);
    var bitstamp = await Bitstamp.deployed();
    await deployer.deploy(Coinbase, medianizer.address, makerMedianizer.address, weth9.address);
    var coinbase = await Coinbase.deployed();
    await deployer.deploy(CryptoWatch, medianizer.address, makerMedianizer.address, weth9.address);
    var cryptoWatch = await CryptoWatch.deployed();
    await deployer.deploy(Coinpaprika, medianizer.address, makerMedianizer.address, weth9.address);
    var coinpaprika = await Coinpaprika.deployed();
    await deployer.deploy(Kraken, medianizer.address, makerMedianizer.address, weth9.address);
    var kraken = await Kraken.deployed();
    await medianizer.setOracles([blockchainInfo.address, coinMarketCap.address, cryptoCompare.address, gemini.address, bitBay.address, bitstamp.address, coinbase.address, cryptoWatch.address, coinpaprika.address, kraken.address]);
  })
};
