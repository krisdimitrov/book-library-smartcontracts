// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract BookLibrary is Ownable {
    struct Book {
        bytes32 id;
        string title;
        uint256 copies;
        address[] borrowedUsersHistory;
    }

    // events
    event BookAdded(bytes32 id, string title, uint256 copies);
    event BookBorrowed(bytes32 id, string title, address user);
    event BookReturned(bytes32 id, string title, address user);

    // storage and mapping
    bytes32[] private bookIds;
    mapping(bytes32 => Book) books;
    mapping(bytes32 => address[]) bookToCurrentBorrowedUsers;
    mapping(address => mapping(bytes32 => bool)) userToBorrowedBooks;

    function addBook(string memory _title, uint256 _copies)
        public
        onlyOwner
        validateInputs(_title, _copies)
    {
        address[] memory borrowHistory;
        bytes32 bookId = _getId(_title);
        Book memory newBook = Book(bookId, _title, _copies, borrowHistory);
        bookIds.push(bookId);
        books[bookId] = newBook;

        emit BookAdded(bookId, _title, _copies);
    }

    function borrowBook(bytes32 _bookId) public {
        require(
            userToBorrowedBooks[msg.sender][_bookId] == false,
            "User has already borrowed the book."
        );
        require(books[_bookId].copies > 0, "No available copies of the book.");

        Book storage bookToBorrow = books[_bookId];
        bookToBorrow.copies--;
        bookToBorrow.borrowedUsersHistory.push(msg.sender);
        userToBorrowedBooks[msg.sender][_bookId] = true;

        emit BookBorrowed(_bookId, bookToBorrow.title, msg.sender);
    }

    function returnBook(bytes32 _bookId) public {
        require(
            userToBorrowedBooks[msg.sender][_bookId] == true,
            "User has not borrowed this book."
        );

        books[_bookId].copies++;
        userToBorrowedBooks[msg.sender][_bookId] = false;

        emit BookReturned(_bookId, books[_bookId].title, msg.sender);
    }

    function getAvailableBooks() public view returns (Book[] memory) {
        uint256 availableBooksCount = 0;
        for (uint256 i = 0; i < bookIds.length; i++) {
            bytes32 bookId = bookIds[i];

            if (books[bookId].copies > 0) {
                availableBooksCount++;
            }
        }

        if (availableBooksCount == 0) {
            return new Book[](0);
        }

        Book[] memory availableBooks = new Book[](availableBooksCount);
        uint256 k = 0;
        for (uint256 i = 0; i < bookIds.length; i++) {
            bytes32 bookId = bookIds[i];

            if (books[bookId].copies > 0) {
                availableBooks[k] = books[bookId];
                k++;
            }
        }

        return availableBooks;
    }

    function getAllBooks() public view returns (Book[] memory) {
        Book[] memory allBooks = new Book[](bookIds.length);

        for (uint256 i = 0; i < bookIds.length; i++) {
            bytes32 bookId = bookIds[i];
            allBooks[i] = books[bookId];
        }

        return allBooks;
    }

    function getBookBorrowers(bytes32 _bookId)
        public
        view
        returns (address[] memory)
    {
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

    modifier validateInputs(string memory _title, uint256 _copies) {
        require(bytes(_title).length > 0, "Title should not be empty.");
        require(
            _checkBookExists(_getId(_title)) == false,
            "Book already added."
        );
        require(_copies > 0, "Copies should be greater than 0.");
        _;
    }
}
