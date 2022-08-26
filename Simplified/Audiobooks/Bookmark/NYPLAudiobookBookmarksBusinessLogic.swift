//
//  NYPLAudiobookBookmarksBusinessLogic.swift
//  Simplified
//
//  Created by Ernest Fan on 2022-08-12.
//  Copyright © 2022 NYPL. All rights reserved.
//

import Foundation
import NYPLAudiobookToolkit

class NYPLAudiobookBookmarksBusinessLogic: NYPLAudiobookBookmarksBusinessLogicDelegate {
  var bookmarks: [NYPLAudiobookBookmark] = [NYPLAudiobookBookmark]()
  
  var bookmarksCount: Int {
    return bookmarks.count
  }
  
  func bookmark(at index: Int) -> NYPLAudiobookBookmark? {
    guard index >= 0 && index < bookmarksCount else {
      return nil
    }
    
    return bookmarks[index]
  }
  
  func addAudiobookBookmark(_ chapterLocation: ChapterLocation) {
    // Check if bookmark already existing
    // Create audiobook bookmark with given location
    // Upload bookmark to server
    // Store bookmark to local storage
  }
  
  func deleteAudiobookBookmark(at index: Int) {
    // Remove bookmark from local storage
    // Check if bookmark has annotationId (uploaded to server)
    // Delete bookmark from server
  }
  
  func syncBookmarks(completion: @escaping (Bool) -> ()) {
    // Check logic from NYPLReadiumBookmarksBusinessLogic
    // Fetch bookmarks from server
    // Filter bookmarks (local, deleted etc.)
    // Update bookmark in business logic
  }
  
  
}
