//
//  AdobeDRMLibraryService.swift
//  SimplyE
//
//  Created by Vladimir Fedorov on 13.05.2020.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation
import UIKit
import R2Shared
import R2Streamer

class AdobeDRMLibraryService: DRMLibraryService {
    
  /// Publication container for DRM Container
  var container: Container?
  
  /// Library service brand
  var brand: DRM.Brand {
    return .adobe
  }
  
  /// Returns whether this DRM can fulfill the given file into a protected publication.
  /// - Parameter file: file URL
  /// - Returns: `true` if file contains Adobe DRM license information.
  func canFulfill(_ file: URL) -> Bool {
    return file.path.hasSuffix("_rights.xml")
  }
  
  /// Fulfills the given file to the fully protected publication.
  /// - Parameters:
  ///   - file: file URL
  ///   - completion: fulfilled publication, CancellableResult<DRMFulfilledPublication>
  func fulfill(_ file: URL, completion: @escaping (CancellableResult<DRMFulfilledPublication>) -> Void) {
    let publication = DRMFulfilledPublication(localURL: file, downloadTask: nil, suggestedFilename: file.lastPathComponent)
    completion(.success(publication))
  }
  
  /// Fills the DRM context of the given protected publication.
  /// - Parameters:
  ///   - publication: file URL
  ///   - drm: DRM
  ///   - completion: result of retrieving a license for the publication, CancellableResult<DRM?>
  func loadPublication(at publication: URL, drm: DRM, completion: @escaping (CancellableResult<DRM?>) -> Void) {
    retrieveLicense { (license, error) in
      if let license = license {
        var drm = drm
        drm.license = license as DRMLicense
        completion(.success(drm))
      } else if let error = error {
        completion(.failure(error))
      } else {
        completion(.cancelled)
      }
    }
  }
  
  /// Retrieve license for the publication
  /// - Parameters:
  ///   - completion: license for the file, AdobeDRMLicense
  func retrieveLicense(completion: (_ license: AdobeDRMLicense?, _ error: Error?) -> ()) {
    guard let container = container else {
      // TODO: SIMPLY-2656
      // There may be a better logger method for this
      NYPLErrorLogger.logError(withCode: .epubDecodingError,
                               summary: "Unable to retrieve Adobe DRM license: container not initialized",
                               message: "AdobeDRMLibraryService container is not initialized")
      completion(nil, nil)
      return
    }
    completion(AdobeDRMLicense(for: container), nil)
  }
  
}
