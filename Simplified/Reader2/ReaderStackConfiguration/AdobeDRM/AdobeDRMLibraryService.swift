//
//  AdobeDRMLibraryService.swift
//  SimplyE
//
//  Created by Vladimir Fedorov on 13.05.2020.
//  Copyright © 2020 NYPL. All rights reserved.
//

import Foundation
import UIKit
import R2Shared
import R2Streamer

#if FEATURE_DRM_CONNECTOR

class AdobeDRMLibraryService: DRMLibraryService {

  var contentProtection: ContentProtection? = AdobeDRMContentProtection()
    
  /// Returns whether this DRM can fulfill the given file into a protected publication.
  /// - Parameter file: file URL
  /// - Returns: `true` if file contains Adobe DRM license information.
  func canFulfill(_ file: URL) -> Bool {
    return file.path.hasSuffix(RIGHTS_XML_SUFFIX)
  }
  
  /// Fulfills the given file to the fully protected publication.
  /// - Parameter file: file URL
  /// - Returns: Deferred fulfilled publication or error
  func fulfill(_ file: URL) -> Deferred<DRMFulfilledPublication, Error> {
    // Publications with Adobe DRM are fulfilled (license data already stored in _rights.xml file),
    // this step is aalways a success.
    return deferred { completion in
      completion(.success(DRMFulfilledPublication(
        localURL: file,
        suggestedFilename: file.lastPathComponent
      )))
    }
  }
}

#endif
