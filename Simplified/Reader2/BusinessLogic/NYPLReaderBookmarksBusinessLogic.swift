//
//  NYPLReaderBookmarksBusinessLogic.swift
//  Simplified
//
//  Created by Ettore Pasquini on 5/1/20.
//  Copyright © 2020 NYPL. All rights reserved.
//

import Foundation
import R2Shared
import R2Navigator

/// Encapsulates all of the SimplyE business logic related to bookmarking
/// for a given book.
class NYPLReaderBookmarksBusinessLogic: NSObject {

  var bookmarks: [NYPLReadiumBookmark] = []
  let book: NYPLBook
  private let publication: Publication
  private let drmDeviceID: String?
  private let bookRegistry: NYPLBookRegistryProvider
  private let currentLibraryAccountProvider: NYPLCurrentLibraryAccountProvider
  private let bookmarksFactory: NYPLBookmarkFactory
  
  private let annotationsSynchronizer: NYPLAnnotationSyncing.Type

  init(book: NYPLBook,
       r2Publication: Publication,
       drmDeviceID: String?,
       bookRegistryProvider: NYPLBookRegistryProvider,
       currentLibraryAccountProvider: NYPLCurrentLibraryAccountProvider,
       annotationsSynchronizer: NYPLAnnotationSyncing.Type) {
    self.book = book
    self.publication = r2Publication
    self.drmDeviceID = drmDeviceID
    self.bookRegistry = bookRegistryProvider
    bookmarks = bookRegistryProvider.readiumBookmarks(forIdentifier: book.identifier)
    self.currentLibraryAccountProvider = currentLibraryAccountProvider
    self.bookmarksFactory = NYPLBookmarkFactory(publication: publication,
                                                drmDeviceID: drmDeviceID)

    self.annotationsSynchronizer = annotationsSynchronizer
    
    super.init()
  }

  func bookmark(at index: Int) -> NYPLReadiumBookmark? {
    guard index >= 0 && index < bookmarks.count else {
      return nil
    }

    return bookmarks[index]
  }

  /// Derives Readium 2 location information for bookmarking from current
  /// navigation state.
  ///
  /// - Parameter navigator: The `Navigator` object used to browse
  /// the `publication`.
  /// - Returns: Location information related to the current reading position.
  func currentLocation(in navigator: Navigator) -> NYPLBookmarkR2Location? {
    guard
      let locator = navigator.currentLocation,
      let index = publication.resourceIndex(forLocator: locator) else {
        return nil
    }

    return NYPLBookmarkR2Location(resourceIndex: index, locator: locator)
  }

  /// Verifies if a bookmark exists at the given location.
  /// - Parameter location: The Readium 2 location to be checked.
  /// - Returns: The bookmark at the given `location` if it exists,
  /// otherwise nil.
  func bookmarkExisting(at location: NYPLBookmarkR2Location?) -> NYPLReadiumBookmark? {
    guard let currentLocator = location?.locator else {
      return nil
    }

    return bookmarks.first { $0.locationMatches(currentLocator,
                                                inPublication: publication)}
  }

