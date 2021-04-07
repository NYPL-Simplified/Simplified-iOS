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

private struct AxisHelper {
  static let isbnKey = "isbn"
  static let bookVaultKey = "book_vault_uuid"
  /// This is the url for downloading content for a given book with axis drm.
  static let baseURL = URL(string: "https://node.axisnow.com/content/stream/")!
  /// Default base URL for downloading license for a book from Axis
  static let licenseBaseURL = URL(string: "https://node.axisnow.com/license")!
  static let desiredNameForLicenseFile = "license.json"
  static let containerDownloadEndpoint = "META-INF/container.xml"
  static let containerFileName = "container.xml"
  static let encryptionDownloadEndpoint = "META-INF/encryption.xml"
  static let hrefKey = "href"
  static let fullPathKey = "full-path"
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
  
  /// Failable initializer that extracts `isbn` and `book_vault_id` from the downloaded file. Returns
  /// nil if keys are not present and notifies delegate.
  /// - Parameters:
  ///   - delegate: An object confirming to NYPLBookDownloadBroadcasting protocol.
  ///   - fileURL: Local url of the downloaded file.
  ///   - book: NYPLBook object
  @objc init?(delegate: NYPLBookDownloadBroadcasting,
              fileURL: URL,
              forBook book: NYPLBook) {
    /*
     The downloaded file is supposed to have a key for isbn and
     book_vauld_uuid. Those keys are needed to download license.json,
     encryption.xml, container.xml, package.opf, and assets enclosed in
     package.opf.
     */
    guard
      let data = try? Data(contentsOf: fileURL),
      let jsonObject = try? JSONSerialization
        .jsonObject(with: data, options: .fragmentsAllowed),
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
    self.baseURL = AxisHelper.baseURL.appendingPathComponent(isbn)
    self.book = book
  }
  
  /// Fulfill AxisNow license. Notifies NYPLBookDownloadBroadcasting upon completion or failure.
  /// - Parameters:
  ///   - downloadTask: downloadTask download task
  @objc func fulfillAxisLicense(downloadTask: URLSessionDownloadTask) {
    DispatchQueue.global(qos: .utility).async {
      let dispatchGroup = DispatchGroup()
      self.downloadLicense(group: dispatchGroup, forBook: self.book)
      self.downloadEncryption(group: dispatchGroup, forBook: self.book)
      self.downloadContainer(group: dispatchGroup, forBook: self.book)
      self.downloadPackage(group: dispatchGroup, forBook: self.book)
      self.downloadAssetsFromPackage(group: dispatchGroup, forBook: self.book)
      
      dispatchGroup.notify(queue: .global(qos: .utility)) {
        print("Book content downloaded!")
        
        // TODO: SIMPLY-3673: Update replaceBook method to accomodate axis drm content
        /*
         _ = self.delegate?.replaceBook(
         book,
         withFileAtURL: self.dedicatedWriteURL,
         forDownloadTask: downloadTask)
         */
      }
    }
  }
  
  // MARK: - Download License
  private func downloadLicense(group: DispatchGroup, forBook book: NYPLBook) {
    group.wait()
    group.enter()
    let writeURL = dedicatedWriteURL
      .appendingPathComponent(AxisHelper.desiredNameForLicenseFile)
    
    guard let cypher = NYPLRSACypher() else {
      NYPLErrorLogger.logError(nil, summary: "Failed to generate NYPLRSACypher")
      return
    }
    
    // TODO: SIMPLY-3672: Generate Device ID and Device IP address to be used in
    // license URL for Axis DRM content
    let licenseURL = NYPLAxisLicenseURLGenerator(
      baseURL: AxisHelper.licenseBaseURL,
      bookVaultId: bookVaultId,
      clientIP: "192.168.0.1",
      cypher: cypher,
      deviceID: UUID().uuidString,
      isbn: isbn
    ).generateLicenseURL()
    
    downloadItem(from: licenseURL, at: writeURL, group: group)
  }
  
  // MARK: - Download Encryption
  private func downloadEncryption(group: DispatchGroup, forBook book: NYPLBook) {
    group.wait()
    group.enter()
    
    let encryptionURL = baseURL
      .appendingPathComponent(AxisHelper.encryptionDownloadEndpoint)
    
    let writeURL = self.dedicatedWriteURL
      .appendingPathComponent(encryptionURL.lastPathComponent)
    
    downloadItem(from: encryptionURL, at: writeURL, group: group)
  }
  
