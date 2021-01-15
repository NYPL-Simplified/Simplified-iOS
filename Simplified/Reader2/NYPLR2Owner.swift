//
//  NYPLR2Owner.swift
//
//  Created by Mickaël Menu on 20.02.19.
//
//  Copyright 2019 European Digital Reading Lab. All rights reserved.
//  Licensed to the Readium Foundation under one or more contributor license agreements.
//  Use of this source code is governed by a BSD-style license which is detailed in the
//  LICENSE file present in the project repository where this source code is maintained.
//

import Foundation
import UIKit
import R2Shared
import R2Streamer


/// Base module delegate, that sub-modules' delegate can extend.
/// Provides basic shared functionalities.
protocol ModuleDelegate: AnyObject {
    func presentAlert(_ title: String, message: String, from viewController: UIViewController)
    func presentError(_ error: Error?, from viewController: UIViewController)
}


/// This class is the main root of R2 objects. It:
/// - owns the sub-modules (library, reader, etc.)
/// - orchestrates the communication between its sub-modules, through the
/// modules' delegates.
@objc public final class NYPLR2Owner: NSObject {

  var library: LibraryModuleAPI! = nil
  var reader: ReaderModuleAPI! = nil

  override init() {
    super.init()
    guard let server = PublicationServer() else {
      /// FIXME: we should recover properly if the publication server can't
      /// start, maybe this should only forbid opening a publication?
      fatalError("Can't start publication server")
    }

    library = LibraryModule(delegate: self, server: server)
    reader = ReaderModule(delegate: self, resourcesServer: server)

    // Set Readium 2's logging minimum level.
    R2EnableLog(withMinimumSeverityLevel: .debug)
  }

  deinit {
    Log.warn(#file, "NYPLR2Owner being dealloced")
  }
}

extension NYPLR2Owner: ModuleDelegate {
  func presentAlert(_ title: String,
                    message: String,
                    from viewController: UIViewController) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    let dismissButton = UIAlertAction(title: NSLocalizedString("ok_button", comment: "Alert button"), style: .cancel)
    alert.addAction(dismissButton)
    viewController.present(alert, animated: true)
  }

  func presentError(_ error: Error?, from viewController: UIViewController) {
    guard let error = error else { return }
    presentAlert(
      NSLocalizedString("error_title", comment: "Alert title for errors"),
      message: error.localizedDescription,
      from: viewController
    )
  }
}

extension NYPLR2Owner: ReaderModuleDelegate {

}

extension NYPLR2Owner: LibraryModuleDelegate {
    func libraryDidSelectPublication(_ publication: Publication, book: NYPLBook, completion: @escaping () -> Void) {
        reader.presentPublication(publication: publication, book: book, in: library.rootViewController, completion: completion)
    }
}
