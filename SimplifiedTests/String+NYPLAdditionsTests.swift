//
//  String+NYPLAdditionsTests.swift
//  SimplyETests
//
//  Created by Ettore Pasquini on 4/8/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import XCTest
@testable import SimplyE

class String_NYPLAdditionsTests: XCTestCase {
  func testMD5() {
    XCTAssertEqual("password".md5hex(), "5f4dcc3b5aa765d61d8327deb882cf99")
  }
}
