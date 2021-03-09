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
  
  convenience init?(locator: Locator, publication: Publication, renderer: String) {
    // Store all required properties of a locator object in a dictionary
    // Create a json string from it and use it as the location string in NYPLBookLocation
    // There is no specific format to follow, the value of the keys can be change if needed
    let dict: [String : Any] = [
      NYPLBookLocation.hrefKey: locator.href,
      NYPLBookLocation.typeKey: locator.type,
      NYPLBookLocation.chapterProgressKey: locator.locations.progression ?? 0.0,
      NYPLBookLocation.bookProgressKey: locator.locations.totalProgression ?? 0.0
    ]
    
    guard let jsonString = serializeJSONString(dict) else {
      Log.warn(#file, "Failed to serialize json string from dictionary - \(dict.debugDescription)")
      return nil
    }
    
    self.init(locationString: jsonString, renderer: renderer)
  }
  
  func convertToLocator() -> Locator? {
    guard self.renderer == NYPLBookLocation.r2Renderer,
      let data = self.locationString.data(using: .utf8),
      let dict = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any],
      let href = dict[NYPLBookLocation.hrefKey] as? String,
      let type = dict[NYPLBookLocation.typeKey] as? String,
      let progressWithinChapter = dict[NYPLBookLocation.chapterProgressKey] as? Double,
      let progressWithinBook = dict[NYPLBookLocation.bookProgressKey] as? Double else {
      Log.error(#file, "Failed to convert NYPLBookLocation to Locator object with location string: \(locationString ?? "N/A")")
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

private extension NYPLBookLocation {
  static let hrefKey = "idref"
  static let typeKey = "locatorType"
  static let chapterProgressKey = "progressWithinChapter"
  static let bookProgressKey = "progressWithinBook"
}
