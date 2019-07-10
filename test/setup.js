const { time, shouldFail, balance } = require('openzeppelin-test-helpers');

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
var SoChain = artifacts.require("./chainlink/SoChain.sol");
var Coinbase = artifacts.require("./oraclize/Coinbase.sol");
var WETH9 = artifacts.require("./WETH9.sol");
var Medianizer = artifacts.require("./Medianizer.sol");
var MakerMedianizer = artifacts.require("./DSValue.sol");

const utils = require('./helpers/Utils.js');

const { rateToSec, numToBytes32 } = utils;
const { toWei, fromWei, asciiToHex, hexToNumberString } = web3.utils;

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
    this.blockchainInfo = await BlockchainInfo.deployed()
    this.coinMarketCap = await CoinMarketCap.deployed()
    this.cryptoCompare = await CryptoCompare.deployed()
    this.gemini = await Gemini.deployed()
    this.soChain = await SoChain.deployed()
    this.coinbase = await Coinbase.deployed()
    this.med = await Medianizer.deployed()

    await this.token.transfer(updater, toWei('100', 'ether'))
    await this.link.transfer(updater, toWei('100', 'ether'))

    await this.token.approve(this.med.address, toWei('100', 'ether'))
  })

  describe('push', function() {
    it('should send funds to all oracle contracts', async function() {
      await this.med.push(toWei('100', 'ether'), this.token.address)
      const bal  = await this.token.balanceOf.call(this.blockchainInfo.address)

      assert.equal(bal.toString(), BigNumber(toWei('100', 'ether')).dividedBy(6).minus(1).toString())
    })
  })
})