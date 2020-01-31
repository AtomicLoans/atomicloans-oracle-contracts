const { time, expectRevert, balance } = require('openzeppelin-test-helpers');

const toSecs        = require('@mblackmblack/to-seconds');
const { sha256 }    = require('@liquality/crypto')
const { ensure0x, remove0x   }  = require('@liquality/ethereum-utils');
const { BigNumber } = require('bignumber.js');
const axios         = require('axios');

BigNumber.set({ DECIMAL_PLACES: 0, ROUNDING_MODE: 0 })

const ExampleCoin = artifacts.require("./ExampleDaiCoin.sol");
const ExampleLink = artifacts.require("./ExampleLinkCoin.sol");
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

const utils = require('./helpers/Utils.js');

const { rateToSec, numToBytes32 } = utils;
const { toWei, fromWei, asciiToHex, hexToNumberString, hexToNumber, padLeft, padRight, numberToHex } = web3.utils;

const API_ENDPOINT_COIN = "https://atomicloans.io/marketcap/api/v1/"
const BTC_TO_SAT = 10**8

async function fetchCoin(coinName) {
  const url = `${API_ENDPOINT_COIN}${coinName}/`;
  return (await axios.get(url)).data[0].price_usd; // this returns a promise - stored in 'request'
}

contract("Medianizer", accounts => {
  const own       = accounts[0]
  const chainlink = accounts[1]
  const oraclize  = accounts[2]
  const updater   = accounts[3]

  beforeEach(async function () {
    this.token = await ExampleCoin.deployed()
    this.link = await ExampleLink.deployed()
    this.weth = await WETH9.deployed()

    this.blockchainInfo = await BlockchainInfo.deployed()
    this.coinMarketCap = await CoinMarketCap.deployed()
    this.cryptoCompare = await CryptoCompare.deployed()
    this.gemini = await Gemini.deployed()
    this.bitBay = await BitBay.deployed()
    this.bitstamp = await Bitstamp.deployed()
    this.coinbase = await Coinbase.deployed()
    this.cryptoWatch = await CryptoWatch.deployed()
    this.coinpaprika = await Coinpaprika.deployed()
    this.kraken = await Kraken.deployed()

    this.med = await Medianizer.deployed()
    this.medm = await MakerMedianizer.deployed()

    this.chainlinkBill = await this.blockchainInfo.bill.call()
    this.oraclizeBill  = await this.bitstamp.bill.call()

    // Transfer tokens to updater
    await this.token.transfer(updater, toWei('100', 'ether'))
    await this.link.transfer(updater, toWei('100', 'ether'))
    await this.weth.deposit({ value: toWei('1', 'ether')})
    await this.weth.transfer(updater, toWei('1', 'ether'))

    await this.token.approve(this.med.address, toWei('100', 'ether'))

    await this.link.approve(this.blockchainInfo.address, toWei('100', 'ether'), { from: updater })
    await this.link.approve(this.coinMarketCap.address,  toWei('100', 'ether'), { from: updater })
    await this.link.approve(this.cryptoCompare.address,  toWei('100', 'ether'), { from: updater })
    await this.link.approve(this.gemini.address,         toWei('100', 'ether'), { from: updater })
    await this.link.approve(this.bitBay.address,        toWei('100', 'ether'), { from: updater })

    await this.weth.approve(this.bitstamp.address,       toWei('1', 'ether'), { from: updater })
    await this.weth.approve(this.coinbase.address,       toWei('1', 'ether'), { from: updater })
    await this.weth.approve(this.cryptoWatch.address,    toWei('1', 'ether'), { from: updater })
    await this.weth.approve(this.coinpaprika.address,    toWei('1', 'ether'), { from: updater })
    await this.weth.approve(this.kraken.address,         toWei('1', 'ether'), { from: updater })

    await this.med.fund(toWei('100', 'ether'), this.token.address)
  })

  describe('fund', function() {
    it('should send funds to all oracle contracts', async function() {
      const bal  = await this.token.balanceOf.call(this.blockchainInfo.address)

      assert.equal(bal.toString(), toWei('10', 'ether'))
    })

    it('should not return median for oracles if less than 5 are set', async function() {
      await time.increase(901)

      await this.blockchainInfo.update(this.chainlinkBill, this.token.address, { from: updater })
      await this.blockchainInfo.returnAssetPrice(asciiToHex("9f0406209cf64acda32636018b33de11"), toWei('12529.71', 'ether'), { from: chainlink })
      await this.blockchainInfo.returnPaymentTokenPrice(asciiToHex("35e428271aad4506afc4f4089ce98f68"), toWei('3.19', 'ether'), { from: chainlink })

      await this.coinMarketCap.update(this.chainlinkBill, this.token.address, { from: updater })
      await this.coinMarketCap.returnAssetPrice(asciiToHex("9f0406209cf64acda32636018b33de11"), toWei('12529.71', 'ether'), { from: chainlink })
      await this.coinMarketCap.returnPaymentTokenPrice(asciiToHex("35e428271aad4506afc4f4089ce98f68"), toWei('3.19', 'ether'), { from: chainlink })

      await this.kraken.update(this.oraclizeBill, this.token.address, { from: updater })
      await this.kraken.__callback(padRight('0x', 64), '12529.71')

      const peek = await this.med.peek.call()
      assert.equal(peek[1], false)
    })

    it('should return correct median of oracles when only 5 are set', async function() {
      await time.increase(901)

      await this.blockchainInfo.update(this.chainlinkBill, this.token.address, { from: updater })
      await this.blockchainInfo.returnAssetPrice(asciiToHex("9f0406209cf64acda32636018b33de11"), toWei('12529.71', 'ether'), { from: chainlink })
      await this.blockchainInfo.returnPaymentTokenPrice(asciiToHex("35e428271aad4506afc4f4089ce98f68"), toWei('3.19', 'ether'), { from: chainlink })

      await this.coinMarketCap.update(this.chainlinkBill, this.token.address, { from: updater })
      await this.coinMarketCap.returnAssetPrice(asciiToHex("9f0406209cf64acda32636018b33de11"), toWei('12529.71', 'ether'), { from: chainlink })
      await this.coinMarketCap.returnPaymentTokenPrice(asciiToHex("35e428271aad4506afc4f4089ce98f68"), toWei('3.19', 'ether'), { from: chainlink })

      await this.cryptoCompare.update(this.chainlinkBill, this.token.address, { from: updater })
      await this.cryptoCompare.returnAssetPrice(asciiToHex("9f0406209cf64acda32636018b33de11"), toWei('12529.71', 'ether'), { from: chainlink })
      await this.cryptoCompare.returnPaymentTokenPrice(asciiToHex("35e428271aad4506afc4f4089ce98f68"), toWei('3.19', 'ether'), { from: chainlink })

      await this.bitstamp.update(this.oraclizeBill, this.token.address, { from: updater })
      await this.bitstamp.__callback(padRight('0x', 64), '12529.71')

      await this.coinbase.update(this.oraclizeBill, this.token.address, { from: updater })
      await this.coinbase.__callback(padRight('0x', 64), '12529.71')

      const read = await this.med.read.call()

      assert.equal(read, padLeft(numberToHex(toWei('12529.71', 'ether')), 64))
    })

    it('should return correct median of all oracles when all oracles have same price', async function() {
      await time.increase(901)

      await this.blockchainInfo.update(this.chainlinkBill, this.token.address, { from: updater })
      await this.blockchainInfo.returnAssetPrice(asciiToHex("9f0406209cf64acda32636018b33de11"), toWei('12529.71', 'ether'), { from: chainlink })
      await this.blockchainInfo.returnPaymentTokenPrice(asciiToHex("35e428271aad4506afc4f4089ce98f68"), toWei('3.19', 'ether'), { from: chainlink })

      await this.coinMarketCap.update(this.chainlinkBill, this.token.address, { from: updater })
      await this.coinMarketCap.returnAssetPrice(asciiToHex("9f0406209cf64acda32636018b33de11"), toWei('12529.71', 'ether'), { from: chainlink })
      await this.coinMarketCap.returnPaymentTokenPrice(asciiToHex("35e428271aad4506afc4f4089ce98f68"), toWei('3.19', 'ether'), { from: chainlink })

      await this.cryptoCompare.update(this.chainlinkBill, this.token.address, { from: updater })
      await this.cryptoCompare.returnAssetPrice(asciiToHex("9f0406209cf64acda32636018b33de11"), toWei('12529.71', 'ether'), { from: chainlink })
      await this.cryptoCompare.returnPaymentTokenPrice(asciiToHex("35e428271aad4506afc4f4089ce98f68"), toWei('3.19', 'ether'), { from: chainlink })

      await this.gemini.update(this.chainlinkBill, this.token.address, { from: updater })
      await this.gemini.returnAssetPrice(asciiToHex("9f0406209cf64acda32636018b33de11"), toWei('12529.71', 'ether'), { from: chainlink })
      await this.gemini.returnPaymentTokenPrice(asciiToHex("35e428271aad4506afc4f4089ce98f68"), toWei('3.19', 'ether'), { from: chainlink })

      await this.bitBay.update(this.chainlinkBill, this.token.address, { from: updater })
      await this.bitBay.returnAssetPrice(asciiToHex("9f0406209cf64acda32636018b33de11"), toWei('12529.71', 'ether'), { from: chainlink })
      await this.bitBay.returnPaymentTokenPrice(asciiToHex("35e428271aad4506afc4f4089ce98f68"), toWei('3.19', 'ether'), { from: chainlink })

      await this.bitstamp.update(this.oraclizeBill, this.token.address, { from: updater })
      await this.bitstamp.__callback(padRight('0x', 64), '12529.71')

      await this.coinbase.update(this.oraclizeBill, this.token.address, { from: updater })
      await this.coinbase.__callback(padRight('0x', 64), '12529.71')

      await this.cryptoWatch.update(this.oraclizeBill, this.token.address, { from: updater })
      await this.cryptoWatch.__callback(padRight('0x', 64), '12529.71')

      await this.coinpaprika.update(this.oraclizeBill, this.token.address, { from: updater })
      await this.coinpaprika.__callback(padRight('0x', 64), '12529.71')

      await this.kraken.update(this.oraclizeBill, this.token.address, { from: updater })
      await this.kraken.__callback(padRight('0x', 64), '12529.71')

      const read = await this.med.read.call()

      assert.equal(read, padLeft(numberToHex(toWei('12529.71', 'ether')), 64))
    })

    it('should return correct median of all oracles when different prices', async function() {
      await time.increase(901)

      await this.blockchainInfo.update(this.chainlinkBill, this.token.address, { from: updater })
      await this.blockchainInfo.returnAssetPrice(asciiToHex("9f0406209cf64acda32636018b33de11"), toWei('12000', 'ether'), { from: chainlink })
      await this.blockchainInfo.returnPaymentTokenPrice(asciiToHex("35e428271aad4506afc4f4089ce98f68"), toWei('3.19', 'ether'), { from: chainlink })

      await this.coinMarketCap.update(this.chainlinkBill, this.token.address, { from: updater })
      await this.coinMarketCap.returnAssetPrice(asciiToHex("9f0406209cf64acda32636018b33de11"), toWei('13000', 'ether'), { from: chainlink })
      await this.coinMarketCap.returnPaymentTokenPrice(asciiToHex("35e428271aad4506afc4f4089ce98f68"), toWei('3.19', 'ether'), { from: chainlink })

      await this.cryptoCompare.update(this.chainlinkBill, this.token.address, { from: updater })
      await this.cryptoCompare.returnAssetPrice(asciiToHex("9f0406209cf64acda32636018b33de11"), toWei('14000', 'ether'), { from: chainlink })
      await this.cryptoCompare.returnPaymentTokenPrice(asciiToHex("35e428271aad4506afc4f4089ce98f68"), toWei('3.19', 'ether'), { from: chainlink })

      await this.gemini.update(this.chainlinkBill, this.token.address, { from: updater })
      await this.gemini.returnAssetPrice(asciiToHex("9f0406209cf64acda32636018b33de11"), toWei('15000', 'ether'), { from: chainlink })
      await this.gemini.returnPaymentTokenPrice(asciiToHex("35e428271aad4506afc4f4089ce98f68"), toWei('3.19', 'ether'), { from: chainlink })

      await this.bitBay.update(this.chainlinkBill, this.token.address, { from: updater })
      await this.bitBay.returnAssetPrice(asciiToHex("9f0406209cf64acda32636018b33de11"), toWei('16000', 'ether'), { from: chainlink })
      await this.bitBay.returnPaymentTokenPrice(asciiToHex("35e428271aad4506afc4f4089ce98f68"), toWei('3.19', 'ether'), { from: chainlink })

      await this.bitstamp.update(this.oraclizeBill, this.token.address, { from: updater })
      await this.bitstamp.__callback(padRight('0x', 64), '17000')

      await this.coinbase.update(this.oraclizeBill, this.token.address, { from: updater })
      await this.coinbase.__callback(padRight('0x', 64), '18000')

      await this.cryptoWatch.update(this.oraclizeBill, this.token.address, { from: updater })
      await this.cryptoWatch.__callback(padRight('0x', 64), '19000')

      await this.coinpaprika.update(this.oraclizeBill, this.token.address, { from: updater })
      await this.coinpaprika.__callback(padRight('0x', 64), '20000')

      await this.kraken.update(this.oraclizeBill, this.token.address, { from: updater })
      await this.kraken.__callback(padRight('0x', 64), '21000')

      const read = await this.med.read.call()

      assert.equal(read, padLeft(numberToHex(toWei('16500', 'ether')), 64))
    })

    it('should not return median for oracles if 12 hours has passed since last update', async function() {
      await time.increase(901)

      await this.blockchainInfo.update(this.chainlinkBill, this.token.address, { from: updater })
      await this.blockchainInfo.returnAssetPrice(asciiToHex("9f0406209cf64acda32636018b33de11"), toWei('12529.71', 'ether'), { from: chainlink })
      await this.blockchainInfo.returnPaymentTokenPrice(asciiToHex("35e428271aad4506afc4f4089ce98f68"), toWei('3.19', 'ether'), { from: chainlink })

      await this.coinMarketCap.update(this.chainlinkBill, this.token.address, { from: updater })
      await this.coinMarketCap.returnAssetPrice(asciiToHex("9f0406209cf64acda32636018b33de11"), toWei('12529.71', 'ether'), { from: chainlink })
      await this.coinMarketCap.returnPaymentTokenPrice(asciiToHex("35e428271aad4506afc4f4089ce98f68"), toWei('3.19', 'ether'), { from: chainlink })

      await this.cryptoCompare.update(this.chainlinkBill, this.token.address, { from: updater })
      await this.cryptoCompare.returnAssetPrice(asciiToHex("9f0406209cf64acda32636018b33de11"), toWei('12529.71', 'ether'), { from: chainlink })
      await this.cryptoCompare.returnPaymentTokenPrice(asciiToHex("35e428271aad4506afc4f4089ce98f68"), toWei('3.19', 'ether'), { from: chainlink })

      await this.gemini.update(this.chainlinkBill, this.token.address, { from: updater })
      await this.gemini.returnAssetPrice(asciiToHex("9f0406209cf64acda32636018b33de11"), toWei('12529.71', 'ether'), { from: chainlink })
      await this.gemini.returnPaymentTokenPrice(asciiToHex("35e428271aad4506afc4f4089ce98f68"), toWei('3.19', 'ether'), { from: chainlink })

      await this.bitBay.update(this.chainlinkBill, this.token.address, { from: updater })
      await this.bitBay.returnAssetPrice(asciiToHex("9f0406209cf64acda32636018b33de11"), toWei('12529.71', 'ether'), { from: chainlink })
      await this.bitBay.returnPaymentTokenPrice(asciiToHex("35e428271aad4506afc4f4089ce98f68"), toWei('3.19', 'ether'), { from: chainlink })

      await this.bitstamp.update(this.oraclizeBill, this.token.address, { from: updater })
      await this.bitstamp.__callback(padRight('0x', 64), '12529.71')

      await this.coinbase.update(this.oraclizeBill, this.token.address, { from: updater })
      await this.coinbase.__callback(padRight('0x', 64), '12529.71')

      await this.cryptoWatch.update(this.oraclizeBill, this.token.address, { from: updater })
      await this.cryptoWatch.__callback(padRight('0x', 64), '12529.71')

      await this.coinpaprika.update(this.oraclizeBill, this.token.address, { from: updater })
      await this.coinpaprika.__callback(padRight('0x', 64), '12529.71')

      await this.kraken.update(this.oraclizeBill, this.token.address, { from: updater })
      await this.kraken.__callback(padRight('0x', 64), '12529.71')

      await time.increase(43300)

      await this.med.poke()

      const peek = await this.med.peek.call()
      assert.equal(peek[1], false)
    })

    it('should fail if amount is greater than 2**128-1', async function() {
      await expectRevert(this.med.fund(BigNumber(2).pow(128).toFixed(), this.token.address), 'VM Exception while processing transaction: revert')
    })
  })

  describe('compute', function() {
    it('should return median price of 0 if all oracle values are equal or above 2^128', async function() {
      await time.increase(901)

      await this.blockchainInfo.update(this.chainlinkBill, this.token.address, { from: updater })
      await this.blockchainInfo.returnAssetPrice(asciiToHex("9f0406209cf64acda32636018b33de11"), BigNumber(2).pow(128).toFixed(), { from: chainlink })
      await this.blockchainInfo.returnPaymentTokenPrice(asciiToHex("35e428271aad4506afc4f4089ce98f68"), toWei('3.19', 'ether'), { from: chainlink })

      await this.coinMarketCap.update(this.chainlinkBill, this.token.address, { from: updater })
      await this.coinMarketCap.returnAssetPrice(asciiToHex("9f0406209cf64acda32636018b33de11"), BigNumber(2).pow(128).toFixed(), { from: chainlink })
      await this.coinMarketCap.returnPaymentTokenPrice(asciiToHex("35e428271aad4506afc4f4089ce98f68"), toWei('3.19', 'ether'), { from: chainlink })

      await this.cryptoCompare.update(this.chainlinkBill, this.token.address, { from: updater })
      await this.cryptoCompare.returnAssetPrice(asciiToHex("9f0406209cf64acda32636018b33de11"), BigNumber(2).pow(128).toFixed(), { from: chainlink })
      await this.cryptoCompare.returnPaymentTokenPrice(asciiToHex("35e428271aad4506afc4f4089ce98f68"), toWei('3.19', 'ether'), { from: chainlink })

      await this.gemini.update(this.chainlinkBill, this.token.address, { from: updater })
      await this.gemini.returnAssetPrice(asciiToHex("9f0406209cf64acda32636018b33de11"), BigNumber(2).pow(128).toFixed(), { from: chainlink })
      await this.gemini.returnPaymentTokenPrice(asciiToHex("35e428271aad4506afc4f4089ce98f68"), toWei('3.19', 'ether'), { from: chainlink })

      await this.bitBay.update(this.chainlinkBill, this.token.address, { from: updater })
      await this.bitBay.returnAssetPrice(asciiToHex("9f0406209cf64acda32636018b33de11"), BigNumber(2).pow(128).toFixed(), { from: chainlink })
      await this.bitBay.returnPaymentTokenPrice(asciiToHex("35e428271aad4506afc4f4089ce98f68"), toWei('3.19', 'ether'), { from: chainlink })

      const read = await this.med.read.call()

      assert.equal(read, padLeft(numberToHex(0), 64))
    })

    it('should return median price of 2^128-1 if all oracle values are equal to 2^128-1', async function() {
      await time.increase(901)

      await this.blockchainInfo.update(this.chainlinkBill, this.token.address, { from: updater })
      await this.blockchainInfo.returnAssetPrice(asciiToHex("9f0406209cf64acda32636018b33de11"), BigNumber(2).pow(128).minus(1).toFixed(), { from: chainlink })
      await this.blockchainInfo.returnPaymentTokenPrice(asciiToHex("35e428271aad4506afc4f4089ce98f68"), toWei('3.19', 'ether'), { from: chainlink })

      await this.coinMarketCap.update(this.chainlinkBill, this.token.address, { from: updater })
      await this.coinMarketCap.returnAssetPrice(asciiToHex("9f0406209cf64acda32636018b33de11"), BigNumber(2).pow(128).minus(1).toFixed(), { from: chainlink })
      await this.coinMarketCap.returnPaymentTokenPrice(asciiToHex("35e428271aad4506afc4f4089ce98f68"), toWei('3.19', 'ether'), { from: chainlink })

      await this.cryptoCompare.update(this.chainlinkBill, this.token.address, { from: updater })
      await this.cryptoCompare.returnAssetPrice(asciiToHex("9f0406209cf64acda32636018b33de11"), BigNumber(2).pow(128).minus(1).toFixed(), { from: chainlink })
      await this.cryptoCompare.returnPaymentTokenPrice(asciiToHex("35e428271aad4506afc4f4089ce98f68"), toWei('3.19', 'ether'), { from: chainlink })

      await this.gemini.update(this.chainlinkBill, this.token.address, { from: updater })
      await this.gemini.returnAssetPrice(asciiToHex("9f0406209cf64acda32636018b33de11"), BigNumber(2).pow(128).minus(1).toFixed(), { from: chainlink })
      await this.gemini.returnPaymentTokenPrice(asciiToHex("35e428271aad4506afc4f4089ce98f68"), toWei('3.19', 'ether'), { from: chainlink })

      await this.bitBay.update(this.chainlinkBill, this.token.address, { from: updater })
      await this.bitBay.returnAssetPrice(asciiToHex("9f0406209cf64acda32636018b33de11"), BigNumber(2).pow(128).minus(1).toFixed(), { from: chainlink })
      await this.bitBay.returnPaymentTokenPrice(asciiToHex("35e428271aad4506afc4f4089ce98f68"), toWei('3.19', 'ether'), { from: chainlink })

      const read = await this.med.read.call()

      assert.equal(read, padLeft(numberToHex(BigNumber(2).pow(128).minus(1).toFixed()), 64))
    })
  })
})
