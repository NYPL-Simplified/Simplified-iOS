//
//  OPDS2Link.swift
//  SimplyE
//
//  Created by Benjamin Anderman on 5/10/19.
//  Copyright © 2019 NYPL Labs. All rights reserved.
//

import Foundation

struct OPDS2Link: Codable {
  let href: String
  let type: String?
  let rel: String?
  let templated: Bool?

  let displayNames: [OPDS2InternationalVariable]?
  let descriptions: [OPDS2InternationalVariable]?
}

struct OPDS2InternationalVariable: Codable {
  let language: String
  let value: String
}
