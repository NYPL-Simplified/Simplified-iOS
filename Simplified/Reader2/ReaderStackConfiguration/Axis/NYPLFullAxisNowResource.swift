//
//  NYPLAxisLibraryService.swift
//  Open eBooks
//
//  Created by Raman Singh on 2021-05-18.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation
import R2Shared
import R2Streamer

class NYPLFullAxisNowResource: TransformingResource {
  
  private let aesKey: Data
  private let cypher: NYPLRSACryptographing
  private let decompressor: NYPLZlibDecompressing
  
  init(aesKey: Data,
       cypher: NYPLRSACryptographing,
       decompressor: NYPLZlibDecompressing,
       resource: Resource) {
    
    self.aesKey = aesKey
    self.cypher = cypher
    self.decompressor = decompressor
    super.init(resource)
  }
  
  /// Decrypts the given resource using the `AES` key. Returns original resource if not encrypted or if failure
  /// occurs during decrypting.
  override func transform(_ data: ResourceResult<Data>) -> ResourceResult<Data> {
    return data.tryMap {
      guard
        let compressed = cypher.decryptWithAES($0, key: aesKey),
        /// After decrypting the resource, we get a raw compressed data stream with no header which
        /// has to be decompressed before using.
        let decompressed = decompressor.decompress(sourceData: compressed)
      else {
        return $0
      }
      
      return decompressed
    }
  }
  
  override var length: ResourceResult<UInt64> {
    // Uses `originalLength` or falls back on the actual decrypted data length.
    resource.link.properties.encryption?.originalLength.map { .success(UInt64($0)) }
      ?? super.length
  }
  
}

