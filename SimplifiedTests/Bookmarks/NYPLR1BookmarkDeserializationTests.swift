//
//  NYPLR1BookmarkDeserializationTests.swift
//  Simplified
//
//  Created by Ettore Pasquini on 4/7/21.
//  Copyright © 2021 NYPL. All rights reserved.
//

import XCTest
@testable import SimplyE

class NYPLR1BookmarkDeserializationTests: XCTestCase {
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
    let publication = NYPLFake.bookmarkSpecPublication

    // test: make bookmark with the wrong book id or annotation type
    let wrong1 = NYPLBookmarkFactory.make(fromServerAnnotation: json,
                                          annotationType: .bookmark,
                                          bookID: "ciccio",
                                          publication: publication)
    let wrong2 = NYPLBookmarkFactory.make(fromServerAnnotation: json,
                                          annotationType: .readingProgress,
                                          bookID: bookID,
                                          publication: publication)

    // test: make a bookmark with the data we manually read
    guard let madeBookmark =
      NYPLBookmarkFactory.make(fromServerAnnotation: json,
                               annotationType: .bookmark,
                               bookID: bookID,
                               publication: publication) else {
                                XCTFail("Failed to create bookmark from valid data")
                                return
    }

    // verify
    XCTAssertNil(wrong1)
    XCTAssertNil(wrong2)
    XCTAssertEqual(madeBookmark.annotationId, annotationID)
    XCTAssertEqual(madeBookmark.href, "/xyz.html")
    XCTAssert(madeBookmark.location.contains(madeBookmark.href!))
    XCTAssert(madeBookmark.location.contains("0.7471264"))
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
    let motivationRaw = json[NYPLBookmarkSpec.Motivation.key] as! String
    let motivation = NYPLBookmarkSpec.Motivation(rawValue: motivationRaw)!
    let publication = NYPLFake.bookmarkSpecPublication

    // test: make bookmark with the wrong book id or annotation type
    let wrong1 = NYPLBookmarkFactory.make(fromServerAnnotation: json,
                                          annotationType: motivation,
                                          bookID: "ciccio",
                                          publication: publication)
    let wrong2 = NYPLBookmarkFactory.make(fromServerAnnotation: json,
                                          annotationType: .bookmark,
                                          bookID: bookID,
                                          publication: publication)

    // test: make a bookmark with the data we manually read
    guard let madeBookmark =
      NYPLBookmarkFactory.make(fromServerAnnotation: json,
                               annotationType: motivation,
                               bookID: bookID,
                               publication: publication) else {
                                XCTFail("Failed to create bookmark from valid data")
                                return
    }

    // verify
    XCTAssertNil(wrong1)
    XCTAssertNil(wrong2)
    XCTAssertEqual(madeBookmark.annotationId, annotationID)
    XCTAssertEqual(madeBookmark.href, "/xyz.html")
    XCTAssert(madeBookmark.location.contains(madeBookmark.href!))
    XCTAssertEqual(madeBookmark.device, device)
    XCTAssertEqual(madeBookmark.timestamp, time)
    XCTAssertEqual(madeBookmark.idref, "c001")
  }

  // This covers the case of bookmarks retrieved from disk
  func testRestoringFromDictionary() {
    // preconditions
    let bookProgress: Float = 0.3684210479259491
    let chapterProgress: Float = 0.666
    let idref = "mikhail_feminine_sign_text-12"
    let cfi = "/4[mikhail_feminine_sign_text-12]/2/72/1:0"
    let diskRepresentation: [String: Any] = [
      NYPLBookmarkDictionaryRepresentation.annotationIdKey: "https://circulation.librarysimplified.org/NYNYPL/annotations/3195762",
      NYPLBookmarkDictionaryRepresentation.chapterKey: "Current Chapter",
      NYPLBookmarkDictionaryRepresentation.cfiKey: cfi,
      NYPLBookmarkDictionaryRepresentation.deviceKey: "urn:uuid:789166c5-ed87-413a-8d9f-f306f6f02362",
      NYPLBookmarkDictionaryRepresentation.idrefKey: idref,
      NYPLBookmarkDictionaryRepresentation.locationKey: "{\"idref\":\"\(idref)\",\"contentCFI\":\"\(cfi)\"}",
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
    XCTAssert(bookmark.location.contains("\"idref\": \"\(idref)\""))
    XCTAssert(bookmark.location.contains("\"contentCFI\": \"\(cfi)\""))
    XCTAssertEqual(bookmark.progressWithinBook, bookProgress)
    XCTAssertEqual(bookmark.progressWithinChapter, chapterProgress)
    XCTAssertEqual(bookmark.timestamp,
                   diskRepresentation[NYPLBookmarkDictionaryRepresentation.timeKey] as? String)
  }
}
