//
//  NYPLBookLocation+Locator.swift
//  Simplified
//
//  Created by Ernest Fan on 2020-11-09.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation
import R2Shared

extension NYPLBookLocation {
  static let r2Renderer = "readium2"
  
  convenience init?(locator: Locator,
                    renderer: String = NYPLBookLocation.r2Renderer) {
    let locatorString = NYPLBookmarkFactory
      .makeLocatorString(chapterHref: locator.href,
                         chapterProgression: Float(locator.locations.progression ?? 0.0))

    self.init(locationString: locatorString, renderer: renderer)
  }

  func convertToLocator(for publication: Publication) -> Locator? {
    guard self.renderer == NYPLBookLocation.r2Renderer,
      let data = self.locationString.data(using: .utf8),
      let dict = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
      else {
        Log.error(#file, "Failed to convert NYPLBookLocation to Locator object with location string: \(locationString ?? "N/A")")
        return nil
    }

    let dictHref = dict[NYPLBookmarkSpec.Target.Selector.Value.locatorChapterIDKey] as? String
    let dictIdref = dict[NYPLBookmarkSpec.Target.Selector.Value.locatorLegacyChapterIDKey] as? String
    guard let href = dictHref ?? publication.href(forIdref: dictIdref) else {
      Log.error(#file, "Unable to create R2 locator because `href` and `idref` are both nil: \(self.locationString ?? "")")
      return nil
    }

    let progressWithinChapter = dict[NYPLBookmarkSpec.Target.Selector.Value.locatorChapterProgressionKey]
      as? Double ?? 0.0
    let progressWithinBook = dict[NYPLBookLocation.bookProgressKey] as? Double
    let title: String = dict[NYPLBookLocation.titleKey] as? String ?? ""
    let position: Int? = dict[NYPLBookLocation.positionKey] as? Int
    let type = publication.metadata.type ?? MediaType.xhtml.string

    let locations = Locator.Locations(fragments: [],
                                      progression: progressWithinChapter,
                                      totalProgression: progressWithinBook,
                                      position: position,
                                      otherLocations: [:])

    return Locator(href: href,
                   type: type,
                   title: title,
                   locations: locations)
  }
}

private extension NYPLBookLocation {
  static let bookProgressKey = "progressWithinBook"
  static let titleKey = "title"
  static let positionKey = "position"
}
