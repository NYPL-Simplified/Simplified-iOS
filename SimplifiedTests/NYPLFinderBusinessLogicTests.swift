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
  }

  override func tearDownWithError() throws {
    libraryRegistryMock.requestUrl = nil
    libraryRegistryMock.libraryAccounts = [Account]()
    
    businessLogic.userLocation = nil
    businessLogic.newLibraryAccounts = [Account]()
  }

  func testLibraryRegistryRequestUrlWithSearchKeyword() throws {
    businessLogic.requestLibraryList(searchKeyword: "test") { (success) in
      XCTAssertEqual(self.libraryRegistryMock.requestUrl?.absoluteString, "http://librarysimplified.org/terms/rel/search?query=test&stage=all")
    }
  }

  func testLibraryRegistryRequestUrlWithSearchKeywordAndLocation() throws {
    businessLogic.userLocation = CLLocationCoordinate2DMake(41, -87)
    businessLogic.requestLibraryList(searchKeyword: "test") { (success) in
      XCTAssertEqual(self.libraryRegistryMock.requestUrl?.absoluteString, "http://librarysimplified.org/terms/rel/search?query=test&location=41.0,-87.0&stage=all")
    }
  }
  
  func testLibraryRegistryRequestUrlWithLocation() throws {
    businessLogic.userLocation = CLLocationCoordinate2DMake(41, -87)
    businessLogic.requestLibraryList(searchKeyword: nil) { (success) in
      XCTAssertEqual(self.libraryRegistryMock.requestUrl?.absoluteString, "http://librarysimplified.org/terms/rel/nearby?location=41.0,-87.0&stage=all")
    }
    
    businessLogic.requestLibraryList(searchKeyword: "") { (success) in
      XCTAssertEqual(self.libraryRegistryMock.requestUrl?.absoluteString, "http://librarysimplified.org/terms/rel/nearby?location=41.0,-87.0&stage=all")
    }
  }
  
  func testUpdateBusinessLogicLibraryAccounts() throws {
    XCTAssertEqual(businessLogic.newLibraryAccounts.count, 0)
    libraryRegistryMock.libraryAccounts = libraryAccounts
    
    businessLogic.requestLibraryList(searchKeyword: "") { (success) in
      XCTAssertEqual(self.businessLogic.newLibraryAccounts.count, self.libraryAccounts.count - self.businessLogic.userAccounts.count)
    }
    
    libraryRegistryMock.libraryAccounts = [Account]()
    businessLogic.requestLibraryList(searchKeyword: "") { (success) in
      XCTAssertEqual(self.businessLogic.newLibraryAccounts.count, 0)
    }
  }
}
