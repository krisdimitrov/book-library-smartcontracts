// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.6;

contract BookFactory {
    address private owner;
    uint bookIdCounter;

    struct Book {
        uint id;
        string title;
        uint numberOfCopies;
        address[] borrowedUsersHistory;
    }

    // events
    event BookCreated(uint id, string title, uint numberOfCopies);

    // storage and mapping
    uint[] private bookIds;
    mapping(uint => Book) booksStorage;
    mapping(uint => address[]) bookToCurrentBorrowedUsers;
    mapping(address => mapping(uint => Book)) userToBorrowedBooks;

    constructor() {
        owner = msg.sender;
    }

    function addBook(string memory _title, uint _numberOfCopies) public {
        require(msg.sender == owner, "Only the library owner can add books!");
        _addBook(_getId(), _title, _numberOfCopies);
    }

    function borrowBook(uint _bookId) public {
        address[] memory borrowedUsers = bookToCurrentBorrowedUsers[_bookId];
        if (borrowedUsers.length > 0) {
            require(borrowedUsers[borrowedUsers.length - 1] != msg.sender,"User has already borrowed the book.");
        }
        require(booksStorage[_bookId].numberOfCopies > 0, "No available copies of the book.");

        booksStorage[_bookId].numberOfCopies--;
        booksStorage[_bookId].borrowedUsersHistory.push(msg.sender);
        bookToCurrentBorrowedUsers[_bookId].push(msg.sender);
    }

    function getAvailableBooks() public view returns (Book[] memory) {
        uint availableBooksCount;
        for (uint i = 0; i < bookIds.length; i++) {
            uint bookId = bookIds[i];

            if (booksStorage[bookId].numberOfCopies > 0) {
                availableBooksCount++;
            }
        }

        Book[] memory availableBooks = new Book[](availableBooksCount);
        for (uint i = 0; i < bookIds.length; i++) {
            uint bookId = bookIds[i];

            if (booksStorage[bookId].numberOfCopies > 0) {
                availableBooks[i] = booksStorage[bookId];
            }
        }

        return availableBooks;
    }

    function getBookBorrowers(uint _bookId)
        public
        view
        returns (address[] memory)
    {
        return bookToCurrentBorrowedUsers[_bookId];
    }

    function _addBook(
        uint id,
        string memory _title,
        uint _numberOfCopies
    ) private {
        address[] memory borrowHistory;
        Book memory newBook = Book(id, _title, _numberOfCopies, borrowHistory);
        bookIds.push(id);
        booksStorage[id] = newBook;
        emit BookCreated(id, _title, _numberOfCopies);
    }

    function _getIsBookBorrowedByUser(address _userId) private {}

    function _getId() private returns (uint) {
        return bookIdCounter++;
    }
}
