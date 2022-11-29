//
//  NYPLLastListenPositionSynchronizer.swift
//  Simplified
//
//  Created by Ernest Fan on 2022-11-10.
//  Copyright © 2022 NYPL. All rights reserved.
//

import Foundation
import NYPLAudiobookToolkit

// TODO: Update NYPLAnnotations to have generic sync reading position function
// TODO: Implement network executor as property of NYPLLastListenPositionSynchronizer, see NYPLLastReadPositionSynchronizer
// TODO: Ask Risa about sync interval and chapterLocation vs server bookmark

// Placeholder, move to audiobook toolkit
protocol NYPLLastListenPositionSynchronizing {
  func getLastListenPosition(for bookID: String,
                             completion: @escaping (_ localPosition: NYPLAudiobookBookmark?, _ serverPosition: NYPLAudiobookBookmark?) -> ())
  func postLastListenPosition(_ location: NYPLAudiobookBookmark, for bookID: String)
}

class NYPLLastListenPositionSynchronizer: NYPLLastListenPositionSynchronizing {
  private let book: NYPLBook
  private let bookRegistryProvider: NYPLBookRegistryProvider
  private let annotationSynchronizer: NYPLAnnotationSyncing
  
  private let serialQueue = DispatchQueue(label: "\(Bundle.main.bundleIdentifier!).lastListenedPositionSynchronizer", target: .global(qos: .utility))
  private let renderer: String = "NYPLAudiobookToolkit"
  
  init(book: NYPLBook,
       bookRegistryProvider: NYPLBookRegistryProvider,
       annotationSynchronizer: NYPLAnnotationSyncing) {
    self.book = book
    self.bookRegistryProvider = bookRegistryProvider
    self.annotationSynchronizer = annotationSynchronizer
  }
  
  func getLastListenPosition(for bookID: String,
                             completion: @escaping (_ localPosition: NYPLAudiobookBookmark?, _ serverPosition: NYPLAudiobookBookmark?) -> ()) {
    serialQueue.async { [weak self] in
      guard let self = self else { return }
      
      // Retrive local last-listened position
      let localPosition = self.getLocalLastListenPosition(for: bookID)
      
      // Check if server sync allowed
      // Return local last-listened position if not
      guard self.annotationSynchronizer.syncIsPossibleAndPermitted() else {
        completion(localPosition, nil)
        return
      }
      
      // Retrieve last-listened position from server, return both local and server positions
      self.annotationSynchronizer.syncReadingPosition(of: NYPLAudiobookBookmark.self,
                                                      forBook: bookID,
                                                      publication: nil,
                                                      toURL: self.book.annotationsURL) { serverPosition in
        guard let serverPosition = serverPosition else {
          Log.info(#function, "No reading position annotation exists on the server for \(self.book.loggableShortString()).")
          completion(localPosition, nil)
          return
        }
        
        // Pass through returning nil (meaning the server doesn't have a
        // last listen position worth restoring) if:
        // 1 - The most recent position on the server comes from the same device, or
        // 2 - The server and the client have the same position marked
        if localPosition?.device == serverPosition.device ||
            serverPosition.isEqual(localPosition) {
          completion(localPosition, nil)
          return
        }
        
        completion(localPosition, serverPosition)
      }
    }
  }
  
  func postLastListenPosition(_ location: NYPLAudiobookBookmark, for bookID: String) {
    let selectorValue = NYPLAudiobookBookmarkFactory.makeLocatorString(title: location.title ?? "",
                                                                       part: location.part,
                                                                       chapter: location.chapter,
                                                                       audiobookId: location.audiobookId,
                                                                       duration: location.duration,
                                                                       time: location.time)
    serialQueue.async { [weak self] in
      self?.annotationSynchronizer.postReadingPosition(forBook: bookID, selectorValue: selectorValue)
    }
  }
  
  // MARK: - Helper
  
  private func getLocalLastListenPosition(for bookID: String) -> NYPLAudiobookBookmark? {
    guard let bookLocation = self.bookRegistryProvider.location(forIdentifier: bookID),
       bookLocation.renderer == self.renderer else {
      return nil
    }
    
    if let bookmark = self.bookmark(from: bookLocation.locationString) {
      return bookmark
    }
      
    if let chapterLocation = self.chapterLocation(from: bookLocation.locationString) {
      // If the retrieved location is a ChapterLocation object,
      // we should create a bookmark object from it.
      return NYPLAudiobookBookmark(chapterLocation: chapterLocation, creationTime: Date())
    }
    return nil
  }
  
  private func chapterLocation(from locationString: String) -> ChapterLocation? {
    // TODO:
    return nil
  }
  
  private func bookmark(from locationString: String) -> NYPLAudiobookBookmark? {
    // TODO:
    return nil
  }
}
