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

@objc protocol NYPLAudiobookDownloadStatusDelegate {
  func audiobookDidUpdateDownloadProgress(progress: Float, bookID: String)
  func audiobookDidCompleteDownload(bookID: String)
  func audiobookDidCompleteDownloadFirstElement(bookID: String)
  func audiobookDidReceiveDownloadError(error: NSError?, bookID: String)
}

class NYPLAudiobookDownloadObject {
  var bookID: String
  var audiobookManager: DefaultAudiobookManager
  
  init(bookID: String, audiobookManager: DefaultAudiobookManager) {
    self.bookID = bookID
    self.audiobookManager = audiobookManager
  }
}

@objcMembers class NYPLAudiobookDownloader: NSObject {
  weak var delegate: NYPLAudiobookDownloadStatusDelegate?
  
  private var serialQueue: DispatchQueue = DispatchQueue(label: "org.nypl.labs.NYPLAudiobooksDownloader")
  private var downloadObjects: [NYPLAudiobookDownloadObject] = []
  private var currentDownloadObject: NYPLAudiobookDownloadObject?
  
  @objc(downloadAudiobookForBookID:audiobookManager:)
  func downloadAudiobook(for bookID: String,
                         audiobookManager: DefaultAudiobookManager) {
    guard downloadObject(for: bookID) == nil else {
      return
    }
    
    serialQueue.async {
      self.downloadObjects.append(NYPLAudiobookDownloadObject(bookID: bookID,
                                                              audiobookManager: audiobookManager))
    }
    fetchNext()
  }
  
  @objc func cancelDownload(for bookID: String) {
    if let downloadObject = currentDownloadObject,
       downloadObject.bookID == bookID {
      cancelDownload(for: downloadObject)
      releaseCurrentDownloadObject()
      fetchNext()
    } else if let index = downloadObjects.firstIndex(where: { $0.bookID == bookID }) {
      cancelDownload(for: downloadObjects[index])
      serialQueue.async {
        _ = self.downloadObjects.remove(at: index)
      }
    }
  }
  
  func audiobookManager(for bookID: String) -> DefaultAudiobookManager? {
    return downloadObject(for: bookID)?.audiobookManager
  }
  
  // MARK: - Helper
  
  private func releaseCurrentDownloadObject() {
    serialQueue.async {
      self.currentDownloadObject = nil
    }
  }
  
  private func fetchNext() {
    serialQueue.async {
      guard self.currentDownloadObject == nil else {
        return
      }
      
      if let downloadObject = self.downloadObjects.popFirst() {
        Log.debug(#file, "Fetch initiated for \(downloadObject.bookID)")
        downloadObject.audiobookManager.networkService.registerDelegate(self)
        downloadObject.audiobookManager.networkService.fetch()
        self.currentDownloadObject = downloadObject
      }
    }
  }
  
  private func cancelDownload(for downloadObject: NYPLAudiobookDownloadObject) {
    downloadObject.audiobookManager.networkService.cancelFetch()
    downloadObject.audiobookManager.networkService.removeDelegate(self)
    Log.debug(#file, "Fetch cancelled for \(downloadObject.bookID)")
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
      delegate?.audiobookDidUpdateDownloadProgress(progress: audiobookNetworkService.downloadProgress,
                                                   bookID: downloadObject.bookID)
    }
  }
  
  func audiobookNetworkService(_ audiobookNetworkService: AudiobookNetworkService, didUpdateProgressFor spineElement: SpineElement) {}
  
  func audiobookNetworkService(_ audiobookNetworkService: AudiobookNetworkService, didUpdateOverallDownloadProgress progress: Float) {
    if progress == 1,
      let downloadObject = currentDownloadObject
    {
      delegate?.audiobookDidCompleteDownload(bookID: downloadObject.bookID)
      downloadObject.audiobookManager.networkService.removeDelegate(self)
      Log.debug(#file, "\(downloadObject.bookID) download completed and removed")

      releaseCurrentDownloadObject()
      fetchNext()
    }
  }
  
  func audiobookNetworkService(_ audiobookNetworkService: AudiobookNetworkService, didDeleteFileFor spineElement: SpineElement) {}
  
  func audiobookNetworkService(_ audiobookNetworkService: AudiobookNetworkService, didReceive error: NSError?, for spineElement: SpineElement) {
    audiobookNetworkService.cancelFetch()
    if let downloadObject = currentDownloadObject {
      delegate?.audiobookDidReceiveDownloadError(error: error, bookID: downloadObject.bookID)
      releaseCurrentDownloadObject()
      fetchNext()
    }
  }
}
#endif
