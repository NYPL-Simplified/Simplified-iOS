//
//  OPDS2Publication.swift
//  SimplyE
//
//  Created by Benjamin Anderman on 5/10/19.
//  Copyright © 2019 NYPL Labs. All rights reserved.
//

import Foundation

struct OPDS2Publication: Codable {
  struct Metadata: Codable {
    let updated: Date
    let description: String?
    let id: String
    let title: String
  }
  
  let links: [OPDS2Link]
  let metadata: Metadata
  let images: [OPDS2Link]?
}
