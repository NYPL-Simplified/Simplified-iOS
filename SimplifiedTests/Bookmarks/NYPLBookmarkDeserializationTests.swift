//
//  NYPLBookmarkDeserializationTests.swift
//  Simplified
//
//  Created by Ettore Pasquini on 3/31/21.
//  Copyright © 2021 NYPL. All rights reserved.
//

import XCTest
import NYPLUtilities
@testable import SimplyE

class NYPLBookmarkDeserializationTests: XCTestCase {
  var bundle: Bundle!

  override func setUpWithError() throws {
    bundle = Bundle(for: NYPLBookmarkSpecTests.self)
  }

  override func tearDownWithError() throws {
    bundle = nil
  }

  // MARK:- Valid bookmarks tests

  func testMakeBookmarkFromJSON() throws {
    // preconditions: get expected values from manually reading from disk
    let bookmarkURL = bundle.url(forResource: "valid-bookmark-3",
                                 withExtension: "json")!
    let bookmarkData = try Data(contentsOf: bookmarkURL)
    let json = try JSONSerialization.jsonObject(with: bookmarkData) as! [String: Any]
    let annotationID = json[NYPLBookmarkSpec.Id.key] as! String
    let body = json[NYPLBookmarkSpec.Body.key] as! [String: Any]
    let device = body[NYPLBookmarkSpec.Body.Device.key] as! String
    let time = body[NYPLBookmarkSpec.Body.Time.key] as! String
    let target = json[NYPLBookmarkSpec.Target.key] as! [String: Any]
    let bookID = target[NYPLBookmarkSpec.Target.Source.key] as! String
    let selector = target[NYPLBookmarkSpec.Target.Selector.key] as! [String: Any]
    let locator = selector[NYPLBookmarkSpec.Target.Selector.Value.key] as! String

    // test: make a bookmark with the data we manually read with the wrong book id
    let wrong1 = NYPLReadiumBookmarkFactory.make(fromServerAnnotation: json,
                                                 annotationType: .bookmark,
                                                 bookID: "ciccio",
                                                 publication: NYPLFake.bookmarkSpecPublication)

    // test: make a bookmark with the data we manually read
    guard let madeBookmark =
      NYPLReadiumBookmarkFactory.make(fromServerAnnotation: json,
                                      annotationType: .bookmark,
                                      bookID: bookID,
                                      publication: NYPLFake.bookmarkSpecPublication) else {
                                        XCTFail("Failed to create bookmark from valid data")
                                        return
    }

    // verify
    XCTAssertNil(wrong1)
    XCTAssertEqual(madeBookmark.annotationId, annotationID)
    XCTAssertEqual(madeBookmark.location.trimmingCharacters(in: .whitespacesAndNewlines),
                   locator.trimmingCharacters(in: .whitespacesAndNewlines))
    XCTAssertEqual(madeBookmark.device, device)
    XCTAssertEqual(madeBookmark.timestamp, time)
    XCTAssertEqual(madeBookmark.progressWithinChapter, 0.666)
    verifyLocator(href: "/xyz.html", chapterProgress: 0.666, forBookmark: madeBookmark)
  }

  func testMakeReadingProgressFromJSON() throws {
    // preconditions: get expected values from manually reading from disk
    let bookmarkURL = bundle.url(forResource: "valid-bookmark-0",
                                 withExtension: "json")!
    let bookmarkData = try Data(contentsOf: bookmarkURL)
    let json = try JSONSerialization.jsonObject(with: bookmarkData) as! [String: Any]
    let annotationID = json[NYPLBookmarkSpec.Id.key] as! String
    let body = json[NYPLBookmarkSpec.Body.key] as! [String: Any]
    let device = body[NYPLBookmarkSpec.Body.Device.key] as! String
    let time = body[NYPLBookmarkSpec.Body.Time.key] as! String
    let target = json[NYPLBookmarkSpec.Target.key] as! [String: Any]
    let bookID = target[NYPLBookmarkSpec.Target.Source.key] as! String
    let selector = target[NYPLBookmarkSpec.Target.Selector.key] as! [String: Any]
    let locator = selector[NYPLBookmarkSpec.Target.Selector.Value.key] as! String

    // test: make a bookmark with the data we manually read with the wrong book id
    let wrong1 = NYPLReadiumBookmarkFactory.make(fromServerAnnotation: json,
                                                 annotationType: .readingProgress,
                                                 bookID: "ciccio",
                                                 publication: NYPLFake.bookmarkSpecPublication)

    // test: make a bookmark with the data we manually read
    guard let madeBookmark =
      NYPLReadiumBookmarkFactory.make(fromServerAnnotation: json,
                                      annotationType: .readingProgress,
                                      bookID: bookID,
                                      publication: NYPLFake.bookmarkSpecPublication) else {
                                        XCTFail("Failed to create bookmark from valid data")
                                        return
    }

    // verify
    XCTAssertNil(wrong1)
    XCTAssertEqual(madeBookmark.annotationId, annotationID)
    XCTAssertEqual(madeBookmark.location.trimmingCharacters(in: .whitespacesAndNewlines),
                   locator.trimmingCharacters(in: .whitespacesAndNewlines))
    XCTAssertEqual(madeBookmark.device, device)
    XCTAssertEqual(madeBookmark.timestamp, time)
    XCTAssertEqual(madeBookmark.progressWithinChapter, 0.666)
    verifyLocator(href: "/xyz.html", chapterProgress: 0.666, forBookmark: madeBookmark)
  }

