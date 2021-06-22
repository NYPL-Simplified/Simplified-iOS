//
//  NYPLAxisPackageService.swift
//  Open eBooks
//
//  Created by Raman Singh on 2021-05-11.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation

protocol NYPLAxisPackageHandling {
  func makeDownloadPackageContentTasks() -> [NYPLAxisTask]
  func cancelPackageDownload(with error: NYPLAxisError)
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
  private let aggregator = NYPLAxisTaskAggregator()
  
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
  
  /// Creates a task for downloading the package file  and other required files mentioned in the package
  /// file (e.g. `Fonts`, `Images`, `xHTMLs` etc.) requiredfor the book.
  func makeDownloadPackageContentTasks() -> [NYPLAxisTask] {
    let packageFileTask = makeDownloadPackageFileTask()
    let packageContentTask = makeDownloadContentFromPackageFileTask()
    return [packageFileTask, packageContentTask]
  }
  
  /// Creates a task for downloading the package file.
  private func makeDownloadPackageFileTask() -> NYPLAxisTask {
    return NYPLAxisTask() { task in
      
      guard let endpoint = packageEndpointProvider.getPackageEndpoint()
      else {
        task.failed(with: .invalidContainerFile)
        return
      }
      
      let packageURL = baseURL.appendingPathComponent(endpoint)
      let writeURL = parentDirectory.appendingPathComponent(endpoint)
      axisItemDownloader.downloadItem(from: packageURL, at: writeURL) {
        task.processResult($0)
      }
    }
  }
  
  /// Creates a task for finding links to all the requried items from the package file and downloading them.
  private func makeDownloadContentFromPackageFileTask() -> NYPLAxisTask {
    return NYPLAxisTask() { task in
      
      guard let endpoint = packageEndpointProvider.getPackageEndpoint()
      else {
        task.failed(with: .invalidPackageFile)
        return
      }
      
      let packageLocation = parentDirectory.appendingPathComponent(endpoint)
      guard
        let data = try? Data(contentsOf: packageLocation),
        let axisXML = NYPLAxisXML(data: data)
      else {
        NYPLErrorLogger.logError(
          withCode: .axisDRMFulfillmentFail,
          summary: NYPLAxisPackageService.axisXMLGenerationFailureSummary)
        task.failed(with: .invalidPackageFile)
        return
      }
      
      let hrefs = Set(axisXML.findRecursivelyInAttributes(axisKeysProvider.hrefKey))
      let packagePathPrefix = packagePathProvider
        .getPackagePathPrefix(packageEndpoint: endpoint)
      
      let urls = hrefs.map { href -> URL in
        let endpath = "\(packagePathPrefix ?? "")\(href)"
        return baseURL.appendingPathComponent(endpath)
      }
      
      axisItemDownloader.addURLsToDownloadProgress(urls)
      
      let subtasks = hrefs.map { href -> NYPLAxisTask in
        let endpath = "\(packagePathPrefix ?? "")\(href)"
        let linkURL = baseURL.appendingPathComponent(endpath)
        let writeURL = self.parentDirectory.appendingPathComponent(endpath)
        return NYPLAxisTask() { task in
          axisItemDownloader.downloadItem(from: linkURL, at: writeURL) {
            task.processResult($0)
          }
        }
      }
      
      aggregator
        .addTasks(subtasks)
        .run()
        .onCompletion { (result) in
          task.processResult(result)
        }
    }
  }
  
  func cancelPackageDownload(with error: NYPLAxisError) {
    aggregator.cancelAllTasks(with: error)
  }
  
}
