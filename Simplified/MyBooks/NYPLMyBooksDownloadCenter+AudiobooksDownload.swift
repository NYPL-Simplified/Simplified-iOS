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

extension NYPLMyBooksDownloadCenter: NYPLAudiobookDownloadStatusDelegate {
  func audiobookDidUpdateDownloadProgress(progress: Float, bookID: String) {
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
