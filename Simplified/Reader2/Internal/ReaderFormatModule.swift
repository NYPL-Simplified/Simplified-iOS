//
//  ReaderFormatModule.swift
//  r2-testapp-swift
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


/// A ReaderFormatModule is a sub-module of ReaderModule that handles publication of a given format (eg. EPUB, CBZ).
protocol ReaderFormatModule {
  
  var delegate: ReaderFormatModuleDelegate? { get }
  
  /// Publication types handled by this sub-module.
  var publicationFormats: [Publication.Format] { get }
  
  /// Creates the view controller to present the publication.
  func makeReaderViewController(for publication: Publication, book: NYPLBook, resourcesServer: ResourcesServer) throws -> UIViewController
  
}

protocol ReaderFormatModuleDelegate: AnyObject {
  
  /// Show error in Reader
  func presentError(_ error: Error?, from viewController: UIViewController)
  
}

