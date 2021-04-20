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

@objc
class NYPLAxisService: NSObject {
  private weak var delegate: NYPLBookDownloadBroadcasting?
  private let isbn: String
  private let bookVaultId: String
  private let dedicatedWriteURL: URL
  private let fileURL: URL
  private let baseURL: URL
  private let book: NYPLBook
  private let deviceInfoProviding: NYPLDeviceInfoProviding
  private var packageEndpointproviding: NYPLAxisPackageEndpointProviding
  private let packagePathProviding: NYPLAxisPackagePathPrefixProviding
  private let axisKeysProviding: NYPLAxisKeysProviding
  private let dispatchGroup: DispatchGroup
  private let assetWriter: NYPLAssetWriting
  
  // MARK: - Static Constants
  static let reason = "reason"
  
  // Initialization constants
  static private let initializationFailureSummary = "AXIS: Failed instantiating AxisService"
  static let nilDataFromFileURLFailure = "Failed to get data from fileURL"
  static private let jsonSerializationFailure = "Failed to get json object from data"
  static private let requiredKeysFailure = "Failed to get required keys from downloaded file"
  static private let jsonContent = "jsonContent"
  
  // Content Downloading constants
  static private let writeFailureSummary = "AXIS: Failed writing item to specified write URL"
  static private let failedDownloadingItemSummary = "AXIS: Failed downloading item"
  static private let failedDownloadingAssetsFromPackageSummary = "AXIS: Failed downloading content from pacakge.opf"
  
  // MARK: - Initialization
  init(delegate: NYPLBookDownloadBroadcasting?,
       isbn: String,
       bookVaultId: String,
       fileURL: URL,
       book: NYPLBook,
       deviceInfoProviding: NYPLDeviceInfoProviding,
       packageEndpointproviding: NYPLAxisPackageEndpointProviding,
       packagePathProviding: NYPLAxisPackagePathPrefixProviding,
       axisKeysProviding: NYPLAxisKeysProviding,
       assetWriter: NYPLAssetWriting) {
    
    self.axisKeysProviding = axisKeysProviding
    self.isbn = isbn
    self.fileURL = fileURL
    self.delegate = delegate
    self.bookVaultId = bookVaultId
    self.baseURL = axisKeysProviding.baseURL.appendingPathComponent(isbn)
    self.book = book
    self.deviceInfoProviding = deviceInfoProviding
    self.packagePathProviding = NYPLAxisPackagePathPrefixProvider()
    self.dispatchGroup = DispatchGroup()
    self.assetWriter = NYPLAssetWriter()
    self.packageEndpointproviding = packageEndpointproviding
    self.dedicatedWriteURL = fileURL
      .deletingLastPathComponent()
      .appendingPathComponent(book.identifier.sha256())
  }
  
  /// Fulfill AxisNow license. Notifies NYPLBookDownloadBroadcasting upon completion or failure.
  
  /// - Parameters:
  ///   - downloadTask: downloadTask download task
  @objc func fulfillAxisLicense(downloadTask: URLSessionDownloadTask) {
    DispatchQueue.global(qos: .utility).async {
      
      // TODO: OE-63: As soon as we experience a failure we should stop the
      // download process and delete all downloaded files.
      
      self.downloadLicense(forBook: self.book)
      self.downloadEncryption(forBook: self.book)
      self.downloadContainer(forBook: self.book)
      self.downloadPackage(forBook: self.book)
      self.downloadAssetsFromPackage(forBook: self.book)
      
      self.dispatchGroup.notify(queue: .global(qos: .utility)) {
        _ = self.delegate?.replaceBook(self.book,
                                       withFileAtURL: self.dedicatedWriteURL,
                                       forDownloadTask: downloadTask)
      }
    }
  }
  
  // MARK: - Download License
  private func downloadLicense(forBook book: NYPLBook) {
    dispatchGroup.wait()
    dispatchGroup.enter()
    let writeURL = dedicatedWriteURL
      .appendingPathComponent(axisKeysProviding.desiredNameForLicenseFile)
    
    guard let cypher = NYPLRSACypher() else {
      // No need to log error here since NYPLRSACypher takes care of that.
      return
    }
    
    let licenseURL = NYPLAxisLicenseURLGenerator(
      baseURL: axisKeysProviding.licenseBaseURL,
      bookVaultId: bookVaultId,
      clientIP: deviceInfoProviding.clientIP,
      cypher: cypher,
      deviceID: deviceInfoProviding.deviceID,
      isbn: isbn
    ).generateLicenseURL()
    
    downloadItem(from: licenseURL, at: writeURL)
  }
  
  // MARK: - Download Encryption
  private func downloadEncryption(forBook book: NYPLBook) {
    dispatchGroup.wait()
    dispatchGroup.enter()
    
    let encryptionURL = baseURL
      .appendingPathComponent(axisKeysProviding.encryptionDownloadEndpoint)
    
    let writeURL = self.dedicatedWriteURL
      .appendingPathComponent(encryptionURL.lastPathComponent)
    
    downloadItem(from: encryptionURL, at: writeURL)
  }
  
