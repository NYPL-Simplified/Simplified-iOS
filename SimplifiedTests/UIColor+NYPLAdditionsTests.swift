//
//  UIColor+NYPLAdditionsTests.swift
//  Simplified
//
//  Created by Ettore Pasquini on 9/28/20.
//  Copyright © 2020 NYPL. All rights reserved.
//

import XCTest
@testable import SimplyE

class UIColor_NYPLAdditionsTests: XCTestCase {
  func testExample() throws {
    let color = UIColor(red: 0.65, green: 0.23, blue: 0.8, alpha: 0.4)

    XCTAssertEqual(color.javascriptHexString(), "#A63BCC")
  }

}
