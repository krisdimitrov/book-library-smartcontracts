const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("BookLibrary", function () {
  let BookLibrary;
  let bookLibrary;
  let bookInLibrary;

  const TEST_BOOK_TITLE = "12 Rules for Life: An Antidote to Chaos";
  const TEST_NUMBER_OF_BOOKS = 2;

  beforeEach(async () => {
    BookLibrary = await ethers.getContractFactory("BookLibrary");
    bookLibrary = await BookLibrary.deploy();
    await bookLibrary.deployed();

    const addBookTx = await bookLibrary.addBook(TEST_BOOK_TITLE, TEST_NUMBER_OF_BOOKS);
    await addBookTx.wait();
  });

  it("check add book", async () => {
    BookLibrary = await ethers.getContractFactory("BookLibrary");
    bookLibrary = await BookLibrary.deploy();
    await bookLibrary.deployed();

    const addBookTx = await bookLibrary.addBook(TEST_BOOK_TITLE, TEST_NUMBER_OF_BOOKS);
    await addBookTx.wait();
  });

  it("should be one book available", async () => {
    let books = await bookLibrary.getAvailableBooks();
    expect(books.length).to.equal(1);

    bookInLibrary = books['0'];
    expect(bookInLibrary).to.not.be.null;
    expect(bookInLibrary).to.not.be.undefined;
    expect(bookInLibrary).to.have.property("title").to.equal(TEST_BOOK_TITLE, "titles should match");
    expect(bookInLibrary).to.have.property("numberOfCopies").to.equal(TEST_NUMBER_OF_BOOKS, "titles should match");
  });

  it("should be no books available", async () => {
    BookLibrary = await ethers.getContractFactory("BookLibrary");
    bookLibrary = await BookLibrary.deploy();
    await bookLibrary.deployed();

    let books = await bookLibrary.getAvailableBooks();
    expect(books.length).to.equal(0);
  });

  it("check borrowBook", async () => {
    let books = await bookLibrary.getAvailableBooks();
    expect(books["0"]).property("numberOfCopies").to.be.equal(2, "should be two books available.");
    
    const borrowBookTx = await bookLibrary.borrowBook(bookInLibrary.id);
    await borrowBookTx.wait();

    books = await bookLibrary.getAvailableBooks();
    expect(books["0"]).property("numberOfCopies").to.be.equal(1, "should be one book available.");
  });

  it("check borrow same book twice", async () => {
    await bookLibrary.borrowBook(bookInLibrary.id);
    await expect(bookLibrary.borrowBook(bookInLibrary.id)).to.be.revertedWith('User has already borrowed the book.');
  });

  it("check return book", async () => {
    const borrowTx = await bookLibrary.borrowBook(bookInLibrary.id);
    await borrowTx.wait();

    let books = await bookLibrary.getAvailableBooks();
    expect(books["0"]).property("numberOfCopies").to.equal(1, "should be only one copy available");
    
    await bookLibrary.returnBook(bookInLibrary.id);
    books = await bookLibrary.getAvailableBooks();
    expect(books["0"]).property("numberOfCopies").to.equal(2, "should be two copies available");
  });

  it("check return not borrowed book", async () => {
    await expect(bookLibrary.returnBook(bookInLibrary.id)).to.be.revertedWith("User has not borrowed this book.");
  });

  it("check add with different owner", async () => {
    const [owner, differentOwner] = await ethers.getSigners();
    await expect(bookLibrary
      .connect(differentOwner)
      .addBook(TEST_BOOK_TITLE, TEST_NUMBER_OF_BOOKS))
      .to.be.revertedWith("Ownable: caller is not the owner");
  });

  it("check empty book borrowers history", async () => {
    const bookBorrowers = await bookLibrary.getBookBorrowers(bookInLibrary.id);
    expect(bookBorrowers).property("length").to.be.equal(0);
  });

  it("check book borrowers history", async () => {
    await bookLibrary.borrowBook(bookInLibrary.id);
    const borrowers = await bookLibrary.getBookBorrowers(bookInLibrary.id);
    const [owner] = await ethers.getSigners();

    expect(borrowers.length).to.be.equal(1);
    expect(borrowers).to.contain(await owner.getAddress());
  });

  it("check borrow by two users", async () => {
    const [owner, anotherUser] = await ethers.getSigners();
    let books =  await bookLibrary.getAvailableBooks();
    expect(books["0"].numberOfCopies).to.be.equal(2, "should be two books available initially");

    await bookLibrary.borrowBook(bookInLibrary.id);
    books = await bookLibrary.getAvailableBooks();
    expect(books["0"].numberOfCopies).to.be.equal(1, "should be one available after borrow");

    await bookLibrary.connect(anotherUser).borrowBook(bookInLibrary.id);
    books = await bookLibrary.getAvailableBooks();
    expect(books.length).to.be.equal(0, "should be no available books after second borrow");
  });
});
