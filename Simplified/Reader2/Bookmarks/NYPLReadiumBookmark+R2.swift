//
//  NYPLReadiumBookmark+R2.swift
//
//  Created by Ettore Pasquini on 4/23/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation
import R2Shared

extension NYPLReadiumBookmark {

  /// Converts the bookmark model into a location object that can be used
  /// with Readium 2.
  ///
  /// Not every single piece of data contained in this bookmark is considered
  /// for this conversion: only what's strictly necessary to be able to point
  /// at the same location inside the `Publication`.
  ///
  /// - Complexity: O(*n*) where *n* is the length of internal
  /// `Publication.readingOrder` data structure.
  ///
  /// - Parameter publication: The R2 publication object where the bookmark is
  /// located.

  /// - Returns: An object with R2 location information pointing at the same
  /// position the bookmark model is pointing to.
  func convertToR2(from publication: Publication) -> NYPLBookmarkR2Location? {
    let href: String
    if let r2href = self.href {
      href = r2href
    } else if let idref = self.idref, let r1href = publication.link(withIDref: idref)?.href {
      href = r1href
    } else {
      return nil
    }

    var position: Int? = nil
    if let page = page, let pos = Int(page) {
      position = pos
    }

    let bookProgress = (progressWithinBook != nil) ? Double(progressWithinBook!) : nil
    let locations = Locator.Locations(progression: Double(progressWithinChapter),
                                      totalProgression: bookProgress,
                                      position: position)
    let locator = Locator(href: href,
                          type: publication.metadata.type ?? MediaType.xhtml.string,
                          title: self.chapter,
                          locations: locations)

    guard let resourceIndex = publication.readingOrder.firstIndex(withHREF: locator.href) else {
      return nil
    }

    return NYPLBookmarkR2Location(resourceIndex: resourceIndex,
                                  locator: locator,
                                  creationDate: creationTime)
  }

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

    if self.progressWithinChapter =~= locatorChapterProgress {
      return true
    }

    return false
  }
}

