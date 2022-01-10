//
//  String+NYPLAdditionsTests.swift
//  SimplyETests
//
//  Created by Ettore Pasquini on 4/8/20.
//  Copyright © 2020 NYPL. All rights reserved.
//

import XCTest
@testable import SimplyE

class String_NYPLAdditionsTests: XCTestCase {
  func testURLEncodingQueryParam() {
    let multiASCIIWord = "Pinco Pallino".stringURLEncodedAsQueryParamValue()
    XCTAssertEqual(multiASCIIWord, "Pinco%20Pallino")

    let queryCharsSeparators = "?=&".stringURLEncodedAsQueryParamValue()
    XCTAssertEqual(queryCharsSeparators, "%3F%3D%26")

    let accentedVowels = "àèîóú".stringURLEncodedAsQueryParamValue()
    XCTAssertEqual(accentedVowels, "%C3%A0%C3%A8%C3%AE%C3%B3%C3%BA")

    let legacyEscapes = ";/?:@&=$+{}<>,".stringURLEncodedAsQueryParamValue()
    XCTAssertEqual(legacyEscapes, "%3B%2F%3F%3A%40%26%3D%24%2B%7B%7D%3C%3E%2C")

    let noEscapes = "-_".stringURLEncodedAsQueryParamValue()
    XCTAssertEqual(noEscapes, "-_")

    let otherEscapes = "~`!#%^*()[]|\\".stringURLEncodedAsQueryParamValue()
    XCTAssertEqual(otherEscapes, "~%60!%23%25%5E*()%5B%5D%7C%5C")
  }

  func testBase64Encode() {
    let s = ("ynJZEsWMnTudEGg646Tmua" as NSString).fileSystemSafeBase64EncodedString(usingEncoding: String.Encoding.utf8.rawValue)
    XCTAssertEqual(s, "eW5KWkVzV01uVHVkRUdnNjQ2VG11YQ")
  }

  func testBase64Decode() {
    let s = ("eW5KWkVzV01uVHVkRUdnNjQ2VG11YQ" as NSString).fileSystemSafeBase64DecodedString(usingEncoding: String.Encoding.utf8.rawValue)
    XCTAssertEqual(s, "ynJZEsWMnTudEGg646Tmua")
  }

  func testSHA256() {
    XCTAssertEqual(("967824¬Ó¨⁄€™®©♟♞♝♜♛♚♙♘♗♖♕♔" as NSString).sha256(),
                   "269b80eff0cd705e4b1de9fdbb2e1b0bccf30e6124cdc3487e8d74620eedf254")
  }
}