  /// Creates a new bookmark at the given location for the publication.
  ///
  /// The bookmark is added to the internal list of bookmarks, and the list
  /// is kept sorted by progression-within-book, in ascending order.
  ///
  /// - Parameter bookmarkLoc: The location to boomark.
  ///
  /// - Returns: A newly created bookmark object, unless the input location
  /// lacked progress information.
  func addBookmark(_ bookmarkLoc: NYPLBookmarkR2Location) -> NYPLReadiumBookmark? {
    guard bookmarkExisting(at: bookmarkLoc) == nil else {
      Log.error(#function, "Bookmark already exists at R2 location: \(bookmarkLoc)")
      return nil
    }
    
    guard let bookmark = bookmarksFactory.make(fromR2Location: bookmarkLoc) else {
      Log.error(#function, "Unable to add bookmark from R2 location: \(bookmarkLoc)")
      return nil
    }

    bookmarks.append(bookmark)
    bookmarks.sort { $0.lessThan($1) }

    postBookmark(bookmark)

    return bookmark
  }
    
  private func postBookmark(_ bookmark: NYPLReadiumBookmark) {
    guard
      let currentAccount = currentLibraryAccountProvider.currentAccount,
      let accountDetails = currentAccount.details,
      accountDetails.syncPermissionGranted else {
        self.bookRegistry.add(bookmark, forIdentifier: book.identifier)
        return
    }
    
    annotationsSynchronizer.postBookmark(bookmark, forBookID: book.identifier) { serverAnnotationID in
      Log.info(#function, serverAnnotationID != nil ? "Bookmark upload succeed" : "Bookmark failed to upload")
      bookmark.annotationId = serverAnnotationID
      self.bookRegistry.add(bookmark, forIdentifier: self.book.identifier)
    }
  }

  func deleteBookmark(_ bookmark: NYPLReadiumBookmark) {
    var wasDeleted = false
    bookmarks.removeAll  {
      let isMatching = $0.isEqual(bookmark)
      if isMatching {
        wasDeleted = true
      }
      return isMatching
    }

    if wasDeleted {
      didDeleteBookmark(bookmark)
    }
  }

  func deleteBookmark(at index: Int) -> NYPLReadiumBookmark? {
    guard index >= 0 && index < bookmarks.count else {
      return nil
    }

    let bookmark = bookmarks.remove(at: index)
    didDeleteBookmark(bookmark)

    return bookmark
  }

  private func didDeleteBookmark(_ bookmark: NYPLReadiumBookmark) {
    bookRegistry.delete(bookmark, forIdentifier: book.identifier)

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

  var noBookmarksText: String {
    return NSLocalizedString("There are no bookmarks for this book.", comment: "Text showing in bookmarks view when there are no bookmarks")
  }

  func shouldSelectBookmark(at index: Int) -> Bool {
    return true
  }

  // MARK: - Bookmark Syncing

  func shouldAllowRefresh() -> Bool {
    return annotationsSynchronizer.syncIsPossibleAndPermitted()
  }
    
  func syncBookmarks(completion: @escaping (Bool, [NYPLReadiumBookmark]) -> ()) {
    NYPLReachability.shared()?.reachability(for: NYPLConfiguration.mainFeedURL(),
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
      let localBookmarks = self.bookRegistry.readiumBookmarks(forIdentifier: self.book.identifier)
      self.annotationsSynchronizer.uploadLocalBookmarks(localBookmarks, forBook: self.book.identifier) { (bookmarksUploaded, bookmarksFailedToUpload) in
        for localBookmark in localBookmarks {
          for uploadedBookmark in bookmarksUploaded {
            if localBookmark.isEqual(uploadedBookmark) {
              self.bookRegistry.replace(localBookmark, with: uploadedBookmark, forIdentifier: self.book.identifier)
            }
          }
        }
        
        self.annotationsSynchronizer.getServerBookmarks(forBook: self.book.identifier,
                                                        publication: self.publication,
                                                        atURL: self.book.annotationsURL) { serverBookmarks in
          guard let serverBookmarks = serverBookmarks else {
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
              completion(false, localBookmarks)
              return
            }
            self.bookmarks = self.bookRegistry.readiumBookmarks(forIdentifier: self.book.identifier)
            completion(true, self.bookmarks)
          }
        }
      }
      
    })
  }
    
  func updateLocalBookmarks(serverBookmarks: [NYPLReadiumBookmark],
                                     localBookmarks: [NYPLReadiumBookmark],
                                     bookmarksFailedToUpload: [NYPLReadiumBookmark],
                                     completion: @escaping () -> ())
  {
    // Bookmarks that are present on the client, and have a corresponding version on the server
    // with matching annotation ID's should be kept on the client.
    var localBookmarksToKeep = [NYPLReadiumBookmark]()
    // Bookmarks that are present on the server, but not the client, should be added to this
    // client as long as they were not created on this device originally.
    var serverBookmarksToKeep = serverBookmarks
    // Bookmarks present on the server, that were originally created on this device,
    // and are no longer present on the client, should be deleted on the server.
    var serverBookmarksToDelete = [NYPLReadiumBookmark]()
    
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
        bookRegistry.delete(localBookmark, forIdentifier: self.book.identifier)
      }
    }
    
    var bookmarksToAdd = serverBookmarks + bookmarksFailedToUpload
        
    // Look for duplicates in server and local bookmarks, remove them from bookmarksToAdd
    let duplicatedBookmarks = Set(serverBookmarksToKeep).intersection(Set(localBookmarksToKeep))
    bookmarksToAdd = Array(Set(bookmarksToAdd).subtracting(duplicatedBookmarks))
        
    for bookmark in bookmarksToAdd {
      bookRegistry.add(bookmark, forIdentifier: self.book.identifier)
    }
    
    annotationsSynchronizer.deleteBookmarks(serverBookmarksToDelete)
    
    completion()
  }

  private func handleBookmarksSyncFail(message: String,
                                       completion: @escaping (Bool, [NYPLReadiumBookmark]) -> ()) {
    Log.info(#file, message)
    
    self.bookmarks = self.bookRegistry.readiumBookmarks(forIdentifier: self.book.identifier)
    completion(false, self.bookmarks)
  }
}
