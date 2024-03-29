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

/// This class is the main root of R2 objects. It:
/// - owns the sub-modules (library, reader, etc.)
/// - orchestrates the communication between its sub-modules, through the
/// modules' delegates.
@objc public final class NYPLR2Owner: NSObject {

  var libraryService: LibraryService
  var readerModule: ReaderModuleAPI! = nil

  init(bookRegistry: NYPLBookRegistryProvider,
       annotationsSynchronizer: NYPLAnnotationSyncing) {
    libraryService = LibraryService()

    super.init()

    readerModule = ReaderModule(
      delegate: self,
      resourcesServer: libraryService.publicationServer,
      bookRegistry: bookRegistry,
      annotationsSynchronizer: annotationsSynchronizer)

    // Set Readium 2's logging minimum level.
    R2EnableLog(withMinimumSeverityLevel: .warning)
  }

  deinit {
    Log.warn(#file, "NYPLR2Owner being dealloced")
  }
}

extension NYPLR2Owner: R2ModuleDelegate {
  func presentAlert(_ title: String,
                    message: String,
                    from viewController: UIViewController) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    let dismissButton = UIAlertAction(title: NSLocalizedString("OK", comment: "Alert button"), style: .cancel)
    alert.addAction(dismissButton)
    viewController.present(alert, animated: true)
  }

  func presentError(_ error: Error?, from viewController: UIViewController) {
    guard let error = error else { return }
    presentAlert(
      NSLocalizedString("Error", comment: "Alert title for errors"),
      message: error.localizedDescription,
      from: viewController
    )
  }
}
