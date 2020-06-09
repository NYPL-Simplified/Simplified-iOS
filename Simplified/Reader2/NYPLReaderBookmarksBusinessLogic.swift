//
//  NYPLReaderBookmarksBusinessLogic.swift
//  Simplified
//
//  Created by Ettore Pasquini on 5/1/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation
import R2Shared

class NYPLReaderBookmarksBusinessLogic: NSObject, NYPLReadiumViewSyncManagerDelegate {

  var bookmarks: [NYPLReadiumBookmark] = []
  private let book: NYPLBook
  private let publication: Publication
  private let syncManager: NYPLReadiumViewSyncManager? = nil

  init(book: NYPLBook, r2Publication: Publication) {
    self.book = book
    self.publication = r2Publication
    let registry = NYPLBookRegistry.shared()
    bookmarks = registry.readiumBookmarks(forIdentifier: book.identifier)
  }

  func bookmark(at index: Int) -> NYPLReadiumBookmark? {
    guard index >= 0 && index < bookmarks.count else {
      return nil
    }

    return bookmarks[index]
  }

  func removeBookmark(at index: Int) -> NYPLReadiumBookmark? {
    guard index >= 0 && index < bookmarks.count else {
      return nil
    }

    return bookmarks.remove(at: index)
  }

  var noBookmarksText: String {
    return NSLocalizedString("There are no bookmarks for this book.", comment: "Text showing in bookmarks view when there are no bookmarks")
  }

  func shouldSelectBookmark(at index: Int) -> Bool {
    return true
  }

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
