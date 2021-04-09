//
//  NYPLReaderBookmarkBusinessLogicTests.swift
//  SimplyETests
//
//  Created by Ernest Fan on 2020-10-29.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import XCTest
import R2Shared
@testable import SimplyE

class NYPLReaderBookmarksBusinessLogicTests: XCTestCase {
    var bookmarkBusinessLogic: NYPLReaderBookmarksBusinessLogic!
    var bookRegistryMock: NYPLBookRegistryMock!
    var libraryAccountMock: NYPLLibraryAccountMock!
    var bookmarkCounter: Int = 0
    let bookIdentifier = "fakeEpub"
    
    override func setUpWithError() throws {
      try super.setUpWithError()
      
      let emptyUrl = URL.init(fileURLWithPath: "")
      let fakeAcquisition = NYPLOPDSAcquisition.init(
        relation: .generic,
        type: "application/epub+zip",
        hrefURL: emptyUrl,
        indirectAcquisitions: [NYPLOPDSIndirectAcquisition](),
        availability: NYPLOPDSAcquisitionAvailabilityUnlimited.init()
      )
      let fakeBook = NYPLBook.init(
        acquisitions: [fakeAcquisition],
        bookAuthors: [NYPLBookAuthor](),
        categoryStrings: [String](),
        distributor: "",
        identifier: bookIdentifier,
        imageURL: emptyUrl,
        imageThumbnailURL: emptyUrl,
        published: Date.init(),
        publisher: "",
        subtitle: "",
        summary: "",
        title: "",
        updated: Date.init(),
        annotationsURL: emptyUrl,
        analyticsURL: emptyUrl,
        alternateURL: emptyUrl,
        relatedWorksURL: emptyUrl,
        seriesURL: emptyUrl,
        revokeURL: emptyUrl,
        report: emptyUrl
      )
      
      bookRegistryMock = NYPLBookRegistryMock()
      bookRegistryMock.addBook(book: fakeBook, state: .DownloadSuccessful)
      libraryAccountMock = NYPLLibraryAccountMock()
      let manifest = Manifest(metadata: Metadata(title: "fakeMetadata"))
      let pub = Publication(manifest: manifest)
      bookmarkBusinessLogic = NYPLReaderBookmarksBusinessLogic(
        book: fakeBook,
        r2Publication: pub,
        drmDeviceID: "fakeDeviceID",
        bookRegistryProvider: bookRegistryMock,
        currentLibraryAccountProvider: libraryAccountMock)
      bookmarkCounter = 0
    }

    override func tearDownWithError() throws {
      try super.tearDownWithError()
      bookmarkBusinessLogic = nil
      libraryAccountMock = nil
      bookRegistryMock.identifiersToRecords.removeAll()
      bookRegistryMock = nil
      bookmarkCounter = 0
    }

    // MARK: - Test updateLocalBookmarks
    
    func testUpdateLocalBookmarksWithNoLocalBookmarks() throws {
      var serverBookmarks = [NYPLReadiumBookmark]()
        
      // Make sure BookRegistry contains no bookmark
      XCTAssertEqual(bookRegistryMock.readiumBookmarks(forIdentifier: bookIdentifier).count, 0)
      
      guard let firstBookmark = newBookmark(idref: "Intro",
                                          chapter: "1",
                                          progressWithinChapter: 0.1,
                                          progressWithinBook: 0.1) else {
        XCTFail("Failed to create new bookmark")
        return
      }
      serverBookmarks.append(firstBookmark)

      bookmarkBusinessLogic.updateLocalBookmarks(serverBookmarks: serverBookmarks,
                                                 localBookmarks: bookRegistryMock.readiumBookmarks(forIdentifier: bookIdentifier),
                                                 bookmarksFailedToUpload: [NYPLReadiumBookmark]()) {
        XCTAssertEqual(self.bookRegistryMock.readiumBookmarks(forIdentifier: self.bookIdentifier).count, 1)
      }
    }
    
    func testUpdateLocalBookmarksWithDuplicatedLocalBookmarks() throws {
      var serverBookmarks = [NYPLReadiumBookmark]()

      // Make sure BookRegistry contains no bookmark
      XCTAssertEqual(bookRegistryMock.readiumBookmarks(forIdentifier: bookIdentifier).count, 0)
      
      guard let firstBookmark = newBookmark(idref: "Intro",
                                          chapter: "1",
                                          progressWithinChapter: 0.1,
                                          progressWithinBook: 0.1),
        let secondBookmark = newBookmark(idref: "Intro",
                                         chapter: "1",
                                         progressWithinChapter: 0.2,
                                         progressWithinBook: 0.1) else {
        XCTFail("Failed to create new bookmark")
        return
      }
        
      serverBookmarks.append(firstBookmark)
      serverBookmarks.append(secondBookmark)
      bookRegistryMock.add(firstBookmark, forIdentifier: bookIdentifier)
      XCTAssertEqual(self.bookRegistryMock.readiumBookmarks(forIdentifier: self.bookIdentifier).count, 1)

      // There are one duplicated bookmark and one non-synced (server) bookmark
      bookmarkBusinessLogic.updateLocalBookmarks(serverBookmarks: serverBookmarks,
                                                 localBookmarks: bookRegistryMock.readiumBookmarks(forIdentifier: self.bookIdentifier),
                                                 bookmarksFailedToUpload: [NYPLReadiumBookmark]()) {
        XCTAssertEqual(self.bookRegistryMock.readiumBookmarks(forIdentifier: self.bookIdentifier).count, 2)
      }
    }
    
