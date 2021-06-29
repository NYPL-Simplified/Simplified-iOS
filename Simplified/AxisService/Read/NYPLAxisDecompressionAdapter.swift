//
//  NYPLAxisDecompressionAdapter.swift
//  Open eBooks
//
//  Created by Raman Singh on 2021-06-23.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation
import NYPLAxis

struct NYPLAxisDecompressionAdapter {
  
  private let decompresser: NYPLAxisZlibDecompressor
  
  init(decompresser: NYPLAxisZlibDecompressor = NYPLAxisZlibDecompressor(
        errorLogger: NYPLAxisErrorLogsAdapter())) {
    self.decompresser = decompresser
  }
  
  func decompress(sourceData: Data) -> Data? {
    return decompresser.decompress(sourceData: sourceData)
  }
  
}
