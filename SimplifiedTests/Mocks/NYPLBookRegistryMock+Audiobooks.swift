//
//  NYPLBookRegistryMock+Audiobooks.swift
//  SimplyETests
//
//  Created by Ernest Fan on 2022-09-29.
//  Copyright © 2022 NYPL. All rights reserved.
//

import Foundation
import NYPLAudiobookToolkit
@testable import SimplyE

extension NYPLBookRegistryMock: NYPLAudiobookRegistryProvider {
  func audiobookBookmarks(for identifier: String) -> [NYPLAudiobookBookmark] {
    guard let record = identifiersToRecords[identifier] else { return [NYPLAudiobookBookmark]() }
    if let bookmarks = record.audiobookBookmarks as? [NYPLAudiobookBookmark] {
      return bookmarks.sorted { $0.lessThan($1) }
    } else {
      return [NYPLAudiobookBookmark]()
    }
  }
  
  func addAudiobookBookmark(_ audiobookBookmark: NYPLAudiobookBookmark, for identifier: String) {
    guard let record = identifiersToRecords[identifier] else { return }
    var bookmarks = [NYPLAudiobookBookmark]()
    if let recordBookmarks = record.audiobookBookmarks as? [NYPLAudiobookBookmark] {
      bookmarks.append(contentsOf: recordBookmarks)
    }
    bookmarks.append(audiobookBookmark)
    identifiersToRecords[identifier] = record.withAudiobookBookmarks(bookmarks)
  }
  
  func deleteAudiobookBookmark(_ audiobookBookmark: NYPLAudiobookBookmark, for identifier: String) {
    guard let record = identifiersToRecords[identifier] else { return }
    if let bookmarks = record.audiobookBookmarks as? [NYPLAudiobookBookmark] {
      let newBookmarks = bookmarks.filter { $0 != audiobookBookmark }
      identifiersToRecords[identifier] = record.withAudiobookBookmarks(newBookmarks)
    }
  }
  
  func replaceAudiobookBookmark(_ oldAudiobookBookmark: NYPLAudiobookBookmark,
                                with newAudiobookBookmark: NYPLAudiobookBookmark,
                                for identifier: String) {
    guard let record = identifiersToRecords[identifier] else { return }
    if let bookmarks = record.audiobookBookmarks as? [NYPLAudiobookBookmark] {
      var newBookmarks = bookmarks.filter { $0 != oldAudiobookBookmark }
      newBookmarks.append(newAudiobookBookmark)
      identifiersToRecords[identifier] = record.withAudiobookBookmarks(newBookmarks)
    }
  }
}
