//
//  ReaderModule.swift
//  Simplified
//
//  Created by Mickaël Menu on 22.02.19.
//
//  Copyright 2019 European Digital Reading Lab. All rights reserved.
//  Licensed to the Readium Foundation under one or more contributor license agreements.
//  Use of this source code is governed by a BSD-style license which is detailed in the
//  LICENSE file present in the project repository where this source code is maintained.
//

import Foundation
import UIKit
import R2Shared


/// Base module delegate, that sub-modules' delegate can extend.
/// Provides basic shared functionalities.
protocol R2ModuleDelegate: AnyObject {
  func presentAlert(_ title: String, message: String, from viewController: UIViewController)
  func presentError(_ error: Error?, from viewController: UIViewController)
}

// MARK:-

/// The ReaderModuleAPI declares what is needed to handle the presentation
/// of a publication.
protocol ReaderModuleAPI {
  
  var delegate: R2ModuleDelegate? { get }
  
  /// Presents the given publication to the user, inside the given navigation controller.
  /// - Parameter publication: The R2 publication to display.
  /// - Parameter book: Our internal book model related to the `publication`.
  /// - Parameter deviceID: This is used to understand if we're resuming
  /// reading on the same device as the previous time.
  /// - Parameter navigationController: The navigation stack the book will be presented in.
  func presentPublication(_ publication: Publication,
                          book: NYPLBook,
                          deviceID: String?,
                          in navigationController: UINavigationController)
  
}

// MARK:-

/// The ReaderModule handles the presentation of a publication.
///
/// It contains sub-modules implementing `ReaderFormatModule` to handle each
/// publication format (e.g. EPUB, PDF, etc).
final class ReaderModule: ReaderModuleAPI {
  
  weak var delegate: R2ModuleDelegate?
  private let resourcesServer: ResourcesServer
  private let progressSynchronizer: NYPLLastReadPositionSynchronizer

  /// Sub-modules to handle different publication formats (eg. EPUB, CBZ)
  var formatModules: [ReaderFormatModule] = []

  init(delegate: R2ModuleDelegate?,
       resourcesServer: ResourcesServer,
       bookRegistry: NYPLBookRegistryProvider) {
    self.delegate = delegate
    self.resourcesServer = resourcesServer
    self.progressSynchronizer = NYPLLastReadPositionSynchronizer(bookRegistry: bookRegistry)

    formatModules = [
      EPUBModule(delegate: self.delegate, resourcesServer: resourcesServer)
    ]
  }
  
  func presentPublication(_ publication: Publication,
                          book: NYPLBook,
                          deviceID: String?,
                          in navigationController: UINavigationController) {
    if delegate == nil {
      NYPLErrorLogger.logError(nil, summary: "ReaderModule delegate is not set")
    }
    
    guard let formatModule = self.formatModules.first(where:{ $0.publicationFormats.contains(publication.format) }) else {
      delegate?.presentError(ReaderError.formatNotSupported, from: navigationController)
      return
    }

    progressSynchronizer.sync(for: publication,
                              book: book,
                              drmDeviceID: deviceID) { [weak self] initialLocator in
                                self?.finalizePresentation(for: publication,
                                                           book: book,
                                                           formatModule: formatModule,
                                                           positioningAt: initialLocator,
                                                           in: navigationController)
    }
  }

  private func finalizePresentation(for publication: Publication,
                                    book: NYPLBook,
                                    formatModule: ReaderFormatModule,
                                    positioningAt initialLocator: Locator?,
                                    in navigationController: UINavigationController) {
    do {
      let readerVC = try formatModule.makeReaderViewController(
        for: publication,
        book: book,
        initialLocation: initialLocator)

      let backItem = UIBarButtonItem()
      backItem.title = NSLocalizedString("Back", comment: "Text for Back button")
      readerVC.navigationItem.backBarButtonItem = backItem
      readerVC.hidesBottomBarWhenPushed = true
      navigationController.pushViewController(readerVC, animated: true)

    } catch {
      delegate?.presentError(error, from: navigationController)
    }
  }
}
