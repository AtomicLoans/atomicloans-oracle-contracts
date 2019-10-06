var HDWalletProvider = require("truffle-hdwallet-provider");
require('dotenv').config();

module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*"
    },
    coverage: {
      host: "localhost",
      network_id: "*",
      port: 8555,
      gas: 0xfffffffffff,
      gasPrice: 0x01
    },
    kovan: {
      provider: function() {
        return new HDWalletProvider(`${process.env.MNEMONIC}`, "https://kovan.infura.io/v3/53bcde36e0404a6da87b71e780783f79")
      },
      network_id: 42,
      gas: 6690000,
      skipDryRun: true
    }
  },
  compilers: {
    solc: {
      version: "0.4.26",
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        },
        evmVersion: 'byzantium'
      },
    },
  },
  plugins: [
    'truffle-plugin-verify'
  ],
  api_keys: {
    etherscan: process.env.ETHERSCAN_API_KEY
  }
};