  // MARK: - Download Container
  private func downloadContainer(group: DispatchGroup, forBook book: NYPLBook) {
    group.wait()
    group.enter()
    
    let containerURL = baseURL
      .appendingPathComponent(AxisHelper.containerDownloadEndpoint)
    
    let writeURL = self.dedicatedWriteURL
      .appendingPathComponent(containerURL.lastPathComponent)
    
    downloadItem(from: containerURL, at: writeURL, group: group)
  }
  
  // MARK: - Download Package
  func downloadPackage(group: DispatchGroup, forBook book: NYPLBook) {
    group.wait()
    group.enter()
    guard let endpoint = packageEndpoint else {
      group.leave()
      return
    }
    
    let packageURL = baseURL.appendingPathComponent(endpoint)
    let writeURL = self.dedicatedWriteURL.appendingPathComponent(endpoint)
    downloadItem(from: packageURL, at: writeURL, group: group)
  }
  
  // MARK: - Download assets listed in package
  private func downloadAssetsFromPackage(group: DispatchGroup, forBook book: NYPLBook) {
    group.wait()
    guard let packageEndpoint = packageEndpoint else {
      NYPLErrorLogger.logError(
        nil,
        summary: "Failed to generate container endpoint")
      delegate?.failDownloadWithAlert(forBook: self.book)
      return
    }
    
    let packageURL = self.dedicatedWriteURL.appendingPathComponent(packageEndpoint)
    guard
      let data = try? Data(contentsOf: packageURL),
      let xml = NYPLXML(data: data)
      else {
        NYPLErrorLogger.logError(
          nil,
          summary: "Failed to generate NYPLXML")
        delegate?.failDownloadWithAlert(forBook: self.book)
        return
    }
    
    let axisXML = NYPLAxisXML(xml: xml)
    let hrefs = axisXML.findRecursivelyInAttributes(AxisHelper.hrefKey)
    
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
      
      group.enter()
      downloadItem(from: linkURL, at: writeURL, group: group)
    }
  }
  
  // MARK: - Helper Methods
  private func downloadItem(from url: URL,
                            at writeURL: URL,
                            group: DispatchGroup) {
    
    let downloader = NYPLContentDownloader(
      networkExecutor: NYPLNetworkExecutor.shared)
    
    downloader.downloadContent(from: url) { (result) in
      switch result {
      case .success(let data):
        do {
          try NYPLAssetWriter.writeAsset(data, atURL: writeURL)
          group.leave()
        } catch {
          NYPLErrorLogger.logError(
            error,
            summary: "Failed writing item to \(writeURL)")
          
          group.leave()
          self.delegate?.failDownloadWithAlert(forBook: self.book)
        }
      case .failure(let error):
        NYPLErrorLogger.logError(
          error,
          summary: "Failed downloading item from \(url)")
        
        group.leave()
        self.delegate?.failDownloadWithAlert(forBook: self.book)
      }
    }
  }
  
  /// We're going with lazy initialization instead of a computed property here because this variable is not
  /// needed until the `container.xml` file has been downloaded. And since  it's going to produce the
  /// same output every time, making it a computed property would be an overkill.
  lazy private var packageEndpoint: String? = {
    let containerURL = dedicatedWriteURL
      .appendingPathComponent(AxisHelper.containerFileName)
    
    guard
      let data = try? Data(contentsOf: containerURL),
      let xml = NYPLXML(data: data)
      else {
        return nil
    }
    
    return NYPLAxisXML(xml: xml)
      .findRecursivelyInAttributes(AxisHelper.fullPathKey)
      .first
  }()
  
  /// This variable gets called inside a loop when downloading assets mentioned in the package file. It relies
  /// on `packageEndpoint` which relies on `container.xml`which has already been downloaded
  /// in the steps leading up to the usage of this variable. Also, it will produce the same output every time it's
  /// called so creating it a computed property does not make sense.
  lazy private var packagePathPrefix: String? = {
    guard let packageEndpoint = packageEndpoint else {
      return nil
    }
    
    return URL(string: packageEndpoint)?
      .deletingLastPathComponent()
      .absoluteString
  }()
  
}

#endif
