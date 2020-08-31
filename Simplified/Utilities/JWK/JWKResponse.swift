//
//  JWKResponse.swift
//  Simplified
//
//  Created by Vladimir Fedorov on 31.08.2020.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation

struct JWKResponse: Codable {
  let keys: [JWK]
}