  // MARK:- Invalid bookmarks tests

  func testInvalidNoBodyReadingProgressFromJSON() throws {
    // preconditions: get expected values from manually reading from disk
    let bookmarkURL = bundle.url(forResource: "invalid-bookmark-0",
                                 withExtension: "json")!
    let bookmarkData = try Data(contentsOf: bookmarkURL)
    let json = try JSONSerialization.jsonObject(with: bookmarkData) as! [String: Any]
    let target = json[NYPLBookmarkSpec.Target.key] as! [String: Any]
    let bookID = target[NYPLBookmarkSpec.Target.Source.key] as! String
    let motivation = json[NYPLBookmarkSpec.Motivation.key] as! String
    XCTAssertEqual(motivation, NYPLBookmarkSpec.Motivation.readingProgress.rawValue)

    // test: make a locator with the data we manually read
    let bookmark = NYPLReadiumBookmarkFactory.make(fromServerAnnotation: json,
                                                   annotationType: .readingProgress,
                                                   bookID: bookID,
                                                   publication: NYPLFake.bookmarkSpecPublication)

    // verify
    XCTAssertNil(bookmark, "should not deserialize a Bookmark without a Body section")
  }

  func testInvalidNoMotivationBookmarkFromJSON() throws {
    // preconditions: get expected values from manually reading from disk
    let bookmarkURL = bundle.url(forResource: "invalid-bookmark-1",
                                 withExtension: "json")!
    let bookmarkData = try Data(contentsOf: bookmarkURL)
    let json = try JSONSerialization.jsonObject(with: bookmarkData) as! [String: Any]
    let target = json[NYPLBookmarkSpec.Target.key] as! [String: Any]
    let bookID = target[NYPLBookmarkSpec.Target.Source.key] as! String

    // test: make a locator with the data we manually read
    let bookmark = NYPLReadiumBookmarkFactory.make(fromServerAnnotation: json,
                                                   annotationType: .bookmark,
                                                   bookID: bookID,
                                                   publication: NYPLFake.bookmarkSpecPublication)
    let readingProgress = NYPLReadiumBookmarkFactory.make(fromServerAnnotation: json,
                                                          annotationType: .readingProgress,
                                                          bookID: bookID,
                                                          publication: NYPLFake.bookmarkSpecPublication)

    // verify
    XCTAssertNil(bookmark, "should not deserialize a Bookmark without a Motivation section")
    XCTAssertNil(readingProgress, "should not deserialize a Reading Progress without a Motivation section")
  }

  func testInvalidNoTargetReadingProgressFromJSON() throws {
    // preconditions: get expected values from manually reading from disk
    let bookmarkURL = bundle.url(forResource: "invalid-bookmark-2",
                                 withExtension: "json")!
    let bookmarkData = try Data(contentsOf: bookmarkURL)
    let json = try JSONSerialization.jsonObject(with: bookmarkData) as! [String: Any]
    let target = json[NYPLBookmarkSpec.Target.key]
    XCTAssertNil(target)
    let motivation = json[NYPLBookmarkSpec.Motivation.key] as! String
    XCTAssertEqual(motivation, NYPLBookmarkSpec.Motivation.readingProgress.rawValue)

    // test: make a locator with the data we manually read
    let readingProgress = NYPLReadiumBookmarkFactory.make(fromServerAnnotation: json,
                                                          annotationType: .readingProgress,
                                                          bookID: "A book",
                                                          publication: NYPLFake.bookmarkSpecPublication)

    // verify
    XCTAssertNil(readingProgress, "should not deserialize a Bookmark without a Target section")
  }

  func testInvalidNoSelectorValueReadingProgressFromJSON() throws {
    // preconditions: get expected values from manually reading from disk
    let bookmarkURL = bundle.url(forResource: "invalid-bookmark-4",
                                 withExtension: "json")!
    let bookmarkData = try Data(contentsOf: bookmarkURL)
    let json = try JSONSerialization.jsonObject(with: bookmarkData) as! [String: Any]
    let target = json[NYPLBookmarkSpec.Target.key] as! [String: Any]
    let bookID = target[NYPLBookmarkSpec.Target.Source.key] as! String
    let motivation = json[NYPLBookmarkSpec.Motivation.key] as! String
    XCTAssertEqual(motivation, NYPLBookmarkSpec.Motivation.readingProgress.rawValue)
    let selector = target[NYPLBookmarkSpec.Target.Selector.key] as! [String: Any]
    let selectorValue = selector[NYPLBookmarkSpec.Target.Selector.Value.key] as? String
    XCTAssertEqual(selectorValue?.trimmingCharacters(in: .whitespacesAndNewlines), "{\n [] }")

    // test: make a locator with the data we manually read
    let readingProgress = NYPLReadiumBookmarkFactory.make(fromServerAnnotation: json,
                                                          annotationType: .readingProgress,
                                                          bookID: bookID,
                                                          publication: NYPLFake.bookmarkSpecPublication)

    // verify
    XCTAssertNil(readingProgress, "should not deserialize a Bookmark without a Selector section")
  }

