//
//  NYPLLastListenPositionSynchronizer.swift
//  Simplified
//
//  Created by Ernest Fan on 2022-11-10.
//  Copyright © 2022 NYPL. All rights reserved.
//
#if FEATURE_AUDIOBOOKS
import Foundation
import NYPLAudiobookToolkit

class NYPLLastListenPositionSynchronizer: NYPLLastListenPositionSynchronizing {
  private let book: NYPLBook
  private let bookRegistryProvider: NYPLBookRegistryProvider
  private let annotationsSynchronizer: NYPLLastReadPositionSupportAPI
  
  private let serialQueue = DispatchQueue(label: "\(Bundle.main.bundleIdentifier!).lastListenedPositionSynchronizer", target: .global(qos: .utility))
  private let renderer: String = "NYPLAudiobookToolkit"
  
  init(book: NYPLBook,
       bookRegistryProvider: NYPLBookRegistryProvider,
       annotationsSynchronizer: NYPLLastReadPositionSupportAPI) {
    self.book = book
    self.bookRegistryProvider = bookRegistryProvider
    self.annotationsSynchronizer = annotationsSynchronizer
  }
  
  func getLastListenPosition(completion: @escaping (_ localPosition: NYPLAudiobookBookmark?, _ serverPosition: NYPLAudiobookBookmark?) -> ()) {
    serialQueue.async { [weak self] in
      guard let self = self else { return }
      
      // Retrive local last-listened position
      let localPosition = self.getLocalLastListenPosition(for: self.book.identifier)
      
      // Retrieve last-listened position from server, return both local and server positions
      self.annotationsSynchronizer.syncReadingPosition(of: NYPLAudiobookBookmark.self,
                                                       forBook: self.book.identifier,
                                                      publication: nil,
                                                      toURL: self.book.annotationsURL) { serverPosition in
        guard let serverPosition = serverPosition else {
          Log.info(#function, "No reading position annotation exists on the server for \(self.book.loggableShortString()).")
          completion(localPosition, nil)
          return
        }
        
        guard let localPosition = localPosition else {
          completion(nil, serverPosition)
          return
        }
        
        // Pass through without server position (meaning the server doesn't have a
        // last listen position worth restoring) if:
        // 1 - The most recent position on the server comes from the same device, or
        // 2 - The local position is further in the audiobook than the server position
        if serverPosition.device == NYPLUserAccount.sharedAccount().deviceID ||
            localPosition >= serverPosition {
          completion(localPosition, nil)
          return
        }
        
        completion(localPosition, serverPosition)
      }
    }
  }
  
  func updateLastListenPositionInMemory(_ location: ChapterLocation) {
    let selectorValue = NYPLAudiobookBookmarkFactory.makeLocatorString(title: location.title ?? "",
                                                                       part: location.part,
                                                                       chapter: location.number,
                                                                       audiobookId: location.audiobookID,
                                                                       duration: location.duration,
                                                                       time: location.playheadOffset)
    
    let bookLocation = NYPLBookLocation.init(locationString: selectorValue, renderer: self.renderer)
    serialQueue.async { [weak self] in
      guard let self = self else {
        return
      }
      self.bookRegistryProvider.setLocation(bookLocation, forIdentifier: self.book.identifier)
    }
  }
  
  
  func syncLastListenPositionToServer() {
    let bookID = self.book.identifier
    
    guard let localPosition = getLocalLastListenPosition(for: bookID) else {
      return
    }
    
    let selectorValue = NYPLAudiobookBookmarkFactory.makeLocatorString(title: localPosition.title ?? "",
                                                                       part: localPosition.part,
                                                                       chapter: localPosition.chapter,
                                                                       audiobookId: localPosition.audiobookId,
                                                                       duration: localPosition.duration,
                                                                       time: localPosition.time)
    serialQueue.async { [weak self] in
      self?.annotationsSynchronizer.postReadingPosition(forBook: bookID,
                                                        selectorValue: selectorValue)
    }
  }
  
  // MARK: - Helper
  
  private func getLocalLastListenPosition(for bookID: String) -> NYPLAudiobookBookmark? {
    guard let bookLocation = self.bookRegistryProvider.location(forIdentifier: bookID),
       bookLocation.renderer == self.renderer else {
      return nil
    }
    
    if let bookmark = NYPLAudiobookBookmark(selectorString: bookLocation.locationString, creationTime: Date()) {
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
    guard let data = locationString.data(using: .utf8),
          let chapterLocation = ChapterLocation.fromData(data) else {
      return nil
    }
    return chapterLocation
  }
}
#endif
