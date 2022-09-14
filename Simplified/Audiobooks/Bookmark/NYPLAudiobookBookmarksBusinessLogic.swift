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
  
  /// Delete a bookmark from local storage and server if sync permission is granted
  /// - Parameter index: The index of the bookmark.
  func deleteAudiobookBookmark(at index: Int) {
    guard index >= 0 && index < bookmarks.count else {
      return
    }

    let bookmark = bookmarks.remove(at: index)
    didDeleteBookmark(bookmark)

    // TODO: Should this function return bookmark for UI update?
  }
  
  func syncBookmarks(completion: @escaping (Bool) -> ()) {
    // Check logic from NYPLReadiumBookmarksBusinessLogic
    // Fetch bookmarks from server
    // Filter bookmarks (local, deleted etc.)
    // Update bookmark in business logic
    NYPLReachability.shared()?.reachability(for: NYPLConfiguration.mainFeedURL,
                                            timeoutInternal: 8.0,
                                            handler: { (reachable) in
      guard reachable else {
        self.handleBookmarksSyncFail(message: "Error: host was not reachable for bookmark sync attempt.",
                                     completion: completion)
        return
      }
                    
      Log.debug(#file, "Syncing bookmarks...")
      // First check for and upload any local bookmarks that have never been saved to the server.
      // Wait til that's finished, then download the server's bookmark list and filter out any that can be deleted.
      let localBookmarks = self.bookRegistry.audiobookBookmarks(for: self.book.identifier)
      self.annotationsSynchronizer.uploadLocalBookmarks(localBookmarks, forBook: self.book.identifier) { (bookmarksUploaded, bookmarksFailedToUpload) in
        
        for localBookmark in localBookmarks {
          for uploadedBookmark in bookmarksUploaded {
            if localBookmark.isEqual(uploadedBookmark) {
              self.bookRegistry.replaceAudiobookBookmark(localBookmark,
                                                         with: uploadedBookmark,
                                                         for: self.book.identifier)
            }
          }
        }
        
        self.annotationsSynchronizer.getServerBookmarks(forBook: self.book.identifier,
                                                        publication: nil,
                                                        atURL: self.book.annotationsURL) { serverBookmarks in
          guard let serverBookmarks = serverBookmarks as? [NYPLAudiobookBookmark] else {
            self.handleBookmarksSyncFail(message: "Ending sync without running completion. Returning original list of bookmarks.",
                                         completion: completion)
            return
          }
            
          Log.debug(#file, serverBookmarks.count == 0 ? "No server bookmarks" : "Server bookmarks count: \(serverBookmarks.count)")
          
          self.updateLocalBookmarks(serverBookmarks: serverBookmarks,
                                     localBookmarks: localBookmarks,
                                     bookmarksFailedToUpload: bookmarksFailedToUpload)
          { [weak self] in
            guard let self = self else {
              completion(false)
              return
            }
            self.bookmarks = self.bookRegistry.audiobookBookmarks(for: self.book.identifier)
            completion(true)
          }
        }
      }
      
    })
  }
  
  // MARK: - Helper
  
  /// Store a bookmark to local storage and upload it to server if sync permission is granted
  /// - Parameter bookmark: The bookmark to be stored and uploaded.
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
  
  /// Delete a bookmark from local storage and server if sync permission is granted
  /// - Parameter bookmark: The bookmark to be removed.
  private func didDeleteBookmark(_ bookmark: NYPLAudiobookBookmark) {
    bookRegistry.deleteAudiobookBookmark(bookmark, for: book.identifier)

    guard let currentAccount = currentLibraryAccountProvider.currentAccount,
        let details = currentAccount.details,
        let annotationId = bookmark.annotationId else {
      Log.info(#file, "Delete on Server skipped: Annotation ID did not exist for bookmark.")
      return
    }
    
    if details.syncPermissionGranted && annotationId.count > 0 {
      annotationsSynchronizer.deleteBookmark(annotationId: annotationId) { (success) in
        Log.info(#file, success ?
          "Bookmark successfully deleted" :
          "Failed to delete bookmark from server. Will attempt again on next Sync")
      }
    }
  }
  
  func updateLocalBookmarks(serverBookmarks: [NYPLAudiobookBookmark],
                            localBookmarks: [NYPLAudiobookBookmark],
                            bookmarksFailedToUpload: [NYPLAudiobookBookmark],
                            completion: @escaping () -> ())
  {
    // Bookmarks that are present on the client, and have a corresponding version on the server
    // with matching annotation ID's should be kept on the client.
    var localBookmarksToKeep = [NYPLAudiobookBookmark]()
    // Bookmarks that are present on the server, but not the client, should be added to this
    // client as long as they were not created on this device originally.
    var serverBookmarksToKeep = serverBookmarks
    // Bookmarks present on the server, that were originally created on this device,
    // and are no longer present on the client, should be deleted on the server.
    var serverBookmarksToDelete = [NYPLAudiobookBookmark]()
    
    for serverBookmark in serverBookmarks {
      let matched = localBookmarks.contains{ $0.annotationId == serverBookmark.annotationId }
        
      if matched {
        localBookmarksToKeep.append(serverBookmark)
      }
        
      if let deviceID = serverBookmark.device,
        let drmDeviceID = drmDeviceID,
        deviceID == drmDeviceID
        && !matched
      {
        serverBookmarksToDelete.append(serverBookmark)
        if let indexToRemove = serverBookmarksToKeep.firstIndex(of: serverBookmark) {
          serverBookmarksToKeep.remove(at: indexToRemove)
        }
      }
    }
    
    for localBookmark in localBookmarks {
      if !localBookmarksToKeep.contains(localBookmark) {
        bookRegistry.deleteAudiobookBookmark(localBookmark, for: book.identifier)
      }
    }
    
    var bookmarksToAdd = serverBookmarks + bookmarksFailedToUpload
        
    // Look for duplicates in server and local bookmarks, remove them from bookmarksToAdd
    let duplicatedBookmarks = Set(serverBookmarksToKeep).intersection(Set(localBookmarksToKeep))
    bookmarksToAdd = Array(Set(bookmarksToAdd).subtracting(duplicatedBookmarks))
        
    for bookmark in bookmarksToAdd {
      bookRegistry.addAudiobookBookmark(bookmark, for: book.identifier)
    }
    
    annotationsSynchronizer.deleteBookmarks(serverBookmarksToDelete)
    
    completion()
  }

  private func handleBookmarksSyncFail(message: String,
                                       completion: @escaping (Bool) -> ()) {
    Log.info(#file, message)
    
    bookmarks = self.bookRegistry.audiobookBookmarks(for: book.identifier)
    completion(false)
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
  
  func isEqual(_ object: Any?) -> Bool {
    guard let other = object as? NYPLAudiobookBookmark else {
      return false
    }

    guard self.audiobookId == other.audiobookId,
          self.chapter == other.chapter,
          self.part == other.part else {
      return false
    }
    
    return Float(self.time) =~= Float(other.time)
  }
}

extension NYPLAudiobookBookmark: Comparable, Hashable {
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
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(creationTime)
    hasher.combine(device)
  }
}
