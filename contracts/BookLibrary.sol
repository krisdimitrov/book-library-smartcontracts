// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract BookLibrary is Ownable {
    struct Book {
        string title;
        uint256 copies;
        address[] borrowedUsersHistory;
    }

    // events
    event BookAdded(bytes32 id, string title, uint256 copies);
    event BookBorrowed(bytes32 id, string title, address user);
    event BookReturned(bytes32 id, string title, address user);

    // storage and mapping
    bytes32[] public bookIds;
    mapping(bytes32 => Book) public books;
    mapping(address => mapping(bytes32 => bool)) userToBorrowedBooks;

    modifier validateInputs(string memory _title, uint256 _copies) {
        require(bytes(_title).length > 0, "Title should not be empty.");
        require(_copies > 0, "Copies should be greater than 0.");
        _;
    }

    modifier checkBookExists(string memory _title, bool shouldExist) {
        bytes32 bookId = _getId(_title);
        if (shouldExist) {
            require(
                bytes(books[bookId].title).length > 0,
                "Book does not exist."
            );
        } else {
            require(
                bytes(books[bookId].title).length == 0,
                "Book already exists."
            );
        }
        _;
    }

    function addBook(string memory _title, uint256 _copies)
        public
        onlyOwner
        validateInputs(_title, _copies)
        checkBookExists(_title, false)
    {
        address[] memory borrowHistory;
        bytes32 bookId = _getId(_title);
        Book memory newBook = Book(_title, _copies, borrowHistory);

        bookIds.push(bookId);
        books[bookId] = newBook;

        emit BookAdded(bookId, _title, _copies);
    }

    function borrowBook(string memory _title)
        public
        checkBookExists(_title, true)
    {
        bytes32 bookId = _getId(_title);
        Book storage bookToBorrow = books[bookId];

        require(
            userToBorrowedBooks[msg.sender][bookId] == false,
            "User has already borrowed the book."
        );
        require(bookToBorrow.copies > 0, "No available copies of the book.");

        bookToBorrow.copies--;
        bookToBorrow.borrowedUsersHistory.push(msg.sender);
        userToBorrowedBooks[msg.sender][bookId] = true;

        emit BookBorrowed(bookId, bookToBorrow.title, msg.sender);
    }

    function returnBook(string memory _title)
        public
        checkBookExists(_title, true)
    {
        bytes32 bookId = _getId(_title);
        Book storage bookToReturn = books[bookId];

        require(
            userToBorrowedBooks[msg.sender][bookId] == true,
            "User has not borrowed this book."
        );

        bookToReturn.copies++;
        userToBorrowedBooks[msg.sender][bookId] = false;

        emit BookReturned(bookId, bookToReturn.title, msg.sender);
    }

    function getBook(string memory _title)
        external
        view
        checkBookExists(_title, true)
        returns (Book memory)
    {
        bytes32 bookId = _getId(_title);
        return books[bookId];
    }

    function getBooksCount() external view returns (uint256) {
        return bookIds.length;
    }

    function getBookBorrowers(string memory _title)
        public
        view
        checkBookExists(_title, true)
        returns (address[] memory)
    {
        bytes32 bookId = _getId(_title);
        return books[bookId].borrowedUsersHistory;
    }

    function _getId(string memory _title) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(_title));
    }
}
