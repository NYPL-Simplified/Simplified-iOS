//
//  NYPLAudiobooksDownloader.swift
//  Simplified
//
//  Created by Ernest Fan on 2022-04-01.
//  Copyright © 2022 NYPL. All rights reserved.
//
#if FEATURE_AUDIOBOOKS
import Foundation
import NYPLAudiobookToolkit
import NYPLUtilitiesObjc

@objc protocol NYPLAudiobookDownloadStatusDelegate {
  func audiobookDidUpdateDownloadProgress(_ progress: Float, bookID: String)
  func audiobookDidCompleteDownload(bookID: String, beyondTimeLimit: Bool)
  func audiobookDidReceiveDownloadError(error: NSError?, bookID: String)
  func audiobookDownloadDidTimeout(bookID: String, networkStatus: NetworkStatus, metadata: [String: Any])
}

class NYPLAudiobookDownloadObject {
  var bookID: String
  var audiobookManager: DefaultAudiobookManager
  var didRetryDownload: Bool = false
  var beyondTimeLimit: Bool = false
  
  init(bookID: String, audiobookManager: DefaultAudiobookManager) {
    self.bookID = bookID
    self.audiobookManager = audiobookManager
  }
}

/// This class is designed to download audiobook files in the background.
/// Only one audiobook would be downloaded at a time,
/// when it completes or being cancelled, the next audiobook in queue will be downloaded.
/// When the download fails, a second download attempt will be triggered immediately.
/// If the case of a second failure, the audiobook will be removed and user can manually retry download.
@objc class NYPLAudiobookDownloader: NSObject {
  @objc weak var delegate: NYPLAudiobookDownloadStatusDelegate?
  
  private var serialQueue: DispatchQueue = DispatchQueue(label: "org.nypl.labs.NYPLAudiobooksDownloader")
  private var downloadObjects: [NYPLAudiobookDownloadObject] = []
  private var currentDownloadObject: NYPLAudiobookDownloadObject?
  
  /// - Parameters:
  ///   - bookID: The book identifier for updating download status through delegate
  ///   - audiobookManager: Audiobook manager responsible for the download mechanism
  ///   - isHighPriority: If `true`, the audiobook will be the next one in queue,
  ///   download will start once the current download completes.
  ///   Otherwise, audiobook will be added to end of the downlaod queue.
  ///   
  ///   Note: Calling this function does nothing if an audiobook has already been added to queue.
  func downloadAudiobook(for bookID: String,
                         audiobookManager: DefaultAudiobookManager,
                         isHighPriority: Bool) {
    guard downloadObject(for: bookID) == nil else {
      return
    }
    
    serialQueue.async {
      let newDownloadObject = NYPLAudiobookDownloadObject(bookID: bookID,
                                                          audiobookManager: audiobookManager)
      if isHighPriority {
        self.downloadObjects.insert(newDownloadObject, at: 0)
      } else {
        self.downloadObjects.append(newDownloadObject)
      }
      self.fetchNextIfNeeded()
    }
  }
  
  @objc func cancelDownloadFetchingNextIfNeeded(for bookID: String?) {
    guard let bookID = bookID else {
      return
    }
    
    if let downloadObject = currentDownloadObject,
       downloadObject.bookID == bookID {
      cancelDownload(for: downloadObject)
      releaseCurrentDownloadObject()
      fetchNextIfNeeded()
    } else if let index = downloadObjects.firstIndex(where: { $0.bookID == bookID }) {
      cancelDownload(for: downloadObjects[index])
      serialQueue.async {
        _ = self.downloadObjects.remove(at: index)
      }
    }
  }
  
  @objc func audiobookManager(for bookID: String) -> DefaultAudiobookManager? {
    return downloadObject(for: bookID)?.audiobookManager
  }
  
  // MARK: - Helper
  
  private func releaseCurrentDownloadObject() {
    serialQueue.async {
      self.currentDownloadObject = nil
    }
  }
  
