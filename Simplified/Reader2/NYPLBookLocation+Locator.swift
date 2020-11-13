//
//  NYPLBookLocation+Locator.swift
//  Simplified
//
//  Created by Ernest Fan on 2020-11-09.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation
import R2Shared

let hrefKey = "idref"
let typeKey = "locatorType"
let chapterProgressKey = "progressWithinChapter"
let bookProgressKey = "progressWithinBook"

extension NYPLBookLocation {
  static let r2Renderer = "readium2"
  
  convenience init(locator: Locator, publication: Publication, renderer: String) {
    let idref = publication.idref(forHref: locator.href) ?? locator.href
    // Store all required properties of a Locator object in a string
    let locationString = """
    {"\(hrefKey)":"\(idref)","\(typeKey)":"\(locator.type)","\(chapterProgressKey)":\(locator.locations.progression ?? 0.0),"\(bookProgressKey)":\(locator.locations.totalProgression ?? 0.0)}
    """
    self.init(locationString: locationString, renderer: renderer)
  }
  
  func convertToLocator() -> Locator? {
    guard self.renderer == NYPLBookLocation.r2Renderer,
      let data = self.locationString.data(using: .utf8),
      let dict = try? JSONSerialization.jsonObject(with: data, options: []) as! [String: Any],
      let href = dict[hrefKey] as? String,
      let type = dict[typeKey] as? String,
      let progressWithinChapter = dict[chapterProgressKey] as? Double,
      let progressWithinBook = dict[bookProgressKey] as? Double else {
      return nil
    }
    
    let locations = Locator.Locations(fragments: [],
                                      progression: progressWithinChapter,
                                      totalProgression: progressWithinBook,
                                      position: nil,
                                      otherLocations: [:])
    
    return Locator(href: href,
                   type: type,
                   locations: locations)
  }
}
