//
//  AxisService.swift
//  Simplified
//
//  Created by Raman Singh on 2021-04-01.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation

#if AXIS

/// Responsible for moving book content to designated loation upon successful download and showing
/// alert upon failure.
@objc protocol NYPLBookDownloadBroadcasting {
  func failDownloadWithAlert(forBook book: NYPLBook)
  func replaceBook(_ book: NYPLBook,
                   withFileAtURL sourceLocation: URL,
                   forDownloadTask downloadtask: URLSessionDownloadTask) -> Bool
}

/**
 Here's how book downloading works:
 1. When we send a download request to server, we get a file with `isbn` & `book_vault_uuid` key..
 2. If the book's management rights are the ones with axis, we initiate NYPLAxisService and call the
 `NYPLAxisService::fulfillAxisLicense:downloadTask` method.
 3. Using `isbn` & `book_vault_uuid` from the file, we create a url to download a license file for the axis
 book.
 4. If the license download is successful, and the license is valid, we download two files, `Container.xml`
 & `Encryption.xml` from Axis using the isbn key.
 5. From the `container.xml file`, we extract the url for a pacakge file and download the package and
 download all the required book content mentioned in the package file.
 6. When all the files are downloaded, we consider this as book download success and call the method
 associated with success  (`replaceBook:withFileAtURL:forDownloadTask`) on our
 NYPLBookDownloadBroadcasting delegate.
 7. If we experience a failure at any point during the download process, we stop the process, delete the
 downloaded files, and call our delegate's `failDownloadWithAlert:` method.
 */
@objc class NYPLAxisService: NSObject {
  private let axisItemDownloader: NYPLAxisItemDownloading
  private let book: NYPLBook
  private let dedicatedWriteURL: URL
  private let licenseService: NYPLAxisLicenseHandling
  private let metadataDownloader: NYPLAxisMetadataContentHandling
  private let packageDownloader: NYPLAxisPackageHandling
  private weak var delegate: NYPLBookDownloadBroadcasting?
  
  
  // MARK: - Static Constants
  static let reason = "AxisDRMReason"
  
  // Initialization constants
  static private let initializationFailureSummary = "AXIS: Failed instantiating AxisService"
  static let nilDataFromFileURLFailure = "Failed to get data from fileURL"
  static private let jsonSerializationFailure = "Failed to get json object from data"
  static private let requiredKeysFailure = "Failed to get required keys from downloaded file"
  static private let jsonContent = "jsonContent"
  
  // MARK: - Initialization
  init(axisItemDownloader: NYPLAxisItemDownloading,
       book: NYPLBook,
       dedicatedWriteURL: URL,
       delegate: NYPLBookDownloadBroadcasting?,
       licenseService: NYPLAxisLicenseHandling,
       metadataDownloader: NYPLAxisMetadataContentHandling,
       packageDownloader: NYPLAxisPackageHandling) {
    
    self.axisItemDownloader = axisItemDownloader
    self.book = book
    self.dedicatedWriteURL = dedicatedWriteURL
    self.delegate = delegate
    self.licenseService = licenseService
    self.metadataDownloader = metadataDownloader
    self.packageDownloader = packageDownloader
    super.init()
    self.axisItemDownloader.delegate = self
  }
  
  /// Fulfill AxisNow license. Notifies NYPLBookDownloadBroadcasting upon completion or failure.
  /// - Parameters:
  ///   - downloadTask: downloadTask download task
  @objc func fulfillAxisLicense(downloadTask: URLSessionDownloadTask) {
    DispatchQueue.global(qos: .utility).async {
      self.downloadAndValidateLicense()
      self.downloadMetadataContent()
      self.downloadPackage()
      self.axisItemDownloader.dispatchGroup.notify(queue: .global(qos: .utility)) {
        // TODO:- OE-128: Fix reversed hierarchy
        // weak self will result in deallocation before book completion
        guard self.axisItemDownloader.shouldContinue else { return }
        _ = self.delegate?.replaceBook(
          self.book, withFileAtURL: self.dedicatedWriteURL,
          forDownloadTask: downloadTask)
      }
    }
  }
  
  // MARK: - Download & Validate License
  private func downloadAndValidateLicense() {
    licenseService.downloadLicense()
    licenseService.saveBookInfoFromLicense()
    licenseService.validateLicense()
    licenseService.deleteLicenseFile()
  }
  
  // MARK: - Download Encryption & Container
  private func downloadMetadataContent() {
    metadataDownloader.downloadContent()
  }
  
  // MARK: - Download Package file & content mentioned inside
  private func downloadPackage() {
    packageDownloader.downloadPackageContent()
  }
  
}

extension NYPLAxisService: NYPLAxisItemDownloadTerminationListening {
  
  func downloaderDidTerminate() {
    try? FileManager.default.removeItem(at: self.dedicatedWriteURL)
    self.delegate?.failDownloadWithAlert(forBook: self.book)
  }
  
}

extension NYPLAxisService {
  
