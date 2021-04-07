//
//  AxisService.swift
//  Simplified
//
//  Created by Raman Singh on 2021-04-01.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation

#if AXIS

@objc
protocol NYPLBookDownloadBroadcasting {
  
  /// Shows an alert notifying the user about book download failure.
  /// - Parameter book: The book associated with download failure.
  func failDownloadWithAlert(forBook book: NYPLBook)
  
  /// Moves the downloaded book file from current location to desired location.
  /// - Parameters:
  ///   - book: The book that finished downloading.
  ///   - sourceLocation: Current location of book file(s).
  ///   - downloadtask: Downlaod task for book download.
  func replaceBook(_ book: NYPLBook,
                   withFileAtURL sourceLocation: URL,
                   forDownloadTask downloadtask: URLSessionDownloadTask) -> Bool
}

private struct AxisHelper {
  static let isbnKey = "isbn"
  static let bookVaultKey = "book_vault_uuid"
  /// This is the url for downloading content for a given book with axis drm.
  static let baseURL = URL(string: "https://node.axisnow.com/content/stream/")!
}

@objc
class AxisService: NSObject {
  private weak var delegate: NYPLBookDownloadBroadcasting?
  private let isbn: String
  private let bookVaultId: String
  private let dedicatedWriteURL: URL
  private let fileURL: URL
  private let baseURL: URL
  private let book: NYPLBook
  
  /// Failable initializer that extracts `isbn` and `book_vault_id` from the downloaded file. Returns
  /// nil if keys are not present and notifies delegate.
  /// - Parameters:
  ///   - delegate: An object confirming to NYPLBookDownloadBroadcasting protocol.
  ///   - fileURL: Local url of the downloaded file.
  ///   - book: NYPLBook object
  @objc init?(withDelegate delegate: NYPLBookDownloadBroadcasting,
              fileURL: URL,
              forBook book: NYPLBook) {
    do {
      let data = try Data(contentsOf: fileURL)
      let jsonObject = try JSONSerialization
        .jsonObject(with: data, options: .fragmentsAllowed)
      
      /*
       The downloaded file is supposed to have a key for isbn and
       book_vauld_uuid. Those keys are needed to download license.json,
       encryption.xml, container.xml, package.opf, and assets enclosed in
       package.opf.
       */
      guard
        let json = jsonObject as? [String: Any],
        let isbn = json[AxisHelper.isbnKey] as? String,
        let bookVaultId = json[AxisHelper.bookVaultKey] as? String
        else {
          NYPLErrorLogger.logError(nil, summary: "error initiating AxisService")
          delegate.failDownloadWithAlert(forBook: book)
          return nil
      }
      
      self.isbn = isbn
      self.fileURL = fileURL
      self.delegate = delegate
      self.bookVaultId = bookVaultId
      self.dedicatedWriteURL = fileURL.deletingLastPathComponent().appendingPathComponent(isbn)
      self.baseURL = AxisHelper.baseURL.appendingPathComponent(AxisHelper.isbnKey)
      self.book = book
      
    } catch {
      NYPLErrorLogger.logError(error, summary: "error initiating AxisService")
      delegate.failDownloadWithAlert(forBook: book)
      return nil
    }
  }
  
  /// Fulfill AxisNow license. Notifies NYPLBookDownloadBroadcasting upon completion or failure.
  /// - Parameters:
  ///   - downloadTask: downloadTask download task
  @objc func fulfillAxisLicense(downloadTask: URLSessionDownloadTask) {
    
  }
  
}

#endif
