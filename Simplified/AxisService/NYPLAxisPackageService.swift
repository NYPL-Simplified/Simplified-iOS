//
//  NYPLAxisPackageService.swift
//  Open eBooks
//
//  Created by Raman Singh on 2021-05-11.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation

protocol NYPLAxisPackageHandling {
  func downloadPackageContent()
}

/// Downloads the package file and other required files mentioned in the package file (e.g. `Fonts`,
/// `Images`, `xHTMLs` etc.) requiredfor the book.
struct NYPLAxisPackageService: NYPLAxisPackageHandling {
  
  static private let axisXMLGenerationFailureSummary = "NYPLAxisPackageService failed to generate NYPLAxisXML from package file"
  
  private let axisItemDownloader: NYPLAxisItemDownloading
  private let axisKeysProvider: NYPLAxisKeysProviding
  private let baseURL: URL
  private let packageEndpointProvider: NYPLAxisPackageEndpointProviding
  private let packagePathProvider: NYPLAxisPackagePathPrefixProviding
  private let parentDirectory: URL
  
  init(axisItemDownloader: NYPLAxisItemDownloading,
       axisKeysProvider: NYPLAxisKeysProviding,
       baseURL: URL,
       parentDirectory: URL,
       packagePathProvider: NYPLAxisPackagePathPrefixProviding = NYPLAxisPackagePathPrefixProvider()) {
    
    self.axisItemDownloader = axisItemDownloader
    self.axisKeysProvider = axisKeysProvider
    self.baseURL = baseURL
    self.parentDirectory = parentDirectory
    self.packagePathProvider = packagePathProvider
    
    let containerURL = parentDirectory
      .appendingPathComponent(axisKeysProvider.containerDownloadEndpoint)
    self.packageEndpointProvider = NYPLAxisPackageEndpointProvider(
      containerURL: containerURL,
      fullPathKey: axisKeysProvider.fullPathKey)
  }
  
  /// Downloads the package file and other required files mentioned in the package file (e.g. `Fonts`,
  /// `Images`, `xHTMLs` etc.) requiredfor the book.
  func downloadPackageContent() {
    axisItemDownloader.dispatchGroup.wait()
    self.downloadPackageFile()
    self.downloadContentFromPackageFile()
  }
  
  /// Downloads the package file.
  private func downloadPackageFile() {
    axisItemDownloader.dispatchGroup.wait()
    
    // No need to log error here since axisItemDownloader already logs one.
    guard axisItemDownloader.shouldContinue else {
      return
    }
    
    axisItemDownloader.dispatchGroup.enter()
    
    guard let endpoint = packageEndpointProvider.getPackageEndpoint()
    else {
      axisItemDownloader.leaveGroupAndStopDownload()
      return
    }
    
    let packageURL = baseURL.appendingPathComponent(endpoint)
    let writeURL = parentDirectory.appendingPathComponent(endpoint)
    axisItemDownloader.downloadItem(from: packageURL, at: writeURL)
  }
  
  /// Finds links to all the requried items from the package file and downloads them.
  private func downloadContentFromPackageFile() {
    
    axisItemDownloader.dispatchGroup.wait()
    guard
      axisItemDownloader.shouldContinue,
      let endpoint = packageEndpointProvider.getPackageEndpoint()
    else {
      return
    }
    axisItemDownloader.dispatchGroup.enter()
    let packageLocation = parentDirectory.appendingPathComponent(endpoint)
    guard
      let data = try? Data(contentsOf: packageLocation),
      let axisXML = NYPLAxisXML(data: data)
    else {
      NYPLErrorLogger.logError(
        withCode: .axisDRMFulfillmentFail,
        summary: NYPLAxisPackageService.axisXMLGenerationFailureSummary)
      axisItemDownloader.leaveGroupAndStopDownload()
      return
    }
    axisItemDownloader.dispatchGroup.leave()
    let hrefs = Set(axisXML.findRecursivelyInAttributes(axisKeysProvider.hrefKey))
    let packagePathPrefix = packagePathProvider
      .getPackagePathPrefix(packageEndpoint: endpoint)
    
    for href in hrefs {
      let endpath: String
      if let pathPrefix = packagePathPrefix {
        endpath = "\(pathPrefix)\(href)"
      } else {
        endpath = href
      }

      let linkURL = baseURL
        .appendingPathComponent(endpath)

      let writeURL = self.parentDirectory
        .appendingPathComponent(endpath)

      axisItemDownloader.dispatchGroup.enter()
      axisItemDownloader.downloadItem(from: linkURL, at: writeURL)
    }
    
  }
  
}
