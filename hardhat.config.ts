import '@typechain/hardhat'
import '@nomiclabs/hardhat-ethers'
import '@nomiclabs/hardhat-waffle'
import "@nomiclabs/hardhat-etherscan";

require('dotenv').config({ path: './.env.local' })

const hardhatConfig = {
  defaultNetwork: "hardhat",
  // etherscan: {
  //   apiKey: process.env.ETHERSCAN_API_KEY
  // },
  networks: {
    hardhat: {
      chainId: 1337
    },
    // mainnet: {
    //   url: `https://eth-mainnet.alchemyapi.io/v2/${process.env.MAINNET_ALCHEMY_API_KEY}`,
    //   accounts: [process.env.MAINNET_ACCOUNT_PRIVATE_KEY]
    // },
    // rinkeby: {
    //   url: `https://eth-rinkeby.alchemyapi.io/v2/${process.env.RINKEBY_ALCHEMY_API_KEY}`,
    //   accounts: [process.env.RINKEBY_ACCOUNT_PRIVATE_KEY]
    // }
  },
  solidity: {
    version: "0.8.9",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  }
};

export default hardhatConfig
