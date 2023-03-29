require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.17",
  networks: {
    ganache: {
      url: "http://127.0.0.1:7545",
      accounts: [
        `79fc7360a57aa149355d547222f6e716c96eb1a9e301fddcc913d55e0db78337`,
      ],
    }
  }
};
