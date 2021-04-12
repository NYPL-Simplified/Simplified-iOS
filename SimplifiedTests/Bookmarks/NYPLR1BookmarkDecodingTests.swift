//
//  NYPLR1BookmarkDecodingTests.swift
//  Simplified
//
//  Created by Ettore Pasquini on 4/7/21.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import XCTest
@testable import SimplyE

class NYPLR1BookmarkDecodingTests: XCTestCase {
  var bundle: Bundle!

  override func setUpWithError() throws {
    bundle = Bundle(for: NYPLBookmarkSpecTests.self)
  }

  override func tearDownWithError() throws {
    bundle = nil
  }

  func testDecodeValidR1Bookmark() throws {
    // preconditions: get expected values from manually reading from disk
    let bookmarkURL = bundle.url(forResource: "valid-R1-bookmark-1",
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

    // test: make bookmark with the wrong book id or annotation type
    let wrong1 = NYPLBookmarkFactory.make(fromServerAnnotation: json,
                                          annotationType: .bookmark,
                                          bookID: "ciccio")
    let wrong2 = NYPLBookmarkFactory.make(fromServerAnnotation: json,
                                          annotationType: .readingProgress,
                                          bookID: bookID)

    // test: make a bookmark with the data we manually read
    guard let madeBookmark =
      NYPLBookmarkFactory.make(fromServerAnnotation: json,
                               annotationType: .bookmark,
                               bookID: bookID) else {
                                XCTFail("Failed to create bookmark from valid data")
                                return
    }

    // verify
    XCTAssertNil(wrong1)
    XCTAssertNil(wrong2)
    XCTAssertEqual(madeBookmark.annotationId, annotationID)
    XCTAssertEqual(madeBookmark.location.trimmingCharacters(in: .whitespacesAndNewlines),
                   locator.trimmingCharacters(in: .whitespacesAndNewlines))
    XCTAssertEqual(madeBookmark.device, device)
    XCTAssertEqual(madeBookmark.timestamp, time)
    XCTAssertEqual(madeBookmark.idref, "c001")
    XCTAssertEqual(madeBookmark.progressWithinChapter, 0.7471264600753784)
    XCTAssertEqual(madeBookmark.progressWithinBook, 0.6000000238418579)
  }

  func testDecodeValidR1ReadingProgress() throws {
    // preconditions: get expected values from manually reading from disk
    let bookmarkURL = bundle.url(forResource: "valid-R1-readingprogress-1",
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
    let motivationRaw = json[NYPLBookmarkSpec.Motivation.key] as! String
    let motivation = NYPLBookmarkSpec.Motivation(rawValue: motivationRaw)!

    // test: make bookmark with the wrong book id or annotation type
    let wrong1 = NYPLBookmarkFactory.make(fromServerAnnotation: json,
                                          annotationType: motivation,
                                          bookID: "ciccio")
    let wrong2 = NYPLBookmarkFactory.make(fromServerAnnotation: json,
                                          annotationType: .bookmark,
                                          bookID: bookID)

    // test: make a bookmark with the data we manually read
    guard let madeBookmark =
      NYPLBookmarkFactory.make(fromServerAnnotation: json,
                               annotationType: motivation,
                               bookID: bookID) else {
                                XCTFail("Failed to create bookmark from valid data")
                                return
    }

    // verify
    XCTAssertNil(wrong1)
    XCTAssertNil(wrong2)
    XCTAssertEqual(madeBookmark.annotationId, annotationID)
    XCTAssertEqual(madeBookmark.location.trimmingCharacters(in: .whitespacesAndNewlines),
                   locator.trimmingCharacters(in: .whitespacesAndNewlines))
    XCTAssertEqual(madeBookmark.device, device)
    XCTAssertEqual(madeBookmark.timestamp, time)
    XCTAssertEqual(madeBookmark.idref, "c001")
    XCTAssertEqual(madeBookmark.contentCFI, "/4/4/638/1:30")
  }

  // This covers the case of bookmarks retrieved from disk
  func testRestoringFromDictionary() {
    // preconditions
    let bookProgress: Float = 0.3684210479259491
    let chapterProgress: Float = 0.666
    let diskRepresentation: [String: Any] = [
      NYPLBookmarkDictionaryRepresentation.annotationIdKey: "https://circulation.librarysimplified.org/NYNYPL/annotations/3195762",
      NYPLBookmarkDictionaryRepresentation.chapterKey: "Current Chapter",
      NYPLBookmarkDictionaryRepresentation.cfiKey: "/4[mikhail_feminine_sign_text-12]/2/72/1:0",
      NYPLBookmarkDictionaryRepresentation.deviceKey: "urn:uuid:789166c5-ed87-413a-8d9f-f306f6f02362",
      NYPLBookmarkDictionaryRepresentation.idrefKey: "mikhail_feminine_sign_text-12",
      NYPLBookmarkDictionaryRepresentation.locationKey: "{\"idref\":\"mikhail_feminine_sign_text-12\",\"contentCFI\":\"/4[mikhail_feminine_sign_text-12]/2/72/1:0\"}",
      NYPLBookmarkDictionaryRepresentation.pageKey: "",
      NYPLBookmarkDictionaryRepresentation.bookProgressKey: NSNumber(value: bookProgress),
      NYPLBookmarkDictionaryRepresentation.chapterProgressKey: NSNumber(value: chapterProgress),
      NYPLBookmarkDictionaryRepresentation.timeKey: "2021-04-07T23:49:14Z",
    ]

    // test
    guard let bookmark = NYPLReadiumBookmark(dictionary: diskRepresentation as NSDictionary) else {
      XCTFail("Failed to create bookmark from disk dictionary representation")
      return
    }

    // verify
    XCTAssertEqual(bookmark.annotationId!,
                   diskRepresentation[NYPLBookmarkDictionaryRepresentation.annotationIdKey] as? String)
    XCTAssertEqual(bookmark.chapter!,
                   diskRepresentation[NYPLBookmarkDictionaryRepresentation.chapterKey] as? String)
    XCTAssertEqual(bookmark.contentCFI!,
                   diskRepresentation[NYPLBookmarkDictionaryRepresentation.cfiKey] as? String)
    XCTAssertEqual(bookmark.device!,
                   diskRepresentation[NYPLBookmarkDictionaryRepresentation.deviceKey] as? String)
    XCTAssertEqual(bookmark.idref,
                   diskRepresentation[NYPLBookmarkDictionaryRepresentation.idrefKey] as? String)
    XCTAssertEqual(bookmark.location,
                   diskRepresentation[NYPLBookmarkDictionaryRepresentation.locationKey] as? String)
    XCTAssertEqual(bookmark.page!,
                   diskRepresentation[NYPLBookmarkDictionaryRepresentation.pageKey] as? String)
    XCTAssertEqual(bookmark.progressWithinBook, bookProgress)
    XCTAssertEqual(bookmark.progressWithinChapter, chapterProgress)
    XCTAssertEqual(bookmark.timestamp,
                   diskRepresentation[NYPLBookmarkDictionaryRepresentation.timeKey] as? String)
  }
}
