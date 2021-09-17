// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.6;

import "../contracts/Ownable.sol";

contract BookLibrary is Ownable {
    struct Book {
        bytes32 id;
        string title;
        uint numberOfCopies;
        address[] borrowedUsersHistory;
    }

    // events
    event BookAdded(bytes32 id, string title, uint numberOfCopies);
    event BookBorrowed(bytes32 id, address user);
    event BookReturned(bytes32 id, address user);

    // storage and mapping
    bytes32[] private bookIds;
    mapping(bytes32 => Book) books;
    mapping(bytes32 => address[]) bookToCurrentBorrowedUsers;
    mapping(address => mapping(bytes32 => bool)) userToBorrowedBooks;

    function addBook(string memory _title, uint _numberOfCopies) public onlyOwner validateInputs(_title, _numberOfCopies) {        
        address[] memory borrowHistory;
        bytes32 bookId = _getId(_title);
        Book memory newBook = Book(bookId, _title, _numberOfCopies, borrowHistory);
        bookIds.push(bookId);
        books[bookId] = newBook;

        emit BookAdded(bookId, _title, _numberOfCopies);
    }

    function borrowBook(bytes32 _bookId) public {
        require(userToBorrowedBooks[msg.sender][_bookId] == false, "User has already borrowed the book.");     
        require(books[_bookId].numberOfCopies > 0, "No available copies of the book.");

        Book storage bookToBorrow = books[_bookId];
        bookToBorrow.numberOfCopies--;
        bookToBorrow.borrowedUsersHistory.push(msg.sender);
        userToBorrowedBooks[msg.sender][_bookId] = true;

        emit BookBorrowed(_bookId, msg.sender);
    }

    function returnBook(bytes32 _bookId) public {
        require(userToBorrowedBooks[msg.sender][_bookId] == true, "User has not borrowed this book.");     

        books[_bookId].numberOfCopies++;
        userToBorrowedBooks[msg.sender][_bookId] = false;
        
        emit BookReturned(_bookId, msg.sender);
    }

    function getAvailableBooks() public view returns (Book[] memory) {
        uint availableBooksCount = 0;
        for (uint i = 0; i < bookIds.length; i++) {
            bytes32 bookId = bookIds[i];

            if (books[bookId].numberOfCopies > 0) {
                availableBooksCount++;
            }
        }

        if(availableBooksCount == 0) {
            return new Book[](0);
        }

        Book[] memory availableBooks = new Book[](availableBooksCount);
        uint k = 0;
        for (uint i = 0; i < bookIds.length; i++) {
            bytes32 bookId = bookIds[i];

            if (books[bookId].numberOfCopies > 0) {
                availableBooks[k] = books[bookId];
                k++;
            }
        }

        return availableBooks;
    }

    function getBookBorrowers(bytes32 _bookId) public view returns (address[] memory) {
        require(_checkBookExists(_bookId), "Book does not exist.");
        return books[_bookId].borrowedUsersHistory;
    }

    function _getId(string memory _title) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(_title));
    }

    function _checkBookExists(bytes32 _id) private view returns (bool) {
        Book memory existingBook = books[_id];
        return bytes(existingBook.title).length != 0;
    }

    modifier validateInputs(string memory _title, uint _numberOfCopies) {
        require(bytes(_title).length > 0, "Title should not be empty.");
        require(_checkBookExists(_getId(_title)) == false, "Book already added.");
        require(_numberOfCopies > 0, "Copies should be greater than 0.");
        _;
    }
}
