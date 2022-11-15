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
  private let bookRegistryProvider: NYPLBookRegistryProvider
  private let annotationSynchronizer: NYPLAnnotationSyncing.Type
  
  private let serialQueue = DispatchQueue(label: "\(Bundle.main.bundleIdentifier!).lastListenedPositionSynchronizer", target: .global(qos: .utility))
  private let renderer: String = "NYPLAudiobookToolkit"
  
  init(book: NYPLBook,
       bookRegistryProvider: NYPLBookRegistryProvider,
       annotationSynchronizer: NYPLAnnotationSyncing.Type) {
    self.bookRegistryProvider = bookRegistryProvider
    self.annotationSynchronizer = annotationSynchronizer
  }
  
  func getLastListenPosition(for bookID: String,
                             completion: @escaping (_ localPosition: NYPLAudiobookBookmark?, _ serverPosition: NYPLAudiobookBookmark?) -> ()) {
    serialQueue.async { [weak self] in
      guard let self = self else { return }
      
      // Retrive local last-listened position
      var localPosition: NYPLAudiobookBookmark?
      
      if let bookLocation = self.bookRegistryProvider.location(forIdentifier: bookID),
         bookLocation.renderer == self.renderer {
        if let chapterLocation = self.chapterLocation(from: bookLocation.locationString) {
          // If the retrieved location is a ChapterLocation object,
          // we should create a bookmark from it and return it without server position,
          // since we cannot tell which location is the most up-to-date as
          // ChapterLocation object has no creation date.
          let newLocation = NYPLAudiobookBookmark(chapterLocation: chapterLocation, creationTime: Date())
          completion(newLocation, nil)
          return
        }
          
        if let bookmark = self.bookmark(from: bookLocation.locationString) {
          localPosition = bookmark
        }
      }
      
      // Check if server sync allowed
      // Return local last-listened position if not
      guard self.annotationSynchronizer.syncIsPossibleAndPermitted() else {
        completion(localPosition, nil)
        return
      }
      
      // Retrieve last-listened position from server, return both local and server positions
      
    }
  }
  
  func postLastListenPosition(_ location: NYPLAudiobookBookmark, for bookID: String) {
    
  }
  
  // MARK: - Helper
  
  private func chapterLocation(from locationString: String) -> ChapterLocation? {
    return nil
  }
  
  private func bookmark(from locationString: String) -> NYPLAudiobookBookmark? {
    return nil
  }
}
