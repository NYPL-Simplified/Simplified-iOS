//
//  NYPLFullAxisNowResourceAdapter.swift
//  Open eBooks
//
//  Created by Raman Singh on 2021-06-23.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation
import NYPLAxis
import R2Shared
import R2Streamer

struct NYPLFullAxisNowResourceAdapter {
  
  private let aesKey: Data
  private let cypher: NYPLRSACryptographing
  private let decompressor: NYPLAxisDecompression
  
  init(aesKey: Data,
       cypher: NYPLRSACryptographing,
       decompressor: NYPLAxisDecompression) {
    
    self.aesKey = aesKey
    self.cypher = cypher
    self.decompressor = decompressor
  }
  
  /// Decrypts the given resource using the `AES` key. Returns original resource if not encrypted or if failure
  /// occurs during decrypting.
  func transform(_ data: ResourceResult<Data>) -> ResourceResult<Data> {
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
  
}
