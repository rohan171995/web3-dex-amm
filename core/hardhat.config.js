require("@nomicfoundation/hardhat-toolbox");
require('dotenv').config()

const ACCOUNT_PRIVATE_KEY = process.env.ACCOUNT_PRIVATE_KEY;
const GOERLI_RPC_URL = process.env.GOERLI_RPC_URL

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.17",
  networks: {
    goerli: {
      url: GOERLI_RPC_URL,
      accounts: [ACCOUNT_PRIVATE_KEY]
    }
  }
};
