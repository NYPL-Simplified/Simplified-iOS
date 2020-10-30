//
//  NYPLBookRegistryMock.swift
//  Simplified
//
//  Created by Ettore Pasquini on 10/14/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation
@testable import SimplyE

class NYPLBookRegistryMock: NSObject, NYPLBookRegistrySyncing, NYPLBookRegistryProvider {
  var syncing = false
  var identifiersToRecords = [String: NYPLBookRegistryRecord]()

  func reset(_ libraryAccountUUID: String) {
    syncing = false
  }

  func syncResettingCache(_ resetCache: Bool,
                          completionHandler: ((_ success: Bool) -> Void)?) {
    syncing = true
    DispatchQueue.global(qos: .background).async {
      self.syncing = false
    }
  }

  func save() {
  }
    
  func readiumBookmarks(forIdentifier identifier: String) -> [NYPLReadiumBookmark] {
    guard let record = identifiersToRecords[identifier] else { return [NYPLReadiumBookmark]() }
    return record.readiumBookmarks.sorted{ $0.progressWithinBook > $1.progressWithinBook }
  }
  
  func location(forIdentifier identifier: String) -> NYPLBookLocation? {
    guard let record = identifiersToRecords[identifier] else { return nil }
    return record.location
  }
    
  func add(_ bookmark: NYPLReadiumBookmark, forIdentifier identifier: String) {
    guard let record = identifiersToRecords[identifier] else { return }
    var bookmarks = [NYPLReadiumBookmark]()
    bookmarks.append(contentsOf: record.readiumBookmarks)
    bookmarks.append(bookmark)
    identifiersToRecords[identifier] = record.withReadiumBookmarks(bookmarks)
  }

  func delete(_ bookmark: NYPLReadiumBookmark, forIdentifier identifier: String) {
    guard let record = identifiersToRecords[identifier] else { return }
    let bookmarks = record.readiumBookmarks.filter { $0 != bookmark }
    identifiersToRecords[identifier] = record.withReadiumBookmarks(bookmarks)
  }
  
  func replace(_ oldBookmark: NYPLReadiumBookmark, with newBookmark: NYPLReadiumBookmark, forIdentifier identifier: String) {
    guard let record = identifiersToRecords[identifier] else { return }
    var bookmarks = record.readiumBookmarks.filter { $0 != oldBookmark }
    bookmarks.append(newBookmark)
    identifiersToRecords[identifier] = record.withReadiumBookmarks(bookmarks)
  }
}
