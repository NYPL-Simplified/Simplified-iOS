//
//  NYPLReaderSettingsTests.swift
//  Simplified
//
//  Created by Ettore Pasquini on 7/14/21.
//  Copyright © 2021 NYPL. All rights reserved.
//

import XCTest
@testable import SimplyE

class NYPLReaderSettingsTests: XCTestCase {
  func testReaderSettingsFontFaceValues() throws {
    XCTAssertEqual(NYPLReaderSettingsFontFace.fromRawValue(0), .sans)
    XCTAssertEqual(NYPLReaderSettingsFontFace.fromRawValue(1), .serif)
    XCTAssertEqual(NYPLReaderSettingsFontFace.fromRawValue(2), .openDyslexic)
  }
}
