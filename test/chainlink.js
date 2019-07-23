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
const { toWei, fromWei, asciiToHex, hexToNumberString } = web3.utils;

const API_ENDPOINT_COIN = "https://atomicloans.io/marketcap/api/v1/"
const BTC_TO_SAT = 10**8

async function fetchCoin(coinName) {
  const url = `${API_ENDPOINT_COIN}${coinName}/`;
  return (await axios.get(url)).data[0].price_usd; // this returns a promise - stored in 'request'
}

contract("Chainlink", accounts => {
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

    this.bill = await this.blockchainInfo.bill.call()

    await this.token.transfer(updater, toWei('100', 'ether'))
    await this.link.transfer(updater, toWei('100', 'ether'))

    await this.token.approve(this.med.address, toWei('100', 'ether'))

    await this.med.push(toWei('100', 'ether'), this.token.address)

    await this.link.approve(this.blockchainInfo.address, toWei('100', 'ether'), { from: updater })
  })

  describe('pack', function() {
    it('should fail if trying to pack twice before 15 minutes is up', async function() {
      await this.blockchainInfo.pack(this.bill, this.token.address, { from: updater })

      await this.blockchainInfo.cur(asciiToHex("9f0406209cf64acda32636018b33de11"), toWei('12529.71', 'ether'), { from: chainlink })

      await this.blockchainInfo.sup(asciiToHex("35e428271aad4506afc4f4089ce98f68"), toWei('3.19', 'ether'), { from: chainlink })

      await shouldFail.reverting(this.blockchainInfo.pack(this.bill, this.token.address), { from: updater })
    })

    it('should succeed in updating price of called once', async function() {
      await time.increase(901)

      await this.blockchainInfo.pack(this.bill, this.token.address, { from: updater })

      await this.blockchainInfo.cur(asciiToHex("9f0406209cf64acda32636018b33de11"), toWei('12656.71', 'ether'), { from: chainlink })

      await this.blockchainInfo.sup(asciiToHex("35e428271aad4506afc4f4089ce98f68"), toWei('3.19', 'ether'), { from: chainlink })

      const read = await this.blockchainInfo.read.call()
      assert.equal(toWei('12656.71', 'ether'), hexToNumberString(read))

      const lval = await this.blockchainInfo.lval.call()
      assert.equal(toWei('3.19', 'ether'), lval)

      const peek = await this.blockchainInfo.peek.call()
      assert.equal(toWei('12656.71', 'ether'), hexToNumberString(peek[0]))
      assert.equal(peek[1], true)
    })

    it('should reward correct based on max', async function() {
      await time.increase(901)

      await this.med.setMax(toWei('10', 'ether'), { from: own })

      await this.blockchainInfo.pack(this.bill, this.token.address, { from: updater })

      const balBefore = await this.token.balanceOf.call(updater)

      await this.blockchainInfo.cur(asciiToHex("9f0406209cf64acda32636018b33de11"), toWei('12783.31', 'ether'), { from: chainlink })

      await this.blockchainInfo.sup(asciiToHex("35e428271aad4506afc4f4089ce98f68"), toWei('5.19', 'ether'), { from: chainlink })

      const balAfter = await this.token.balanceOf.call(updater)

      assert.equal(balAfter - balBefore, toWei('10', 'ether'))
    })
  })
})