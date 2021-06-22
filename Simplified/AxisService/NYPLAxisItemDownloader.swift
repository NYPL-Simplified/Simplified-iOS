//
//  NYPLAxisItemDownloader.swift
//  Open eBooks
//
//  Created by Raman Singh on 2021-05-12.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation

protocol NYPLAxisDownloadProgressListening: class {
  func downloadProgressDidUpdate(_ progress: Double)
}

protocol NYPLAxisItemDownloading: class {
  func downloadItem(from url: URL, at writeURL: URL, completion: @escaping (Result<Bool, Error>) -> Void)
  func addURLsToDownloadProgress(_ urls: [URL])
  var delegate: NYPLAxisDownloadProgressListening? { get set }
}

class NYPLAxisItemDownloader: NYPLAxisItemDownloading {
  
  // Content Downloading constants
  static private let failedWritingItemSummary = "AXIS: Failed writing item to specified write URL"
  static private let failedDownloadingItemSummary = "AXIS: Failed downloading item"
  
  private let assetWriter: NYPLAssetWriting
  private var downloader: NYPLAxisContentDownloading
  private let downloadProgressHandler: NYPLAxisDownloadProgressHandling
  private let downloadTaskWeightProvider: NYPLAxisWeightProviding
  weak var delegate: NYPLAxisDownloadProgressListening?
  
  init(
    assetWriter: NYPLAssetWriting = NYPLAssetWriter(),
    downloader: NYPLAxisContentDownloading = NYPLAxisContentDownloader(
      networkExecuting: NYPLAxisNetworkExecutor()),
    progressHandler: NYPLAxisDownloadProgressHandling = NYPLAxisDownloadProgress(),
    weightProvider: NYPLAxisWeightProviding = NYPLAxisDownloadTaskWeightProvider()
  ) {
    self.assetWriter = assetWriter
    self.downloader = downloader
    self.downloadProgressHandler = progressHandler
    self.downloadTaskWeightProvider = weightProvider
  }
  
  /// Downloads the item from given url.
  ///
  /// - Parameters:
  ///   - url: URL of the item to be downloaded.
  ///   - writeURL: Desired local url for the item.
  func downloadItem(from url: URL, at writeURL: URL, completion: @escaping (Result<Bool, Error>) -> Void) {
    addTaskToDownloadProgress(with: url)
    downloader.downloadItem(from: url) { [weak self] (result) in
      guard let self = self else {
        completion(.failure(NYPLAxisError.prematureDeallocation))
        return
      }
      switch result {
      case .success(let data):
        do {
          try self.assetWriter.writeAsset(data, atURL: writeURL)
          self.downloadProgressHandler.didFinishTask(with: url)
          completion(.success(true))
        } catch {
          NYPLErrorLogger.logError(
            error,
            summary: NYPLAxisItemDownloader.failedWritingItemSummary,
            metadata: ["writeURL": writeURL.path,
                       "itemURL": url.absoluteString])
          
          completion(.failure(error))
        }
      case .failure(let error):
        NYPLErrorLogger.logError(
          error,
          summary: NYPLAxisItemDownloader.failedDownloadingItemSummary,
          metadata: ["itemURL": url.absoluteString])
        
        completion(.failure(error))
      }
    }
  }
  
  func addURLsToDownloadProgress(_ urls: [URL]) {
    urls.forEach {
      addTaskToDownloadProgress(with: $0)
    }
  }
  
  private func addTaskToDownloadProgress(with url: URL) {
    if downloadProgressHandler.progressListener == nil {
      downloadProgressHandler.progressListener = self.delegate
    }
    
    if let weight = downloadTaskWeightProvider.fixedWeightForTaskWithURL(url) {
      downloadProgressHandler.addFixedWeightTask(with: url, weight: weight)
    } else {
      downloadProgressHandler.addFlexibleWeightTask(with: url)
    }
  }
  
}
