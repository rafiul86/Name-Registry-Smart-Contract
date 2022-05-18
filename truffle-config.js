const HDWalletProvider = require("@truffle/hdwallet-provider");

require('dotenv').config();

module.exports = {
  contracts_build_directory: "./build",
  
  networks: {
    development: {
      host: "127.0.0.1",     // Localhost (default: none)
      port: 7545,            // Standard Ethereum port (default: none)
      network_id: "*",       // Any network (default: none)
     },
     rinkeby : {
      provider : function(){
        return new HDWalletProvider(process.env.MNENOMIC, process.env.INFURA_URL)
      },
      network_id :4,
      gas : 4500000
    },
    fantom: {
      provider: () => new HDWalletProvider("", "https://rpc.ftm.tools/"),
      network_id: 250,
      gasPrice: 470000000000,
      timeoutBlocks: 200,
      skipDryRun: true
    },
    ftmtest: {
      provider: () => new HDWalletProvider(process.env.MNENOMIC, `https://rpc.testnet.fantom.network/`),
      network_id: 4002,//0x61,
      confirmations: 2,
      timeoutBlocks: 200,
      skipDryRun: true
    },
  },

  compilers: {
    solc: {
      version: "0.8.0",    // Fetch exact version from solc-bin (default: truffle's version)
      settings: {          // See the solidity docs for advice about optimization and evmVersion
       optimizer: {
         enabled: true,
         runs: 200
       },
      }
    }
  },

  plugins: ['truffle-plugin-verify'],
  
  api_keys: {
    etherscan: process.env.etherscan_api_key,
    bscscan: process.env.bscscan_api_key,
    ftmscan: process.env.ftmscan_api_key
  },
};