  private func fetchNextIfNeeded() {
    serialQueue.async {
      guard self.currentDownloadObject == nil else {
        return
      }
      
      if let downloadObject = self.downloadObjects.popFirst() {
        Log.info(#file, "Fetch initiated for \(downloadObject.bookID)")
        downloadObject.audiobookManager.networkService.registerDelegate(self)
        downloadObject.audiobookManager.networkService.fetch()
        self.currentDownloadObject = downloadObject
      }
    }
  }
  
  private func cancelDownload(for downloadObject: NYPLAudiobookDownloadObject) {
    downloadObject.audiobookManager.networkService.cancelFetch()
    downloadObject.audiobookManager.networkService.removeDelegate(self)
    Log.info(#file, "Fetch cancelled for \(downloadObject.bookID)")
  }
  
  private func downloadObject(for bookID: String) -> NYPLAudiobookDownloadObject? {
    if let downloadObject = currentDownloadObject,
       downloadObject.bookID == bookID {
      return downloadObject
    } else if let index = downloadObjects.firstIndex(where: { $0.bookID == bookID }) {
      return downloadObjects[index]
    }
    return nil
  }
}

extension NYPLAudiobookDownloader: AudiobookNetworkServiceDelegate {
  func audiobookNetworkService(_ audiobookNetworkService: AudiobookNetworkService, didCompleteDownloadFor spineElement: SpineElement) {
    if let downloadObject = currentDownloadObject {
      delegate?.audiobookDidUpdateDownloadProgress(audiobookNetworkService.downloadProgress,
                                                   bookID: downloadObject.bookID)
    }
  }
  
  func audiobookNetworkService(_ audiobookNetworkService: AudiobookNetworkService, didUpdateProgressFor spineElement: SpineElement) {}
  
  func audiobookNetworkService(_ audiobookNetworkService: AudiobookNetworkService, didUpdateOverallDownloadProgress progress: Float) {
    if progress == 1,
      let downloadObject = currentDownloadObject
    {
      Log.info(#file, "Audiobook - \(downloadObject.bookID) download completed and removed")
      delegate?.audiobookDidCompleteDownload(bookID: downloadObject.bookID, beyondTimeLimit: downloadObject.beyondTimeLimit)
      downloadObject.audiobookManager.networkService.removeDelegate(self)

      releaseCurrentDownloadObject()
      fetchNextIfNeeded()
    }
  }
  
  func audiobookNetworkService(_ audiobookNetworkService: AudiobookNetworkService, didDeleteFileFor spineElement: SpineElement) {}
  
  func audiobookNetworkService(_ audiobookNetworkService: AudiobookNetworkService, didReceive error: NSError?, for spineElement: SpineElement) {
    audiobookNetworkService.cancelFetch()
    if let downloadObject = currentDownloadObject {
      if downloadObject.didRetryDownload {
        Log.error(#file, "Audiobook download failed, bookID - \(downloadObject.bookID)")
        delegate?.audiobookDidReceiveDownloadError(error: error, bookID: downloadObject.bookID)
        releaseCurrentDownloadObject()
        fetchNextIfNeeded()
      } else {
        Log.info(#file, "Audiobook retrying download, bookID - \(downloadObject.bookID)")
        downloadObject.audiobookManager.networkService.fetch()
        downloadObject.didRetryDownload = true
      }
    }
  }
  
  func audiobookNetworkService(_ audiobookNetworkService: AudiobookNetworkService,
                               didTimeoutFor spineElement: SpineElement?,
                               networkStatus: NetworkStatus) {
    if let downloadObject = currentDownloadObject {
      let metadata = [
        "BookID": downloadObject.bookID,
        "Connectivity": connectivityString(networkStatus),
        "Chapter Info": spineElement?.chapter.description ?? "N/A",
      ]
      delegate?.audiobookDownloadDidTimeout(bookID: downloadObject.bookID,
                                            networkStatus: networkStatus,
                                            metadata: metadata)
      releaseCurrentDownloadObject()
      fetchNextIfNeeded()
    }
  }
  
  func audiobookNetworkService(_ audiobookNetworkService: AudiobookNetworkService,
                               downloadExceededTimeLimitFor spineElement: SpineElement,
                               elapsedTime: TimeInterval,
                               networkStatus: NetworkStatus) {
    currentDownloadObject?.beyondTimeLimit = true
    Log.warn(#file, "Audiobook Download Exceeded Time Limit. Chapter: \(spineElement.chapter.description), download progress for current file - \(spineElement.downloadTask.downloadProgress * 100)%, elapsed time - \(elapsedTime)seconds, connectivity - \(connectivityString(networkStatus))")
  }
  
  private func connectivityString(_  networkStatus: NetworkStatus) -> String {
    switch networkStatus {
    case ReachableViaWWAN:
      return "Cellular"
    case ReachableViaWiFi:
      return "WiFi"
    default:
      return "No Internet Connection"
    }
  }
}
#endif
