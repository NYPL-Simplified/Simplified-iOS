//
//  NYPLBookmarkSpecTests.swift
//  Simplified
//
//  Created by Ettore Pasquini on 3/22/21.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import XCTest
@testable import SimplyE

// TODO: SIMPLY-3645
class NYPLBookmarkSpecTests: XCTestCase {

  override func setUpWithError() throws {
  }

  override func tearDownWithError() throws {
  }

  func testBookmarkMotivationKeyword() throws {
    XCTAssert(
      NYPLBookmarkSpec.Motivation.bookmark.rawValue
        .contains(NYPLBookmarkSpec.Motivation.bookmarkingKeyword)
    )
  }
}