    func testUpdateLocalBookmarksWithExtraLocalBookmarks() throws {
      var serverBookmarks = [NYPLReadiumBookmark]()

      // Make sure BookRegistry contains no bookmark
      XCTAssertEqual(bookRegistryMock.readiumBookmarks(forIdentifier: bookIdentifier).count, 0)
      
      guard let firstBookmark = newBookmark(idref: "Intro",
                                          chapter: "1",
                                          progressWithinChapter: 0.1,
                                          progressWithinBook: 0.1),
        let secondBookmark = newBookmark(idref: "Intro",
                                         chapter: "1",
                                         progressWithinChapter: 0.2,
                                         progressWithinBook: 0.1) else {
        XCTFail("Failed to create new bookmark")
        return
      }
        
      serverBookmarks.append(firstBookmark)
      bookRegistryMock.add(firstBookmark, forIdentifier: bookIdentifier)
      bookRegistryMock.add(secondBookmark, forIdentifier: bookIdentifier)
      XCTAssertEqual(self.bookRegistryMock.readiumBookmarks(forIdentifier: self.bookIdentifier).count, 2)

      // There are one duplicated bookmark and one extra (local) bookmark,
      // which means it has been delete from another device and should be removed locally
      bookmarkBusinessLogic.updateLocalBookmarks(serverBookmarks: serverBookmarks,
                                                 localBookmarks: bookRegistryMock.readiumBookmarks(forIdentifier: self.bookIdentifier),
                                                 bookmarksFailedToUpload: [NYPLReadiumBookmark]()) {
        XCTAssertEqual(self.bookRegistryMock.readiumBookmarks(forIdentifier: self.bookIdentifier).count, 1)
      }
    }
    
    func testUpdateLocalBookmarksWithFailedUploadBookmarks() throws {
      var serverBookmarks = [NYPLReadiumBookmark]()

      // Make sure BookRegistry contains no bookmark
      XCTAssertEqual(bookRegistryMock.readiumBookmarks(forIdentifier: bookIdentifier).count, 0)
      
      guard let firstBookmark = newBookmark(idref: "Intro",
                                          chapter: "1",
                                          progressWithinChapter: 0.1,
                                          progressWithinBook: 0.1),
        let secondBookmark = newBookmark(idref: "Intro",
                                         chapter: "1",
                                         progressWithinChapter: 0.2,
                                         progressWithinBook: 0.1) else {
        XCTFail("Failed to create new bookmark")
        return
      }
        
      serverBookmarks.append(firstBookmark)
      bookRegistryMock.add(firstBookmark, forIdentifier: bookIdentifier)
      XCTAssertEqual(self.bookRegistryMock.readiumBookmarks(forIdentifier: self.bookIdentifier).count, 1)
        
      // There are one duplicated bookmark and one failed-to-upload bookmark
      bookmarkBusinessLogic.updateLocalBookmarks(serverBookmarks: serverBookmarks,
                                                 localBookmarks: bookRegistryMock.readiumBookmarks(forIdentifier: self.bookIdentifier),
                                                 bookmarksFailedToUpload: [secondBookmark]) {
        XCTAssertEqual(self.bookRegistryMock.readiumBookmarks(forIdentifier: self.bookIdentifier).count, 2)
      }
    }

    // MARK: Helper
    
    func newBookmark(idref: String,
                     chapter: String,
                     progressWithinChapter: Float,
                     progressWithinBook: Float,
                     device: String? = nil) -> NYPLReadiumBookmark? {
      // Annotation id needs to be unique
      // contentCFI should be empty string for R2 bookmark
      bookmarkCounter += 1
      return NYPLReadiumBookmark(annotationId: "fakeAnnotationID\(bookmarkCounter)",
                                 contentCFI: "",
                                 idref: idref,
                                 chapter: chapter,
                                 page: nil,
                                 location: nil,
                                 progressWithinChapter: progressWithinChapter,
                                 progressWithinBook: progressWithinBook,
                                 creationTime: Date(),
                                 device:device)
    }
}
