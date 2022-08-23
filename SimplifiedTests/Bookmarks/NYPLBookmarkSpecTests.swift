//
//  NYPLBookmarkSpecTests.swift
//  Simplified
//
//  Created by Ettore Pasquini on 3/22/21.
//  Copyright © 2021 NYPL. All rights reserved.
//

import XCTest
import NYPLUtilities
@testable import SimplyE

class NYPLBookmarkSpecTests: XCTestCase {
  var bundle: Bundle!

  override func setUpWithError() throws {
    bundle = Bundle(for: NYPLBookmarkSpecTests.self)
  }

  override func tearDownWithError() throws {
    bundle = nil
  }

  func testBookmarkMotivationKeyword() throws {
    XCTAssert(
      NYPLBookmarkSpec.Motivation.bookmark.rawValue
        .contains(NYPLBookmarkSpec.Motivation.bookmarkingKeyword)
    )
  }

  // MARK:- Locators

  func testMakeLocatorFromJSON() throws {
    // preconditions: get expected values from manually reading locator on disk
    let locatorURL = bundle.url(forResource: "valid-locator-0", withExtension: "json")!
    let locatorData = try Data(contentsOf: locatorURL)
    let json = try JSONSerialization.jsonObject(with: locatorData) as! [String: Any]
    let typeValue = json[NYPLBookmarkSpec.Target.Selector.Value.locatorTypeKey] as! String
    let chapterID = json[NYPLBookmarkSpec.Target.Selector.Value.locatorChapterIDKey] as! String
    let progress = Float(json[NYPLBookmarkSpec.Target.Selector.Value.locatorChapterProgressionKey] as! Double)

    // test: make a locator, encode it to binary, parse binary back to JSON
    let madeLocatorString = NYPLReadiumBookmarkFactory
      .makeLocatorString(chapterHref: chapterID, chapterProgression: progress)
    let madeLocatorData = madeLocatorString.data(using: .utf8)!
    let madeJSONObject: Any
    do {
      try madeJSONObject = JSONSerialization.jsonObject(with: madeLocatorData)
    } catch {
      XCTFail("Unable to convert created locator to JSON: \(error)")
      return
    }
    guard let madeJSON = madeJSONObject as? [String: Any] else {
      XCTFail("Cannot cast JSON object to [String: Any]")
      return
    }

    // verify: parsing manually created locator should reveal same info of locator on disk
    let parsedType = madeJSON[NYPLBookmarkSpec.Target.Selector.Value.locatorTypeKey] as? String
    let parsedChapterID = madeJSON[NYPLBookmarkSpec.Target.Selector.Value.locatorChapterIDKey] as? String
    let parsedProgress = madeJSON[NYPLBookmarkSpec.Target.Selector.Value.locatorChapterProgressionKey] as? Double
    XCTAssertNotNil(parsedType)
    XCTAssertNotNil(parsedChapterID)
    XCTAssertNotNil(parsedProgress)
    XCTAssertFalse(parsedType!.isEmpty)
    XCTAssertFalse(parsedChapterID!.isEmpty)
    XCTAssertNotEqual(parsedProgress, 0.0)
    XCTAssertEqual(parsedType, typeValue)
    XCTAssertEqual(parsedChapterID, chapterID)
    XCTAssertEqual(Float(parsedProgress!), progress)
  }

  func testMakeOldFormatLocatorFromJSON() throws {
    // preconditions: get expected values from manually reading locator on disk
    let locatorURL = bundle.url(forResource: "valid-locator-1", withExtension: "json")!
    let locatorData = try Data(contentsOf: locatorURL)
    let json = try JSONSerialization.jsonObject(with: locatorData) as! [String: Any]
    let typeValue = json[NYPLBookmarkSpec.Target.Selector.Value.locatorTypeKey] as! String
    let chapterID = json[NYPLBookmarkR1Key.idref.rawValue] as! String
    let progress = Float(json[NYPLBookmarkSpec.Target.Selector.Value.locatorChapterProgressionKey] as! Double)
    let cfi = json[NYPLBookmarkSpec.Target.Selector.Value.legacyLocatorCFIKey] as! String

    // test: make a locator, encode it to binary, parse binary back to JSON
    let madeLocatorString = NYPLReadiumBookmarkFactory
      .makeLegacyLocatorString(idref: chapterID,
                               chapterProgression: progress,
                               cfi: cfi)
    let madeLocatorData = madeLocatorString.data(using: .utf8)!
    let madeJSONObj: Any
    do {
      try madeJSONObj = JSONSerialization.jsonObject(with: madeLocatorData)
    } catch {
      XCTFail("Unable to convert created locator to JSON: \(error)")
      return
    }
    guard let madeJSON = madeJSONObj as? [String: Any] else {
      XCTFail("Cannot cast JSON object to [String: Any]")
      return
    }

    // verify: parsing manually created locator should reveal same info of locator on disk
    let parsedType = madeJSON[NYPLBookmarkSpec.Target.Selector.Value.locatorTypeKey] as? String
    let parsedChapterID = madeJSON[NYPLBookmarkR1Key.idref.rawValue] as? String
    let parsedProgress = madeJSON[NYPLBookmarkSpec.Target.Selector.Value.locatorChapterProgressionKey] as? Float
    let parsedCFI = madeJSON[NYPLBookmarkSpec.Target.Selector.Value.legacyLocatorCFIKey] as? String
    XCTAssertNotNil(parsedType)
    XCTAssertNotNil(parsedChapterID)
    XCTAssertNotNil(parsedProgress)
    XCTAssertNotNil(parsedCFI)
    XCTAssertFalse(parsedType!.isEmpty)
    XCTAssertFalse(parsedChapterID!.isEmpty)
    XCTAssertNotEqual(parsedProgress, 0.0)
    XCTAssertFalse(parsedCFI!.isEmpty)
    XCTAssertEqual(parsedType!, typeValue)
    XCTAssertEqual(parsedChapterID!, chapterID)
    XCTAssertEqual(Float(parsedProgress!), progress)
    XCTAssertEqual(parsedCFI!, cfi)
  }

