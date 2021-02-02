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


/// The ReaderModule handles the presentation of publications to be read by the user.
/// It contains sub-modules implementing ReaderFormatModule to handle each format of publication (eg. CBZ, EPUB).
protocol ReaderModuleAPI {
  
  var delegate: ModuleDelegate? { get }
  
  /// Presents the given publication to the user, inside the given navigation controller.
  /// - Parameter publication: The R2 publication to display.
  /// - Parameter book: Our internal book model related to the `publication`.
  /// - Parameter navigationController: The navigation stack the book will be presented in.
  /// - Parameter completion: Called once the publication is presented, or if an error occured.
  func presentPublication(publication: Publication, book: NYPLBook, in navigationController: UINavigationController, completion: @escaping () -> Void)
  
}

final class ReaderModule: ReaderModuleAPI {
  
  weak var delegate: ModuleDelegate?
  private let resourcesServer: ResourcesServer
  
  /// Sub-modules to handle different publication formats (eg. EPUB, CBZ)
  var formatModules: [ReaderFormatModule] = []
  
  init(delegate: ModuleDelegate?, resourcesServer: ResourcesServer) {
    self.delegate = delegate
    self.resourcesServer = resourcesServer
    
    formatModules = [
      EPUBModule(delegate: self)
    ]

  }
  
  func presentPublication(publication: Publication,
                          book: NYPLBook,
                          in navigationController: UINavigationController,
                          completion: @escaping () -> Void) {
    guard let delegate = delegate else {
      fatalError("Reader delegate not set")
    }
    
    func present(_ viewController: UIViewController) {
      let backItem = UIBarButtonItem()
      backItem.title = NSLocalizedString("Back", comment: "Text for Back button")
      viewController.navigationItem.backBarButtonItem = backItem
      viewController.hidesBottomBarWhenPushed = true
      navigationController.pushViewController(viewController, animated: true)
    }
    
    guard let module = self.formatModules.first(where:{ $0.publicationFormats.contains(publication.format) }) else {
      delegate.presentError(ReaderError.formatNotSupported, from: navigationController)
      completion()
      return
    }
    
    do {
      let readerViewController = try module.makeReaderViewController(for: publication, book: book, resourcesServer: resourcesServer)
      present(readerViewController)
    } catch {
      delegate.presentError(error, from: navigationController)
    }
    
    completion()
  }
  
}


extension ReaderModule: ReaderFormatModuleDelegate {
    
  func presentError(_ error: Error?, from viewController: UIViewController) {
    delegate?.presentError(error, from: viewController)
  }
  
}
