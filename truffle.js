var HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = "";

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
    goerli: {
      provider: function() {
        return new HDWalletProvider(mnemonic, "https://goerli.infura.io/v3/53bcde36e0404a6da87b71e780783f79")
      },
      network_id: 4,
      gas: 4690000,
      skipDryRun: true
    }
  },
  compilers: {
    solc: {
      version: "0.4.26",
      settings: {
        optimizer: {
          enabled: false,
          runs: 200
        },
        evmVersion: 'byzantium'
      },
    },
  }
};
