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

extension NYPLMyBooksDownloadCenter {
  /// Create an audiobook object and add to download queue
  @objc(downloadAudiobookForBook:)
  func downloadAudiobook(for book: NYPLBook?) {
    guard let book = book,
          let url = self.fileURL(forBookIndentifier: book.identifier) else {
      return
    }
    
    AudiobookManifestAdapter.transformManifestToDictionary(for: book,
                                                              fileURL: url) { json, decryptor, error in
      if error == .none {
        guard let audiobook = AudiobookFactory.audiobook(json, decryptor: decryptor) else {
          Log.info(#file, "Audiobook initiate failed for book id - \(book.identifier)")
          // TODO: Handle Error
          self.broadcastUpdate(book.identifier)
          return
        }
        
        let metadata = AudiobookMetadata(title: book.title, authors: [(book.authors ?? "")])
        let manager = DefaultAudiobookManager(metadata: metadata, audiobook: audiobook)
        
        NYPLBookRegistry.shared().setStateWithCode(NYPLBookState.Downloading.rawValue, forIdentifier: book.identifier)
        
        self.downloadProgressDidUpdate(to: Double(manager.networkService.downloadProgress),
                                       forBookIdentifier: book.identifier)
        
        self.audiobookDownloader.downloadAudiobook(for: book.identifier, audiobookManager: manager)
      } else {
        Log.info(#file, "Audiobook manifest corrupted/unsupported")
        // TODO: Handle Error
        self.broadcastUpdate(book.identifier)
      }
    }
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
    downloadProgressDidUpdate(to: Double(progress), forBookIdentifier: bookID)
  }
  
  func audiobookDidCompleteDownload(bookID: String) {
    NYPLBookRegistry.shared().setStateWithCode(NYPLBookState.DownloadSuccessful.rawValue,
                                               forIdentifier: bookID)
    NYPLBookRegistry.shared().save()
  }
  
  func audiobookDidCompleteDownloadFirstElement(bookID: String) {
    // Update UI to present listen button
  }
  
  func audiobookDidReceiveDownloadError(error: NSError?, bookID: String) {
    // Update book registry and update UI
  }
}
#endif
