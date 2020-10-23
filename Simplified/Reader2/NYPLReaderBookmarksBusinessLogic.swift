//
//  NYPLReaderBookmarksBusinessLogic.swift
//  Simplified
//
//  Created by Ettore Pasquini on 5/1/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation
import R2Shared
import R2Navigator

/// Encapsulates all of the SimplyE business logic related to bookmarking.
class NYPLReaderBookmarksBusinessLogic: NSObject, NYPLReadiumViewSyncManagerDelegate {

  var bookmarks: [NYPLReadiumBookmark] = []
  private let book: NYPLBook
  private let publication: Publication
  private let syncManager: NYPLReadiumViewSyncManager? = nil
  private let drmDeviceID: String?
  private let bookRegistry: NYPLBookRegistry

  init(book: NYPLBook,
       r2Publication: Publication,
       drmDeviceID: String?,
       bookRegistry: NYPLBookRegistry) {
    self.book = book
    self.publication = r2Publication
    self.drmDeviceID = drmDeviceID
    self.bookRegistry = bookRegistry
    bookmarks = bookRegistry.readiumBookmarks(forIdentifier: book.identifier)
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
  func isBookmarkExisting(at location: NYPLBookmarkR2Location?) -> NYPLReadiumBookmark? {
    guard let currentLocator = location?.locator else {
      return nil
    }

    let idref = publication.idref(forHref: currentLocator.href)

    for bookmark in bookmarks {
      if bookmark.locationMatches(currentLocator, withIDref: idref) {
        return bookmark
      }
    }

    return nil
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
    guard let progression = bookmarkLoc.locator.locations.progression else {
      return nil
    }
    let chapterProgress = Float(progression)

    guard let total = bookmarkLoc.locator.locations.totalProgression else {
      return nil
    }
    let totalProgress = Float(total)
    
    var page: String? = nil
    if let position = bookmarkLoc.locator.locations.position {
      page = "\(position)"
    }

    let registryLoc = bookRegistry.location(forIdentifier: book.identifier)
    var cfi: String? = nil
    var idref: String? = nil
    if registryLoc?.locationString != nil,
      let data = registryLoc?.locationString.data(using: .utf8),
      let registryLocationJSON = try? JSONSerialization.jsonObject(with: data),
      let registryLocationDict = registryLocationJSON as? [String: Any] {

      cfi = registryLocationDict["contentCFI"] as? String

      // backup idref from R1 in case parsing from R2 fails for some reason
      idref = registryLocationDict["idref"] as? String
    }

    // get the idref from R2 data structures. Should be more reliable than R1's
    // when working with R2 since it comes directly from a R2 Locator object.
    if let idrefFromR2 = publication.idref(forHref: bookmarkLoc.locator.href) {
      idref = idrefFromR2
    }

    let chapter: String?
    if let locatorChapter = bookmarkLoc.locator.title {
      chapter = locatorChapter
    } else if let tocLink = publication.tableOfContents.first(withHref: bookmarkLoc.locator.href) {
      chapter = tocLink.title
    } else {
      chapter = nil
    }

    guard let bookmark = NYPLReadiumBookmark(
      annotationId: nil,
      contentCFI: cfi,
      idref: idref,
      chapter: chapter,
      page: page,
      location: registryLoc?.locationString,
      progressWithinChapter: chapterProgress,
      progressWithinBook: totalProgress,
      time: (bookmarkLoc.creationDate as NSDate).rfc3339String(),
      device: drmDeviceID) else {
        return nil
    }

    bookmarks.append(bookmark)
    bookmarks.sort { $0.progressWithinBook < $1.progressWithinBook }

    addBookmark(bookmark)

    return bookmark
  }
    
  private func addBookmark(_ bookmark: NYPLReadiumBookmark) {
    guard
      let currentAccount = AccountsManager.shared.currentAccount,
      let accountDetails = currentAccount.details,
      accountDetails.syncPermissionGranted else {
        self.bookRegistry.add(bookmark, forIdentifier: book.identifier)
        return
    }
    
    NYPLAnnotations.postBookmark(forBook: book.identifier,
                                 toURL: nil,
                                 bookmark: bookmark) { (serverAnnotationID) in
      Log.debug(#function, serverAnnotationID != nil ? "Bookmark upload succeed" : "Bookmark failed to upload")
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

    guard let currentAccount = AccountsManager.shared.currentAccount,
        let details = currentAccount.details,
        let annotationId = bookmark.annotationId else {
      Log.debug(#file, "Delete on Server skipped: Annotation ID did not exist for bookmark.")
      return
    }
    
    if details.syncPermissionGranted && annotationId.count > 0 {
      NYPLAnnotations.deleteBookmark(annotationId: annotationId) { (success) in
        Log.debug(#file, success ?
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

  // MARK: - Syncing

  func shouldAllowRefresh() -> Bool {
    return NYPLAnnotations.syncIsPossibleAndPermitted()
  }
    
  func syncBookmarks(completion: @escaping (Bool, [NYPLReadiumBookmark]) -> ()) {
    NYPLReachability.shared()?.reachability(for: NYPLConfiguration.mainFeedURL(),
                                            timeoutInternal: 8.0,
                                            handler: { (reachable) in
      if (!reachable) {
        Log.warn(#file, "Error: host was not reachable for bookmark sync attempt.")
        self.bookmarks = self.bookRegistry.readiumBookmarks(forIdentifier: self.book.identifier)
        completion(false, self.bookmarks)
        return
      }
                    
      Log.debug(#file, "Syncing bookmarks...")
      // First check for and upload any local bookmarks that have never been saved to the server.
      // Wait til that's finished, then download the server's bookmark list and filter out any that can be deleted.
      let localBookmarks = self.bookRegistry.readiumBookmarks(forIdentifier: self.book.identifier)
      NYPLAnnotations.uploadLocalBookmarks(localBookmarks, forBook: self.book.identifier) { (bookmarksUploaded, bookmarksFailedToUpload) in
        for localBookmark in localBookmarks {
          for uploadedBookmark in bookmarksUploaded {
            if localBookmark.isEqual(uploadedBookmark) {
              self.bookRegistry.replace(localBookmark, with: uploadedBookmark, forIdentifier: self.book.identifier)
            }
          }
        }
        
        NYPLAnnotations.getServerBookmarks(forBook: self.book.identifier, atURL: self.book.annotationsURL) { (serverBookmarks) in
          guard let serverBookmarks = serverBookmarks else {
            Log.debug(#file, "Ending sync without running completion. Returning original list of bookmarks.")
            self.bookmarks = self.bookRegistry.readiumBookmarks(forIdentifier: self.book.identifier)
            completion(false, self.bookmarks)
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
    
  private func updateLocalBookmarks(serverBookmarks: [NYPLReadiumBookmark],
                                     localBookmarks: [NYPLReadiumBookmark],
                                     bookmarksFailedToUpload: [NYPLReadiumBookmark],
                                     completion: @escaping () -> ())
  {
    // Bookmarks that are present on the client, and have a corresponding version on the server
    // with matching annotation ID's should be kept on the client.
    var localBookmarksToKeep = [NYPLReadiumBookmark]()
    // Bookmarks that are present on the client, have been uploaded before,
    // but are no longer on the server, should be deleted on the client.
    var localBookmarksToDelete = [NYPLReadiumBookmark]()
    // Bookmarks that are present on the server, but not the client, should be added to this
    // client as long as they were not created on this device originally.
    var serverBookmarksToKeep = serverBookmarks
    // Bookmarks present on the server, that were originally created on this device,
    // and are no longer present on the client, should be deleted on the server.
    var serverBookmarksToDelete = [NYPLReadiumBookmark]()
    
    for serverBookmark in serverBookmarks {
      let matchingBookmarks = localBookmarks.filter { $0.annotationId == serverBookmark.annotationId }
        
      localBookmarksToKeep.append(contentsOf: matchingBookmarks)
        
      if let deviceID = serverBookmark.device,
        deviceID == NYPLUserAccount.sharedAccount().deviceID
        && matchingBookmarks.count == 0
      {
        serverBookmarksToDelete.append(serverBookmark)
        if let indexToRemove = serverBookmarksToKeep.index(of: serverBookmark) {
          serverBookmarksToKeep.remove(at: indexToRemove)
        }
      }
    }
    
    for localBookmark in localBookmarks {
      if !localBookmarksToKeep.contains(localBookmark) {
        bookRegistry.delete(localBookmark, forIdentifier: self.book.identifier)
        localBookmarksToDelete.append(localBookmark)
      }
    }
    
    var bookmarksToAdd = serverBookmarks
    bookmarksToAdd.append(contentsOf: bookmarksFailedToUpload)
        
    for serverBookmark in serverBookmarksToKeep {
      for localBookmark in localBookmarksToKeep {
        if serverBookmark.isEqual(localBookmark), let index = bookmarksToAdd.index(of: localBookmark) {
          bookmarksToAdd.remove(at: index)
        }
      }
    }
        
    for bookmark in bookmarksToAdd {
      bookRegistry.add(bookmark, forIdentifier: self.book.identifier)
    }
    
    if serverBookmarksToDelete.count > 0 {
      NYPLAnnotations.deleteBookmarks(serverBookmarksToDelete)
    }
    
    completion()
  }

  // TODO: Sync reading position

  // MARK: - NYPLReadiumViewSyncManagerDelegate

  func patronDecidedNavigation(_ toLatestPage: Bool, withNavDict dict: [AnyHashable : Any]!) {

  }

  func uploadFinished(for bookmark: NYPLReadiumBookmark!, inBook bookID: String!) {

  }
}
