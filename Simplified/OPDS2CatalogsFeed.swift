//
//  OPDS2CatalogsFeed.swift
//  SimplyE
//
//  Created by Benjamin Anderman on 5/10/19.
//  Copyright © 2019 NYPL Labs. All rights reserved.
//

import Foundation

struct OPDS2CatalogsFeed: Codable {
  struct Metadata: Codable {
    let adobe_vendor_id: String?
    let title: String
  }
  
  let catalogs: [OPDS2Publication]
  let links: [OPDS2Link]
  let metadata: Metadata
  
  static func fromData(_ data: Data) throws -> OPDS2CatalogsFeed {
    enum DateError: String, Error {
      case invalidDate
    }
    
    let jsonDecoder = JSONDecoder()
      
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .iso8601)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    
    jsonDecoder.dateDecodingStrategy = .custom({ (decoder) -> Date in
      let container = try decoder.singleValueContainer()
      let dateStr = try container.decode(String.self)
      
      formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
      if let date = formatter.date(from: dateStr) {
        return date
      }
      formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
      if let date = formatter.date(from: dateStr) {
        return date
      }
      throw DateError.invalidDate
    })
    
    return try jsonDecoder.decode(OPDS2CatalogsFeed.self, from: data)
  }
}
