//
//  LibraryService.swift
//  Simplified
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

final class LibraryService: Loggable {
  
  private let streamer: Streamer
  private let publicationServer: PublicationServer
  private var drmLibraryServices = [DRMLibraryService]()
  
  private lazy var documentDirectory = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
  
  init(publicationServer: PublicationServer) {
    self.publicationServer = publicationServer
    
    #if LCP
    drmLibraryServices.append(LCPLibraryService())
    #endif
    
    #if FEATURE_DRM_CONNECTOR
//    drmLibraryServices.append(AdobeDRMLibraryService())
    #endif
    
    streamer = Streamer(
      contentProtections: drmLibraryServices.compactMap { $0.contentProtection }
    )
  }
  
  
  // MARK: Opening
  
  /// Opens the Readium 2 Publication for the given `book`.
  ///
  /// If the `Publication` is intended to be presented in a navigator, set `forPresentation`.
  func openBook(_ book: NYPLBook, sender: UIViewController, completion: @escaping (CancellableResult<Publication, LibraryError>) -> Void) {
    guard let bookUrl =  book.url else {
      completion(.failure(.publicationIsNotValid))
      return
    }
    deferredCatching { .success(bookUrl) }
      .flatMap { self.openPublication(at: $0, allowUserInteraction: true, sender: sender) }
      .flatMap { publication in
        guard !publication.isRestricted else {
          if let error = publication.protectionError {
            return .failure(error)
          } else {
            return .cancelled
          }
        }
        
        self.preparePresentation(of: publication, book: book)
        return .success(publication)
    }
    .mapError { LibraryError.openFailed($0) }
    .resolve(completion)
  }
  
  /// Opens the Readium 2 Publication at the given `url`.
  private func openPublication(at url: URL, allowUserInteraction: Bool, sender: UIViewController?) -> Deferred<Publication, Error> {
    return deferred {
      self.streamer.open(asset: FileAsset(url: url), allowUserInteraction: allowUserInteraction, sender: sender, completion: $0)
    }
    .eraseToAnyError()
  }
  
  private func preparePresentation(of publication: Publication, book: NYPLBook) {
    // If the book is a webpub, it means it is loaded remotely from a URL, and it doesn't need to be added to the publication server.
    guard publication.format != .webpub else {
      return
    }
    
    publicationServer.removeAll()
    do {
      try publicationServer.add(publication)
    } catch {
      log(.error, error)
    }
  }

}
