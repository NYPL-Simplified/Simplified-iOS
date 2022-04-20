//
//  NYPLAnnotationResponseTests.swift
//  Simplified
//
//  Created by Ettore Pasquini on 4/14/21.
//  Copyright © 2021 NYPL. All rights reserved.
//

import XCTest
import R2Shared
@testable import SimplyE

class NYPLAnnotationResponseTests: XCTestCase {
  var bundle: Bundle!
  var responseData: Data!
  var publication: Publication!
  let bookID = "urn:librarysimplified.org/terms/id/book1"

  override func setUpWithError() throws {
    // preconditions
    bundle = Bundle(for: NYPLBookmarkSpecTests.self)
    let annotationResponseURL = bundle.url(forResource: "annotation-response",
                                           withExtension: "json")!
    let annotationData = try Data(contentsOf: annotationResponseURL)
    let json = try JSONSerialization.jsonObject(with: annotationData) as! [String: Any]
    responseData = NYPLAnnotations.makeSubmissionData(fromRepresentation: json)
    publication = NYPLFake.bookmarkSpecPublication
  }

  override func tearDownWithError() throws {
    bundle = nil
    responseData = nil
    publication = nil
  }

  func testParseAnnotationsResponseForReadingProgress() throws {
    // test
    let annotations = NYPLAnnotations.test_parseAnnotationsResponse(
      responseData,
      error: nil,
      motivation: .readingProgress,
      publication: publication,
      bookID: bookID)

    // verify
    XCTAssertNotNil(annotations)
    XCTAssertEqual(annotations!.count, 1)
    let readingProgress = annotations!.first!
    XCTAssertNotNil(readingProgress)
    XCTAssertEqual(readingProgress.timestamp, "2021-04-14T22:49:41Z")
    XCTAssertEqual(readingProgress.device!,
                   "urn:uuid:789166c5-ed87-413a-8d9f-f306f6f02362")
    XCTAssertEqual(readingProgress.annotationId!,
                   "https://circulation.librarysimplified.org/NYNYPL/annotations/3217539")
    XCTAssertEqual(readingProgress.progressWithinChapter, 0.666)
    XCTAssertEqual(readingProgress.href!, "/xyz.html")
  }

  func testParseAnnotationsResponseForBookmarks() throws {
    // test
    let annotations = NYPLAnnotations.test_parseAnnotationsResponse(
      responseData,
      error: nil,
      motivation: .bookmark,
      publication: publication,
      bookID: bookID)

    // verify
    XCTAssertNotNil(annotations)
    XCTAssertEqual(annotations!.count, 1)
    let bookmark = annotations!.first!
    XCTAssertNotNil(bookmark)
    XCTAssertEqual(bookmark.timestamp, "2021-04-14T22:50:04Z")
    XCTAssertEqual(bookmark.device!,
                   "urn:uuid:789166c5-ed87-413a-8d9f-f306f6f02362")
    XCTAssertEqual(bookmark.annotationId!,
                   "https://circulation.librarysimplified.org/NYNYPL/annotations/3217569")
    XCTAssertEqual(bookmark.progressWithinChapter, 0.09090909)
    XCTAssertEqual(bookmark.progressWithinBook, 0.13910505)
    XCTAssertEqual(bookmark.href!, "/xyz.html")
  }
}
