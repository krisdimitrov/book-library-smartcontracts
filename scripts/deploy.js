const hre = require('hardhat')
const ethers = hre.ethers;

async function deployContract(_privateKey) {
    await hre.run('compile');

    if (!_privateKey) {
        console.log('Private key not provided. Reading from config...');
        _privateKey = process.env.WALLET_PRIVATE_KEY;
    }

    const wallet = new ethers.Wallet(_privateKey, hre.ethers.provider);
    console.log('Deploying contracts with the account:', wallet.address);
    console.log('Account balance:', (await wallet.getBalance()).toString());

    const [deployer] = await ethers.getSigners();
    const BookLibrary = await ethers.getContractFactory("BookLibrary");
    const bookLibraryContract = await BookLibrary.deploy();

    console.log('Deployer: ' + await deployer.getAddress());
    console.log('Waiting for BookLibrary deployment...');
    await bookLibraryContract.deployed();

    console.log('BookLibrary Contract address: ', bookLibraryContract.address);
    console.log('Done!');
}

module.exports = deployContract;