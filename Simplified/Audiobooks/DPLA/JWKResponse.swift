//
//  JWKResponse.swift
//  Simplified
//
//  Created by Vladimir Fedorov on 31.08.2020.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation
import NYPLAudiobookToolkit

struct JWKResponse: Codable {
  let keys: [JWK]
}

struct JWK: Codable {
  /// Custom JWK structure in response
  private enum JWKKeys: String, CodingKey {
    case kty
    case publickKeyEncoded = "http://www.feedbooks.com/audiobooks/signature/pem-key"
  }
  /// Key type
  let kty: String
  /// Public key data
  let publicKeyData: Data?
  // Need to manually parse the key with the Url as the key
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: JWKKeys.self)
    self.kty = try container.decode(String.self, forKey: .kty)
    let pemString = try container.decode(String.self, forKey: .publickKeyEncoded).replacingOccurrences(of: "\n", with: "")
    self.publicKeyData = Data(base64Encoded: RSAUtils.stripPEMKeyHeader(pemString))    
  }
}
