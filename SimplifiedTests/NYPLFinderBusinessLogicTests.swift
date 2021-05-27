//
//  NYPLFinderBusinessLogicTests.swift
//  SimplyETests
//
//  Created by Ernest Fan on 2021-05-26.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import XCTest
import CoreLocation

@testable import SimplyE

class NYPLFinderBusinessLogicTests: XCTestCase {

  var businessLogic: NYPLLibraryFinderBusinessLogic!
  var libraryRegistryMock: NYPLLibraryRegistryFeedRequestHandlerMock!
  var libraryAccounts: [Account]!
  var stageValue: String!
  var expectation: XCTestExpectation!
  
  override func setUpWithError() throws {
    libraryAccounts = [Account]()
    let testFeedUrl = Bundle.init(for: OPDS2LibraryRegistryFeedTests.self)
      .url(forResource: "OPDS2LibraryRegistryFeed", withExtension: "json")!
    let data = try Data(contentsOf: testFeedUrl)
    let feed = try OPDS2LibraryRegistryFeed.fromData(data)
    for catalog in feed.catalogs {
      libraryAccounts.append(Account(libraryCatalog: catalog))
    }
    
    let userAccounts: [Account] = [libraryAccounts.first!]
    
    libraryRegistryMock = NYPLLibraryRegistryFeedRequestHandlerMock()
    
    businessLogic = NYPLLibraryFinderBusinessLogic(userAccounts: userAccounts, libraryRegistry: libraryRegistryMock)
    
    stageValue = NYPLSettings.shared.useBetaLibraries ? LibraryFinderQueryStage.beta.rawValue : LibraryFinderQueryStage.production.rawValue
    
    expectation = self.expectation(description: "NYPLFinderBusinessLogicTests")
  }

  override func tearDownWithError() throws {
    libraryRegistryMock.requestUrl = nil
    libraryRegistryMock.libraryAccounts = [Account]()
    
    businessLogic.userLocation = nil
    businessLogic.newLibraryAccounts = [Account]()
  }

  func testLibraryRegistryRequestUrlWithSearchKeyword() throws {
    businessLogic.requestLibraryList(searchKeyword: "test") { (success) in
      self.expectation.fulfill()
    }
    waitForExpectations(timeout: 1, handler: nil)
    XCTAssertEqual(libraryRegistryMock.requestUrl?.absoluteString,
                   "http://librarysimplified.org/terms/rel/search?query=test&stage=" + stageValue)
  }

  func testLibraryRegistryRequestUrlWithSearchKeywordAndLocation() throws {
    businessLogic.userLocation = CLLocationCoordinate2DMake(41, -87)
    businessLogic.requestLibraryList(searchKeyword: "test") { (success) in
      self.expectation.fulfill()
    }
    waitForExpectations(timeout: 1, handler: nil)
    XCTAssertEqual(libraryRegistryMock.requestUrl?.absoluteString, "http://librarysimplified.org/terms/rel/search?query=test&location=41.0,-87.0&stage=" + stageValue)
  }
  
  func testLibraryRegistryRequestUrlWithLocation() throws {
    businessLogic.userLocation = CLLocationCoordinate2DMake(41, -87)
    businessLogic.requestLibraryList(searchKeyword: nil) { (success) in
      self.expectation.fulfill()
    }
    waitForExpectations(timeout: 1, handler: nil)
    XCTAssertEqual(libraryRegistryMock.requestUrl?.absoluteString,
                   "http://librarysimplified.org/terms/rel/nearby?location=41.0,-87.0&stage=" + stageValue)
    
    let emptyStringUrlExpectation = expectation(description: "UrlWithEmptyString")
    businessLogic.requestLibraryList(searchKeyword: "") { (success) in
      emptyStringUrlExpectation.fulfill()
    }
    waitForExpectations(timeout: 1, handler: nil)
    XCTAssertEqual(libraryRegistryMock.requestUrl?.absoluteString,
                   "http://librarysimplified.org/terms/rel/nearby?location=41.0,-87.0&stage=" + stageValue)
  }
  
  func testUpdateBusinessLogicLibraryAccounts() throws {
    XCTAssertEqual(businessLogic.newLibraryAccounts.count, 0)
    libraryRegistryMock.libraryAccounts = libraryAccounts
    
    businessLogic.requestLibraryList(searchKeyword: "") { (success) in
      self.expectation.fulfill()
    }
    waitForExpectations(timeout: 1, handler: nil)
    XCTAssertEqual(businessLogic.newLibraryAccounts.count, libraryAccounts.count - businessLogic.userAccounts.count)
    
    let resetLibraryAccountsExpectation = expectation(description: "ResetLibraryAccounts")
    libraryRegistryMock.libraryAccounts = [Account]()
    businessLogic.requestLibraryList(searchKeyword: "") { (success) in
      resetLibraryAccountsExpectation.fulfill()
    }
    waitForExpectations(timeout: 1, handler: nil)
    XCTAssertEqual(businessLogic.newLibraryAccounts.count, 0)
  }
}
