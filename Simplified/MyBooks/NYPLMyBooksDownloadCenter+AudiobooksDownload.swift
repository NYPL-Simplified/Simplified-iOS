//
//  NYPLMyBooksDownloadCenter+AudiobooksDownload.swift
//  Simplified
//
//  Created by Ernest Fan on 2022-04-06.
//  Copyright © 2022 NYPL. All rights reserved.
//
#if FEATURE_AUDIOBOOKS
import Foundation
import NYPLAudiobookToolkit
import NYPLUtilitiesObjc

extension NYPLMyBooksDownloadCenter {
  /// Create an audiobook object and add to download queue.
  /// Below are the steps:
  ///   1. Retrieve book manifest from local storage
  ///   2. Transform manifest into dictionary and add book identifier if needed
  ///   3. Update vendor DRM key if needed
  ///   4. Add audiobook to downloader queue
  @objc(downloadAudiobookForBook:)
  func downloadAudiobook(for book: NYPLBook?) {
    guard let book = book,
          let url = self.fileURL(forBookIndentifier: book.identifier) else {
            Log.error(#file, "Missing book or url. Book: \(String(describing: book?.loggableShortString)). URL: \(String(describing:self.fileURL(forBookIndentifier: book?.identifier)))")
            return
    }
    
    let metadata = [
      "book": book.loggableShortString(),
      "fileURL": url.absoluteString
    ]
    
    AudiobookManifestAdapter.transformManifestToDictionary(for: book,
                                                              fileURL: url) { json, decryptor, error in
      if error == .none,
        let json = json {
        AudioBookVendorsHelper.updateVendorKey(book: json) { [weak self] error in
          guard let audiobook = AudiobookFactory.audiobook(json, decryptor: decryptor) else {
            if let error = error {
              NYPLErrorLogger.logError(error,
                                       summary: "Audiobooks: DRM Error",
                                       metadata: metadata)
            } else {
              Log.error(#file, "Audiobooks: unsupported - \(String(describing: book.loggableShortString))")
            }
            
            NYPLBookRegistry.shared().setStateWithCode(NYPLBookState.DownloadFailed.rawValue,
                                                       forIdentifier: book.identifier)
            NYPLBookRegistry.shared().save()
            self?.broadcastUpdate(book.identifier)
            return
          }
          
          let metadata = AudiobookMetadata(title: book.title, authors: [(book.authors ?? "")])
          let audiobookManager = DefaultAudiobookManager(metadata: metadata, audiobook: audiobook)
          
          self?.addAudiobookManagerToDownloader(audiobookManager,
                                                bookID: book.identifier,
                                                isHighPriority: false)
        }
      } else {
        NYPLErrorLogger.logError(withCode: .audiobookCorrupted,
                                 summary: "Audiobooks: corrupted audiobook",
                                 metadata: metadata)
        NYPLBookRegistry.shared().setStateWithCode(NYPLBookState.DownloadFailed.rawValue,
                                                   forIdentifier: book.identifier)
        NYPLBookRegistry.shared().save()
        self.broadcastUpdate(book.identifier)
      }
    }
  }
  
  /// - Parameters:
  ///   - audiobookManager: Audiobook manager responsible for the download mechanism
  ///   - bookID: The book identifier for updating download status through delegate
  ///   - isHighPriority: Only pass in `true` if user is opening the audiobook to listen
  ///
  ///   We use `AudiobookManager` instead of `Audiobook` here because `AudiobookManager`
  ///   allow us to determine if download is needed or not before presenting the audiobook.
  @objc func addAudiobookManagerToDownloader(_ audiobookManager: DefaultAudiobookManager,
                                             bookID: String,
                                             isHighPriority: Bool) {
    NYPLBookRegistry.shared().setStateWithCode(NYPLBookState.Downloading.rawValue, forIdentifier: bookID)
    
    self.downloadProgressDidUpdate(to: Double(audiobookManager.networkService.downloadProgress),
                                   forBookIdentifier: bookID)
    
    self.audiobookDownloader.downloadAudiobook(for: bookID,
                                               audiobookManager: audiobookManager,
                                               isHighPriority: isHighPriority)
  }
  
  @objc(audiobookManagerForBookID:)
  func audiobookManager(for bookID: String?) -> DefaultAudiobookManager? {
    guard let bookID = bookID else {
      return nil
    }
    
    return self.audiobookDownloader.audiobookManager(for: bookID)
  }
}

extension NYPLMyBooksDownloadCenter: NYPLAudiobookDownloadStatusDelegate {
  func audiobookDidUpdateDownloadProgress(_ progress: Float, bookID: String) {
    // Since this delegate is only called when an audiobook file download completed,
    // we know it's ready to play once the download progress is greater than 0
    if (progress > 0 &&
        NYPLBookRegistry.shared().stateRawValue(forIdentifier: bookID) == NYPLBookState.Downloading.rawValue) {
      NYPLBookRegistry.shared().setStateWithCode(NYPLBookState.DownloadingUsable.rawValue, forIdentifier: bookID)
    }
    
    downloadProgressDidUpdate(to: Double(progress), forBookIdentifier: bookID)
  }
  
  func audiobookDidCompleteDownload(bookID: String, beyondTimeLimit: Bool) {
    if beyondTimeLimit {
      NYPLErrorLogger.logError(withCode: .audiobookDownloadCompletedBeyondTimeLimit,
                               summary: "Audiobook Download Completed Beyond Time Limit",
                               metadata: ["BookID": bookID])
    }
    
    NYPLBookRegistry.shared().setStateWithCode(NYPLBookState.DownloadSuccessful.rawValue,
                                               forIdentifier: bookID)
    NYPLBookRegistry.shared().save()
  }
  
  func audiobookDidReceiveDownloadError(error: NSError?, bookID: String) {
    NYPLErrorLogger.logError(error,
                             summary: "Audiobook Download Failed",
                             metadata: ["BookID": bookID])
    NYPLBookRegistry.shared().setStateWithCode(NYPLBookState.DownloadFailed.rawValue, forIdentifier: bookID)
    NYPLBookRegistry.shared().save()
    self.broadcastUpdate(bookID)
  }
  
  func audiobookDownloadDidTimeout(bookID: String, networkStatus: NetworkStatus, metadata: [String : Any]) {
    let errorCode: NYPLErrorCode = networkStatus == NotReachable ? .audiobookDownloadTimedOutNotReachable : .audiobookDownloadTimedOutReachable
    NYPLErrorLogger.logError(withCode: errorCode,
                             summary: "Audiobook Download Timed Out",
                             metadata: metadata)
    NYPLBookRegistry.shared().setStateWithCode(NYPLBookState.DownloadFailed.rawValue, forIdentifier: bookID)
    NYPLBookRegistry.shared().save()
    self.broadcastUpdate(bookID)
  }
}
#endif
