const hre = require("hardhat");
const yargs = require('yargs');
const dotenv = require("dotenv").config();
const BookLibrary = require("./artifacts/contracts/BookLibrary.sol/BookLibrary.json");
let bookLibraryContract = null;

async function main() {
    createCommandsWithHandlers();
};

async function createCommandsWithHandlers() {
    return yargs
        .command('add', 'Adds a book to the library.', {
            title: {
                description: 'the year to check for',
                alias: 't',
                type: 'string',
            },
            copies: {
                description: 'Number of book copies',
                alias: 'c',
                type: 'number'
            }
        }, async (args) => {
            bookLibraryContract = await getContractInstanceForNetwork(args.network);

            bookLibraryContract.addBook(args.title, args.copies)
                .then(transaction => waitAndLogTransactionStatus(transaction))
                .catch(reason => handleError(reason));
        })
        .command('borrow', 'Borrow a book by ID.', {
            id: {
                description: 'ID of the book to borrow.',
                alias: 'i',
                type: 'string'
            }
        }, async (args) => {
            bookLibraryContract = await getContractInstanceForNetwork(args.network);

            bookLibraryContract.borrowBook(args.id)
                .then(transaction => waitAndLogTransactionStatus(transaction))
                .catch(reason => handleError(reason));
        })
        .command('return', 'Return a book by ID.', {
            id: {
                description: 'ID of the book to borrow.',
                alias: 'i',
                type: 'string'
            }
        }, async (args) => {
            bookLibraryContract = await getContractInstanceForNetwork(args.network);

            bookLibraryContract.returnBook(args.id)
                .then(transaction => waitAndLogTransactionStatus(transaction))
                .catch(reason => handleError(reason));
        })
        .command('history', 'Get book borrowers history', {
            id: {
                description: 'ID of the book to borrow.',
                alias: 'i',
                type: 'string'
            }
        }, async (args) => {
            bookLibraryContract = await getContractInstanceForNetwork(args.network);

            bookLibraryContract.getBookBorrowers(args.id)
                .then(borrowers => {
                    console.log(`Borrowers History: \n `);
                    console.log(`${borrowers.map(borrower => `${borrower}`).join('\n')}`);
                })
                .catch(reason => handleError(reason));
        })
        .command('list', 'List available books', {}, async (args) => {
            bookLibraryContract = await getContractInstanceForNetwork(args.network);

            let availableBooks = await bookLibraryContract.getAvailableBooks();
            console.log(`Available Books: \n `);
            console.log(`${availableBooks.map(book => `${book.id} - ${book.title} - ${book.numberOfCopies}`).join('\n')}`);
        })
        .option('network', {
            alias: 'n',
            default: 'localhost',
            description: 'Specify network: localhost or Ropsten.',
            type: 'string',
        })
        .help()
        .alias('help', 'h')
        .parse();
}

async function getContractInstanceForNetwork(network) {
    let provider = null;
    let wallet = null;
    let contractAddress = null;

    switch (network) {
        case 'ropsten':
            provider = new hre.ethers.providers.InfuraProvider("ropsten", process.env.ROPSTEN_API_KEY);
            wallet = new hre.ethers.Wallet(process.env.METAMASK_WALLET_PRIVATE_KEY, provider);
            contractAddress = process.env.ROPSTEN_CONTRACT_ADDRESS;
            break;
        case 'localhost':
        default:
            provider = new hre.ethers.providers.JsonRpcProvider(process.env.JSON_RPC_PROVIDER_URL);
            wallet = new hre.ethers.Wallet(process.env.LOCAL_WALLET_PRIVATE_KEY, provider);
            contractAddress = process.env.LOCAL_CONTRACT_ADDRESS;
    }

    const balance = await wallet.getBalance();
    console.log(`Wallet Balance: ${hre.ethers.utils.formatEther(balance, 18)}`);

    return new hre.ethers.Contract(contractAddress, BookLibrary.abi, wallet);
}

async function waitAndLogTransactionStatus(transaction) {
    const receipt = await transaction.wait();
    if (receipt.status == 1) {
        console.log('Operation is successful.');
    } else {
        console.error('Operation is not successful!');
    }
}

function handleError(reason) {
    if (reason.error) {
        const body = JSON.parse(reason.error.body.replace("\/", ''));
        console.log(body.error.message);
    }

    console.log('Operation failed. No error message present.');
}

main();