var ExampleCoin = artifacts.require("./ExampleDaiCoin.sol");
var ExampleLink = artifacts.require("./ExampleLinkCoin.sol");
var BlockchainInfo = artifacts.require("./chainlink/BlockchainInfo.sol");
var CoinMarketCap = artifacts.require("./chainlink/CoinMarketCap.sol");
var CryptoCompare = artifacts.require("./chainlink/CryptoCompare.sol");
var Gemini = artifacts.require("./chainlink/Gemini.sol");
var SoChain = artifacts.require("./chainlink/SoChain.sol");
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
    await deployer.deploy(ExampleCoin);
    await deployer.deploy(ExampleLink);
    var link = await ExampleLink.deployed();
    const oracle = '0xc99B3D447826532722E41bc36e644ba3479E4365'
    await deployer.deploy(WETH9);
    var weth9 = await WETH9.deployed();
    await deployer.deploy(Medianizer);
    var medianizer = await Medianizer.deployed();
    await deployer.deploy(MakerMedianizer);
    var makerMedianizer = await MakerMedianizer.deployed();
    await makerMedianizer.poke('0x0000000000000000000000000000000000000000000000108ee6a12edb308000')
    await deployer.deploy(BlockchainInfo, medianizer.address, link.address, oracle);
    var blockchainInfo = await BlockchainInfo.deployed();
    await deployer.deploy(CoinMarketCap, medianizer.address, link.address, oracle);
    var coinMarketCap = await CoinMarketCap.deployed();
    await deployer.deploy(CryptoCompare, medianizer.address, link.address, oracle);
    var cryptoCompare = await CryptoCompare.deployed();
    await deployer.deploy(Gemini, medianizer.address, link.address, oracle);
    var gemini = await Gemini.deployed();
    await deployer.deploy(SoChain, medianizer.address, link.address, oracle);
    var soChain = await SoChain.deployed();
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
    await medianizer.setOracles([blockchainInfo.address, coinMarketCap.address, cryptoCompare.address, gemini.address, soChain.address, bitstamp.address, coinbase.address, cryptoWatch.address, coinpaprika.address, kraken.address]);
  })
};
