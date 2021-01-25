//
//  LibraryService.swift
//  r2-testapp-swift
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

protocol LibraryServiceDelegate: AnyObject {
  
  func reloadLibrary()
  func confirmImportingDuplicatePublication(withTitle title: String) -> Deferred<Void, Error>
  
}


final class LibraryService: Loggable {
  
  weak var delegate: LibraryServiceDelegate?
  
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
  func openBook(_ book: NYPLBook, forPresentation prepareForPresentation: Bool, sender: UIViewController, completion: @escaping (CancellableResult<Publication, LibraryError>) -> Void) {
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
  
  
  // MARK: Importation
  
  /// Imports a bunch of publications.
  func importPublications(from sourceURLs: [URL], sender: UIViewController, completion: @escaping (CancellableResult<(), LibraryError>) -> Void) {
    var sourceURLs = sourceURLs
    guard let url = sourceURLs.popFirst() else {
      completion(.success(()))
      return
    }
    
    importPublication(from: url, sender: sender) { result in
      switch result {
      case .success, .cancelled:
        self.importPublications(from: sourceURLs, sender: sender, completion: completion)
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
  
  /// Imports the publication at the given `url` to the bookshelf.
  ///
  /// If the `url` is a local file URL, the publication is copied to Documents/. For a remote URL,
  /// it is first downloaded.
  ///
  /// DRM services are used to fulfill the publication, in case the URL locates a licensing
  /// document.
  func importPublication(from sourceURL: URL, title: String? = nil, sender: UIViewController, completion: @escaping (CancellableResult<NYPLBook, LibraryError>) -> Void = { _ in }) {
  }
  
  /// Downloads `sourceURL` if it locates a remote file.
  private func downloadIfNeeded(_ sourceURL: URL, title: String?) -> Deferred<URL, Error> {
    guard !sourceURL.isFileURL, sourceURL.scheme != nil else {
      return .success(sourceURL)
    }
    return .success(sourceURL)
  }
  
  /// Fulfills the given `url` if it's a DRM license file.
  private func fulfillIfNeeded(_ url: URL) -> Deferred<URL, Error> {
    guard let drmService = drmLibraryServices.first(where: { $0.canFulfill(url) }) else {
      return .success(url)
    }
    
    return drmService.fulfill(url)
      .flatMap { download in
        // Removes the license file if it's in the App directory (e.g. Inbox/)
        if url.isAppFile {
          try? FileManager.default.removeItem(at: url)
        }
        
        return self.moveToDocuments(download.localURL, suggestedFilename: download.suggestedFilename)
    }
  }
  
  /// Moves the given `sourceURL` to the user Documents/ directory.
  private func moveToDocuments(_ sourceURL: URL, suggestedFilename: String? = nil) -> Deferred<URL, Error> {
      return deferredCatching(on: .global(qos: .background)) {
          // Necessary to read URL exported from the Files app, for example.
          let shouldRelinquishAccess = sourceURL.startAccessingSecurityScopedResource()
          defer {
              if shouldRelinquishAccess {
                  sourceURL.stopAccessingSecurityScopedResource()
              }
          }
          
          let destinationURL = self.documentDirectory.appendingUniquePathComponent(suggestedFilename ?? sourceURL.lastPathComponent)
          
          // If the source file is part of the app folder, we can move it. Otherwise we make a
          // copy, to avoid deleting files from iCloud, for example.
          if sourceURL.isAppFile {
              try FileManager.default.moveItem(at: sourceURL, to: destinationURL)
          } else {
              try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
          }
          
          return .success(destinationURL)
      }
  }

}
