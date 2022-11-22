//
//  EPUB.swift
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


final class EPUBModule: ReaderFormatModule {
  
  weak var delegate: R2ModuleDelegate?
  let resourcesServer: ResourcesServer
  private let annotationsSynchronizer: NYPLAnnotationSyncing
  
  init(delegate: R2ModuleDelegate?,
       resourcesServer: ResourcesServer,
       annotationsSynchronizer: NYPLAnnotationSyncing) {
    self.delegate = delegate
    self.resourcesServer = resourcesServer
    self.annotationsSynchronizer = annotationsSynchronizer
  }

  func supports(_ publication: Publication) -> Bool {
    return publication.conforms(to: .epub) || publication.readingOrder.allAreHTML
  }

  func makeReaderViewController(for publication: Publication,
                                book: NYPLBook,
                                syncPermission: Bool,
                                initialLocation: Locator?) throws -> UIViewController {
      
    guard publication.metadata.identifier != nil else {
      throw ReaderError.epubNotValid
    }
    
    let epubVC = NYPLEPUBViewController(publication: publication,
                                        book: book,
                                        initialLocation: initialLocation,
                                        resourcesServer: resourcesServer,
                                        syncPermission: syncPermission,
                                        annotationsSynchronizer: annotationsSynchronizer)
    epubVC.moduleDelegate = delegate
    return epubVC
  }
  
}
