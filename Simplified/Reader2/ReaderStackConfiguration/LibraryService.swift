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

// =============================================================================
// MARK: - Workaround for VoiceOver Issues

/// Temporary workaround to continue using the old Readium `PublicationServer`.
///
/// Readium 2.5.0 deprecates `PublicationServer` and introduces
/// `GCDHTTPServer` in its place. However, this causes significant scrolling
/// and book content navigation issues with VoiceOver. By casting 
/// `PublicationServer` references to `PublicationServing`, this workaround
/// silences the deprecation warnings until we find an official solution.
protocol PublicationServing: ResourcesServer {
  func add(_ publication: Publication) throws
  func removeAll()
}

extension PublicationServer: PublicationServing {
  @available(*, deprecated, message: "To suppress this warning, cast to PublicationServing protocol")
  func add(_ publication: Publication) throws {
    try add(publication, at: UUID().uuidString)
  }
}

private protocol PublicationServerMaking {
  func make() -> PublicationServing?
}

private class PublicationServerFactory: PublicationServerMaking {
  @available(*, deprecated, message: "To suppress this warning, cast to PublicationServerMaking protocol")
  func make() -> PublicationServing? {
    PublicationServer()
  }
}


// =============================================================================
// MARK: -

/// The LibraryService makes a book ready for presentation without dealing
/// with the specifics of how a book should be presented.
///
/// It sets up the various components necessary for presenting a book,
/// such as the streamer, publication server, DRM systems.  Presentation
/// iself is handled by the `ReaderModule`.
final class LibraryService: Loggable {
  
  private let streamer: Streamer
  let publicationServer: PublicationServing
  private var drmLibraryServices = [DRMLibraryService]()
  
  private lazy var documentDirectory = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
  
  init() {
    guard let server = (PublicationServerFactory() as PublicationServerMaking).make() else {
      /// FIXME: we should recover properly if the publication server can't
      /// start, maybe this should only forbid opening a publication?
      fatalError("Can't start publication server")
    }

    self.publicationServer = server

    #if FEATURE_DRM_CONNECTOR
    drmLibraryServices.append(AdobeDRMLibraryService())
    #endif
    
    #if AXIS
    if let protectedAssetOpener = NYPLAxisProtectedAssetOpener() {
      drmLibraryServices.append(
        NYPLAxisLibraryService(protectedAssetOpener: protectedAssetOpener))
    }
    #endif

    streamer = Streamer(
      contentProtections: drmLibraryServices.compactMap { $0.contentProtection }
    )
  }
  
  
  // MARK: Opening
  
  /// Opens the book file in Readium 2.
  ///
  /// - Parameters:
  ///   - sender: The VC that requested the opening and that will handle
  ///   error alerts or other messages for the user.
  ///   - completion: When this is called, the book is ready for
  ///   presentation if there are no errors.
  func openBook(fromFileURL bookFileURL: URL?,
                sender: UIViewController,
                completion: @escaping (CancellableResult<Publication, LibraryServiceError>) -> Void) {

    guard let bookUrl = bookFileURL else {
      completion(.failure(.invalidBook))
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
        
        self.preparePresentation(of: publication)
        return .success(publication)
    }
    .mapError { LibraryServiceError.openFailed($0) }
    .resolve(completion)
  }
  
  /// Opens the Readium 2 Publication at the given `url`.
  private func openPublication(at fileURL: URL, allowUserInteraction: Bool, sender: UIViewController?) -> Deferred<Publication, Error> {
    return deferred {
      self.streamer.open(asset: FileAsset(url: fileURL), allowUserInteraction: allowUserInteraction, sender: sender, completion: $0)
    }
    .eraseToAnyError()
  }

  private func preparePresentation(of publication: Publication) {
    // What we want to avoid here it to add a webPub to the publication server,
    // because there's no need to do that if it is loaded remotely from a URL.
    // Note that WebPub is not a Publication.Profile, and it will never
    // become one because it's the super set of all the profiles.
    // However, if the WebPub is packaged in a .webpub file, we do need to
    // add it to the publication server.
    // Note that all packaged publications will have a `baseURL` set to nil,
    // while a WebPub will have it set to a nonnull value.
    // Note that a publication that was already added to the web server
    // will also have a nonnull `baseURL`.
    guard publication.baseURL == nil else {
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
