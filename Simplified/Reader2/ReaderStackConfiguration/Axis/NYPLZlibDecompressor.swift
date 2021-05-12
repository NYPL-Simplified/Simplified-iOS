//
//  NYPLZlibDecompressor.swift
//  Open eBooks
//
//  Created by Raman Singh on 2021-05-12.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation
import Compression

protocol NYPLZlibDecompressing {
  func decompress(sourceData: Data) -> Data?
}

struct NYPLZlibDecompressor: NYPLZlibDecompressing {
  
  /// Decompresses the given data using `ZLIB COMPRESSION` algorithm
  /// - Parameter sourceData: raw compressed data stream with no header
  /// - Returns: Decompressed data
  func decompress(sourceData: Data) -> Data? {
    let size = 8_000_000
    let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: size)
    let result = sourceData.withUnsafeBytes ({
        let read = compression_decode_buffer(
          buffer, size, $0.baseAddress!.bindMemory(to: UInt8.self, capacity: 1),
          sourceData.count, nil, COMPRESSION_ZLIB)
        
      return Data(bytes: buffer, count:read)
    }) as Data
  
    buffer.deallocate()
    return result
  }
  
}
