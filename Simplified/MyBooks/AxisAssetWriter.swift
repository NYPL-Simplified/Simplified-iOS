//
//  AxisAssetWriter.swift
//  Simplified
//
//  Created by Raman Singh on 2021-03-31.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation

@objc protocol AxisAssetWriting {
  func writeAsset(_ data: Data, atURL url: URL) throws
    
}

@objc
class AxisAssetWriter: NSObject, AxisAssetWriting {
    
  func writeAsset(_ data: Data, atURL url: URL) throws {
    let folderURL = url.deletingLastPathComponent()
    let dirExists = FileManager.default.fileExists(atPath: folderURL.path)
    if (!dirExists) {
      try FileManager.default.createDirectory(at: folderURL,
                                              withIntermediateDirectories: true,
                                              attributes: nil)
    }
        
    try data.write(to: url)
  }
    
}
