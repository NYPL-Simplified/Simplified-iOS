//
//  NYPLAxisDecompressor.swift
//  Open eBooks
//
//  Created by Raman Singh on 2021-05-18.
//  Copyright © 2021 NYPL. All rights reserved.
//

import Foundation

protocol NYPLAxisDecompression {
  func decompress(sourceData: Data) -> Data?
}

struct NYPLAxisDecompressor: NYPLAxisDecompression {
  
  private let decompressionAdapter: NYPLAxisDecompressionAdapter
  
  init(decompressionAdapter: NYPLAxisDecompressionAdapter = NYPLAxisDecompressionAdapter()) {
    self.decompressionAdapter = decompressionAdapter
  }
  
  /// Decompresses the given data using compression algorithm for Axis
  func decompress(sourceData: Data) -> Data? {
    return decompressionAdapter.decompress(sourceData: sourceData)
  }
  
}
