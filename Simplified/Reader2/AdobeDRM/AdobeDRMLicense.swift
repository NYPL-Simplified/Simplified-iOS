//
//  AdobeDRMLicense.swift
//  SimplyE
//
//  Created by Vladimir Fedorov on 13.05.2020.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation
import R2Shared
import R2Streamer

/// DRM License for Adobe DRM
class AdobeDRMLicense: DRMLicense {
  
  var publicationContainer: Container?
  
  /// DRM container for file
  var adobeDRMContainer: AdobeDRMContainer?
  
  /// DRM license for file
  /// - Parameter container: .epub file container
  init(for container: Container) {
    publicationContainer = container
    let fileUrl = URL(fileURLWithPath: container.rootFile.rootPath)
    // META-INF is a part of epub structure
    let encryptionPath = "META-INF/encryption.xml"
    do {
      let data = try container.data(relativePath: encryptionPath)
      adobeDRMContainer = AdobeDRMContainer(url: fileUrl, encryptionData: data)
      if let errorMessage = adobeDRMContainer?.epubDecodingError {
        // TODO: SIMPLY-2656
        // There may be a better logger method for this
        NYPLErrorLogger.logError(withCode: .epubDecodingError,
                                 summary: "Unable to initialize Adobe DRM license",
                                 message: errorMessage)
      }
    } catch {
      // This is not an error, container doesn't have a method to check the file existance
      // If epub file contains no DRM, encryption.xml doesn't exist.
      // In this case, container.data(...) will throw an error,
      // no need to do anything about it.
    }
    
  }
  
  /// Depichers the given encrypted data to be displayed in the reader.
  func decipher(_ data: Data) throws -> Data? {
    guard let container = adobeDRMContainer else { return data }
    let decodedData = container.decode(data)
    if let errorMessage = adobeDRMContainer?.epubDecodingError {
      // TODO: SIMPLY-2656
      // There may be a better logger method for this
      NYPLErrorLogger.logError(withCode: .epubDecodingError,
                               summary: "Unable to decrype Adobe DRM license",
                               message: errorMessage)
    }
    return decodedData
  }
}
