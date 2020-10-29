//
//  Date+NYPLAdditionsTests.swift
//  SimplyETests
//
//  Created by Ettore Pasquini on 3/25/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import XCTest
@testable import SimplyE

class Date_NYPLAdditionsTests: XCTestCase {
  func testRFC1123() {
    let date = Date(timeIntervalSince1970: 1_000_000_000)
    let rfc1123String = date.rfc1123String
    XCTAssertEqual(rfc1123String, "Sun, 09 Sep 2001 01:46:40 GMT")
  }

  func testRFC1123Performance() {
    let date = Date(timeIntervalSince1970: 1_000_000_000)

    // the first call is several orders of magnitude more expensive
    _ = date.rfc1123String

    self.measure {
      (1...4000).forEach { _ in
        _ = date.rfc1123String
      }
    }
  }

  func testISO8601FullDateParsing() {
    let dateString = "2020-06-02"
    let iOS10Date = NSDate(iso8601DateString: dateString)
    XCTAssertNotNil(iOS10Date)
    XCTAssertEqual(iOS10Date?.utcComponents()?.year, 2020)
    XCTAssertEqual(iOS10Date?.utcComponents()?.month, 6)
    XCTAssertEqual(iOS10Date?.utcComponents()?.day, 2)
  }

  func testInvalidRFC3339Date() {
    XCTAssertNil(NSDate(rfc3339String: "not a date"))
    XCTAssertNil(NSDate(rfc3339String: nil))
  }

  func testParsesRFC3339DateCorrectly() {
    let date = NSDate(rfc3339String: "1984-09-08T08:23:45Z")
    XCTAssertNotNil(date)

    let dateComponents = date?.utcComponents()
    XCTAssertNotNil(dateComponents)
    XCTAssertEqual(dateComponents?.year, 1984);
    XCTAssertEqual(dateComponents?.month, 9);
    XCTAssertEqual(dateComponents?.day, 8);
    XCTAssertEqual(dateComponents?.hour, 8);
    XCTAssertEqual(dateComponents?.minute, 23);
    XCTAssertEqual(dateComponents?.second, 45);
  }

  func testParsesRFC3339DateWithFractionalSecondsCorrectly() {
    let date = NSDate(rfc3339String: "1984-09-08T08:23:45.99Z")
    XCTAssertNotNil(date)

    let dateComponents = date?.utcComponents()
    XCTAssertNotNil(dateComponents)
    XCTAssertEqual(dateComponents?.year, 1984);
    XCTAssertEqual(dateComponents?.month, 9);
    XCTAssertEqual(dateComponents?.day, 8);
    XCTAssertEqual(dateComponents?.hour, 8);
    XCTAssertEqual(dateComponents?.minute, 23);
    XCTAssertEqual(dateComponents?.second, 45);
  }

  func testRFC3339RoundTrip() {
    let date = NSDate(rfc3339String: "1984-09-08T10:23:45+0200")
    XCTAssertNotNil(date)

    let dateString = date?.rfc3339String()
    XCTAssertNotNil(dateString)

    XCTAssertEqual(dateString, "1984-09-08T08:23:45Z")
  }


}
