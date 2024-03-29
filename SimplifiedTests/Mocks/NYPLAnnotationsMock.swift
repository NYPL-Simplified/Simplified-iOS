//
//  NYPLAnnotationsMock.swift
//  SimplyETests
//
//  Created by Ernest Fan on 2021-12-07.
//  Copyright © 2021 NYPL. All rights reserved.
//

import Foundation
import R2Shared
import NYPLUtilities
@testable import SimplyE

class NYPLAnnotationsMock: NYPLAnnotationSyncing {
  var failRequest: Bool = false
  var serverBookmarks: [String: [NYPLBookmark]] = [String: [NYPLBookmark]]()
  var readingPositions: [String: NYPLBookmarkSpec] = [String: NYPLBookmarkSpec]()
  
  // For generating unique annotation id
  private var annotationCounter: Int = 0
  
  // Server status
  
  func checkServerSyncStatus(settings: NYPLAnnotationSettings,
                             syncPermissionGranted: Bool,
                             syncSupportedCompletion: @escaping (Bool, Error?) -> ()) {
    syncSupportedCompletion(true, nil)
  }
  
  func updateServerSyncSetting(toEnabled enabled: Bool,
                               completion:@escaping (Bool)->()) {
    completion(false)
  }
  
  // Reading position
  
  func syncReadingPosition<T>(of type: T.Type,
                              forBook bookID: String?,
                              publication: Publication?,
                              toURL url: URL?,
                              completion: @escaping (T?) -> ()) where T : NYPLBookmark {
    guard !failRequest,
          let id = bookID,
          let bookmarkSpec = readingPositions[id] else {
      completion(nil)
      return
    }
    
    let bookmarkData = bookmarkSpec.dictionaryForJSONSerialization()
    if type == NYPLReadiumBookmark.self {
      let bookmark = NYPLReadiumBookmarkFactory.make(fromServerAnnotation: bookmarkData,
                                                     annotationType: .readingProgress,
                                                     bookID: id,
                                                     publication: publication)
      completion(bookmark as? T)
      return
    }
    completion(nil)
  }
  
  func postReadingPosition(forBook bookID: String, selectorValue: String) {
    guard !failRequest else {
      return
    }
    
    let bookmarkSpec = NYPLBookmarkSpec(time: Date(),
                                        device: "",
                                        motivation: .readingProgress,
                                        bookID: bookID,
                                        selectorValue: selectorValue)
    readingPositions[bookID] = bookmarkSpec
  }
  
  // Bookmark
  
  func getServerBookmarks<T>(of type: T.Type,
                             forBook bookID: String?,
                             publication: Publication?,
                             atURL annotationURL: URL?,
                             completion: @escaping ([T]?) -> ()) where T : NYPLBookmark {
    guard !failRequest, let id = bookID else {
      completion(nil)
      return
    }
    completion(serverBookmarks[id] as? [T])
  }
  
  func deleteBookmarks(_ bookmarks: [NYPLBookmark]) {
    guard !failRequest else {
      return
    }
    for bookmark in bookmarks {
      if let annotationID = bookmark.annotationId {
        deleteBookmark(annotationId: annotationID, completionHandler: {_ in })
      }
    }
  }

  func deleteBookmark(annotationId: String,
                      completionHandler: @escaping (_ success: Bool) -> ()) {
    let stringComponents = annotationId.components(separatedBy: "_")
    guard !failRequest,
          let bookID = stringComponents.first,
          let bookmarks = serverBookmarks[bookID] else {
      completionHandler(false)
      return
    }
    serverBookmarks[bookID] = bookmarks.filter{ $0.annotationId != annotationId }
    completionHandler(true)
  }

  func uploadLocalBookmarks<T>(_ bookmarks: [T],
                               forBook bookID: String,
                               completion: @escaping ([T], [T]) -> ()) where T : NYPLBookmark {
    guard !failRequest else {
      completion([], bookmarks)
      return
    }
    var bookmarksUpdated = [T]()
    var bookmarksFailedToUpdate = [T]()
    for bookmark in bookmarks {
      postBookmark(bookmark, forBookID: bookID) { serverID in
        if let serverID = serverID {
          var newBookmark = bookmark
          newBookmark.annotationId = serverID
          bookmarksUpdated.append(newBookmark)
        } else {
          bookmarksFailedToUpdate.append(bookmark)
        }
      }
    }
    completion(bookmarksUpdated, bookmarksFailedToUpdate)
  }
  
  func postBookmark(_ bookmark: NYPLBookmark,
                    forBookID bookID: String,
                    completion: @escaping (String?) -> ()) {
    guard !failRequest else {
      completion(nil)
      return
    }

    if let bookmarks = serverBookmarks[bookID],
       bookmarks.contains(where: { $0.annotationId == bookmark.annotationId })
    {
      completion(nil)
      return
    }
    let annotationID = generateAnnotationID(bookID)
    var newBookmark = bookmark
    newBookmark.annotationId = annotationID
    var currentBookmarks = serverBookmarks[bookID] ?? [NYPLReadiumBookmark]()
    currentBookmarks.append(newBookmark)
    serverBookmarks[bookID] = currentBookmarks
    completion(annotationID)
  }
  
  // Permission
  
  func syncIsPossibleAndPermitted() -> Bool {
    return true
  }
  
  // Helper
  
  /// Returns an unique string in the format of "[bookID]_number"
  /// eg. BookID123_37
  func generateAnnotationID(_ bookID: String) -> String {
    annotationCounter += 1
    return "\(bookID)_\(annotationCounter)"
  }
}
