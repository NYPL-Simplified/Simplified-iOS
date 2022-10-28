//
//  NYPLAudiobookBookmarksBusinessLogicTests.swift
//  SimplyETests
//
//  Created by Ernest Fan on 2022-09-29.
//  Copyright © 2022 NYPL. All rights reserved.
//

import XCTest
import NYPLAudiobookToolkit
@testable import SimplyE

class NYPLAudiobookBookmarksBusinessLogicTests: XCTestCase {
  var bookmarkBusinessLogic: NYPLAudiobookBookmarksBusinessLogic!
  var bookRegistryMock: NYPLBookRegistryMock!
  var libraryAccountMock: NYPLLibraryAccountMock!
  var annotationsMock: NYPLAnnotationsMock.Type!
  var bookmarkCounter: Int = 0
  let bookIdentifier = "fakeAudiobook"
  let deviceID = "fakeDeviceID"

  override func setUpWithError() throws {
    try super.setUpWithError()
    
    let emptyUrl = URL.init(fileURLWithPath: "")
    let fakeAcquisition = NYPLOPDSAcquisition.init(
      relation: .generic,
      type: "application/audiobook+zip",
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
    bookmarkBusinessLogic = NYPLAudiobookBookmarksBusinessLogic(book: fakeBook,
                                                                drmDeviceID: deviceID,
                                                                bookRegistryProvider: bookRegistryMock,
                                                                currentLibraryAccountProvider: libraryAccountMock,
                                                                annotationsSynchronizer: annotationsMock)
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
    var serverBookmarks = [NYPLAudiobookBookmark]()
      
    // Make sure BookRegistry contains no bookmark
    XCTAssertEqual(bookRegistryMock.audiobookBookmarks(for: bookIdentifier).count, 0)
    
    guard let firstBookmark = newBookmark(title: "Title",
                                          chapter: 1,
                                          part: 1,
                                          duration: 10.0,
                                          time: 1.0,
                                          audiobookId: bookIdentifier,
                                          device: deviceID) else {
      XCTFail("Failed to create new bookmark")
      return
    }
    serverBookmarks.append(firstBookmark)

    bookmarkBusinessLogic.updateLocalBookmarks(serverBookmarks: serverBookmarks,
                                               localBookmarks: bookRegistryMock.audiobookBookmarks(for: bookIdentifier),
                                               bookmarksFailedToUpload: [NYPLAudiobookBookmark]()) {
      XCTAssertEqual(self.bookRegistryMock.audiobookBookmarks(for: self.bookIdentifier).count, 1)
    }
  }

  func testUpdateLocalBookmarksWithDuplicatedLocalBookmarks() throws {
    var serverBookmarks = [NYPLAudiobookBookmark]()

    // Make sure BookRegistry contains no bookmark
    XCTAssertEqual(bookRegistryMock.audiobookBookmarks(for: bookIdentifier).count, 0)
    
    guard let firstBookmark = newBookmark(title: "Title",
                                          chapter: 1,
                                          part: 1,
                                          duration: 10.0,
                                          time: 1.0,
                                          audiobookId: bookIdentifier,
                                          device: deviceID),
      let secondBookmark = newBookmark(title: "Title",
                                       chapter: 1,
                                       part: 1,
                                       duration: 10.0,
                                       time: 4.0,
                                       audiobookId: bookIdentifier,
                                       device: deviceID) else {
      XCTFail("Failed to create new bookmark")
      return
    }
      
    serverBookmarks.append(firstBookmark)
    serverBookmarks.append(secondBookmark)
    bookRegistryMock.addAudiobookBookmark(firstBookmark, for: bookIdentifier)
    XCTAssertEqual(self.bookRegistryMock.audiobookBookmarks(for: self.bookIdentifier).count, 1)

    // There are one duplicated bookmark and one non-synced (server) bookmark
    bookmarkBusinessLogic.updateLocalBookmarks(serverBookmarks: serverBookmarks,
                                               localBookmarks: bookRegistryMock.audiobookBookmarks(for: self.bookIdentifier),
                                               bookmarksFailedToUpload: [NYPLAudiobookBookmark]()) {
      XCTAssertEqual(self.bookRegistryMock.audiobookBookmarks(for: self.bookIdentifier).count, 2)
    }
  }

  func testUpdateLocalBookmarksWithExtraLocalBookmarks() throws {
    var serverBookmarks = [NYPLAudiobookBookmark]()

    // Make sure BookRegistry contains no bookmark
    XCTAssertEqual(bookRegistryMock.audiobookBookmarks(for: bookIdentifier).count, 0)
    
    guard let firstBookmark = newBookmark(title: "Title",
                                          chapter: 1,
                                          part: 1,
                                          duration: 10.0,
                                          time: 1.0,
                                          audiobookId: bookIdentifier,
                                          device: deviceID),
      let secondBookmark = newBookmark(title: "Title",
                                       chapter: 1,
                                       part: 1,
                                       duration: 10.0,
                                       time: 4.0,
                                       audiobookId: bookIdentifier,
                                       device: deviceID) else {
      XCTFail("Failed to create new bookmark")
      return
    }
      
    serverBookmarks.append(firstBookmark)
    bookRegistryMock.addAudiobookBookmark(firstBookmark, for: bookIdentifier)
    bookRegistryMock.addAudiobookBookmark(secondBookmark, for: bookIdentifier)
    XCTAssertEqual(self.bookRegistryMock.audiobookBookmarks(for: self.bookIdentifier).count, 2)

    // There are one duplicated bookmark and one extra (local) bookmark,
    // which means it has been delete from another device and should be removed locally
    bookmarkBusinessLogic.updateLocalBookmarks(serverBookmarks: serverBookmarks,
                                               localBookmarks: bookRegistryMock.audiobookBookmarks(for: self.bookIdentifier),
                                               bookmarksFailedToUpload: [NYPLAudiobookBookmark]()) {
      XCTAssertEqual(self.bookRegistryMock.audiobookBookmarks(for: self.bookIdentifier).count, 1)
      
      XCTAssertEqual (self.bookRegistryMock.audiobookBookmarks(for: self.bookIdentifier).first, firstBookmark)
    }
  }

  func testUpdateLocalBookmarksWithFailedUploadBookmarks() throws {
    var serverBookmarks = [NYPLAudiobookBookmark]()

    // Make sure BookRegistry contains no bookmark
    XCTAssertEqual(bookRegistryMock.audiobookBookmarks(for: bookIdentifier).count, 0)
    
    guard let firstBookmark = newBookmark(title: "Title",
                                          chapter: 1,
                                          part: 1,
                                          duration: 10.0,
                                          time: 1.0,
                                          audiobookId: bookIdentifier,
                                          device: deviceID),
      let secondBookmark = newBookmark(title: "Title",
                                       chapter: 1,
                                       part: 1,
                                       duration: 10.0,
                                       time: 3.0,
                                       audiobookId: bookIdentifier,
                                       device: deviceID) else {
      XCTFail("Failed to create new bookmark")
      return
    }
      
    serverBookmarks.append(firstBookmark)
    bookRegistryMock.addAudiobookBookmark(firstBookmark, for: bookIdentifier)
    XCTAssertEqual(self.bookRegistryMock.audiobookBookmarks(for: self.bookIdentifier).count, 1)
      
    // There are one duplicated bookmark and one failed-to-upload bookmark
    bookmarkBusinessLogic.updateLocalBookmarks(serverBookmarks: serverBookmarks,
                                               localBookmarks: bookRegistryMock.audiobookBookmarks(for: self.bookIdentifier),
                                               bookmarksFailedToUpload: [secondBookmark]) {
      XCTAssertEqual(self.bookRegistryMock.audiobookBookmarks(for: self.bookIdentifier).count, 2)
    }
  }

  // MARK: - Test addBookmark/postBookmark

  func testAddBookmarkWithSucceededUpload() throws {
    // Make sure server contains no bookmark
    annotationsMock.getServerBookmarks(of: NYPLAudiobookBookmark.self,
                                       forBook: bookIdentifier,
                                       publication: nil,
                                       atURL: nil) { bookmarks in
      XCTAssertEqual(bookmarks, nil)
    }
    
    
    guard let chapterLocation = ChapterLocation(number: 1, part: 1, duration: 10.0, startOffset: 0, playheadOffset: 1.0, title: "Title", audiobookID: bookIdentifier) else {
      XCTFail("Failed to create chapter location")
      return
    }
    bookmarkBusinessLogic.addAudiobookBookmark(chapterLocation)
    
    // There should be one bookmark uploaded
    XCTAssertEqual(self.bookRegistryMock.audiobookBookmarks(for: self.bookIdentifier).count, 1)
    annotationsMock.getServerBookmarks(of: NYPLAudiobookBookmark.self,
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
    annotationsMock.getServerBookmarks(of: NYPLAudiobookBookmark.self,
                                       forBook: bookIdentifier,
                                       publication: nil,
                                       atURL: nil) { bookmarks in
      XCTAssertEqual(bookmarks, nil)
    }
    
    annotationsMock.failRequest = true
    guard let chapterLocation = ChapterLocation(number: 1, part: 1, duration: 10.0, startOffset: 0, playheadOffset: 1.0, title: "Title", audiobookID: bookIdentifier) else {
      XCTFail("Failed to create chapter location")
      return
    }
    
    // BookRegistry should have one bookmark even upload failed
    // While server should not have any bookmarks
    bookmarkBusinessLogic.addAudiobookBookmark(chapterLocation)
    XCTAssertEqual(self.bookRegistryMock.audiobookBookmarks(for: self.bookIdentifier).count, 1)
    
    annotationsMock.failRequest = false
    annotationsMock.getServerBookmarks(of: NYPLAudiobookBookmark.self,
                                       forBook: bookIdentifier,
                                       publication: nil,
                                       atURL: nil) { bookmarks in
      XCTAssertEqual(bookmarks, nil)
    }
  }
  
  func testAddBookmarkWithNotDuplicatedBookmarks() throws {
    XCTAssertEqual(bookmarkBusinessLogic.bookmarksCount, 0)
    
    guard let firstChapterLocation = ChapterLocation(number: 1, part: 1, duration: 10.0, startOffset: 0, playheadOffset: 1.0, title: "Title", audiobookID: bookIdentifier) else {
      XCTFail("Failed to create chapter location")
      return
    }
    bookmarkBusinessLogic.addAudiobookBookmark(firstChapterLocation)
    XCTAssertEqual(bookmarkBusinessLogic.bookmarksCount, 1)
    
    // Adding bookmark with exact same chapter location
    bookmarkBusinessLogic.addAudiobookBookmark(firstChapterLocation)
    XCTAssertEqual(bookmarkBusinessLogic.bookmarksCount, 1)
    
    guard let secondChapterLocation = ChapterLocation(number: 1, part: 2, duration: 50.0, startOffset: 0, playheadOffset: 15.0, title: "Title", audiobookID: bookIdentifier),
          let secondDuplicatedChapterLocation = ChapterLocation(number: 1, part: 2, duration: 50.0, startOffset: 0, playheadOffset: 18.1, title: "Title", audiobookID: bookIdentifier) else {
      XCTFail("Failed to create chapter location")
      return
    }
    bookmarkBusinessLogic.addAudiobookBookmark(secondChapterLocation)
    XCTAssertEqual(bookmarkBusinessLogic.bookmarksCount, 2)
    
    // Adding bookmark with matching chapter location and >3s difference (considered as different bookmark)
    bookmarkBusinessLogic.addAudiobookBookmark(secondDuplicatedChapterLocation)
    XCTAssertEqual(bookmarkBusinessLogic.bookmarksCount, 3)
    
    guard let thirdChapterLocation = ChapterLocation(number: 1, part: 3, duration: 70.0, startOffset: 0, playheadOffset: 35.0, title: "Title", audiobookID: bookIdentifier),
          let thirdDuplicatedChapterLocation = ChapterLocation(number: 1, part: 3, duration: 70.0, startOffset: 0, playheadOffset: 31.9, title: "Title", audiobookID: bookIdentifier) else {
      XCTFail("Failed to create chapter location")
      return
    }
    bookmarkBusinessLogic.addAudiobookBookmark(thirdChapterLocation)
    XCTAssertEqual(bookmarkBusinessLogic.bookmarksCount, 4)
    
    // Adding bookmark with matching chapter location and >3s difference in backward direction (considered as different bookmark)
    bookmarkBusinessLogic.addAudiobookBookmark(thirdDuplicatedChapterLocation)
    XCTAssertEqual(bookmarkBusinessLogic.bookmarksCount, 5)
  }
  
  func testAddBookmarkWithDuplicatedBookmarks() throws {
    XCTAssertEqual(bookmarkBusinessLogic.bookmarksCount, 0)
    
    guard let firstChapterLocation = ChapterLocation(number: 1, part: 1, duration: 10.0, startOffset: 0, playheadOffset: 1.0, title: "Title", audiobookID: bookIdentifier) else {
      XCTFail("Failed to create chapter location")
      return
    }
    bookmarkBusinessLogic.addAudiobookBookmark(firstChapterLocation)
    XCTAssertEqual(bookmarkBusinessLogic.bookmarksCount, 1)
    
    // Adding bookmark with same chapter location
    bookmarkBusinessLogic.addAudiobookBookmark(firstChapterLocation)
    XCTAssertEqual(bookmarkBusinessLogic.bookmarksCount, 1)
    
    guard let secondChapterLocation = ChapterLocation(number: 1, part: 2, duration: 50.0, startOffset: 0, playheadOffset: 15.0, title: "Title", audiobookID: bookIdentifier),
          let secondDuplicatedChapterLocation = ChapterLocation(number: 1, part: 2, duration: 50.0, startOffset: 0, playheadOffset: 17.9, title: "Title", audiobookID: bookIdentifier) else {
      XCTFail("Failed to create chapter location")
      return
    }
    bookmarkBusinessLogic.addAudiobookBookmark(secondChapterLocation)
    XCTAssertEqual(bookmarkBusinessLogic.bookmarksCount, 2)
    
    // Adding bookmark with matching chapter location and offset difference smaller than 3s (considered as same bookmark)
    bookmarkBusinessLogic.addAudiobookBookmark(secondDuplicatedChapterLocation)
    XCTAssertEqual(bookmarkBusinessLogic.bookmarksCount, 2)
    
    guard let thirdChapterLocation = ChapterLocation(number: 1, part: 3, duration: 70.0, startOffset: 0, playheadOffset: 35.0, title: "Title", audiobookID: bookIdentifier),
          let thirdDuplicatedChapterLocation = ChapterLocation(number: 1, part: 3, duration: 70.0, startOffset: 0, playheadOffset: 32.1, title: "Title", audiobookID: bookIdentifier) else {
      XCTFail("Failed to create chapter location")
      return
    }
    bookmarkBusinessLogic.addAudiobookBookmark(thirdChapterLocation)
    XCTAssertEqual(bookmarkBusinessLogic.bookmarksCount, 3)
    
    // Adding bookmark with matching chapter location and offset difference smaller than 3s in backward direction (considered as same bookmark)
    bookmarkBusinessLogic.addAudiobookBookmark(thirdDuplicatedChapterLocation)
    XCTAssertEqual(bookmarkBusinessLogic.bookmarksCount, 3)
  }

  // MARK: - Test deleteBookmark/didDeleteBookmark
  
  func testDeleteBookmarkWithValidIndex() throws {
    
    guard let firstChapterLocation = ChapterLocation(number: 1, part: 1, duration: 10.0, startOffset: 0, playheadOffset: 1.0, title: "Title", audiobookID: bookIdentifier) else {
      XCTFail("Failed to create chapter location")
      return
    }
    bookmarkBusinessLogic.addAudiobookBookmark(firstChapterLocation)
    
    guard let secondChapterLocation = ChapterLocation(number: 1, part: 2, duration: 50.0, startOffset: 0, playheadOffset: 15.0, title: "Title", audiobookID: bookIdentifier) else {
      XCTFail("Failed to create chapter location")
      return
    }
    bookmarkBusinessLogic.addAudiobookBookmark(secondChapterLocation)
    
    // Make sure we have the right amount of bookmarks in BookRegistry
    XCTAssertEqual(self.bookRegistryMock.audiobookBookmarks(for: self.bookIdentifier).count, 2)
    
    // Deleting bookmark at index
    XCTAssertEqual(bookmarkBusinessLogic.deleteAudiobookBookmark(at: 1), true)
    
    // BookRegistry should have one bookmark after deletion
    // Server should not contain the deleted bookmark
    XCTAssertEqual(self.bookRegistryMock.audiobookBookmarks(for: self.bookIdentifier).count, 1)
    annotationsMock.getServerBookmarks(of: NYPLAudiobookBookmark.self,
                                       forBook: bookIdentifier,
                                       publication: nil,
                                       atURL: nil) { bookmarks in
      guard let bookmarks = bookmarks else {
        XCTFail("Failed to get bookmark from server")
        return
      }
      for bookmark in bookmarks {
        if bookmark.locationMatches(secondChapterLocation) {
          XCTFail("Failed to delete bookmark")
        }
      }
    }
  }
  
  func testDeleteBookmarkWithInvalidIndex() throws {
    guard let firstChapterLocation = ChapterLocation(number: 1, part: 1, duration: 10.0, startOffset: 0, playheadOffset: 1.0, title: "Title", audiobookID: bookIdentifier) else {
      XCTFail("Failed to create chapter location")
      return
    }
    bookmarkBusinessLogic.addAudiobookBookmark(firstChapterLocation)
    
    guard let secondChapterLocation = ChapterLocation(number: 1, part: 2, duration: 50.0, startOffset: 0, playheadOffset: 15.0, title: "Title", audiobookID: bookIdentifier) else {
      XCTFail("Failed to create chapter location")
      return
    }
    bookmarkBusinessLogic.addAudiobookBookmark(secondChapterLocation)
    // Make sure we have the right amount of bookmarks in BookRegistry
    XCTAssertEqual(self.bookRegistryMock.audiobookBookmarks(for: self.bookIdentifier).count, 2)
    
    // Deleting bookmark at invalid index
    XCTAssertEqual(bookmarkBusinessLogic.deleteAudiobookBookmark(at: -1), false)
    
    // Bookmarks in BookRegistry should remain unchanged
    XCTAssertEqual(self.bookRegistryMock.audiobookBookmarks(for: self.bookIdentifier).count, 2)
    
    // Deleting bookmark at invalid index
    XCTAssertEqual(bookmarkBusinessLogic.deleteAudiobookBookmark(at: 3), false)
    
    // Bookmarks in BookRegistry should remain unchanged
    XCTAssertEqual(self.bookRegistryMock.audiobookBookmarks(for: self.bookIdentifier).count, 2)
  }
  
  func testBookmarkExisting() throws {
    guard let chapterLocation = ChapterLocation(number: 1, part: 1, duration: 10.0, startOffset: 0, playheadOffset: 1.0, title: "Title", audiobookID: bookIdentifier) else {
      XCTFail("Failed to create chapter location")
      return
    }
    
    XCTAssertNil(bookmarkBusinessLogic.bookmarkExisting(at:chapterLocation))
    bookmarkBusinessLogic.addAudiobookBookmark(chapterLocation)
    XCTAssertNotNil(bookmarkBusinessLogic.bookmarkExisting(at:chapterLocation))
    
    XCTAssertEqual(bookmarkBusinessLogic.deleteAudiobookBookmark(at: 0), true)
    XCTAssertNil(bookmarkBusinessLogic.bookmarkExisting(at:chapterLocation))
  }
  
  func testBookmarkIsFirstInChapter() throws {
    guard let firstChapterLocation = ChapterLocation(number: 1, part: 1, duration: 30.0, startOffset: 0, playheadOffset: 1.0, title: "Title", audiobookID: bookIdentifier),
    let secondChapterLocation = ChapterLocation(number: 1, part: 1, duration: 30.0, startOffset: 0, playheadOffset: 5.0, title: "Title", audiobookID: bookIdentifier),
    let thirdChapterLocation = ChapterLocation(number: 1, part: 1, duration: 30.0, startOffset: 0, playheadOffset: 10.0, title: "Title", audiobookID: bookIdentifier) else {
      XCTFail("Failed to create chapter location")
      return
    }
    
    bookmarkBusinessLogic.addAudiobookBookmark(firstChapterLocation)
    bookmarkBusinessLogic.addAudiobookBookmark(secondChapterLocation)
    bookmarkBusinessLogic.addAudiobookBookmark(thirdChapterLocation)
    
    guard let firstBookmark = bookmarkBusinessLogic.bookmarkExisting(at: firstChapterLocation),
          let secondBookmark = bookmarkBusinessLogic.bookmarkExisting(at: secondChapterLocation),
          let thirdBookmark = bookmarkBusinessLogic.bookmarkExisting(at: thirdChapterLocation) else {
      XCTFail("Failed to add/retrieve bookmark")
      return
    }
    
    XCTAssertEqual(bookmarkBusinessLogic.bookmarkIsFirstInChapter(firstBookmark), true)
    XCTAssertEqual(bookmarkBusinessLogic.bookmarkIsFirstInChapter(secondBookmark), false)
    XCTAssertEqual(bookmarkBusinessLogic.bookmarkIsFirstInChapter(thirdBookmark), false)
    
    // Delete first bookmark, secondBookmark should now be the first bookmark in the chapter
    XCTAssertNotNil(bookmarkBusinessLogic.deleteAudiobookBookmark(firstBookmark))
    XCTAssertEqual(bookmarkBusinessLogic.bookmarkIsFirstInChapter(firstBookmark), false)
    XCTAssertEqual(bookmarkBusinessLogic.bookmarkIsFirstInChapter(secondBookmark), true)
    XCTAssertEqual(bookmarkBusinessLogic.bookmarkIsFirstInChapter(thirdBookmark), false)
    
    // Delete second bookmark, thirdBookmark should now be the first bookmark in the chapter
    XCTAssertNotNil(bookmarkBusinessLogic.deleteAudiobookBookmark(secondBookmark))
    XCTAssertEqual(bookmarkBusinessLogic.bookmarkIsFirstInChapter(firstBookmark), false)
    XCTAssertEqual(bookmarkBusinessLogic.bookmarkIsFirstInChapter(secondBookmark), false)
    XCTAssertEqual(bookmarkBusinessLogic.bookmarkIsFirstInChapter(thirdBookmark), true)
    
    // Delete third bookmark, there should now be no bookmarks in the chapter
    XCTAssertNotNil(bookmarkBusinessLogic.deleteAudiobookBookmark(thirdBookmark))
    XCTAssertEqual(bookmarkBusinessLogic.bookmarkIsFirstInChapter(firstBookmark), false)
    XCTAssertEqual(bookmarkBusinessLogic.bookmarkIsFirstInChapter(secondBookmark), false)
    XCTAssertEqual(bookmarkBusinessLogic.bookmarkIsFirstInChapter(thirdBookmark), false)

  }
  
  // MARK: Helper

  private func newBookmark(title: String? = nil,
                           chapter: UInt,
                           part: UInt,
                           duration: TimeInterval,
                           time: TimeInterval,
                           audiobookId: String,
                           device: String? = nil) -> NYPLAudiobookBookmark? {
    // Annotation id needs to be unique
    bookmarkCounter += 1
    return NYPLAudiobookBookmark(title: title,
                                 chapter: chapter,
                                 part: part,
                                 duration: duration,
                                 time: time,
                                 audiobookId: audiobookId,
                                 annotationId: "fakeAnnotationID\(bookmarkCounter)",
                                 device: device,
                                 creationTime: Date())
  }
}
