//
//  Bookmark.swift
//
//  Created by Ettore Pasquini on 4/23/20.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation
import R2Shared

// TODO: SIMPLY-2820
// Should be temporary only just to make things compile.
// Meld into NYPLReadiumBookmark.
class NYPLR2Bookmark {
  var id: Int64?
  var publicationID: String
  var resourceIndex: Int
  var locator: Locator
  var creationDate: Date

  init(id: Int64? = nil,
       publicationID: String,
       resourceIndex: Int,
       locator: Locator,
       creationDate: Date = Date()) {
    self.id = id
    self.publicationID = publicationID
    self.resourceIndex = resourceIndex
    self.locator = locator
    self.creationDate = creationDate
  }
}

extension NYPLReadiumBookmark {
  func convertToR2(from publication: Publication) -> NYPLR2Bookmark? {
    guard let publicationID = publication.id else {
      return nil
    }

    guard let link = publication.link(withIDref: self.idref) else {
      return nil
    }

    let locations = Locator.Locations(progression: Double(progressWithinChapter),
                                      totalProgression: Double(progressWithinBook),
                                      position: nil)
    let locator = Locator(href: link.href,
                          type: publication.metadata.type ?? MediaType.xhtml.string,
                          title: self.chapter,
                          locations: locations)

    guard let resourceIndex = publication.readingOrder.firstIndex(withHref: locator.href) else {
      return nil
    }

    let creationDate = NSDate(rfc3339String: self.time) as Date?
    return NYPLR2Bookmark(id: nil,
                          publicationID: publicationID,
                          resourceIndex: resourceIndex,
                          locator: locator,
                          creationDate: creationDate ?? Date())
  }
}

