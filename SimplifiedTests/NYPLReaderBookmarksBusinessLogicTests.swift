//
//  NYPLReaderBookmarkBusinessLogicTests.swift
//  SimplyETests
//
//  Created by Ernest Fan on 2020-10-29.
//  Copyright © 2020 NYPL. All rights reserved.
//

import XCTest
import R2Shared
@testable import SimplyE

class NYPLReaderBookmarksBusinessLogicTests: XCTestCase {
  var bookmarkBusinessLogic: NYPLReaderBookmarksBusinessLogic!
  var bookRegistryMock: NYPLBookRegistryMock!
  var libraryAccountMock: NYPLLibraryAccountMock!
  var annotationsMock: NYPLAnnotationsMock.Type!
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
    libraryAccountMock.currentAccount?.details?.syncPermissionGranted = true
    annotationsMock = NYPLAnnotationsMock.self
    let manifest = Manifest(metadata: Metadata(title: "fakeMetadata"))
    let pub = Publication(manifest: manifest)
    bookmarkBusinessLogic = NYPLReaderBookmarksBusinessLogic(
      book: fakeBook,
      r2Publication: pub,
      drmDeviceID: "fakeDeviceID",
      bookRegistryProvider: bookRegistryMock,
      currentLibraryAccountProvider: libraryAccountMock,
      bookmarksSynchronizer: annotationsMock)
    bookmarkCounter = 0
  }

  override func tearDownWithError() throws {
    try super.tearDownWithError()
    bookmarkBusinessLogic = nil
    libraryAccountMock = nil
    bookRegistryMock.identifiersToRecords.removeAll()
    bookRegistryMock = nil
    bookmarkCounter = 0
    annotationsMock.serverBookmarks.removeAll()
    annotationsMock.readingPositions.removeAll()
    annotationsMock = nil
  }

  // MARK: - Test updateLocalBookmarks

  func testUpdateLocalBookmarksWithNoLocalBookmarks() throws {
    var serverBookmarks = [NYPLReadiumBookmark]()
      
    // Make sure BookRegistry contains no bookmark
    XCTAssertEqual(bookRegistryMock.readiumBookmarks(forIdentifier: bookIdentifier).count, 0)
    
    guard let firstBookmark = newBookmark(href: "Intro",
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
    
    guard let firstBookmark = newBookmark(href: "Intro",
                                          chapter: "1",
                                          progressWithinChapter: 0.1,
                                          progressWithinBook: 0.1),
      let secondBookmark = newBookmark(href: "Intro",
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
    
    guard let firstBookmark = newBookmark(href: "Intro",
                                          chapter: "1",
                                          progressWithinChapter: 0.1,
                                          progressWithinBook: 0.1),
      let secondBookmark = newBookmark(href: "Intro",
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
    
    guard let firstBookmark = newBookmark(href: "Intro",
                                          chapter: "1",
                                          progressWithinChapter: 0.1,
                                          progressWithinBook: 0.1),
      let secondBookmark = newBookmark(href: "Intro",
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

  // MARK: - Test addBookmark/postBookmark

  func testAddBookmarkWithSucceededUpload() throws {
    // Make sure server contains no bookmark
    annotationsMock.getServerBookmarks(of: NYPLReadiumBookmark.self,
                                       forBook: bookIdentifier,
                                       publication: nil,
                                       atURL: nil) { bookmarks in
      XCTAssertEqual(bookmarks, nil)
    }
    
    let bookmarkLoc = newBookmarkR2Location(href: "Intro", chapter: "1", progressWithinChapter: 0.1, progressWithinBook: 0.1)
    guard let _ = bookmarkBusinessLogic.addBookmark(bookmarkLoc) else {
      XCTFail("Failed to create new bookmark")
      return
    }
    
    // There should be one bookmark uploaded
    XCTAssertEqual(self.bookRegistryMock.readiumBookmarks(forIdentifier: self.bookIdentifier).count, 1)
    annotationsMock.getServerBookmarks(of: NYPLReadiumBookmark.self,
                                       forBook: bookIdentifier,
                                       publication: nil,
                                       atURL: nil) { bookmarks in
      guard let bookmarks = bookmarks else {
        XCTFail("Failed to get bookmark from server")
        return
      }
      XCTAssertEqual(bookmarks.count, 1)
    }
  }

  func testAddBookmarkWithFailedUpload() throws {
    // Make sure server contains no bookmark
    annotationsMock.getServerBookmarks(of: NYPLReadiumBookmark.self,
                                       forBook: bookIdentifier,
                                       publication: nil,
                                       atURL: nil) { bookmarks in
      XCTAssertEqual(bookmarks, nil)
    }
    
    let bookmarkLoc = newBookmarkR2Location(href: "Intro", chapter: "1", progressWithinChapter: 0.1, progressWithinBook: 0.1)
    annotationsMock.failRequest = true
    guard let _ = bookmarkBusinessLogic.addBookmark(bookmarkLoc) else {
      XCTFail("Failed to create new bookmark")
      return
    }
    
    // BookRegistry should have one bookmark even upload failed
    // While server should not have any bookmarks
    XCTAssertEqual(self.bookRegistryMock.readiumBookmarks(forIdentifier: self.bookIdentifier).count, 1)
    
    annotationsMock.failRequest = false
    annotationsMock.getServerBookmarks(of: NYPLReadiumBookmark.self,
                                       forBook: bookIdentifier,
                                       publication: nil,
                                       atURL: nil) { bookmarks in
      XCTAssertEqual(bookmarks, nil)
    }
  }
  
  func testAddBookmarkWithDuplicatedBookmarks() throws {
    let firstBookmarkLoc = newBookmarkR2Location(href: "Intro", chapter: "1", progressWithinChapter: 0.1, progressWithinBook: 0.1)
    guard let _ = bookmarkBusinessLogic.addBookmark(firstBookmarkLoc) else {
      XCTFail("Failed to create new bookmark")
      return
    }
    
    // Adding bookmark with duplicated location
    let firstDuplicatedBookmarkLoc = newBookmarkR2Location(href: "Intro", chapter: "1", progressWithinChapter: 0.1, progressWithinBook: 0.1)
    XCTAssertNil(bookmarkBusinessLogic.addBookmark(firstDuplicatedBookmarkLoc))
    
    let secondBookmarkLoc = newBookmarkR2Location(href: "Chapter 1", chapter: "2", progressWithinChapter: 0.1, progressWithinBook: 0.2)
    guard let _ = bookmarkBusinessLogic.addBookmark(secondBookmarkLoc) else {
      XCTFail("Failed to create new bookmark")
      return
    }
    
    // Adding bookmark with matching href and progressWithinChatper
    let secondDuplicatedBookmarkLoc = newBookmarkR2Location(href: "Chapter 1", chapter: "2", progressWithinChapter: 0.1, progressWithinBook: 0.2)
    XCTAssertNil(bookmarkBusinessLogic.addBookmark(secondDuplicatedBookmarkLoc))
  }

  // MARK: - Test deleteBookmark/didDeleteBookmark
  
  func testDeleteBookmarkWithMatchingBookmark() throws {
    let firstBookmarkLoc = newBookmarkR2Location(href: "Intro", chapter: "1", progressWithinChapter: 0.1, progressWithinBook: 0.1)
    guard let firstBookmark = bookmarkBusinessLogic.addBookmark(firstBookmarkLoc) else {
      XCTFail("Failed to create new bookmark")
      return
    }
    
    let secondBookmarkLoc = newBookmarkR2Location(href: "Chapter 1", chapter: "2", progressWithinChapter: 0.1, progressWithinBook: 0.2)
    guard let _ = bookmarkBusinessLogic.addBookmark(secondBookmarkLoc) else {
      XCTFail("Failed to create new bookmark")
      return
    }
    
    // Make sure we have the right amount of bookmarks in BookRegistry
    XCTAssertEqual(self.bookRegistryMock.readiumBookmarks(forIdentifier: self.bookIdentifier).count, 2)
    
    // Deleting one matching bookmark
    bookmarkBusinessLogic.deleteBookmark(firstBookmark)
    
    // BookRegistry should have one bookmark after deletion
    // Server should not contain the deleted bookmark
    XCTAssertEqual(self.bookRegistryMock.readiumBookmarks(forIdentifier: self.bookIdentifier).count, 1)
    annotationsMock.getServerBookmarks(of: NYPLReadiumBookmark.self,
                                       forBook: bookIdentifier,
                                       publication: nil,
                                       atURL: nil) { bookmarks in
      guard let bookmarks = bookmarks else {
        XCTFail("Failed to get bookmark from server")
        return
      }
      XCTAssertFalse(bookmarks.contains(firstBookmark))
    }
  }
  
  func testDeleteBookmarkWithValidIndex() throws {
    let firstBookmarkLoc = newBookmarkR2Location(href: "Intro", chapter: "1", progressWithinChapter: 0.1, progressWithinBook: 0.1)
    guard let _ = bookmarkBusinessLogic.addBookmark(firstBookmarkLoc) else {
      XCTFail("Failed to create new bookmark")
      return
    }
    
    let secondBookmarkLoc = newBookmarkR2Location(href: "Chapter 1", chapter: "2", progressWithinChapter: 0.1, progressWithinBook: 0.2)
    guard let secondBookmark = bookmarkBusinessLogic.addBookmark(secondBookmarkLoc) else {
      XCTFail("Failed to create new bookmark")
      return
    }
    
    // Make sure we have the right amount of bookmarks in BookRegistry
    XCTAssertEqual(self.bookRegistryMock.readiumBookmarks(forIdentifier: self.bookIdentifier).count, 2)
    
    // Deleting bookmark at index
    guard let deletedBookmark = bookmarkBusinessLogic.deleteBookmark(at: 1) else {
      XCTFail("Failed to delete bookmark")
      return
    }
    
    // The deleted bookmark should match the second bookmark
    XCTAssertEqual(secondBookmark, deletedBookmark)
    
    // BookRegistry should have one bookmark after deletion
    // Server should not contain the deleted bookmark
    XCTAssertEqual(self.bookRegistryMock.readiumBookmarks(forIdentifier: self.bookIdentifier).count, 1)
    annotationsMock.getServerBookmarks(of: NYPLReadiumBookmark.self,
                                       forBook: bookIdentifier,
                                       publication: nil,
                                       atURL: nil) { bookmarks in
      guard let bookmarks = bookmarks else {
        XCTFail("Failed to get bookmark from server")
        return
      }
      XCTAssertFalse(bookmarks.contains(deletedBookmark))
    }
  }
  
  func testDeleteBookmarkWithInvalidIndex() throws {
    let firstBookmarkLoc = newBookmarkR2Location(href: "Intro", chapter: "1", progressWithinChapter: 0.1, progressWithinBook: 0.1)
    guard let _ = bookmarkBusinessLogic.addBookmark(firstBookmarkLoc) else {
      XCTFail("Failed to create new bookmark")
      return
    }
    
    let secondBookmarkLoc = newBookmarkR2Location(href: "Chapter 1", chapter: "2", progressWithinChapter: 0.1, progressWithinBook: 0.2)
    guard let _ = bookmarkBusinessLogic.addBookmark(secondBookmarkLoc) else {
      XCTFail("Failed to create new bookmark")
      return
    }
    
    // Make sure we have the right amount of bookmarks in BookRegistry
    XCTAssertEqual(self.bookRegistryMock.readiumBookmarks(forIdentifier: self.bookIdentifier).count, 2)
    
    // Deleting bookmark at invalid index
    if let _ = bookmarkBusinessLogic.deleteBookmark(at: -1) {
      XCTFail("Deleted bookmark at invalid index")
    }
    
    // Bookmarks in BookRegistry should remain unchanged
    XCTAssertEqual(self.bookRegistryMock.readiumBookmarks(forIdentifier: self.bookIdentifier).count, 2)
    
    // Deleting bookmark at invalid index
    if let _ = bookmarkBusinessLogic.deleteBookmark(at: 3) {
      XCTFail("Deleted bookmark at invalid index")
    }
    
    // Bookmarks in BookRegistry should remain unchanged
    XCTAssertEqual(self.bookRegistryMock.readiumBookmarks(forIdentifier: self.bookIdentifier).count, 2)
  }
  
  // MARK: Helper

  private func newBookmark(href: String,
                           chapter: String,
                           progressWithinChapter: Float,
                           progressWithinBook: Float,
                           device: String? = nil) -> NYPLReadiumBookmark? {
    // Annotation id needs to be unique
    // contentCFI should be empty string for R2 bookmark
    bookmarkCounter += 1
    return NYPLReadiumBookmark(annotationId: "fakeAnnotationID\(bookmarkCounter)",
                               contentCFI: "",
                               href: href,
                               idref: nil,
                               chapter: chapter,
                               location: nil,
                               progressWithinChapter: progressWithinChapter,
                               progressWithinBook: NSNumber(value: progressWithinBook),
                               creationTime: Date(),
                               device:device)
  }
    
  private func newBookmarkR2Location(href: String,
                                     chapter: String,
                                     progressWithinChapter: Double,
                                     progressWithinBook: Double) -> NYPLBookmarkR2Location {
    let locations = Locator.Locations(progression: progressWithinChapter, totalProgression: progressWithinBook)
    let locator = Locator(href: href,
                          type: "text/html",
                          locations: locations)
    return NYPLBookmarkR2Location(resourceIndex: 0, locator: locator)
  }
}
