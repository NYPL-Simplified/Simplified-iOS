//
//  NYPLAudiobookBookmarksBusinessLogic.swift
//  Simplified
//
//  Created by Ernest Fan on 2022-08-12.
//  Copyright © 2022 NYPL. All rights reserved.
//

import Foundation
import NYPLAudiobookToolkit

class NYPLAudiobookBookmarksBusinessLogic: NYPLAudiobookBookmarksBusinessLogicDelegate {
  
  // MARK: - Properties
  
  var bookmarks: [NYPLAudiobookBookmark]
  
  let book: NYPLBook
  private let drmDeviceID: String?
  private let bookRegistry: NYPLAudiobookRegistryProvider
  private let currentLibraryAccountProvider: NYPLCurrentLibraryAccountProvider
  private let annotationsSynchronizer: NYPLAnnotationSyncing.Type
  
  var bookmarksCount: Int {
    return bookmarks.count
  }
  
  // MARK: - Init
  
  init(book: NYPLBook,
       drmDeviceID: String?,
       bookRegistryProvider: NYPLAudiobookRegistryProvider,
       currentLibraryAccountProvider: NYPLCurrentLibraryAccountProvider,
       annotationsSynchronizer: NYPLAnnotationSyncing.Type) {
    self.bookmarks = [NYPLAudiobookBookmark]()
    self.book = book
    self.drmDeviceID = drmDeviceID
    self.bookRegistry = bookRegistryProvider
    self.currentLibraryAccountProvider = currentLibraryAccountProvider
    self.annotationsSynchronizer = annotationsSynchronizer
  }
  
  // MARK: - NYPLAudiobookBookmarksBusinessLogicDelegate
  
  func bookmark(at index: Int) -> NYPLAudiobookBookmark? {
    guard index >= 0 && index < bookmarksCount else {
      return nil
    }
    
    return bookmarks[index]
  }
  
  func addAudiobookBookmark(_ chapterLocation: ChapterLocation) {
    // Check if bookmark already existing
    guard bookmarkExisting(at: chapterLocation) == nil else {
      return
    }
    
    // Create audiobook bookmark with given location
    let bookmark = NYPLAudiobookBookmark(chapterLocation: chapterLocation,
                                         device: drmDeviceID,
                                         creationTime: Date())
    
    // Store bookmark to local storage
    bookmarks.append(bookmark)
    bookmarks.sort{ $0 < $1 }
    
    // Upload bookmark to server and store to local storage
    postBookmark(bookmark)
    
    // TODO: Should this function return bookmark for UI update?
  }
  
  func deleteAudiobookBookmark(at index: Int) {
    // Remove bookmark from local storage
    // Check if bookmark has annotationId (uploaded to server)
    // Delete bookmark from server
  }
  
  func syncBookmarks(completion: @escaping (Bool) -> ()) {
    // Check logic from NYPLReadiumBookmarksBusinessLogic
    // Fetch bookmarks from server
    // Filter bookmarks (local, deleted etc.)
    // Update bookmark in business logic
  }
  
  // MARK: - Helper
  
  private func postBookmark(_ bookmark: NYPLAudiobookBookmark) {
    guard
      let currentAccount = currentLibraryAccountProvider.currentAccount,
      let accountDetails = currentAccount.details,
      accountDetails.syncPermissionGranted else {
      self.bookRegistry.addAudiobookBookmark(bookmark, for: book.identifier)
        return
    }
    
    annotationsSynchronizer.postBookmark(bookmark, forBookID: book.identifier) { [weak self] serverAnnotationID in
      Log.info(#function, serverAnnotationID != nil ? "Bookmark upload succeed" : "Bookmark failed to upload")
      guard let self = self else {
        return
      }
      bookmark.annotationId = serverAnnotationID
      self.bookRegistry.addAudiobookBookmark(bookmark, for: self.book.identifier)
    }
  }
  
  /// Verifies if a bookmark exists at the given location.
  /// - Parameter location: The audiobook location to be checked.
  /// - Returns: The bookmark at the given `location` if it exists,
  /// otherwise nil.
  private func bookmarkExisting(at location: ChapterLocation) -> NYPLAudiobookBookmark? {
    return bookmarks.first {
      $0.locationMatches(location)
    }
  }
}

// TODO: Move these extension to NYPLAudiobookToolkit?
// If so, =~= operator needs to be moved to iOS-Utilities

extension NYPLAudiobookBookmark {
  /// Determines if a given chapter location matches the location addressed by this
  /// bookmark.
  ///
  /// - Complexity: O(*1*).
  ///
  /// - Parameters:
  ///   - locator: The object representing the given location in the audiobook
  ///
  /// - Returns: `true` if the chapter location's position matches the bookmark's.
  func locationMatches(_ location: ChapterLocation) -> Bool {
    guard self.audiobookId == location.audiobookID,
          self.chapter == location.number,
          self.part == location.part,
          self.duration == location.duration else {
      return false
    }
    
    return Float(self.time) =~= Float(location.playheadOffset)
  }
}

extension NYPLAudiobookBookmark: Comparable {
  public static func < (lhs: NYPLAudiobookBookmark, rhs: NYPLAudiobookBookmark) -> Bool {
    if lhs.part != rhs.part {
      return lhs.part < rhs.part
    } else if lhs.chapter != rhs.chapter {
      return lhs.chapter < rhs.chapter
    } else {
      return lhs.time < rhs.time
    }
  }
  
  public static func == (lhs: NYPLAudiobookBookmark, rhs: NYPLAudiobookBookmark) -> Bool {
    guard lhs.audiobookId == rhs.audiobookId,
          lhs.chapter == rhs.chapter,
          lhs.part == rhs.part else {
      return false
    }
    
    return Float(lhs.time) =~= Float(rhs.time)
  }
}
