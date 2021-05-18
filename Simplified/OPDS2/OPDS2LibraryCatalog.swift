//
//  OPDS2LibraryCatalog.swift
//  SimplyE
//
//  Created by Benjamin Anderman on 5/10/19.
//  Copyright © 2019 NYPL Labs. All rights reserved.
//

import Foundation

struct OPDS2LibraryCatalog: Codable {
  struct Metadata: Codable {
    struct Subject: Codable {
      let name: String
      let code: String
      let scheme: String
    }
    
    let title: String
    let description: String?
    let identifier: String
    let modified: Date
    let distance: String?
    let area: String?
    let subject: [Subject]
    
    private enum CodingKeys: String, CodingKey {
      case title
      case description
      case identifier
      case modified
      case distance = "schema:distance"
      case area = "schema:areaServed"
      case subject
    }
  }
  
  let links: [OPDS2Link]
  let metadata: Metadata
  let images: [OPDS2Link]?
}
