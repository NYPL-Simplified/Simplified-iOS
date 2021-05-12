//
//  NYPLAxisItemDownloader.swift
//  Open eBooks
//
//  Created by Raman Singh on 2021-05-12.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation

protocol NYPLAxisItemDownloadTerminationListening: class {
  func downloaderDidTerminate()
}

protocol NYPLAxisItemDownloading: class {
  var delegate: NYPLAxisItemDownloadTerminationListening? { get set }
  var dispatchGroup: DispatchGroup { get }
  var shouldContinue: Bool { get }
  func downloadItem(from url: URL, at writeURL: URL)
  func leaveGroupAndStopDownload()
}

class NYPLAxisItemDownloader: NYPLAxisItemDownloading {
  
  // Content Downloading constants
  static private let writeFailureSummary = "AXIS: Failed writing item to specified write URL"
  static private let failedDownloadingItemSummary = "AXIS: Failed downloading item"
  
  let dispatchGroup: DispatchGroup
  private let assetWriter: NYPLAssetWriting
  private let globalBackgroundSyncronizeDataQueue = DispatchQueue(label: "NYPLAxis")
  private var downloader: NYPLAxisContentDownloading?
  var delegate: NYPLAxisItemDownloadTerminationListening?
  
  init(assetWriter: NYPLAssetWriting = NYPLAssetWriter(),
       dispatchGroup: DispatchGroup = DispatchGroup(),
       downloader: NYPLAxisContentDownloading? = NYPLAxisContentDownloader(
        networkExecuting: NYPLAxisNetworkExecutor())) {
    self.assetWriter = assetWriter
    self.dispatchGroup = dispatchGroup
    self.downloader = downloader
  }
  
  var shouldContinue: Bool {
    return globalBackgroundSyncronizeDataQueue.sync { [weak self] in
      self?.downloader != nil
    }
  }
  
  /// Downloads the item from given url. Exits dispatchGroup on success. Terminates all subsequent
  /// downloads upon failure.
  /// - Parameters:
  ///   - url: URL of the item to be downloaded.
  ///   - writeURL: Desired local url for the item.
  func downloadItem(from url: URL, at writeURL: URL) {
    guard shouldContinue else {
      return
    }
    
    downloader?.downloadItem(from: url) { [weak self] (result) in
      guard let self = self else { return }
      switch result {
      case .success(let data):
        do {
          try self.assetWriter.writeAsset(data, atURL: writeURL)
          self.dispatchGroup.leave()
        } catch {
          NYPLErrorLogger.logError(
            error,
            summary: NYPLAxisItemDownloader.writeFailureSummary,
            metadata: ["writeURL": writeURL.path,
                       "itemURL": url.absoluteString])
          
          self.leaveGroupAndStopDownload()
        }
      case .failure(let error):
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
      self.downloader = nil
      delegate?.downloaderDidTerminate()
      self.dispatchGroup.leave()
    }
  }
  
}
