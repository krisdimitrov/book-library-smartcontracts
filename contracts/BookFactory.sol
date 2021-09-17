// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.6;

import "../contracts/Ownable.sol";

contract BookFactory is Ownable {
    uint bookIdCounter;

    struct Book {
        uint id;
        string title;
        uint numberOfCopies;
        address[] borrowedUsersHistory;
    }

    // events
    event BookAdded(uint id, string title, uint numberOfCopies);
    event BookBorrowed(uint id, address user);
    event BookReturned(uint id, address user);

    // storage and mapping
    uint[] private bookIds;
    mapping(uint => Book) books;
    mapping(uint => address[]) bookToCurrentBorrowedUsers;
    mapping(address => mapping(uint => bool)) userToBorrowedBooks;

    function addBook(string memory _title, uint _numberOfCopies) public onlyOwner {        
        address[] memory borrowHistory;
        uint bookId = _getId();
        Book memory newBook = Book(bookId, _title, _numberOfCopies, borrowHistory);
        bookIds.push(bookId);
        books[bookId] = newBook;

        emit BookAdded(bookId, _title, _numberOfCopies);
    }

    function borrowBook(uint _bookId) public {
        require(userToBorrowedBooks[msg.sender][_bookId] == false, "User has already borrowed the book.");     
        require(books[_bookId].numberOfCopies > 0, "No available copies of the book.");

        Book storage bookToBorrow = books[_bookId];
        bookToBorrow.numberOfCopies--;
        bookToBorrow.borrowedUsersHistory.push(msg.sender);
        userToBorrowedBooks[msg.sender][_bookId] = true;

        emit BookBorrowed(_bookId, msg.sender);
    }

    function returnBook(uint _bookId) public {
        require(userToBorrowedBooks[msg.sender][_bookId] == true, "User has not borrowed this book.");     

        books[_bookId].numberOfCopies++;
        userToBorrowedBooks[msg.sender][_bookId] = false;
        emit BookReturned(_bookId, msg.sender);
    }

    function getAvailableBooks() public view returns (Book[] memory) {
        uint availableBooksCount;
        for (uint i = 0; i < bookIds.length; i++) {
            uint bookId = bookIds[i];

            if (books[bookId].numberOfCopies > 0) {
                availableBooksCount++;
            }
        }

        if(availableBooksCount == 0) {
            return new Book[](0);
        }

        Book[] memory availableBooks = new Book[](availableBooksCount);
        for (uint i = 0; i < bookIds.length; i++) {
            uint bookId = bookIds[i];

            if (books[bookId].numberOfCopies > 0) {
                availableBooks[i] = books[bookId];
            }
        }

        return availableBooks;
    }

    function getBookBorrowers(uint _bookId) public view returns (address[] memory) {
        return books[_bookId].borrowedUsersHistory;
    }

    function _getId() private returns (uint) {
        return bookIdCounter++;
    }

    modifier checkIfBookExists(string memory _title) {
        // add implementation
        _;
    }
}
