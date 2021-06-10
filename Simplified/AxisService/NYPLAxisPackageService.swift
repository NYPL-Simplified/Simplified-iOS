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
  private let taskSynchnorizer: NYPLAxisTasksSynchorizing
  
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
    
    self.taskSynchnorizer = axisItemDownloader.tasksSynchnorizer
  }
  
  /// Downloads the package file and other required files mentioned in the package file (e.g. `Fonts`,
  /// `Images`, `xHTMLs` etc.) requiredfor the book.
  func downloadPackageContent() {
    self.downloadPackageFile()
    self.downloadContentFromPackageFile()
  }
  
  /// Downloads the package file.
  private func downloadPackageFile() {
    // No need to log error here since axisItemDownloader already logs one.
    guard axisItemDownloader.shouldContinue else {
      return
    }
    
    taskSynchnorizer.startSynchronizedTaskWhenIdle()
    
    guard let endpoint = packageEndpointProvider.getPackageEndpoint()
    else {
      axisItemDownloader.terminateDownloadProcess()
      return
    }
    
    taskSynchnorizer.endSynchronizedTask()
    
    let packageURL = baseURL.appendingPathComponent(endpoint)
    let writeURL = parentDirectory.appendingPathComponent(endpoint)
    axisItemDownloader.downloadItem(from: packageURL, at: writeURL)
  }
  
  /// Finds links to all the requried items from the package file and downloads them.
  private func downloadContentFromPackageFile() {
    
    guard
      axisItemDownloader.shouldContinue,
      let endpoint = packageEndpointProvider.getPackageEndpoint()
    else {
      return
    }

    taskSynchnorizer.startSynchronizedTaskWhenIdle()
    let packageLocation = parentDirectory.appendingPathComponent(endpoint)
    guard
      let data = try? Data(contentsOf: packageLocation),
      let axisXML = NYPLAxisXML(data: data)
    else {
      NYPLErrorLogger.logError(
        withCode: .axisDRMFulfillmentFail,
        summary: NYPLAxisPackageService.axisXMLGenerationFailureSummary)
      axisItemDownloader.terminateDownloadProcess()
      return
    }

    taskSynchnorizer.endSynchronizedTask()
    let hrefs = Set(axisXML.findRecursivelyInAttributes(axisKeysProvider.hrefKey))
    let packagePathPrefix = packagePathProvider
      .getPackagePathPrefix(packageEndpoint: endpoint)
    
    let dict: [URL: URL] = hrefs.reduce(into: [:]) {
      let endpath = "\(packagePathPrefix ?? "")\($1)"
      let linkURL = baseURL.appendingPathComponent(endpath)
      let writeURL = parentDirectory.appendingPathComponent(endpath)
      $0[linkURL] = writeURL
    }
    
    axisItemDownloader.downloadItems(with: dict)
  }
  
}
