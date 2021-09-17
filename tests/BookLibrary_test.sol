// SPDX-License-Identifier: GPL-3.0
    
pragma solidity >=0.4.22 <0.9.0;

import "remix_tests.sol"; 
import "remix_accounts.sol";
import "../contracts/BookLibrary.sol";

contract BookLibraryTests is BookLibrary {
    BookLibrary bookLibrary;
    Book bookInLibrary;

    string testBookTitle = "12 Rules for Life: An Antidote to Chaos";
    uint testNumberOfBooks = 2;
    
    function beforeEach() public {
        bookLibrary = new BookLibrary();
        bookLibrary.addBook(testBookTitle, testNumberOfBooks);
        bookInLibrary = bookLibrary.getAvailableBooks()[0];
    }

    function checkGetAvailableBooks() public {
        Book memory actualBook = bookLibrary.getAvailableBooks()[0];
        
        Assert.equal(actualBook.title, testBookTitle, "title should be equal");
        Assert.equal(actualBook.numberOfCopies, testNumberOfBooks, "copies should be equal");
    }

     function checkGetAvailableBooksEmpty() public {
        bookLibrary = new BookLibrary();
        Book[] memory actualBooks = bookLibrary.getAvailableBooks();
        
        Assert.equal(actualBooks.length, 0, "should not be any books available");
    }
    
    function checkBorrowBook() public {
        bookLibrary.borrowBook(bookInLibrary.id);
        uint availableBooks = bookLibrary.getAvailableBooks().length;
        
        Assert.equal(availableBooks, 1, "should be only one book available");
    }
    
    function checkBorrowSameBookTwice() public {
        bookLibrary.borrowBook(bookInLibrary.id);
        try bookLibrary.borrowBook(bookInLibrary.id) {
        } catch Error(string memory reason) {
            Assert.equal(reason, "User has already borrowed the book.", "should fail with expected reason");
        }
    }
    
    function checkReturnBook() public {
        bookLibrary.borrowBook(bookInLibrary.id);
        uint bookCopies = bookLibrary.getAvailableBooks()[0].numberOfCopies;
        Assert.equal(bookCopies, 1, "should be only one copy available");
        
        bookLibrary.returnBook(bookInLibrary.id);
        bookCopies = bookLibrary.getAvailableBooks()[0].numberOfCopies;
        Assert.equal(bookCopies, 2, "should be two copies available");
    }
    
    function checkReturnNotBorrowedBook() public {
        try bookLibrary.returnBook(bookInLibrary.id) {
        } catch Error(string memory reason) {
            Assert.equal(reason, "User has not borrowed this book.", "should fail with expected reason");
        }
    }
}
