//
//  NYPLAxisContentDecryptor.swift
//  Open eBooks
//
//  Created by Raman Singh on 2021-05-18.
//  Copyright © 2021 NYPL. All rights reserved.
//

import Foundation
import R2Shared
import R2Streamer
import NYPLAxis

protocol NYPLAxisContentDecrypting {
  var cypher: NYPLRSACryptographing { get }
  func decryptAESKey(from data: Data) -> Data?
  func decrypt(resource: Resource, withKey key: Data) -> Resource
}

struct NYPLAxisContentDecryptor: NYPLAxisContentDecrypting {
  
  private let decryptionAdapter: NYPLAxisBookContentDecryptionAdapter
  let cypher: NYPLRSACryptographing
  
  init?(adapter: NYPLAxisBookContentDecryptionAdapter? = NYPLAxisBookContentDecryptionAdapter()) {
    guard let adapter = adapter else {
      return nil
    }
    self.decryptionAdapter = adapter
    self.cypher = decryptionAdapter.cypher
  }
  
  /// Decrypts given resource if encrypted. Returns original resource if not encrypted.
  func decrypt(resource: Resource, withKey key: Data) -> Resource {
    return decryptionAdapter.decrypt(resource: resource, withKey: key)
  }
  
  /// Decrypts the given data using private key to return `AES` key data
  /// - Parameter data: Base64EncodedData
  /// - Returns: `AES` key data
  func decryptAESKey(from data: Data) -> Data? {
    return decryptionAdapter.decryptAESKey(from: data)
  }
  
}


