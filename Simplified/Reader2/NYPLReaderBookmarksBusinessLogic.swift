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

  init(book: NYPLBook, r2Publication: Publication, drmDeviceID: String?) {
    self.book = book
    self.publication = r2Publication
    self.drmDeviceID = drmDeviceID
    let registry = NYPLBookRegistry.shared()
    bookmarks = registry.readiumBookmarks(forIdentifier: book.identifier)
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

    let registry = NYPLBookRegistry.shared()
    let registryLoc = registry.location(forIdentifier: book.identifier)
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

    /*
     // TODO: SIMPLY-2804 sync with server
     // this is what happens in R1
     [self.delegate updateCurrentBookmark:bookmark];
     [self.syncManager addBookmark:bookmark withCFI:bookmark.location forBook:book.identifier];
     */

    return bookmark
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
    let registry = NYPLBookRegistry.shared()
    registry.delete(bookmark, forIdentifier: book.identifier)

    // TODO: SIMPLY-2804 (syncing)
    // see NYPLReaderReadiumView::deleteBookmark
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

  // TODO: SIMPLY-2804 not sure how this translates to R2. It might require
  // server side changes
  func refreshBookmarks(inVC vc: NYPLReaderPositionsVC) {
    // NB: this was taken from R1's NYPLReaderTOCViewController
//    syncManager.syncBookmarksWithCompletion { [weak self] success, bookmarks in
//      NYPLMainThreadRun.asyncIfNeeded { [weak self] in
//        self?.bookmarks = bookmarks
//        vc.tableView.reloadData()
//        vc.bookmarksRefreshControl.endRefreshing()
//        if !success {
//          let alert = NYPLAlertUtils.alert(title: "Error Syncing Bookmarks",
//                                           message: "There was an error syncing bookmarks to the server. Ensure your device is connected to the internet or try again later.")
//          vc.present(alert, animated: true)
//        }
//      }
//    }
  }

  // MARK: - NYPLReadiumViewSyncManagerDelegate

  func patronDecidedNavigation(_ toLatestPage: Bool, withNavDict dict: [AnyHashable : Any]!) {

  }

  func uploadFinished(for bookmark: NYPLReadiumBookmark!, inBook bookID: String!) {

  }
}
