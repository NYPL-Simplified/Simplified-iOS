//
//  NYPLAxisBookContentDecryptionAdapter.swift
//  Open eBooks
//
//  Created by Raman Singh on 2021-06-23.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation
import NYPLAxis
import R2Shared
import R2Streamer

struct NYPLAxisBookContentDecryptionAdapter {
  
  private static let aes256cbc = "http://www.w3.org/2001/04/xmlenc#aes256-cbc"
  
  let cypher: NYPLRSACryptographing
  private let decompressor: NYPLAxisDecompression
  
  init?(cypher: NYPLRSACryptographing? = NYPLRSACypher(
          errorLogger: NYPLAxisErrorLogsAdapter()),
       decompressor: NYPLAxisDecompression = NYPLAxisDecompressor()) {
    guard let cypher = cypher else {
      /// No need to log error here since cypher already logs one in case of failed initialization
      return nil
    }
    
    self.cypher = cypher
    self.decompressor = decompressor
  }
  
  /// Decrypts given resource if encrypted. Returns original resource if not encrypted.
  func decrypt(resource: Resource, withKey key: Data) -> Resource {
    guard
      let encryption = resource.link.properties.encryption,
      encryption.algorithm == NYPLAxisBookContentDecryptionAdapter.aes256cbc
    else {
      return resource
    }
    
    let resourceAdapter = NYPLFullAxisNowResourceAdapter(
      aesKey: key, cypher: cypher, decompressor: decompressor)
    
    return NYPLFullAxisNowResource(
      adapter: resourceAdapter, resource: resource)
  }
  
  /// Decrypts the given data using private key to return `AES` key data
  /// - Parameter data: Base64EncodedData
  /// - Returns: `AES` key data
  func decryptAESKey(from data: Data) -> Data? {
    return cypher.decryptWithPKCS1_OAEP(data)
  }
  
}
