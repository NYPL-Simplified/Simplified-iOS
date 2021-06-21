//
//  NYPLAxisItemDownloader.swift
//  Open eBooks
//
//  Created by Raman Singh on 2021-05-12.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation

protocol NYPLAxisDownloadProgressListening: class {
  func downloaderDidTerminate()
  func downloadProgressDidUpdate(_ progress: Double)
}

protocol NYPLAxisItemDownloading: class {
  var delegate: NYPLAxisDownloadProgressListening? { get set }
  var dispatchGroup: DispatchGroup { get }
  var shouldContinue: Bool { get }
  func downloadItem(from url: URL, at writeURL: URL)
  func leaveGroupAndStopDownload()
  func cancelDownload()
}

class NYPLAxisItemDownloader: NYPLAxisItemDownloading {
  
  // Content Downloading constants
  static private let failedWritingItemSummary = "AXIS: Failed writing item to specified write URL"
  static private let failedDownloadingItemSummary = "AXIS: Failed downloading item"
  
  let dispatchGroup: DispatchGroup
  /// set to true when download gets terminated (either by user or due to error)
  private let isTerminated: ThreadSafeValueContainer<Bool>
  private let assetWriter: NYPLAssetWriting
  private let globalBackgroundSyncronizeDataQueue = DispatchQueue(label: "NYPLAxis")
  private var downloader: NYPLAxisContentDownloading?
  private let downloadProgressHandler: NYPLAxisDownloadProgressHandling
  private let downloadTaskWeightProvider: NYPLAxisWeightProviding
  weak var delegate: NYPLAxisDownloadProgressListening?
  
  init(
    assetWriter: NYPLAssetWriting = NYPLAssetWriter(),
    dispatchGroup: DispatchGroup = DispatchGroup(),
    downloader: NYPLAxisContentDownloading? = NYPLAxisContentDownloader(
      networkExecuting: NYPLAxisNetworkExecutor()),
    progressHandler: NYPLAxisDownloadProgressHandling = NYPLAxisDownloadProgress(),
    weightProvider: NYPLAxisWeightProviding = NYPLAxisDownloadTaskWeightProvider()
  ) {
    self.assetWriter = assetWriter
    self.dispatchGroup = dispatchGroup
    self.downloader = downloader
    self.downloadProgressHandler = progressHandler
    self.downloadTaskWeightProvider = weightProvider
    self.isTerminated = ThreadSafeValueContainer(
      value: false, queue: DispatchQueue(label: "NYPLAxisItemDownloader_isTerminated"))
  }
  
  var shouldContinue: Bool {
    return !(self.isTerminated.value ?? true)
  }
  
  /// Downloads the item from given url. Exits dispatchGroup on success. Terminates all subsequent
  /// downloads upon failure.
  ///
  /// - Note: A call to this function must balance a call to `dispatchGroup.enter()`. Leaving a
  /// dispatch group more times than it is entered results in a negative count which causes a crash.
  ///
  /// - TODO: OE-136: Fix direct reliance on DispatchGroup
  ///
  /// - Parameters:
  ///   - url: URL of the item to be downloaded.
  ///   - writeURL: Desired local url for the item.
  func downloadItem(from url: URL, at writeURL: URL) {
    guard shouldContinue else {
      dispatchGroup.leave()
      return
    }
    
    addTaskToDownloadProgress(with: url)
    downloader?.downloadItem(from: url) { [weak self] (result) in
      guard let self = self else { return }
      switch result {
      case .success(let data):
        do {
          try self.assetWriter.writeAsset(data, atURL: writeURL)
          self.downloadProgressHandler.didFinishTask(with: url)
          self.dispatchGroup.leave()
        } catch {
          NYPLErrorLogger.logError(
            error,
            summary: NYPLAxisItemDownloader.failedWritingItemSummary,
            metadata: ["writeURL": writeURL.path,
                       "itemURL": url.absoluteString])
          
          self.leaveGroupAndStopDownload()
        }
      case .failure(let error):
        if (error as NSError).code == NSURLErrorCancelled {
          self.dispatchGroup.leave()
          self.delegate = nil
          self.downloadProgressHandler.progressListener = nil
          return
        }
        
        if !self.shouldContinue {
          self.dispatchGroup.leave()
          return
        }
        
        NYPLErrorLogger.logError(
          error,
          summary: NYPLAxisItemDownloader.failedDownloadingItemSummary,
          metadata: ["itemURL": url.absoluteString])
        
        self.leaveGroupAndStopDownload()
      }
    }
  }
  
  /// Stops the download process, leaves the dispatch group, deletes downloaded files, and notifies the
  /// delegate of download failure.
  func leaveGroupAndStopDownload() {
    // Already processed failure. No need to do it again.
    if !shouldContinue {
      return
    }
    
    globalBackgroundSyncronizeDataQueue.sync { [weak self] in
      guard let self = self else { return }
      delegate?.downloaderDidTerminate()
      self.isTerminated.value = true
      self.delegate = nil
      self.downloadProgressHandler.progressListener = nil
      self.dispatchGroup.leave()
    }
  }
  
  func cancelDownload() {
    let error = NSError(
      domain: "User cancelled download", code: NSURLErrorCancelled,
      userInfo: nil)
    
    self.downloader?.cancelAllDownloads(withError: error)
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
