const { expect } = require("chai");
const { assert } = require("mocha");
const { ethers } = require("hardhat");

describe("BookLibrary", function () {
  let BookLibrary;
  let bookLibrary;
  let bookInLibrary;

  const TEST_BOOK_TITLE_1 = "12 Rules for Life: An Antidote to Chaos";
  const TEST_COPIES_1 = 2;
  const TEST_BOOK_TITLE_2 = "Sapiens";
  const TEST_COPIES_2 = 1;

  beforeEach(async () => {
    BookLibrary = await ethers.getContractFactory("BookLibrary");
    bookLibrary = await BookLibrary.deploy();
    await bookLibrary.deployed();

    const addBookTx = await bookLibrary.addBook(TEST_BOOK_TITLE_1, TEST_COPIES_1);
    await addBookTx.wait();
  });

  it("check addBook", async () => {
    const count = await bookLibrary.getBooksCount();
    expect(count).to.equal(1, "should be no books initially");

    const addBookTx = await bookLibrary.addBook(TEST_BOOK_TITLE_2, TEST_COPIES_2);
    await addBookTx.wait();

    const booksCount = await bookLibrary.getBooksCount();
    expect(booksCount).to.be.equal(2);
  });

  it("check addBook existing", async () => {
    await expect(bookLibrary.addBook(TEST_BOOK_TITLE_1, TEST_COPIES_1)).to.be.revertedWith("Book already exists.");
  });

  it("check addBook invalid params", async () => {
    await expect(bookLibrary.addBook('', 1)).to.be.revertedWith("Title should not be empty.");
    await expect(bookLibrary.addBook('Title', 0)).to.be.revertedWith("Copies should be greater than 0.");
  });

  it("check getBooksCount with books", async () => {
    const booksCount = await bookLibrary.getBooksCount();
    expect(booksCount).to.equal(1);
  });

  it("check getBooksCount with no books", async () => {
    BookLibrary = await ethers.getContractFactory("BookLibrary");
    bookLibrary = await BookLibrary.deploy();
    await bookLibrary.deployed();

    const booksCount = await bookLibrary.getBooksCount();
    expect(booksCount).to.equal(0);
  });

  it("check get books from mapping", async () => {
    const booksCount = await bookLibrary.getBooksCount();
    expect(booksCount).to.equal(1);

    for (let i = 0; i < booksCount; i++) {
      const bookId = await bookLibrary.bookIds(i);
      const book = await bookLibrary.books(bookId);
      bookInLibrary = book;

      expect(book).property("title").to.equal(TEST_BOOK_TITLE_1), "titles should match";
      expect(book).property("copies").to.equal(TEST_COPIES_1, "copies should match");
    }
  })

  it("check getBook with existing", async () => {
    const book = await bookLibrary.getBook(TEST_BOOK_TITLE_1);
    expect(book).property("title").to.equal(TEST_BOOK_TITLE_1), "titles should match";
    expect(book).property("copies").to.equal(TEST_COPIES_1, "copies should match");
  });

  it("check getBook with non-existing", async () => {
    await expect(bookLibrary.getBook("does not exist")).to.be.revertedWith("Book does not exist");
  });

  it("check borrowBook", async () => {
    let book = await bookLibrary.getBook(TEST_BOOK_TITLE_1);
    expect(book).property("copies").to.be.equal(2, "should be two books available.");

    const borrowBookTx = await bookLibrary.borrowBook(bookInLibrary.title);
    await borrowBookTx.wait();

    book = await bookLibrary.getBook(TEST_BOOK_TITLE_1);
    expect(book).property("copies").to.be.equal(1, "should be one book available.");
  });

  it("check borrow same book twice", async () => {
    await bookLibrary.borrowBook(bookInLibrary.title);
    await expect(bookLibrary.borrowBook(bookInLibrary.title)).to.be.revertedWith('User has already borrowed the book.');
  });

  it("check return book", async () => {
    const borrowTx = await bookLibrary.borrowBook(bookInLibrary.title);
    await borrowTx.wait();

    let book = await getTestBook();
    expect(book.copies).to.equal(1, "should be only one copy available");

    await bookLibrary.returnBook(bookInLibrary.title);
    book = await getTestBook();
    expect(book.copies).to.equal(2, "should be two copies available");
  });

  it("check return not borrowed book", async () => {
    await expect(bookLibrary.returnBook(bookInLibrary.title)).to.be.revertedWith("User has not borrowed this book.");
  });

  it("check add with different owner", async () => {
    const [owner, differentOwner] = await ethers.getSigners();
    await expect(bookLibrary
      .connect(differentOwner)
      .addBook(TEST_BOOK_TITLE_1, TEST_COPIES_1))
      .to.be.revertedWith("Ownable: caller is not the owner");
  });

  it("check empty book borrowers history", async () => {
    const bookBorrowers = await bookLibrary.getBookBorrowers(bookInLibrary.title);
    expect(bookBorrowers).property("length").to.be.equal(0);
  });

  it("check getBookBorrowers non-existing", async () => {
    await expect(bookLibrary.getBookBorrowers("does not exist")).to.be.revertedWith("Book does not exist.");
  });

  it("check book borrowers history", async () => {
    await bookLibrary.borrowBook(bookInLibrary.title);
    const borrowers = await bookLibrary.getBookBorrowers(bookInLibrary.title);
    const [owner] = await ethers.getSigners();

    expect(borrowers.length).to.be.equal(1);
    expect(borrowers).to.contain(await owner.getAddress());
  });

  it("check borrow by two users", async () => {
    const [owner, anotherUser] = await ethers.getSigners();
    let book = await getTestBook();
    expect(book.copies).to.be.equal(2, "should be two books available initially");

    await bookLibrary.borrowBook(bookInLibrary.title);
    book = await getTestBook();
    expect(book.copies).to.be.equal(1, "should be one available after borrow");

    await bookLibrary
      .connect(anotherUser)
      .borrowBook(bookInLibrary.title);

    book = await getTestBook();
    expect(book.copies).to.be.equal(0, "should be no available books after second borrow");
  });

  async function getTestBook() {
    return await bookLibrary.getBook(TEST_BOOK_TITLE_1);
  }
});