  func testInvalidLocatorNegativeProgressFromJSON() throws {
    // preconditions: get expected values from manually reading locator on disk
    let locatorURL = bundle.url(forResource: "invalid-locator-3", withExtension: "json")!
    let locatorData = try Data(contentsOf: locatorURL)
    let json = try JSONSerialization.jsonObject(with: locatorData) as! [String: Any]
    let chapterID = json[NYPLBookmarkSpec.Target.Selector.Value.locatorChapterIDKey] as! String
    let progress = Float(json[NYPLBookmarkSpec.Target.Selector.Value.locatorChapterProgressionKey] as! Double)
    XCTAssertLessThan(progress, 0.0)

    // test
    let madeLocatorString = NYPLReadiumBookmarkFactory
      .makeLocatorString(chapterHref: chapterID, chapterProgression: progress)

    // verify
    let madeLocatorData = madeLocatorString.data(using: .utf8)!
    let madeJSONObject: Any
    do {
      try madeJSONObject = JSONSerialization.jsonObject(with: madeLocatorData)
    } catch {
      XCTFail("Unable to convert created locator to JSON: \(error)")
      return
    }
    guard let madeJSON = madeJSONObject as? [String: Any] else {
      XCTFail("Cannot cast JSON object to [String: Any]")
      return
    }

    // verify: parsing manually created locator should reveal same info of locator on disk
    let parsedChapterID = madeJSON[NYPLBookmarkSpec.Target.Selector.Value.locatorChapterIDKey] as? String
    let parsedProgress = madeJSON[NYPLBookmarkSpec.Target.Selector.Value.locatorChapterProgressionKey] as? Double
    XCTAssertEqual(parsedChapterID, chapterID)
    XCTAssertEqual(parsedProgress, 0.0)
    XCTAssertEqual(Float(parsedProgress!), 0.0)
  }

  func testInvalidLocatorTooBigProgressFromJSON() throws {
    // preconditions: get expected values from manually reading locator on disk
    let locatorURL = bundle.url(forResource: "invalid-locator-4", withExtension: "json")!
    let locatorData = try Data(contentsOf: locatorURL)
    let json = try JSONSerialization.jsonObject(with: locatorData) as! [String: Any]
    let chapterID = json[NYPLBookmarkSpec.Target.Selector.Value.locatorChapterIDKey] as! String
    let progress = json[NYPLBookmarkSpec.Target.Selector.Value.locatorChapterProgressionKey] as! Float
    XCTAssertGreaterThan(progress, 1.0)

    // test
    let madeLocatorString = NYPLReadiumBookmarkFactory
      .makeLocatorString(chapterHref: chapterID, chapterProgression: progress)

    // verify
    let madeLocatorData = madeLocatorString.data(using: .utf8)!
    let madeJSONObject: Any
    do {
      try madeJSONObject = JSONSerialization.jsonObject(with: madeLocatorData)
    } catch {
      XCTFail("Unable to convert created locator to JSON: \(error)")
      return
    }
    guard let madeJSON = madeJSONObject as? [String: Any] else {
      XCTFail("Cannot cast JSON object to [String: Any]")
      return
    }

    // verify: parsing manually created locator should reveal same info of locator on disk
    let parsedChapterID = madeJSON[NYPLBookmarkSpec.Target.Selector.Value.locatorChapterIDKey] as? String
    let parsedProgress = madeJSON[NYPLBookmarkSpec.Target.Selector.Value.locatorChapterProgressionKey] as? Double
    XCTAssertEqual(parsedChapterID, chapterID)
    XCTAssertEqual(parsedProgress, 1.0)
    XCTAssertEqual(Float(parsedProgress!), 1.0)
  }
}
