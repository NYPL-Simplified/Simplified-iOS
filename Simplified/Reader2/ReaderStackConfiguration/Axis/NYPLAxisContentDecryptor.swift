//
//  NYPLAxisContentDecryptor.swift
//  Open eBooks
//
//  Created by Raman Singh on 2021-05-12.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation
import R2Shared
import R2Streamer

protocol NYPLAxisContentDecrypting {
  var cypher: NYPLRSACryptographing { get }
  func decryptAESKey(from data: Data) -> Data?
  func decrypt(resource: Resource, withKey key: Data) -> Resource
}

struct NYPLAxisContentDecryptor: NYPLAxisContentDecrypting {
  
  private static let aes256cbc = "http://www.w3.org/2001/04/xmlenc#aes256-cbc"
  
  let cypher: NYPLRSACryptographing
  let decompressor: NYPLZlibDecompressing
  
  init(cypher: NYPLRSACryptographing,
       decompressor: NYPLZlibDecompressing = NYPLZlibDecompressor()) {
    self.cypher = cypher
    self.decompressor = decompressor
  }
  
  /// Decrypts given resource if encrypted. Returns original resource if not encrypted.
  func decrypt(resource: Resource, withKey key: Data) -> Resource {
    guard
      let encryption = resource.link.properties.encryption,
      encryption.algorithm == NYPLAxisContentDecryptor.aes256cbc
    else {
      return resource
    }
    
    return FullAxisNowResource(
      aesKey: key, cypher: cypher, decompressor: decompressor, resource: resource)
  }
  
  /// Decrypts the given data using private key to return `AES` key data
  /// - Parameter data: Base64EncodedData
  /// - Returns: `AES` key data
  func decryptAESKey(from data: Data) -> Data? {
    return cypher.decryptWithPKCS1_OAEP(data)
  }
  
}