  func testInvalidNoDeviceReadingProgressFromJSON() throws {
    // preconditions: get expected values from manually reading from disk
    let bookmarkURL = bundle.url(forResource: "invalid-bookmark-5",
                                 withExtension: "json")!
    let bookmarkData = try Data(contentsOf: bookmarkURL)
    let json = try JSONSerialization.jsonObject(with: bookmarkData) as! [String: Any]
    let target = json[NYPLBookmarkSpec.Target.key] as! [String: Any]
    let bookID = target[NYPLBookmarkSpec.Target.Source.key] as! String
    let motivation = json[NYPLBookmarkSpec.Motivation.key] as! String
    XCTAssertEqual(motivation, NYPLBookmarkSpec.Motivation.readingProgress.rawValue)
    let body = json[NYPLBookmarkSpec.Body.key] as! [String: Any]
    let device = body[NYPLBookmarkSpec.Body.Device.key]
    XCTAssertNil(device)

    // test: make a locator with the data we manually read
    let bookmark = NYPLReadiumBookmarkFactory.make(fromServerAnnotation: json,
                                                   annotationType: .readingProgress,
                                                   bookID: bookID,
                                                   publication: NYPLFake.bookmarkSpecPublication)

    // verify
    XCTAssertNil(bookmark, "should not deserialize a Bookmark without a Body-device section")
  }

  func testMakeBookmarkFromOnlyEssentialInfo() throws {
    // preconditions: get expected values from manually reading from disk
    let bookmarkURL = bundle.url(forResource: "only-essential-info-bookmark",
                                 withExtension: "json")!
    let bookmarkData = try Data(contentsOf: bookmarkURL)
    let json = try JSONSerialization.jsonObject(with: bookmarkData) as! [String: Any]
    let annotationID = json[NYPLBookmarkSpec.Id.key] as! String
    let body = json[NYPLBookmarkSpec.Body.key] as! [String: Any]
    let device = body[NYPLBookmarkSpec.Body.Device.key] as! String
    let target = json[NYPLBookmarkSpec.Target.key] as! [String: Any]
    let bookID = target[NYPLBookmarkSpec.Target.Source.key] as! String
    XCTAssertNil(body[NYPLBookmarkSpec.Body.Time.key],
                 "Body.time not nil, defeating purpose of unit test")

    // test: make a bookmark with the data we manually read
    guard let madeBookmark =
      NYPLReadiumBookmarkFactory.make(fromServerAnnotation: json,
                                      annotationType: .bookmark,
                                      bookID: bookID,
                                      publication: NYPLFake.bookmarkSpecPublication) else {
                                        XCTFail("Failed to create bookmark from valid data")
                                        return
    }

    // verify
    XCTAssertEqual(madeBookmark.annotationId, annotationID)
    XCTAssert(madeBookmark.location.contains("/xyz.html"))
    XCTAssert(madeBookmark.location.contains("\(madeBookmark.progressWithinChapter)"))
    XCTAssertEqual(madeBookmark.device, device)
    XCTAssertEqual(madeBookmark.href, "/xyz.html")
    XCTAssertEqual(madeBookmark.progressWithinChapter, 0.888)
    verifyLocator(href: "/xyz.html", chapterProgress: 0.888, forBookmark: madeBookmark)
  }

  // MARKL:- Helpers for repeated testing

  private func verifyLocator(href: String,
                             chapterProgress: Float,
                             forBookmark bookmark: NYPLReadiumBookmark) {
    let locatorData = bookmark.location.data(using: .utf8)!
    let jsonObject: Any
    do {
      try jsonObject = JSONSerialization.jsonObject(with: locatorData)
    } catch {
      XCTFail("Unable to convert created selector from created bookmark to JSON: \(error)")
      return
    }
    guard let selectorJSON = jsonObject as? [String: Any] else {
      XCTFail("Cannot cast JSON object to [String: Any]")
      return
    }
    let parsedChapterID = selectorJSON[NYPLBookmarkSpec.Target.Selector.Value.locatorChapterIDKey] as? String
    let parsedProgress = selectorJSON[NYPLBookmarkSpec.Target.Selector.Value.locatorChapterProgressionKey] as? Double
    XCTAssertEqual(parsedChapterID, href)
    XCTAssertEqual(Float(parsedProgress!), chapterProgress)
  }
}
