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
@testable import R2Streamer // uses internal class NCXParser


final class LibraryService: NSObject, Loggable {

  let workQueue = DispatchQueue(label: "org.nypl.reader.libservice",
                                qos: .userInitiated,
                                target: .global(qos: .userInitiated))

  let publicationServer: PublicationServer

  /// Publications waiting to be added to the PublicationServer (first opening).
  /// publication identifier : data
  var items = [String: (Container, PubParsingCallback)]()

  var drmLibraryServices = [DRMLibraryService]()

  init(publicationServer: PublicationServer) {
    self.publicationServer = publicationServer

    #if LCP
    drmLibraryServices.append(LCPLibraryService())
    #endif
    
    #if FEATURE_DRM_CONNECTOR
    drmLibraryServices.append(AdobeDRMLibraryService())
    #endif
  }

  /// Complementary parsing of the publication.
  /// Will parse Nav/ncx + mo (files that are possibly encrypted)
  /// using the DRM object of the publication.container.
  func loadDRM(for book: NYPLBook, completion: @escaping (CancellableResult<DRM?>) -> Void) {

    guard let filename = book.fileName, let fileUrl = URL(string: filename), let (container, parsingCallback) = items[fileUrl.lastPathComponent] else {
      completion(.success(nil))
      return
    }

    guard let drm = container.drm else {
      // No DRM, so the parsing callback can be directly called.
      do {
        try parsingCallback(nil)
        completion(.success(nil))
      } catch {
        completion(.failure(error))
      }
      return
    }

    guard let drmService = drmLibraryServices.first(where: { $0.brand == drm.brand }) else {
      completion(.success(nil))
      return
    }
    
    // Load DRM service with publication data
    // If it's Adobe DRM, set contaiener for decrypting
    if let adobeDrmService = drmService as? AdobeDRMLibraryService {
      adobeDrmService.container = container
    }
    
    let url = URL(fileURLWithPath: container.rootFile.rootPath)
    drmService.loadPublication(at: url, drm: drm) { result in
      switch result {
      case .success(let drm):
        do {
          /// Update container.drm to drm and parse the remaining elements.
          try parsingCallback(drm)
          completion(.success(drm))
        } catch {
          completion(.failure(error))
        }
      default:
        completion(result)
      }
    }
  }

  private func preparePresentation(of publication: Publication, book: NYPLBook, with container: Container) {
    // If the book is a webpub, it means it is loaded remotely from a URL,
    // and it doesn't need to be added to the publication server.
    if publication.format != .webpub {
      publicationServer.removeAll()
      guard let bookRelativePath = book.url?.lastPathComponent else {
        log(.error, "Book with ID \(book.identifier ?? "''") has no usable URL")
        return
      }
      do {
        try publicationServer.add(publication, with: container, at: bookRelativePath)
      } catch {
        log(.error, error)
      }
    }
  }

  /// Parses a book asynchronously off of the main queue.
  ///
  /// Parsing a book into a Publication object is expensive, therefore should
  /// never be done on the main queue. This method does the job asynchronously
  /// in an internal serial queue, and completes it on the main queue.
  ///
  /// - Parameters:
  ///   - book: The book to parse into a Publication object.
  ///   - parseSuccessCompletion: Called on the main queue once the book is
  /// parsed. Not called if parsing fails for any reason.
  func parseBookAsync(_ book: NYPLBook,
                      parseSuccessCompletion: @escaping (_: Publication) -> Void) {
    workQueue.async { [weak self] in
      guard let self = self else {
        // not calling completion bc if there's no lib service, there's nothing
        // to present from
        return
      }

      guard let (publication, container) = self.parsePublication(for: book) else {
        // not calling completion bc if there's no publication, there's nothing
        // to present
        return
      }

      self.preparePresentation(of: publication, book: book, with: container)

      DispatchQueue.main.async {
        parseSuccessCompletion(publication)
      }
    }
  }

  private func parsePublication(for book: NYPLBook) -> PubBox? {
    guard let url = book.url else {
      return nil
    }

    return parsePublication(at: url)
  }

  private func parsePublication(atPath path: String) -> PubBox? {
    let path: String = {
      // Relative to Documents/ or the App bundle?
      if !path.hasPrefix("/") {
        let filesMgr = FileManager.default

        let documents = try! FileManager.default.url(
          for: .documentDirectory,
          in: .userDomainMask,
          appropriateFor: nil,
          create: true
        )

        // try in sandbox
        let documentPath = documents.appendingPathComponent(path).path
        if filesMgr.fileExists(atPath: documentPath) {
          return documentPath
        }

        // try in app bundle
        if let bundlePath = Bundle.main.path(forResource: path, ofType: nil),
          filesMgr.fileExists(atPath: bundlePath)
        {
          return bundlePath
        }
      }

      return path
    }()

    return parsePublication(at: URL(fileURLWithPath: path))
  }

  private func parsePublication(at url: URL) -> PubBox? {
    do {
      guard let (pubBox, parsingCallback) = try Publication.parse(at: url) else {
        return nil
      }
      let (publication, container) = pubBox
      // TODO: SIMPLY-2840
      // Parse .ncx document to update TOC and page list if publication doesn't contain TOC
      // -- the code below should be removed as described in SIMPLY-2840 --
      if publication.tableOfContents.isEmpty {
        publication.otherCollections.append(contentsOf: parseNCXDocument(in: container, links: publication.links))
      }
      // -- end of cleanup --
      items[url.lastPathComponent] = (container, parsingCallback)
      return (publication, container)

    } catch {
      // TODO: SIMPLY-2656
      // we can log this error to Crashalytics as well
      log(.error, "Error parsing publication at '\(url.absoluteString)': \(error.localizedDescription)")
      return nil
    }
  }

}



// TODO: SIMPLY-2840
// This extension should be removed as a part of the cleanup
extension LibraryService {
  /*
   Parse .ncx document after the app creates container and publication.
   This step is a workaround for current Readium 2 issue with encrypted TOC.
   */
  private func parseNCXDocument(in container: Container, links: [Link]) -> [PublicationCollection] {
      // Get the link in the readingOrder pointing to the NCX document.
      guard let ncxLink = links.first(withType: .ncx),
          let ncxDocumentData = try? container.data(relativePath: ncxLink.href) else
      {
          return []
      }

      // this part is added to decrypt ncx data
      var data = ncxDocumentData
      let license = AdobeDRMLicense(for: container)
      if let optionalDecipheredData = try? license.decipher(ncxDocumentData),
          let decipheredData = optionalDecipheredData {
          data = decipheredData
      }
      // NCXParser here parses data instead of ncxDocumentData
      let ncx = NCXParser(data: data, at: ncxLink.href)

      func makeCollection(_ type: NCXParser.NavType, role: String) -> PublicationCollection? {
          let links = ncx.links(for: type)
          guard !links.isEmpty else {
              return nil
          }
          return PublicationCollection(role: role, links: links)
      }

      return [
          makeCollection(.tableOfContents, role: "toc"),
          makeCollection(.pageList, role: "pageList")
      ].compactMap { $0 }
  }
}
