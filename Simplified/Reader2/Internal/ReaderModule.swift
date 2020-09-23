//
//  ReaderModule.swift
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


/// The ReaderModule handles the presentation of publications to be read by the
/// user. It contains sub-modules implementing ReaderFormatModule to handle each
/// format of publication (eg. CBZ, EPUB).
protocol ReaderModuleAPI {

  var delegate: ReaderModuleDelegate? { get }


  /// Presents the given publication to the user, inside the given navigation controller.
  ///
  /// - Parameter publication: The R2 publication to display.
  /// - Parameter book: Our internal book model related to the `publication`.
  /// - Parameter navigationController: The navigation stack the book will be
  /// presented in.
  /// - Parameter completion: Called once the publication is presented, or if an error occured.
  func presentPublication(_ publication: Publication,
                          book: NYPLBook,
                          in navigationController: UINavigationController,
                          completion: @escaping () -> Void)

}

protocol ReaderModuleDelegate: ModuleDelegate {

  /// Called when the reader needs to load the R2 DRM object for the given publication.
  func readerLoadDRM(for book: NYPLBook,
                     completion: @escaping (CancellableResult<DRM?>) -> Void)

}


final class ReaderModule: ReaderModuleAPI {

  weak var delegate: ReaderModuleDelegate?
  private let resourcesServer: ResourcesServer

  /// Sub-modules to handle different publication formats (eg. EPUB, CBZ)
  var formatModules: [ReaderFormatModule] = []

  init(delegate: ReaderModuleDelegate, resourcesServer: ResourcesServer) {
    self.delegate = delegate
    self.resourcesServer = resourcesServer

    formatModules = [
      EPUBModule(delegate: self),
    ]

    // TODO: do we need to handle PDFs in R2?
    //        if #available(iOS 11.0, *) {
    //            formatModules.append(PDFModule(delegate: self))
    //        }
  }

  func presentPublication(_ publication: Publication,
                          book: NYPLBook,
                          in navigationController: UINavigationController,
                          completion: @escaping () -> Void) {
    guard let delegate = delegate else {
      preconditionFailure("Reader delegate not set")
    }

    func present(_ viewController: UIViewController) {
      let backItem = UIBarButtonItem()
      backItem.title = NSLocalizedString("Back", comment: "Text for Back button")
      viewController.navigationItem.backBarButtonItem = backItem
      viewController.hidesBottomBarWhenPushed = true
      // sealso: NYPLBookCellDelegate::openEPUB:
      navigationController.pushViewController(viewController, animated: true)
    }

    delegate.readerLoadDRM(for: book) { [resourcesServer] result in
      switch result {
      case .failure(let error):
        delegate.presentError(error, from: navigationController)
        completion()

      case .success(let drm):
        guard let module = self.formatModules.first(where:{ $0.publicationFormats.contains(publication.format) }) else {
          delegate.presentError(ReaderError.formatNotSupported, from: navigationController)
          completion()
          return
        }

        do {
          let readerVC = try module.makeReaderVC(for: publication,
                                                 book: book,
                                                 drm: drm,
                                                 resourcesServer: resourcesServer)
          present(readerVC)
        } catch {
          delegate.presentError(error, from: navigationController)
        }

        completion()

      case .cancelled:
        completion()
      }
    }
  }
}


extension ReaderModule: ReaderFormatModuleDelegate {

  func presentAlert(_ title: String,
                    message: String,
                    from viewController: UIViewController) {
    delegate?.presentAlert(title, message: message, from: viewController)
  }

  func presentError(_ error: Error?,
                    from viewController: UIViewController) {
    delegate?.presentError(error, from: viewController)
  }

}
