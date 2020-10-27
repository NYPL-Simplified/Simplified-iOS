//
//  NYPLBookCreationTests.swift
//  Simplified
//
//  Created by Ettore Pasquini on 10/27/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import XCTest

class NYPLBookCreationTests: XCTestCase {
  var opdsEntry: NYPLOPDSEntry!
  var opdsEntryMinimal: NYPLOPDSEntry!

  override func setUpWithError() throws {
    try super.setUpWithError()
    self.opdsEntry = NYPLFake.opdsEntry
    self.opdsEntryMinimal = NYPLFake.opdsEntryMinimal
  }

  override func tearDownWithError() throws {
    try super.tearDownWithError()
    self.opdsEntry = nil
    self.opdsEntryMinimal = nil
  }

  func testBookCreationViaDictionary() throws {
    let acquisitions = [NYPLFake.genericAcquisition.dictionaryRepresentation()]

    let book = NYPLBook(dictionary: [
      "acquisitions": acquisitions,
      "categories" : ["Fantasy"],
      "id": "666",
      "title": "The Lord of the Rings",
      "updated": "2020-09-08T09:22:45Z"
    ])
    XCTAssertNotNil(book)
    XCTAssertNotNil(book?.acquisitions)
    XCTAssertNotNil(book?.categoryStrings)
    XCTAssertNotNil(book?.identifier)
    XCTAssertNotNil(book?.title)
    XCTAssertNotNil(book?.updated)

    let bookNoUpdatedDate = NYPLBook(dictionary: [
      "acquisitions": acquisitions,
      "categories" : ["Fantasy"],
      "id": "666",
      "title": "The Lord of the Rings",
    ])
    XCTAssertNil(bookNoUpdatedDate)

    let bookNoTitle = NYPLBook(dictionary: [
      "acquisitions": acquisitions,
      "categories" : ["Fantasy"],
      "id": "666",
      "updated": "2020-09-08T09:22:45Z"
    ])
    XCTAssertNil(bookNoTitle)

    let bookNoId = NYPLBook(dictionary: [
      "acquisitions": acquisitions,
      "categories" : ["Fantasy"],
      "title": "The Lord of the Rings",
      "updated": "2020-09-08T09:22:45Z"
    ])
    XCTAssertNil(bookNoId)

    let bookNoCategories = NYPLBook(dictionary: [
      "acquisitions": acquisitions,
      "id": "666",
      "title": "The Lord of the Rings",
      "updated": "2020-09-08T09:22:45Z"
    ])
    XCTAssertNil(bookNoCategories)

    let bookNoAcquisitions = NYPLBook(dictionary: [
      "categories" : ["Fantasy"],
      "id": "123",
      "title": "The Lord of the Rings",
      "updated": "2020-09-08T09:22:45Z"
    ])
    XCTAssertNil(bookNoAcquisitions)
  }

  func testBookCreationViaFactoryMethod() {
    let bookWithNoCategories = NYPLBook(entry: opdsEntryMinimal)
    XCTAssertNotNil(bookWithNoCategories)
    XCTAssertNotNil(bookWithNoCategories?.acquisitions)
    XCTAssertNotNil(bookWithNoCategories?.categoryStrings)
    XCTAssertNotNil(bookWithNoCategories?.identifier)
    XCTAssertNotNil(bookWithNoCategories?.title)
    XCTAssertNotNil(bookWithNoCategories?.updated)
  }

  // for completeness only. This test is not strictly necessary because the
  // member-wise initializer is not public
  func testBookCreationViaMemberWiseInitializer() {
    let book = NYPLBook(acquisitions: opdsEntry.acquisitions,
                        bookAuthors: nil,
                        categoryStrings: nil,
                        distributor: nil,
                        identifier: "666",
                        imageURL: nil,
                        imageThumbnailURL: nil,
                        published: nil,
                        publisher: nil,
                        subtitle: nil,
                        summary: nil,
                        title: "The Lord of the Rings",
                        updated: Date(),
                        annotationsURL: nil,
                        analyticsURL: nil,
                        alternateURL: nil,
                        relatedWorksURL: nil,
                        seriesURL: nil,
                        revokeURL: nil,
                        report: nil)
    XCTAssertNotNil(book)
    XCTAssertNotNil(book.acquisitions)
    XCTAssertNotNil(book.categoryStrings)
    XCTAssertNotNil(book.identifier)
    XCTAssertNotNil(book.title)
    XCTAssertNotNil(book.updated)
  }
}
