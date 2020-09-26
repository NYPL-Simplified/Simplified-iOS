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

  func testBase64Decode() {
    let s = ("eW5KWkVzV01uVHVkRUdnNjQ2VG11YQ" as NSString).fileSystemSafeBase64DecodedString(usingEncoding: String.Encoding.utf8.rawValue)

    XCTAssertEqual(s, "ynJZEsWMnTudEGg646Tmua")
  }

}
