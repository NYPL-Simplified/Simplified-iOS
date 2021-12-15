//
//  NYPLAnnotationsMock.swift
//  SimplyETests
//
//  Created by Ernest Fan on 2021-12-07.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation
import R2Shared
@testable import SimplyE

class NYPLAnnotationsMock: NYPLAnnotationSyncing {
  static var serverBookmarks: [String: [NYPLReadiumBookmark]] = [String: [NYPLReadiumBookmark]]()
  static var readingPositions: [String: NYPLBookmarkSpec] = [String: NYPLBookmarkSpec]()
  
  // For generating unique annotation id
  static private var annotationCounter: Int = 0
  
  // Server status
  
  static func requestServerSyncStatus(forAccount userAccount: NYPLUserAccount,
                                      completion: @escaping (_ enableSync: Bool) -> ()) {
    completion(true)
  }
  
  static func updateServerSyncSetting(toEnabled enabled: Bool, completion:@escaping (Bool)->()) {
    completion(false)
  }
  
  // Reading position
  
  static func syncReadingPosition(ofBook bookID: String?,
                                  publication: Publication?,
                                  toURL url:URL?,
                                  completion: @escaping (_ readPos: NYPLReadiumBookmark?) -> ()) {
    guard let id = bookID, let bookmarkSpec = readingPositions[id] else {
      completion(nil)
      return
    }
    let bookmarkData = bookmarkSpec.dictionaryForJSONSerialization()
    let bookmark = NYPLBookmarkFactory.make(fromServerAnnotation: bookmarkData,
                                            annotationType: .readingProgress,
                                            bookID: id,
                                            publication: publication)
    completion(bookmark)
  }
  
  static func postReadingPosition(forBook bookID: String, selectorValue: String) {
    let bookmarkSpec = NYPLBookmarkSpec(time: Date(),
                                        device: "",
                                        motivation: .readingProgress,
                                        bookID: bookID,
                                        selectorValue: selectorValue)
    readingPositions[bookID] = bookmarkSpec
  }
  
  // Bookmark
  
  static func getServerBookmarks(forBook bookID:String?,
                                 publication: Publication?,
                                 atURL annotationURL:URL?,
                                 completion: @escaping (_ bookmarks: [NYPLReadiumBookmark]?) -> ()) {
    guard let id = bookID else {
      completion(nil)
      return
    }
    completion(serverBookmarks[id])
  }
  
  static func deleteBookmarks(_ bookmarks: [NYPLReadiumBookmark]) {
    for bookmark in bookmarks {
      if let annotationID = bookmark.annotationId {
        deleteBookmark(annotationId: annotationID, completionHandler: {_ in })
      }
    }
  }
  
  static func deleteBookmark(annotationId: String,
                             completionHandler: @escaping (_ success: Bool) -> ()) {
    let stringComponents = annotationId.components(separatedBy: "_")
    guard let bookID = stringComponents.first,
      let bookmarks = serverBookmarks[bookID] else {
      completionHandler(false)
      return
    }
    serverBookmarks[bookID] = bookmarks.filter{ $0.annotationId != annotationId }
    completionHandler(true)
  }
  
  static func uploadLocalBookmarks(_ bookmarks: [NYPLReadiumBookmark],
                                   forBook bookID: String,
                                   completion: @escaping ([NYPLReadiumBookmark], [NYPLReadiumBookmark])->()) {
    var bookmarksUpdated = [NYPLReadiumBookmark]()
    var bookmarksFailedToUpdate = [NYPLReadiumBookmark]()
    for bookmark in bookmarks {
      postBookmark(bookmark, forBookID: bookID) { serverID in
        if let serverID = serverID {
          bookmark.annotationId = serverID
          bookmarksUpdated.append(bookmark)
        } else {
          bookmarksFailedToUpdate.append(bookmark)
        }
      }
    }
    completion(bookmarksUpdated, bookmarksFailedToUpdate)
  }
  
  static func postBookmark(_ bookmark: NYPLReadiumBookmark,
                           forBookID bookID: String,
                           completion: @escaping (_ serverID: String?) -> ()) {
    if let bookmarks = serverBookmarks[bookID],
       bookmarks.contains(bookmark)
    {
      completion(nil)
      return
    }
    let annotationID = generateAnnotationID(bookID)
    bookmark.annotationId = annotationID
    var currentBookmarks = serverBookmarks[bookID] ?? [NYPLReadiumBookmark]()
    currentBookmarks.append(bookmark)
    serverBookmarks[bookID] = currentBookmarks
    completion(annotationID)
  }
  
  // Permission
  
  static func syncIsPossibleAndPermitted() -> Bool {
    return true
  }
  
  // Helper
  
  /// Returns an unique string in the format of "[bookID]_number"
  /// eg. BookID123_37
  static func generateAnnotationID(_ bookID: String) -> String {
    annotationCounter += 1
    return "\(bookID)_\(annotationCounter)"
  }
}
