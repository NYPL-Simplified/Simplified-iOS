//
//  NYPLCatalogUngroupedFeedTests.swift
//  Simplified
//
//  Created by Ernest Fan on 2022-01-04.
//  Copyright © 2022 NYPL. All rights reserved.
//

import XCTest
@testable import SimplyE

class NYPLCatalogUngroupedFeedTests: XCTestCase {
  
  var feedFetcher: NYPLOPDSFeedFetcherMock.Type!
  
  override func setUpWithError() throws {
    try super.setUpWithError()
    feedFetcher = NYPLOPDSFeedFetcherMock.self
    feedFetcher.testType = .none
    feedFetcher.numberOfFetchAllowed = 5
  }

  override func tearDownWithError() throws {
    try super.tearDownWithError()
    feedFetcher = nil
  }

  func testCatalogFeedWithSupportedBooks() throws {
    let expectation = self.expectation(description: "fetching")
    var result: NYPLCatalogUngroupedFeed?
    
    feedFetcher.fetchCatalogUngroupedFeed(url: NYPLCatalogUngroupedFeedBookType.supported.url(),
                                          retryCount: 0) { feed in
      result = feed
      expectation.fulfill()
    }
    
    waitForExpectations(timeout: 3, handler: nil)
    
    guard let result = result else {
      XCTFail()
      return
    }
    
    XCTAssertGreaterThan(result.books.count, 0)
  }
  
  func testCatalogFeedWithSupportedBooksAfterFirstFetch() throws {
    let expectation = self.expectation(description: "fetching")
    var result: NYPLCatalogUngroupedFeed?
    
    feedFetcher.testType = .invertBookType
    
    feedFetcher.fetchCatalogUngroupedFeed(url: NYPLCatalogUngroupedFeedBookType.unsupported.url(),
                                          retryCount: 0) { feed in
      result = feed
      expectation.fulfill()
    }
    
    waitForExpectations(timeout: 3, handler: nil)
    
    guard let result = result else {
      XCTFail()
      return
    }
    
    XCTAssertGreaterThan(result.books.count, 0)
  }

  func testCatalogFeedWithUnsupportedBooksUntilNoNextURLAvailable() throws {
    let expectation = self.expectation(description: "fetching")
    var result: NYPLCatalogUngroupedFeed?

    feedFetcher.fetchCatalogUngroupedFeed(url: NYPLCatalogUngroupedFeedBookType.unsupported.url(),
                                          retryCount: 0) { feed in
      result = feed
      expectation.fulfill()
    }

    waitForExpectations(timeout: 3, handler: nil)

    XCTAssertNil(result)
  }

  func testCatalogFeedWithUnsupportedBooksUntilRetryThresholdReached() throws {
    let expectation = self.expectation(description: "fetching")
    var result: NYPLCatalogUngroupedFeed?

    feedFetcher.testType = .retryThreshold
    
    feedFetcher.fetchCatalogUngroupedFeed(url: NYPLCatalogUngroupedFeedBookType.unsupported.url(),
                                          retryCount: 0) { feed in
      result = feed
      expectation.fulfill()
    }

    waitForExpectations(timeout: 3, handler: nil)

    XCTAssertNil(result)
  }

  func testCatalogFeedFetchFailure() throws {
    let expectation = self.expectation(description: "fetching")
    var result: NYPLCatalogUngroupedFeed?

    feedFetcher.testType = .failRequest
    
    feedFetcher.fetchCatalogUngroupedFeed(url: NYPLCatalogUngroupedFeedBookType.unsupported.url(),
                                          retryCount: 0) { feed in
      result = feed
      expectation.fulfill()
    }

    waitForExpectations(timeout: 3, handler: nil)

    XCTAssertNil(result)
  }
}
