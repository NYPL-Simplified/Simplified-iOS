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
  func didFinishAllDownloads()
}

protocol NYPLAxisItemDownloading: class {
  var delegate: NYPLAxisDownloadProgressListening? { get set }
  var tasksSynchnorizer: NYPLAxisTasksSynchorizing { get }
  var shouldContinue: Bool { get }
  func downloadItem(from url: URL, at writeURL: URL)
  func downloadItems(with dictionary: [URL: URL])
  func terminateDownloadProcess()
  func notifyUponCompletion(on queue: DispatchQueue)
}

class NYPLAxisItemDownloader: NYPLAxisItemDownloading {
  
  // Content Downloading constants
  static private let failedWritingItemSummary = "AXIS: Failed writing item to specified write URL"
  static private let failedDownloadingItemSummary = "AXIS: Failed downloading item"
  
  let tasksSynchnorizer: NYPLAxisTasksSynchorizing
  private let assetWriter: NYPLAssetWriting
  private let globalBackgroundSyncronizeDataQueue = DispatchQueue(label: "NYPLAxis")
  private var downloader: NYPLAxisContentDownloading?
  private let downloadProgressHandler: NYPLAxisDownloadProgressHandling
  private let downloadTaskWeightProvider: NYPLAxisWeightProviding
  var delegate: NYPLAxisDownloadProgressListening?
  
  init(
    assetWriter: NYPLAssetWriting = NYPLAssetWriter(),
    downloader: NYPLAxisContentDownloading? = NYPLAxisContentDownloader(
      networkExecuting: NYPLAxisNetworkExecutor()),
    progressHandler: NYPLAxisDownloadProgressHandling = NYPLAxisDownloadProgress(),
    tasksSynchnorizer: NYPLAxisTasksSynchorizing = NYPLAxisTasksSynchnorizer(),
    weightProvider: NYPLAxisWeightProviding = NYPLAxisDownloadTaskWeightProvider()
  ) {
    self.assetWriter = assetWriter
    self.downloader = downloader
    self.downloadProgressHandler = progressHandler
    self.downloadTaskWeightProvider = weightProvider
    self.tasksSynchnorizer = tasksSynchnorizer
  }
  
  var shouldContinue: Bool {
    return globalBackgroundSyncronizeDataQueue.sync { [weak self] in
      self?.downloader != nil
    }
  }
  
  /// Downloads the item from given url. Terminates all subsequent downloads upon failure and notifies
  /// progressListener.
  ///
  /// - Parameters:
  ///   - url: URL of the item to be downloaded.
  ///   - writeURL: Desired local url for the item.
  func downloadItem(from url: URL, at writeURL: URL) {
    guard shouldContinue else {
      return
    }
    
    addTaskToDownloadProgress(with: url)
    tasksSynchnorizer.startSynchronizedTaskWhenIdle()
    downloadItem(from: url, writeTo: writeURL)
    tasksSynchnorizer.waitForSynchronizedTaskToFinish()
  }
  
  /// Downloads the items from the given dictionary using the keys as downlaod URL and values as write
  /// URLS. Terminates all subsequent downloads upon failure and notifies progressListener.
  ///
  /// - Parameter dictionary: A dictionary object with download URL as key and write URL as value.
  func downloadItems(with dictionary: [URL: URL]) {
    guard shouldContinue else {
      return
    }
    
    dictionary.forEach {
      addTaskToDownloadProgress(with: $0.key)
      tasksSynchnorizer.startSynchronizedTask()
      downloadItem(from: $0.key, writeTo: $0.value)
    }
  }
  
  private func downloadItem(from url: URL, writeTo writeURL: URL) {
    downloader?.downloadItem(from: url) { [weak self] (result) in
      guard let self = self else { return }
      switch result {
      case .success(let data):
        do {
          try self.assetWriter.writeAsset(data, atURL: writeURL)
          self.downloadProgressHandler.didFinishTask(with: url)
          self.tasksSynchnorizer.endSynchronizedTask()
        } catch {
          NYPLErrorLogger.logError(
            error,
            summary: NYPLAxisItemDownloader.failedWritingItemSummary,
            metadata: ["writeURL": writeURL.path,
                       "itemURL": url.absoluteString])
          
          self.terminateDownloadProcess()
        }
      case .failure(let error):
        NYPLErrorLogger.logError(
          error,
          summary: NYPLAxisItemDownloader.failedDownloadingItemSummary,
          metadata: ["itemURL": url.absoluteString])
        
        self.terminateDownloadProcess()
      }
    }
  }
  
  /// Stops the download process, deletes downloaded files, notifies the delegate of download failure, and
  /// nils the delegate to prevent further messages from being sent to the delegate.
  func terminateDownloadProcess() {
    // Already processed failure. No need to do it again.
    if !shouldContinue {
      return
    }
    
    globalBackgroundSyncronizeDataQueue.sync { [weak self] in
      guard let self = self else { return }
      self.downloader = nil
      self.delegate?.downloaderDidTerminate()
      self.tasksSynchnorizer.endSynchronizedTask()
      self.delegate = nil
      self.downloadProgressHandler.progressListener = nil
    }
  }
  
  /// Explicitly indicates that all the synchronized tasks you want to be executed are added to the
  /// taskSynchronizer. Notifies the NYPLAxisDownloadProgressListening object when all the tasks have
  /// finished executing.
  ///
  /// - Parameter queue: The queue on which this method is executed when all the submitted tasks
  /// complete.
  func notifyUponCompletion(on queue: DispatchQueue) {
    tasksSynchnorizer.runOnCompletingAllSynchronizedTasks(on: queue) { [weak self] in
      self?.delegate?.didFinishAllDownloads()
      self?.delegate = nil
      self?.downloadProgressHandler.progressListener = nil
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
