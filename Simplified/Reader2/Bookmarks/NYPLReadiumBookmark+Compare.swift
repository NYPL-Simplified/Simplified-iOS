//
//  NYPLReadiumBookmark+R2.swift
//
//  Created by Ettore Pasquini on 4/23/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation
import R2Shared

extension NYPLReadiumBookmark {

  /// Determines if a given locator matches the location addressed by this
  /// bookmark.
  ///
  /// - Complexity: O(*1*).
  ///
  /// - Parameters:
  ///   - locator: The object representing the given location in `publication`.
  ///   - publication: The publication the `locator` is referring to.
  ///
  /// - Returns: `true` if the `locator`'s position matches the bookmark's.
  func locationMatches(_ locator: Locator,
                       inPublication publication: Publication) -> Bool {

    let locatorChapterProgress: Float?
    if let chapterProgress = locator.locations.progression {
      locatorChapterProgress = Float(chapterProgress)
    } else {
      locatorChapterProgress = nil
    }

    guard self.href == locator.href else {
      return false
    }

    return self.progressWithinChapter =~= locatorChapterProgress
  }

  override func isEqual(_ object: Any?) -> Bool {
    guard let other = object as? NYPLReadiumBookmark else {
      return false
    }

    let progressIsEqual = (self.progressWithinChapter =~= other.progressWithinChapter)

    switch self.chapterID {
    case .href(let href):
      return href == other.href && progressIsEqual
    case .idref(let idref):
      return idref == other.idref && (progressIsEqual || self.contentCFI == other.contentCFI)
    }
  }

  @objc func lessThan(_ bookmark: NYPLReadiumBookmark) -> Bool {
    if let progress1 = progressWithinBook, let progress2 = bookmark.progressWithinBook {
      return progress1 < progress2
    }

    if href == bookmark.href {
      return progressWithinChapter < bookmark.progressWithinChapter
    }

    return creationTime < bookmark.creationTime
  }
}