  // MARK: - Download Container
  private func downloadContainer(forBook book: NYPLBook) {
    dispatchGroup.wait()
    dispatchGroup.enter()
    
    let containerURL = baseURL
      .appendingPathComponent(axisKeysProviding.containerDownloadEndpoint)
    
    let writeURL = self.dedicatedWriteURL
      .appendingPathComponent(containerURL.lastPathComponent)
    
    downloadItem(from: containerURL, at: writeURL)
  }
  
  // MARK: - Download Package
  private func downloadPackage(forBook book: NYPLBook) {
    dispatchGroup.wait()
    dispatchGroup.enter()
    guard let endpoint = packageEndpoint else {
      dispatchGroup.leave()
      return
    }
    
    let packageURL = baseURL.appendingPathComponent(endpoint)
    let writeURL = self.dedicatedWriteURL.appendingPathComponent(endpoint)
    downloadItem(from: packageURL, at: writeURL)
  }
  
  // MARK: - Download assets listed in package
  private func downloadAssetsFromPackage(forBook book: NYPLBook) {
    dispatchGroup.wait()
    guard let packageEndpoint = packageEndpoint else {
      // No need to log error here since an error is already logged when
      // pacakgeEndpoint generation returns nil
      delegate?.failDownloadWithAlert(forBook: self.book)
      return
    }
    
    let packageURL = dedicatedWriteURL.appendingPathComponent(packageEndpoint)
    let data = try? Data(contentsOf: packageURL)
    guard let axisXML = NYPLAxisXML(data: data) else {
      NYPLErrorLogger.logError(
        withCode: .axisDRMFulfillmentFail,
        summary: NYPLAxisService.failedDownloadingAssetsFromPackageSummary,
        metadata: [
          NYPLAxisService.reason: NYPLAxisXML.NYPLXMLGenerationFailure
      ])
      
      return
    }
    
    let hrefs = axisXML.findRecursivelyInAttributes(axisKeysProviding.hrefKey)
    
    for href in hrefs {
      let endpath: String
      if let pathPrefix = packagePathPrefix {
        endpath = "\(pathPrefix)\(href)"
      } else {
        endpath = href
      }
      
      let linkURL = baseURL
        .appendingPathComponent(endpath)
      
      let writeURL = self.dedicatedWriteURL
        .appendingPathComponent(endpath)
      
      dispatchGroup.enter()
      downloadItem(from: linkURL, at: writeURL)
    }
  }
  
  // MARK: - Helper Methods
  private func downloadItem(from url: URL, at writeURL: URL) {
    
    // TODO: OE-62: Axis code might need specific requirements for caching and
    // using the shared network executor will result in whatever we choose to
    // user there.
    
    NYPLNetworkExecutor.shared.GET(url) { (result) in
      switch result {
      case .success(let data, _):
        do {
          try self.assetWriter.writeAsset(data, atURL: writeURL)
          self.dispatchGroup.leave()
        } catch {
          
          NYPLErrorLogger.logError(
            error,
            summary: NYPLAxisService.writeFailureSummary,
            metadata: ["writeURL": writeURL.path,
                       "itemURL": url.absoluteString])
          
          self.dispatchGroup.leave()
          self.delegate?.failDownloadWithAlert(forBook: self.book)
        }
      case .failure(let error, _):
        NYPLErrorLogger.logError(
          error,
          summary: NYPLAxisService.failedDownloadingItemSummary,
          metadata: ["itemURL": url.absoluteString])
        
        self.dispatchGroup.leave()
        self.delegate?.failDownloadWithAlert(forBook: self.book)
      }
    }
  }
  
  private var packageEndpoint: String? {
    return self.packageEndpointproviding.getPackageEndpoint()
  }
  
  private var packagePathPrefix: String? {
    return packagePathProviding
      .getPackagePathPrefix(packageEndpoint: packageEndpoint)
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
    
    let axisKeysProviding = NYPLAxisKeysProvider()
    
    guard
      let isbn = json[axisKeysProviding.isbnKey] as? String,
      let bookVaultId = json[axisKeysProviding.bookVaultKey] as? String
      else {
        NYPLAxisService
          .logInitializationFailure(NYPLAxisService.requiredKeysFailure,
                                    json: json)
        
        delegate.failDownloadWithAlert(forBook: book)
        return nil
    }
    
    
    let dedicatedWriteURL = fileURL
      .deletingLastPathComponent()
      .appendingPathComponent(book.identifier.sha256())
    
    let containerURL = dedicatedWriteURL
      .appendingPathComponent(axisKeysProviding.containerFileName)
    let endpointProviding = NYPLAxisPackageEndpointProvider(
      containerURL: containerURL,
      fullPathKey: axisKeysProviding.fullPathKey)
    
    let packagePathProviding = NYPLAxisPackagePathPrefixProvider()
    let assetWriting = NYPLAssetWriter()
    
    self.init(delegate: delegate,
              isbn: isbn,
              bookVaultId: bookVaultId,
              fileURL: fileURL,
              book: book,
              deviceInfoProviding: deviceInfoProviding,
              packageEndpointproviding: endpointProviding,
              packagePathProviding: packagePathProviding,
              axisKeysProviding: axisKeysProviding,
              assetWriter: assetWriting)
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