  /// Failable initializer that extracts `isbn` and `book_vault_id` from the downloaded file. Returns
  /// nil if keys are not present and notifies delegate.
  /// - Parameters:
  ///   - delegate: An object confirming to NYPLBookDownloadBroadcasting protocol.
  ///   - fileURL: Local url of the downloaded file.
  ///   - deviceInfoProvider: An NYPLDeviceInfoProviding object to get deviceID and clientIP
  ///   required for license URL generation
  ///   - book: NYPLBook object
  @objc convenience init?(delegate: NYPLBookDownloadBroadcasting,
                          fileURL: URL,
                          deviceInfoProviding: NYPLDeviceInfoProviding,
                          forBook book: NYPLBook) {
    
    guard let data = try? Data(contentsOf: fileURL) else {
      NYPLAxisService
        .logInitializationFailure(NYPLAxisService.nilDataFromFileURLFailure)
      
      delegate.failDownloadWithAlert(forBook: book)
      return nil
    }
    
    guard
      let jsonObject = try? JSONSerialization
        .jsonObject(with: data, options: .fragmentsAllowed),
      let json = jsonObject as? [String: Any] else {
        NYPLAxisService
          .logInitializationFailure(NYPLAxisService.jsonSerializationFailure)
        
        delegate.failDownloadWithAlert(forBook: book)
        return nil
    }
    
    /*
     The downloaded file is supposed to have a key for isbn and
     book_vault_uuid. Those keys are needed to download license.json,
     encryption.xml, container.xml, package.opf, and assets enclosed in
     package.opf.
     */
    
    let axisKeysProvider = NYPLAxisKeysProvider()
    
    guard
      let isbn = json[axisKeysProvider.isbnKey] as? String,
      let bookVaultId = json[axisKeysProvider.bookVaultKey] as? String,
      let cypher = NYPLRSACypher()
      else {
        NYPLAxisService
          .logInitializationFailure(NYPLAxisService.requiredKeysFailure,
                                    json: json)
        
        delegate.failDownloadWithAlert(forBook: book)
        return nil
    }
    
    self.init(axisKeysProvider: axisKeysProvider,
              book: book,
              bookVaultId: bookVaultId,
              cypher: cypher,
              delegate: delegate,
              deviceInfoProviding: deviceInfoProviding,
              fileURL: fileURL,
              isbn: isbn)
  }
  
  /// Convenience initialzer to be used for testing
  /// - Parameters:
  ///   - axisKeysProvider: NYPLAxisKeysProviding object
  ///   - book: NYPLBook that is to be downloaded
  ///   - bookVaultId: BookVaultID for the given book extracted from the downloaded file from the
  ///   server when book download begins.
  ///   - cypher: NYPLRSACryptographing object to be used for downloading license
  ///   - delegate: An object confirming to NYPLBookDownloadBroadcasting protocol to be notified
  ///   when download fails or succeeds.
  ///   - deviceInfoProviding: An NYPLDeviceInfoProviding object to get deviceID and clientIP
  ///   required for license URL generation
  ///   - fileURL: Local url of the downloaded file.
  ///   - isbn: ISBN for the book to be downloaded
  convenience init(axisKeysProvider: NYPLAxisKeysProviding,
                   book: NYPLBook,
                   bookVaultId: String,
                   cypher: NYPLRSACryptographing,
                   delegate: NYPLBookDownloadBroadcasting,
                   deviceInfoProviding: NYPLDeviceInfoProviding,
                   fileURL: URL,
                   isbn: String) {
    
    
    let baseURL = axisKeysProvider.baseURL.appendingPathComponent(isbn)
    let dispatchGroup = DispatchGroup()
    
    let dedicatedWriteURL = fileURL
      .deletingLastPathComponent()
      .appendingPathComponent(book.identifier.sha256())
    
    let axisItemDownloader = NYPLAxisItemDownloader(dispatchGroup: dispatchGroup)
    
    let licenseService = NYPLAxisLicenseService(
      axisItemDownloader: axisItemDownloader, axisKeysProvider: axisKeysProvider,
      bookVaultId: bookVaultId, cypher: cypher,
      deviceInfoProvider: deviceInfoProviding, isbn: isbn,
      parentDirectory: dedicatedWriteURL)
    
    let metadataService = NYPLAxisMetadataService(
      axisItemDownloader: axisItemDownloader, axisKeysProvider: axisKeysProvider,
      baseURL: baseURL, parentDirectory: dedicatedWriteURL)
    
    let packageDownloader = NYPLAxisPackageService(
      axisItemDownloader: axisItemDownloader, axisKeysProvider: axisKeysProvider,
      baseURL: baseURL, parentDirectory: dedicatedWriteURL)
    
    self.init(axisItemDownloader: axisItemDownloader,
              book: book,
              dedicatedWriteURL: dedicatedWriteURL,
              delegate: delegate,
              licenseService: licenseService,
              metadataDownloader: metadataService,
              packageDownloader: packageDownloader)
  }
  
  private static func logInitializationFailure(_ reason: String,
                                               json: [String: Any]? = nil) {
    
    var metadata: [String: Any] = [:]
    metadata[NYPLAxisService.reason] = reason
    if let json = json {
      metadata[NYPLAxisService.jsonContent] = json
    }
    
    NYPLErrorLogger.logError(
      withCode: .axisDRMFulfillmentFail,
      summary: NYPLAxisService.initializationFailureSummary,
      metadata: metadata)
  }
  
}

#endif
