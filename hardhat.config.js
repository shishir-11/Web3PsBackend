require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.20",
  networks: {
    fuji: {
      url: "https://avalanche-fuji.infura.io/v3/0fc83caff1ac496a8ab2dffb96beac36",
      accounts: ["0x83d186fe56d37cb782a02fa79af46bddc9491db017d02c0d42ff2b3f082feb54"]
    },
    amoy: {
      url: "https://polygon-amoy.infura.io/v3/0fc83caff1ac496a8ab2dffb96beac36",
      accounts: ["0x83d186fe56d37cb782a02fa79af46bddc9491db017d02c0d42ff2b3f082feb54"]
    }

  }
};
