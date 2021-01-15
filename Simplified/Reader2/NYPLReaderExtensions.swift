//
//  NYPLReaderExtensions.swift
//  SimplyE
//
//  Created by Ettore Pasquini on 3/4/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation
import R2Shared
import R2Streamer

// Required to be able to compile the R2 stuff
extension NYPLBook {

  /// This is really just the file name ("28E5C209-579E-4127-A3C9-1F35AA30286D.epub")
  /// or anything absolute or relative (as long as there's no scheme),
  /// or a file url "file:/some/path/abc.epub",
  /// "file:///some/path/abc.epub"
  var fileName: String? {
    //let url = URL(string: href) //TODO: SIMPLY-2656
    guard url?.scheme == nil || (url?.isFileURL ?? false) else {
      return nil
    }
    return url?.absoluteString
  }

  var url: URL? {
    return NYPLMyBooksDownloadCenter.shared()?.fileURL(forBookIndentifier: identifier)
  }

  //TODO: SIMPLY-2656 this property seems architecturally unsound
//  var href: String {
//    guard let urlStr = url?.absoluteString else {
//      fatalError("TODO: the URL for \(self) is nil")
//    }
//
//    return urlStr
//  }

  var progressionLocator: Locator? {
    // TODO: SIMPLY-2609
    return nil
  }
}

@objc extension NYPLRootTabBarController {
  func presentBook(_ book: NYPLBook) {
    guard let libraryModule = r2Owner?.library as? LibraryModule, let readerModule = r2Owner.reader else {
      return
    }

    libraryModule.library.openBook(book, forPresentation: true, sender: self) { [weak self] result in
      guard let navVC = self?.selectedViewController as? UINavigationController else {
        preconditionFailure("No navigation controller, unable to present reader")
      }
      switch result {
      case .success(let publication):
        readerModule.presentPublication(publication: publication, book: book, in: navVC) {
          //
        }
      case .cancelled:
        preconditionFailure("Open book opration was cancelled")
        
      case .failure(let error):
        preconditionFailure("Open book error: \(error.localizedDescription)")
      }
    }
  }
}

