//
//  NYPLBookmarkSpec+AudiobookTests.swift
//  SimplyETests
//
//  Created by Ernest Fan on 2022-08-24.
//  Copyright © 2022 NYPL. All rights reserved.
//

import XCTest
import NYPLUtilities
import NYPLAudiobookToolkit
@testable import SimplyE

class NYPLBookmarkSpec_AudiobookTests: XCTestCase {
  var bundle: Bundle!

  override func setUpWithError() throws {
    bundle = Bundle(for: NYPLBookmarkSpec_AudiobookTests.self)
  }

  override func tearDownWithError() throws {
    bundle = nil
  }

  func testMakeAudiobookLocatorFromJSON() throws {
    // preconditions: get expected values from manually reading locator on disk
    let locatorURL = bundle.url(forResource: "valid-locator-3", withExtension: "json")!
    let locatorData = try Data(contentsOf: locatorURL)
    let json = try JSONSerialization.jsonObject(with: locatorData) as! [String: Any]
    let typeValue = json[NYPLBookmarkSpec.Target.Selector.Value.locatorTypeKey] as! String
    let title = json[NYPLBookmarkSpec.Target.Selector.Value.audiobookLocatorTitleKey] as! String
    let audiobookId = json[NYPLBookmarkSpec.Target.Selector.Value.audiobookLocatorBookIDKey] as! String
    let chapter = json[NYPLBookmarkSpec.Target.Selector.Value.audiobookLocatorChapterKey] as! Int
    let part = json[NYPLBookmarkSpec.Target.Selector.Value.audiobookLocatorPartKey] as! Int
    let duration = json[NYPLBookmarkSpec.Target.Selector.Value.audiobookLocatorDurationKey] as! Double
    let offset = json[NYPLBookmarkSpec.Target.Selector.Value.audiobookLocatorOffsetKey] as! Double

    // test: make a locator, encode it to binary, parse binary back to JSON
    let madeLocatorString = NYPLAudiobookBookmarkFactory.makeLocatorString(title: title,
                                                                           part: part,
                                                                           chapter: chapter,
                                                                           audiobookId: audiobookId,
                                                                           duration: duration,
                                                                           time: offset)
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
    let parsedTitle = madeJSON[NYPLBookmarkSpec.Target.Selector.Value.audiobookLocatorTitleKey] as? String
    let parsedAudiobookId = madeJSON[NYPLBookmarkSpec.Target.Selector.Value.audiobookLocatorBookIDKey] as? String
    let parsedChapter = madeJSON[NYPLBookmarkSpec.Target.Selector.Value.audiobookLocatorChapterKey] as? Int
    let parsedPart = madeJSON[NYPLBookmarkSpec.Target.Selector.Value.audiobookLocatorPartKey] as? Int
    let parsedDuration = madeJSON[NYPLBookmarkSpec.Target.Selector.Value.audiobookLocatorDurationKey] as? Double
    let parsedOffset = madeJSON[NYPLBookmarkSpec.Target.Selector.Value.audiobookLocatorOffsetKey] as? Double
    XCTAssertNotNil(parsedType)
    XCTAssertNotNil(parsedTitle)
    XCTAssertNotNil(parsedAudiobookId)
    XCTAssertFalse(parsedType!.isEmpty)
    XCTAssertFalse(parsedTitle!.isEmpty)
    XCTAssertFalse(parsedAudiobookId!.isEmpty)
    
    XCTAssertEqual(parsedType, typeValue)
    XCTAssertEqual(parsedAudiobookId, audiobookId)
    XCTAssertEqual(parsedChapter, chapter)
    XCTAssertEqual(parsedPart, part)
    XCTAssertEqual(parsedDuration, duration)
    XCTAssertEqual(parsedOffset, offset)
  }
  
  func testInvalidAudiobookLocatorNegativeChapterFromJSON() throws {
    // preconditions: get expected values from manually reading locator on disk
    let locatorURL = bundle.url(forResource: "invalid-locator-5", withExtension: "json")!
    let locatorData = try Data(contentsOf: locatorURL)
    let json = try JSONSerialization.jsonObject(with: locatorData) as! [String: Any]
    let typeValue = json[NYPLBookmarkSpec.Target.Selector.Value.locatorTypeKey] as! String
    let title = json[NYPLBookmarkSpec.Target.Selector.Value.audiobookLocatorTitleKey] as! String
    let audiobookId = json[NYPLBookmarkSpec.Target.Selector.Value.audiobookLocatorBookIDKey] as! String
    let chapter = json[NYPLBookmarkSpec.Target.Selector.Value.audiobookLocatorChapterKey] as! Int
    let part = json[NYPLBookmarkSpec.Target.Selector.Value.audiobookLocatorPartKey] as! Int
    let duration = json[NYPLBookmarkSpec.Target.Selector.Value.audiobookLocatorDurationKey] as! Double
    let offset = json[NYPLBookmarkSpec.Target.Selector.Value.audiobookLocatorOffsetKey] as! Double
    XCTAssertLessThan(chapter, 0)

    // test: make a locator, encode it to binary, parse binary back to JSON
    let madeLocatorString = NYPLAudiobookBookmarkFactory.makeLocatorString(title: title,
                                                                           part: part,
                                                                           chapter: chapter,
                                                                           audiobookId: audiobookId,
                                                                           duration: duration,
                                                                           time: offset)
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
    let parsedTitle = madeJSON[NYPLBookmarkSpec.Target.Selector.Value.audiobookLocatorTitleKey] as? String
    let parsedAudiobookId = madeJSON[NYPLBookmarkSpec.Target.Selector.Value.audiobookLocatorBookIDKey] as? String
    let parsedChapter = madeJSON[NYPLBookmarkSpec.Target.Selector.Value.audiobookLocatorChapterKey] as? Int
    let parsedPart = madeJSON[NYPLBookmarkSpec.Target.Selector.Value.audiobookLocatorPartKey] as? Int
    let parsedDuration = madeJSON[NYPLBookmarkSpec.Target.Selector.Value.audiobookLocatorDurationKey] as? Double
    let parsedOffset = madeJSON[NYPLBookmarkSpec.Target.Selector.Value.audiobookLocatorOffsetKey] as? Double
    XCTAssertNotNil(parsedType)
    XCTAssertNotNil(parsedTitle)
    XCTAssertNotNil(parsedAudiobookId)
    XCTAssertFalse(parsedType!.isEmpty)
    XCTAssertFalse(parsedTitle!.isEmpty)
    XCTAssertFalse(parsedAudiobookId!.isEmpty)
    
    XCTAssertEqual(parsedType, typeValue)
    XCTAssertEqual(parsedAudiobookId, audiobookId)
    XCTAssertEqual(parsedChapter, 0)
    XCTAssertEqual(parsedPart, part)
    XCTAssertEqual(parsedDuration, duration)
    XCTAssertEqual(parsedOffset, offset)
  }
}
