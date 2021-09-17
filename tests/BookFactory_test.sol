// SPDX-License-Identifier: GPL-3.0
    
pragma solidity >=0.4.22 <0.9.0;

import "remix_tests.sol"; 
import "remix_accounts.sol";
import "../contracts/BookFactory.sol";

contract BookFactoryTests is BookFactory {
    BookFactory bookLibrary;
    string testBookTitle = "12 Rules For Life";
    uint testNumberOfBooks = 2;
    
    function beforeEach() public {
        bookLibrary = new BookFactory();
        bookLibrary.addBook(testBookTitle, testNumberOfBooks);
    }

    function checkGetAvailableBooks() public {
        Book memory actualBook = bookLibrary.getAvailableBooks()[0];
        
        Assert.equal(actualBook.title, testBookTitle, "title should be equal");
        Assert.equal(actualBook.numberOfCopies, testNumberOfBooks, "copies should be equal");
    }
    
    function checkBorrowBook() public {
        bookLibrary.borrowBook(0);
        uint availableBooks = bookLibrary.getAvailableBooks().length;
        
        Assert.equal(availableBooks, 1, "should be only one book available");
    }
    
    function checkBorrowSameBookTwice() public {
        bookLibrary.borrowBook(0);
        try bookLibrary.borrowBook(0) {
        } catch Error(string memory reason) {
            Assert.equal(reason, "User has already borrowed the book.", "should fail with expected reason");
        }
    }
    
    function checkReturnBook() public {
        bookLibrary.borrowBook(0);
        uint bookCopies = bookLibrary.getAvailableBooks()[0].numberOfCopies;
        Assert.equal(bookCopies, 1, "should be only one copy available");
        
        bookLibrary.returnBook(0);
        bookCopies = bookLibrary.getAvailableBooks()[0].numberOfCopies;
        Assert.equal(bookCopies, 2, "should be two copies available");
    }
    
    function checkReturnNotBorrowedBook() public {
        try bookLibrary.returnBook(0) {
            
        } catch Error(string memory reason) {
            Assert.equal(reason, "User has not borrowed this book.", "should fail with expected reason");
        }
    }
}
