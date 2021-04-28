//
//  NYPLBookmarkR2Location.swift
//
//  Created by Ettore Pasquini on 4/23/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation
import R2Shared

/// Collects the information from R2 required to build (or refer to) a bookmark,
/// identify a given location as a bookmark, compare bookmarks.
class NYPLBookmarkR2Location {
  var resourceIndex: Int
  var locator: Locator
  var creationDate: Date

  init(resourceIndex: Int,
       locator: Locator,
       creationDate: Date = Date()) {
    self.resourceIndex = resourceIndex
    self.locator = locator
    self.creationDate = creationDate
  }
}
