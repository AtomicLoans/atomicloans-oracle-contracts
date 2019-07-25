const { time, shouldFail, balance } = require('openzeppelin-test-helpers');

const toSecs        = require('@mblackmblack/to-seconds');
const { sha256 }    = require('@liquality/crypto')
const { ensure0x, remove0x   }  = require('@liquality/ethereum-utils');
const { BigNumber } = require('bignumber.js');
const axios         = require('axios');

const ExampleCoin = artifacts.require("./ExampleDaiCoin.sol");
const ExampleLink = artifacts.require("./ExampleLinkCoin.sol");
var BlockchainInfo = artifacts.require("./chainlink/BlockchainInfo.sol");
var CoinMarketCap = artifacts.require("./chainlink/CoinMarketCap.sol");
var CryptoCompare = artifacts.require("./chainlink/CryptoCompare.sol");
var Gemini = artifacts.require("./chainlink/Gemini.sol");
var SoChain = artifacts.require("./chainlink/SoChain.sol");
var Coinbase = artifacts.require("./oraclize/Coinbase.sol");
var WETH9 = artifacts.require("./WETH9.sol");
var Medianizer = artifacts.require("./Medianizer.sol");
var MakerMedianizer = artifacts.require("./DSValue.sol");

const utils = require('./helpers/Utils.js');

const { rateToSec, numToBytes32 } = utils;
const { toWei, fromWei, asciiToHex, hexToNumberString, numberToHex, padLeft, padRight } = web3.utils;

const API_ENDPOINT_COIN = "https://atomicloans.io/marketcap/api/v1/"
const BTC_TO_SAT = 10**8

async function fetchCoin(coinName) {
  const url = `${API_ENDPOINT_COIN}${coinName}/`;
  return (await axios.get(url)).data[0].price_usd; // this returns a promise - stored in 'request'
}

contract("Oraclize", accounts => {
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
    this.soChain = await SoChain.deployed()
    this.coinbase = await Coinbase.deployed()
    this.med = await Medianizer.deployed()
    this.medm = await MakerMedianizer.deployed()

    await this.medm.poke(padLeft(numberToHex(toWei('303.79', 'ether')), 64))

    this.bill = await this.coinbase.bill.call()

    await this.token.transfer(updater, toWei('100', 'ether'))

    await this.weth.deposit({ value: toWei('1', 'ether')})
    await this.weth.transfer(updater, toWei('1', 'ether'))

    await this.token.approve(this.med.address, toWei('100', 'ether'))

    await this.med.push(toWei('100', 'ether'), this.token.address)

    await this.weth.approve(this.coinbase.address, toWei('1', 'ether'), { from: updater })
  })

  describe('pack', function() {
    it('should fail if trying to pack twice before 15 minutes is up', async function() {
      assert.equal(true, true)

      await this.coinbase.pack(this.bill, this.token.address, { from: updater })

      await this.coinbase.__callback(asciiToHex("1"), "12529.71")

      await shouldFail.reverting(this.coinbase.pack(this.bill, this.token.address), { from: updater })
    })

    it('should succeed in updating price of called once', async function() {
      await time.increase(901)

      await this.coinbase.pack(this.bill, this.token.address, { from: updater })

      await this.coinbase.__callback(asciiToHex("1"), '12656.71')

      const read = await this.coinbase.read.call()
      assert.equal(toWei('12656.71', 'ether'), hexToNumberString(read))

      const lval = await this.coinbase.lval.call()
      assert.equal(toWei('303.79', 'ether'), lval)

      const peek = await this.coinbase.peek.call()
      assert.equal(toWei('12656.71', 'ether'), hexToNumberString(peek[0]))
      assert.equal(peek[1], true)
    })

    it('should reward correctly', async function() {
      await time.increase(901)

      await this.coinbase.pack(this.bill, this.token.address, { from: updater })

      const balBefore = await this.token.balanceOf.call(updater)

      await this.coinbase.__callback(padRight('0x', 64), '12784.2771')

      const balAfter = await this.token.balanceOf.call(updater)

      assert.equal(balAfter - balBefore, BigNumber(this.bill.toString()).times(303.79).times(1.1).plus(7808).toString())
    })

    it('should not reward if price has not changed by 1%', async function() {
      await time.increase(901)

      await this.coinbase.pack(this.bill, this.token.address, { from: updater })

      const balBefore = await this.token.balanceOf.call(updater)

      await this.coinbase.__callback(padRight('0x', 64), '12913.4128')

      const balAfter = await this.token.balanceOf.call(updater)

      assert.equal(balAfter - balBefore, BigNumber(this.bill.toString()).times(303.79).times(1.1).plus(7808).toString())

      await time.increase(901)

      await this.coinbase.pack(this.bill, this.token.address, { from: updater })

      const balBefore2 = await this.token.balanceOf.call(updater)

      await this.coinbase.__callback(padRight('0x', 64), '12913.4128')

      const balAfter2 = await this.token.balanceOf.call(updater)

      assert.equal(balAfter2 - balBefore2, 0)
    })
  })
})