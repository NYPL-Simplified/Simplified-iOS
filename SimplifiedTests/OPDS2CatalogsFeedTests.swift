//
//  OPDS2CatalogsFeedTests.swift
//  SimplyETests
//
//  Created by Benjamin Anderman on 5/10/19.
//  Copyright © 2019 NYPL Labs. All rights reserved.
//

import XCTest

@testable import SimplyE

class OPDS2CatalogsFeedTests: XCTestCase {

  let testFeedUrl = Bundle.init(for: OPDS2CatalogsFeedTests.self)
    .url(forResource: "OPDS2CatalogsFeed", withExtension: "json")!
  
  override func setUp() {
      // Put setup code here. This method is called before the invocation of each test method in the class.
  }

  override func tearDown() {
      // Put teardown code here. This method is called after the invocation of each test method in the class.
  }

  func testLoadCatalogsFeed() {
    
    do {
      let data = try Data(contentsOf: testFeedUrl)
      let _ = try OPDS2CatalogsFeed.fromData(data)
    } catch (let error) {
      XCTAssert(false, error.localizedDescription)
    }
  }

}
