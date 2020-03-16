//
//  LibraryModule.swift
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
import R2Shared
import R2Streamer
import UIKit

// TODO: SIMPLY-2656 Review "module" nomenclature

/// The Library module handles the presentation of the bookshelf, and the publications' management.
protocol LibraryModuleAPI {
  var libraryService: LibraryService {get}
  
  /// Loads the R2 DRM object for the given publication.
  func loadDRM(for book: NYPLBook, completion: @escaping (CancellableResult<DRM?>) -> Void)
}

// TODO: SIMPLY-2656 Do we even need this class?

final class LibraryModule: LibraryModuleAPI {

  let libraryService: LibraryService

  init(server: PublicationServer) {
    self.libraryService = LibraryService(publicationServer: server)
  }

  func loadDRM(for book: NYPLBook, completion: @escaping (CancellableResult<DRM?>) -> Void) {
    libraryService.loadDRM(for: book, completion: completion)
  }

}
