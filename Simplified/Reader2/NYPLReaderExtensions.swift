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
    let url = URL(string: href)
    guard url?.scheme == nil || (url?.isFileURL ?? false) else {
      return nil
    }
    return href
  }

  var url: URL? {
    return NYPLMyBooksDownloadCenter.shared()?.fileURL(forBookIndentifier: identifier)
  }

  var href: String {
    guard let urlStr = url?.absoluteString else {
      fatalError("TODO: the URL for \(self) is nil")
    }

    return urlStr
//    guard let noPercentEscapes = urlStr.removingPercentEncoding else {
//      return urlStr
//    }
//    return noPercentEscapes
  }

  var progressionLocator: Locator? {
    // TODO: XXXX
    return nil
  }
}

@objc extension NYPLRootTabBarController {
  func presentBook(_ book: NYPLBook, fromLibrary lib: LibraryService? = nil) {

    guard let libModule = appModule?.library as? LibraryModule else {
      return
    }

    let library = libModule.library

    guard let (publication, container) = library.parsePublication(for: book) else {
      return
    }

    library.preparePresentation(of: publication, book: book, with: container)

    let objcPublication = OBJCPublication(publication: publication)
    guard let navVC = NYPLRootTabBarController.shared().selectedViewController as? UINavigationController else {
//    guard let navVC = self.navigationController else {
      fatalError("No navigation controller, unable to present reader")
    }

    appModule.library.delegate?.libraryDidSelectPublication(objcPublication,
                                                            book: book,
                                                            inNavVC: navVC) {
//      self.loadingIndicator.removeFromSuperview()
//      collectionView.isUserInteractionEnabled = true
    }
  }
}

@objc class OBJCPublication: NSObject {
  let publication: Publication

  init(publication: Publication) {
    self.publication = publication
    super.init()
  }
}
