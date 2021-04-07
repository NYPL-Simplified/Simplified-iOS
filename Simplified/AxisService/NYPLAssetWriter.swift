//
//  NYPLAssetWriter.swift
//  Simplified
//
//  Created by Raman Singh on 2021-04-06.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation

struct NYPLAssetWriter {
  
  /// writes asset at provided url while creating intermediate directories if not present.
  /// - Parameters:
  ///   - data: Data to be written
  ///   - url: Desired locattion of asset to be written
  /// - Throws: Throws an error if failure to create directories or write data occurs.
  static func writeAsset(_ data: Data, atURL url: URL) throws {
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
