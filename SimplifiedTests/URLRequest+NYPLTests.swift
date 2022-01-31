//
//  URLRequest+NYPLTests.swift
//  SimplyETests
//
//  Created by Ettore Pasquini on 6/10/20.
//  Copyright © 2020 NYPL. All rights reserved.
//

import XCTest
@testable import SimplyE

class URLRequest_NYPLTests: XCTestCase {
  func testAuthorizationHeaderStrip() throws {
    var req = URLRequest(url: URL(string: "https://example.org/ciccio")!)
    req.setValue("Bearer SomeToken", forHTTPHeaderField: "Authorization")
    req.setValue("json", forHTTPHeaderField: "Content-Type")
    XCTAssertFalse(req.loggableString.contains("Authorization"))
    XCTAssertFalse(req.loggableString.contains("authorization"))
    XCTAssertFalse(req.loggableString.contains("SomeToken"))
    XCTAssert(req.loggableString.contains("Content-Type"))
  }
}
