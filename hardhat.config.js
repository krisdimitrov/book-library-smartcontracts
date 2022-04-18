require("@nomiclabs/hardhat-waffle");
require("solidity-coverage");
require('dotenv').config()

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

task("deploy", "Deploys contract.")
  .addOptionalParam("privateKey", "Provide the private key for the wallet account.")
  .setAction(async ({ privateKey }) => {
    const deployContract = require("./scripts/deploy");
    await deployContract(privateKey);
  });

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.8.4",
  networks: {
    ropsten: {
      url: process.env.ROPSTEN_URL,
      accounts: [process.env.ROPSTEN_ACCOUNT]
    }
  }
};
